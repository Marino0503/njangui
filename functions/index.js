const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret, defineString } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// ── Secrets Fapshi (voir functions/.env.example) ──
const FAPSHI_API_USER = defineSecret('FAPSHI_API_USER');
const FAPSHI_API_KEY = defineSecret('FAPSHI_API_KEY');
const FAPSHI_WEBHOOK_SECRET = defineSecret('FAPSHI_WEBHOOK_SECRET');
// sandbox par défaut ; passer à "https://live.fapshi.com" en production
const FAPSHI_BASE_URL = defineString('FAPSHI_BASE_URL', {
  default: 'https://sandbox.fapshi.com',
});

// Calcule le montant réellement dû par un membre (montant de base de la
// tontine + pénalité de sanction active éventuelle). Ne fait JAMAIS
// confiance à un montant envoyé par le client.
async function calculerMontantDu(tontine, membreId) {
  const sanctionsSnap = await db
    .collection('sanctions')
    .where('tontineId', '==', tontine.id)
    .where('membreId', '==', membreId)
    .where('estPayee', '==', false)
    .limit(1)
    .get();

  if (!sanctionsSnap.empty) {
    const sanction = sanctionsSnap.docs[0];
    return { montant: sanction.data().montantDu, sanctionId: sanction.id };
  }

  return { montant: tontine.montant, sanctionId: null };
}

// ════════════════════════════════════════════════════════════════
// initierPaiement : appelée depuis l'app Flutter (cloud_functions).
// Calcule le montant côté serveur, crée le paiement en attente, et
// demande à Fapshi un lien de paiement (checkout hébergé Fapshi).
// ════════════════════════════════════════════════════════════════
exports.initierPaiement = onCall(
  { secrets: [FAPSHI_API_USER, FAPSHI_API_KEY] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Connexion requise.');
    }

    const { tontineId, membreId } = request.data || {};
    if (!tontineId || !membreId) {
      throw new HttpsError('invalid-argument', 'tontineId et membreId requis.');
    }

    const tontineSnap = await db.collection('tontines').doc(tontineId).get();
    if (!tontineSnap.exists) {
      throw new HttpsError('not-found', 'Tontine introuvable.');
    }
    const tontine = { id: tontineSnap.id, ...tontineSnap.data() };

    const membre = (tontine.membres || []).find((m) => m.id === membreId);
    if (!membre) {
      throw new HttpsError('not-found', 'Membre introuvable.');
    }
    if (membre.userId !== uid) {
      throw new HttpsError(
        'permission-denied',
        'Vous ne pouvez initier un paiement que pour vous-même.',
      );
    }

    const { montant, sanctionId } = await calculerMontantDu(tontine, membreId);

    const paiementRef = db.collection('paiements').doc();
    await paiementRef.set({
      id: paiementRef.id,
      membreId,
      membreNom: membre.nom,
      montant,
      date: new Date().toISOString(),
      tontineId,
      tontineNom: tontine.nom,
      statut: 'en_attente',
      sanctionId,
      fapshiTransId: null,
    });

    try {
      const reponse = await fetch(`${FAPSHI_BASE_URL.value()}/initiate-pay`, {
        method: 'POST',
        headers: {
          apiuser: FAPSHI_API_USER.value(),
          apikey: FAPSHI_API_KEY.value(),
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          amount: Math.round(montant),
          userId: uid,
          externalId: paiementRef.id,
          message: `Cotisation ${tontine.nom}`,
        }),
      });

      const data = await reponse.json();

      if (!reponse.ok || !data.link) {
        throw new Error(data.message || 'Réponse Fapshi invalide');
      }

      await paiementRef.update({ fapshiTransId: data.transId });

      return { link: data.link, paiementId: paiementRef.id };
    } catch (erreur) {
      logger.error('Erreur initiation Fapshi', erreur);
      await paiementRef.update({ statut: 'echec' });
      throw new HttpsError('internal', 'Impossible de contacter Fapshi.');
    }
  },
);

// ════════════════════════════════════════════════════════════════
// webhookFapshi : URL fixe à configurer une fois dans le dashboard
// Fapshi (par service). Appelée par Fapshi à chaque changement de
// statut d'un paiement. Vérifie le secret avant de faire confiance
// au contenu.
// ════════════════════════════════════════════════════════════════
exports.webhookFapshi = onRequest(
  { secrets: [FAPSHI_WEBHOOK_SECRET] },
  async (req, res) => {
    if (req.headers['x-wh-secret'] !== FAPSHI_WEBHOOK_SECRET.value()) {
      logger.warn('Webhook Fapshi : secret invalide');
      res.status(401).send('secret invalide');
      return;
    }

    const { externalId, status, transId } = req.body || {};
    if (!externalId) {
      res.status(200).send('ignoré (pas de externalId)');
      return;
    }

    const paiementRef = db.collection('paiements').doc(externalId);
    const paiementSnap = await paiementRef.get();

    if (!paiementSnap.exists) {
      logger.warn(`Webhook Fapshi : paiement ${externalId} introuvable`);
      res.status(200).send('ignoré (paiement introuvable)');
      return;
    }

    const paiement = paiementSnap.data();

    // Idempotence : n'applique les effets qu'une seule fois
    if (paiement.statut === 'paye' || paiement.statut === 'echec') {
      res.status(200).send('déjà traité');
      return;
    }

    if (status === 'SUCCESSFUL') {
      await appliquerPaiementReussi(paiementRef, paiement);
    } else if (status === 'FAILED' || status === 'EXPIRED') {
      await paiementRef.update({ statut: 'echec', fapshiTransId: transId });
    }

    res.status(200).send('ok');
  },
);

async function appliquerPaiementReussi(paiementRef, paiement) {
  const tontineRef = db.collection('tontines').doc(paiement.tontineId);

  await db.runTransaction(async (tx) => {
    const tontineSnap = await tx.get(tontineRef);
    if (!tontineSnap.exists) return;
    const tontine = tontineSnap.data();

    const membres = (tontine.membres || []).map((m) =>
      m.id === paiement.membreId ? { ...m, aPaye: true } : m,
    );

    tx.update(tontineRef, {
      membres,
      totalCollecte: (tontine.totalCollecte || 0) + paiement.montant,
      soldeDisponible: (tontine.soldeDisponible || 0) + paiement.montant,
    });

    tx.update(paiementRef, { statut: 'paye' });

    if (paiement.sanctionId) {
      tx.update(db.collection('sanctions').doc(paiement.sanctionId), {
        estPayee: true,
      });
    }

    const notifRef = db.collection('notifications').doc();
    tx.set(notifRef, {
      id: notifRef.id,
      userId: tontine.gestionnaireId,
      titre: 'Paiement effectué',
      message: `${paiement.membreNom} a payé ${paiement.montant} FCFA pour "${paiement.tontineNom}"`,
      date: new Date().toISOString(),
      type: 3, // TypeNotification.nouveauDepot (voir notification_model.dart)
      lu: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}
