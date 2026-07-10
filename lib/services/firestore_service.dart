import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tontine.dart';
import '../models/notification_model.dart';
import '../models/paiement.dart';
import '../models/pret.dart';
import '../models/sanction.dart';
import '../utils/formatage.dart';
import '../models/demande_adhesion.dart';
import 'user_service.dart';

class FirestoreService {
  // Singleton
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // Instance Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Références des collections ──
  CollectionReference get _tontines => _db.collection('tontines');
  CollectionReference get _notifications => _db.collection('notifications');

  // ════════════════════════════════════════
  //           TONTINES
  // ════════════════════════════════════════

  // Créer une tontine
  Future<void> creerTontine(Tontine tontine) async {
    await _tontines.doc(tontine.id).set({
      'id': tontine.id,
      'nom': tontine.nom,
      'montant': tontine.montant,
      'frequence': tontine.frequence,
      'frequenceEcheance': tontine.frequenceEcheance,
      'prochaineEcheance': tontine.prochaineEcheance,
      'enCours': tontine.enCours,
      'dateDebut': tontine.dateDebut.toIso8601String(),
      'ordreReception': tontine.ordreReception,
      'nombreMembres': tontine.nombreMembres,
      'paiementsEnregistres': tontine.paiementsEnregistres,
      'prevuesObligatoires': tontine.prevuesObligatoires,
      'membresVoientHistorique': tontine.membresVoientHistorique,
      'gestionnaire': tontine.gestionnaire,
      'codeInvitation': tontine.codeInvitation,
      'membres': tontine.membres.map((m) => m.toMap()).toList(),
      'gestionnaireId': tontine.gestionnaireId,
      'tours': tontine.tours.map((t) => t.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'totalCollecte': 0,
      'totalDistribue': 0,
      'soldeDisponible': 0,
      'penaliteParJour': tontine.penaliteParJour,
      'sanctionsActives': tontine.sanctionsActives,
    });
  }

  // Récupérer toutes les tontines en temps réel
  // Mes tontines (celles que je gère)
  Stream<List<Tontine>> getMesTontines() {
    final uid = UserService().uidActuel;
    if (uid == null) return Stream.value([]);

    return _tontines.where('gestionnaireId', isEqualTo: uid).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _tontineFromMap(data);
      }).toList()..sort((a, b) => b.dateDebut.compareTo(a.dateDebut));
    });
  }

  // Tontines que j'ai rejointes (je suis membre actif, pas gestionnaire)
  Stream<List<Tontine>> getTontinesRejointes() {
    final uid = UserService().uidActuel;
    if (uid == null) return Stream.value([]);

    return _tontines.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _tontineFromMap(data);
          })
          .where((t) {
            if (t.gestionnaireId == uid) return false;
            return t.membres.any(
              (m) => m.userId == uid && m.statut == StatutMembre.actif,
            );
          })
          .toList()
        ..sort((a, b) => b.dateDebut.compareTo(a.dateDebut));
    });
  }

  // Mettre à jour les membres d'une tontine
  // ✅ Nouveau
  Future<void> mettreAJourMembres(
    String tontineId,
    List<Membre> membres,
  ) async {
    await _tontines.doc(tontineId).update({
      'membres': membres.map((m) => m.toMap()).toList(),
    });
  }

  // Chercher une tontine par code
  Future<Tontine?> trouverParCode(String code) async {
    final snapshot = await _tontines
        .where('codeInvitation', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first.data() as Map<String, dynamic>;
    return _tontineFromMap(data);
  }

  // Toutes les tontines où je suis impliqué (créées + rejointes)
  Stream<List<Tontine>> getTontines() {
    final uid = UserService().uidActuel;
    if (uid == null) return Stream.value([]);

    return _tontines.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => _tontineFromMap(doc.data() as Map<String, dynamic>))
          .where((t) {
            if (t.gestionnaireId == uid) return true;
            return t.membres.any(
              (m) => m.userId == uid && m.statut == StatutMembre.actif,
            );
          })
          .toList()
        ..sort((a, b) => b.dateDebut.compareTo(a.dateDebut));
    });
  }

  // ════════════════════════════════════════
  //           NOTIFICATIONS
  // ════════════════════════════════════════

  // Créer une notification
  Future<void> creerNotification(NotificationModel notif) async {
    await _notifications.doc(notif.id).set({
      'id': notif.id,
      'userId': notif.userId,
      'titre': notif.titre,
      'message': notif.message,
      'date': notif.date.toIso8601String(),
      'type': notif.type.index,
      'lu': notif.lu,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Récupérer les notifications en temps réel
  Stream<List<NotificationModel>> getNotifications() {
    final uid = UserService().uidActuel;
    if (uid == null) return Stream.value([]);

    return _notifications
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return NotificationModel(
              id: data['id'],
              userId: data['userId'] ?? '',
              titre: data['titre'],
              message: data['message'],
              date: DateTime.parse(data['date']),
              type: TypeNotification.values[data['type']],
              lu: data['lu'],
            );
          }).toList();
        });
  }

  // Marquer notification comme lue
  Future<void> marquerNotifCommeLue(String id) async {
    await _notifications.doc(id).update({'lu': true});
  }

  // Marquer toutes comme lues
  Future<void> marquerToutesCommeLues() async {
    final uid = UserService().uidActuel;
    if (uid == null) return;

    final snapshot = await _notifications
        .where('userId', isEqualTo: uid)
        .where('lu', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'lu': true});
    }
    await batch.commit();
  }

  // ════════════════════════════════════════
  //           HELPERS
  // ════════════════════════════════════════

  // Convertit un Map en Tontine
  Tontine _tontineFromMap(Map<String, dynamic> data) {
    final membresData = data['membres'] as List<dynamic>? ?? [];
    final membres = membresData.map((m) {
      return Membre.fromMap(m as Map<String, dynamic>);
    }).toList();

    final toursData = data['tours'] as List<dynamic>? ?? [];
    final tours = toursData.map((t) {
      return Tour.fromMap(t as Map<String, dynamic>);
    }).toList();

    return Tontine(
      id: data['id'] ?? '',
      nom: data['nom'] ?? '',
      montant: (data['montant'] as num? ?? 0).toDouble(),
      frequence: data['frequence'] ?? 'mois',
      frequenceEcheance: data['frequenceEcheance'] ?? 'semaine',
      prochaineEcheance: data['prochaineEcheance'] ?? '',
      enCours: data['enCours'] ?? false,
      dateDebut: DateTime.parse(
        data['dateDebut'] ?? DateTime.now().toIso8601String(),
      ),
      ordreReception: data['ordreReception'] ?? 'aleatoire',
      nombreMembres: data['nombreMembres'] ?? 0,
      paiementsEnregistres: data['paiementsEnregistres'] ?? true,
      prevuesObligatoires: data['prevuesObligatoires'] ?? true,
      membresVoientHistorique: data['membresVoientHistorique'] ?? true,
      gestionnaire: data['gestionnaire'] ?? '',
      codeInvitation: data['codeInvitation'] ?? '',
      membres: membres,
      tours: tours,
      totalCollecte: (data['totalCollecte'] as num? ?? 0).toDouble(),
      totalDistribue: (data['totalDistribue'] as num? ?? 0).toDouble(),
      soldeDisponible: (data['soldeDisponible'] as num? ?? 0).toDouble(),
      gestionnaireId: data['gestionnaireId'] ?? '',
    );
  }

  // Supprimer une tontine
  Future<void> supprimerTontine(String id) async {
    await _tontines.doc(id).delete();
  }

  // Mettre à jour une tontine
  Future<void> mettreAJourTontine(Tontine tontine) async {
    await _tontines.doc(tontine.id).update({
      'nom': tontine.nom,
      'montant': tontine.montant,
      'frequence': tontine.frequence,
      'nombreMembres': tontine.nombreMembres,
      'ordreReception': tontine.ordreReception,
      'paiementsEnregistres': tontine.paiementsEnregistres,
      'prevuesObligatoires': tontine.prevuesObligatoires,
      'membresVoientHistorique': tontine.membresVoientHistorique,
    });
  }

  // ════════════════════════════════════════
  //           PAIEMENTS
  // ════════════════════════════════════════

  CollectionReference get _paiements => _db.collection('paiements');

  // Enregistrer un paiement
  Future<void> enregistrerPaiement(Paiement paiement) async {
    await _paiements.doc(paiement.id).set(paiement.toMap());
  }

  // Récupérer les paiements d'une tontine en temps réel
  Stream<List<Paiement>> getPaiements(String tontineId) {
    return _paiements.where('tontineId', isEqualTo: tontineId).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return Paiement.fromMap(doc.data() as Map<String, dynamic>);
      }).toList()..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  // Récupérer tous les paiements de l'utilisateur
  Stream<List<Paiement>> getTousPaiements() {
    return _paiements.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Paiement.fromMap(doc.data() as Map<String, dynamic>);
      }).toList()..sort((a, b) => b.date.compareTo(a.date));
    });
  }
  // ════════════════════════════════════════
  //           STATISTIQUES
  // ════════════════════════════════════════

  // Récupère les stats globales
  Stream<Map<String, dynamic>> getStats() {
    return _tontines.snapshots().asyncMap((tontinesSnapshot) async {
      final tontines = tontinesSnapshot.docs;

      // Nombre total de tontines
      final nombreTontines = tontines.length;

      // Nombre total de membres
      int nombreMembres = 0;
      for (var doc in tontines) {
        final data = doc.data() as Map<String, dynamic>;
        final membres = data['membres'] as List<dynamic>? ?? [];
        nombreMembres += membres.length;
      }

      // Paiements
      final paiementsSnapshot = await _paiements.get();
      final paiements = paiementsSnapshot.docs;

      // Total payé
      double totalPaye = 0;
      int nombrePaies = 0;
      int nombreRetards = 0;

      for (var doc in paiements) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['statut'] == 'paye') {
          totalPaye += (data['montant'] as num).toDouble();
          nombrePaies++;
        } else {
          nombreRetards++;
        }
      }

      // Prêts
      final pretsSnapshot = await _prets.get();
      int nombrePretsEnCours = 0;
      double totalPrets = 0;

      for (var doc in pretsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['statut'] != StatutPret.rembourse.index &&
            data['statut'] != StatutPret.refuse.index) {
          nombrePretsEnCours++;
          totalPrets += (data['montant'] as num).toDouble();
        }
      }

      return {
        'nombreTontines': nombreTontines,
        'nombreMembres': nombreMembres,
        'totalPaye': totalPaye,
        'nombrePaies': nombrePaies,
        'nombreRetards': nombreRetards,
        'nombrePretsEnCours': nombrePretsEnCours,
        'totalPrets': totalPrets,
      };
    });
  }

  // Supprimer un membre d'une tontine
  Future<void> supprimerMembre(String tontineId, String membreId) async {
    final doc = await _tontines.doc(tontineId).get();
    final data = doc.data() as Map<String, dynamic>;
    final membres = (data['membres'] as List<dynamic>)
        .where((m) => m['id'] != membreId)
        .toList();

    await _tontines.doc(tontineId).update({'membres': membres});
  }

  // ════════════════════════════════════════
  //           TOURS
  // ════════════════════════════════════════

  // Générer les tours automatiquement
  Future<void> genererTours(Tontine tontine) async {
    final membres = tontine.membres;
    if (membres.isEmpty) return;

    List<Membre> membresOrdonnes = List.from(membres);

    // Si tirage aléatoire, mélange les membres
    if (tontine.ordreReception == 'aleatoire') {
      membresOrdonnes.shuffle();
    }

    // Calcule le montant total par tour
    final montantTotal = tontine.montant * membres.length;

    // Génère les tours
    final tours = List.generate(membres.length, (index) {
      final membre = membresOrdonnes[index];
      final date = DateTime(
        tontine.dateDebut.year,
        tontine.dateDebut.month + index,
        tontine.dateDebut.day,
      );

      return Tour(
        numero: index + 1,
        membreId: membre.id,
        membreNom: membre.nom,
        date: date,
        estComplete: false,
        montantTotal: montantTotal,
      );
    });

    // Sauvegarde dans Firestore
    await _tontines.doc(tontine.id).update({
      'tours': tours.map((t) => t.toMap()).toList(),
    });
  }

  // Marquer un tour comme complété
  Future<void> completerTour(String tontineId, int numeroTour) async {
    final doc = await _tontines.doc(tontineId).get();
    final data = doc.data() as Map<String, dynamic>;
    final tours = (data['tours'] as List<dynamic>).map((t) {
      final tour = t as Map<String, dynamic>;
      if (tour['numero'] == numeroTour) {
        return {...tour, 'estComplete': true};
      }
      return tour;
    }).toList();

    await _tontines.doc(tontineId).update({'tours': tours});
  }
  // ════════════════════════════════════════
  //           PRÊTS
  // ════════════════════════════════════════

  CollectionReference get _prets => _db.collection('prets');

  // Créer une demande de prêt
  Future<void> creerPret(Pret pret) async {
    await _prets.doc(pret.id).set(pret.toMap());
  }

  // Récupérer les prêts d'une tontine
  Stream<List<Pret>> getPretsTontine(String tontineId) {
    return _prets.where('tontineId', isEqualTo: tontineId).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => Pret.fromMap(doc.data() as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.dateDemande.compareTo(a.dateDemande));
    });
  }

  // Récupérer tous les prêts
  Stream<List<Pret>> getTousPrets() {
    return _prets.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Pret.fromMap(doc.data() as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.dateDemande.compareTo(a.dateDemande));
    });
  }

  // Accepter un prêt
  Future<void> accepterPret(String pretId) async {
    final dateAcceptation = DateTime.now();
    final pret = await _prets.doc(pretId).get();
    final data = pret.data() as Map<String, dynamic>;
    final dureeEnMois = data['dureeEnMois'] as int;

    await _prets.doc(pretId).update({
      'statut': StatutPret.accepte.index,
      'dateAcceptation': dateAcceptation.toIso8601String(),
      'dateEcheance': DateTime(
        dateAcceptation.year,
        dateAcceptation.month + dureeEnMois,
        dateAcceptation.day,
      ).toIso8601String(),
    });
  }

  // Refuser un prêt
  Future<void> refuserPret(String pretId) async {
    await _prets.doc(pretId).update({'statut': StatutPret.refuse.index});
  }

  // Ajouter un remboursement
  Future<void> ajouterRemboursement(
    String pretId,
    Remboursement remboursement,
  ) async {
    final doc = await _prets.doc(pretId).get();
    final data = doc.data() as Map<String, dynamic>;
    final rembs = (data['remboursements'] as List<dynamic>? ?? []);
    rembs.add(remboursement.toMap());

    // Calcul montant total et remboursé
    final montant = (data['montant'] as num).toDouble();
    final tauxInteret = (data['tauxInteret'] as num).toDouble();
    final montantTotal = montant + (montant * tauxInteret / 100);
    final montantRembourse = rembs.fold<double>(
      0,
      (sum, r) => sum + (r['montant'] as num).toDouble(),
    );

    // Met à jour le statut si remboursé
    final nouveauStatut = montantRembourse >= montantTotal
        ? StatutPret.rembourse.index
        : StatutPret.enCours.index;

    await _prets.doc(pretId).update({
      'remboursements': rembs,
      'statut': nouveauStatut,
    });
  }

  // Supprimer un prêt
  Future<void> supprimerPret(String pretId) async {
    await _prets.doc(pretId).delete();
  }

  // ════════════════════════════════════════
  //           FLUX FINANCIERS
  // ════════════════════════════════════════

  // Mettre à jour les flux financiers d'une tontine
  Future<void> mettreAJourFluxFinanciers({
    required String tontineId,
    required double montantPaiement,
    required String typeFlux, // 'paiement', 'distribution', 'pret'
  }) async {
    final doc = await _tontines.doc(tontineId).get();
    final data = doc.data() as Map<String, dynamic>;

    double totalCollecte = (data['totalCollecte'] as num? ?? 0).toDouble();
    double totalDistribue = (data['totalDistribue'] as num? ?? 0).toDouble();
    double soldeDisponible = (data['soldeDisponible'] as num? ?? 0).toDouble();

    switch (typeFlux) {
      case 'paiement':
        totalCollecte += montantPaiement;
        soldeDisponible += montantPaiement;
        break;
      case 'distribution':
        totalDistribue += montantPaiement;
        soldeDisponible -= montantPaiement;
        break;
      case 'pret':
        soldeDisponible -= montantPaiement;
        break;
    }

    await _tontines.doc(tontineId).update({
      'totalCollecte': totalCollecte,
      'totalDistribue': totalDistribue,
      'soldeDisponible': soldeDisponible,
    });
  }

  // Récupérer tous les flux d'une tontine
  Stream<List<Map<String, dynamic>>> getFluxFinanciers(String tontineId) {
    return _paiements.where('tontineId', isEqualTo: tontineId).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList()..sort((a, b) {
        final dateA = DateTime.parse(a['date'] as String);
        final dateB = DateTime.parse(b['date'] as String);
        return dateB.compareTo(dateA);
      });
    });
  }

  // ════════════════════════════════════════
  //           PROCHAINE ÉCHÉANCE
  // ════════════════════════════════════════

  // Calcule et met à jour la prochaine échéance
  Future<void> mettreAJourProchaineEcheance(String tontineId) async {
    final doc = await _tontines.doc(tontineId).get();
    final data = doc.data() as Map<String, dynamic>;

    final tours = (data['tours'] as List<dynamic>? ?? []);
    final frequenceEcheance = data['frequenceEcheance'] as String? ?? 'semaine';
    final dateDebut = DateTime.parse(data['dateDebut'] as String);

    DateTime prochaineEcheance;

    if (tours.isEmpty) {
      prochaineEcheance = _calculerProchaineDate(dateDebut, frequenceEcheance);
    } else {
      final toursNonCompletes = tours.where((t) {
        return t['estComplete'] == false;
      }).toList();

      if (toursNonCompletes.isEmpty) {
        prochaineEcheance = _calculerProchaineDate(
          dateDebut,
          frequenceEcheance,
        );
      } else {
        prochaineEcheance = DateTime.parse(
          toursNonCompletes.first['date'] as String,
        );
      }
    }

    const mois = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    final dateFormatee =
        '${prochaineEcheance.day} ${mois[prochaineEcheance.month - 1]}';

    await _tontines.doc(tontineId).update({'prochaineEcheance': dateFormatee});
  }

  // Calcule la prochaine date selon la frequenceEcheance
  DateTime _calculerProchaineDate(
    DateTime dateDebut,
    String frequenceEcheance,
  ) {
    DateTime prochaine;

    switch (frequenceEcheance) {
      case 'semaine':
        prochaine = dateDebut.add(const Duration(days: 7));
        break;
      case 'mois':
        prochaine = DateTime(
          dateDebut.year,
          dateDebut.month + 1,
          dateDebut.day,
        );
        break;
      case 'trimestre':
        prochaine = DateTime(
          dateDebut.year,
          dateDebut.month + 3,
          dateDebut.day,
        );
        break;
      default:
        prochaine = dateDebut.add(const Duration(days: 7));
    }

    return prochaine;
  }

  // Récupérer une tontine en temps réel
  Stream<Tontine?> getTontineStream(String tontineId) {
    return _tontines.doc(tontineId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _tontineFromMap(doc.data() as Map<String, dynamic>);
    });
  }

  // ════════════════════════════════════════
  //           SANCTIONS
  // ════════════════════════════════════════

  CollectionReference get _sanctions => _db.collection('sanctions');

  // Créer une sanction
  Future<void> creerSanction(Sanction sanction) async {
    await _sanctions.doc(sanction.id).set(sanction.toMap());
  }

  // Récupérer les sanctions d'une tontine
  Stream<List<Sanction>> getSanctionsTontine(String tontineId) {
    return _sanctions.where('tontineId', isEqualTo: tontineId).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => Sanction.fromMap(doc.data() as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.dateSanction.compareTo(a.dateSanction));
    });
  }

  // Marquer une sanction comme payée
  Future<void> payerSanction(String sanctionId) async {
    await _sanctions.doc(sanctionId).update({'estPayee': true});
  }

  // Calcule le nombre de fréquences de retard
  int _calculerNombreFrequencesRetard(DateTime dateEcheance, String frequence) {
    final maintenant = DateTime.now();
    final difference = maintenant.difference(dateEcheance);

    switch (frequence) {
      case 'jour':
        return difference.inDays;
      case 'semaine':
        return (difference.inDays / 7).floor();
      case 'mois':
        return ((maintenant.year - dateEcheance.year) * 12 +
                maintenant.month -
                dateEcheance.month)
            .abs();
      case 'trimestre':
        return (((maintenant.year - dateEcheance.year) * 12 +
                    maintenant.month -
                    dateEcheance.month) /
                3)
            .floor();
      default:
        return difference.inDays;
    }
  }

  // Vérifie et crée une sanction si nécessaire
  Future<Sanction?> verifierEtCreerSanction({
    required Tontine tontine,
    required Membre membre,
    required DateTime dateEcheance,
  }) async {
    if (!tontine.sanctionsActives) return null;

    final nombreFrequences = _calculerNombreFrequencesRetard(
      dateEcheance,
      tontine.frequence,
    );

    if (nombreFrequences <= 0) return null;

    // Vérifie si une sanction existe déjà pour cette échéance
    final sanctionsExistantes = await _sanctions
        .where('tontineId', isEqualTo: tontine.id)
        .where('membreId', isEqualTo: membre.id)
        .where('estPayee', isEqualTo: false)
        .get();

    // Calcule le montant dû
    final montantDu = Sanction.calculerMontantDu(
      tontine.montant,
      nombreFrequences,
    );

    if (sanctionsExistantes.docs.isNotEmpty) {
      // Met à jour la sanction existante
      final sanctionId = sanctionsExistantes.docs.first.id;
      await _sanctions.doc(sanctionId).update({
        'nombreFrequencesRetard': nombreFrequences,
        'montantDu': montantDu,
      });

      return Sanction.fromMap(
        sanctionsExistantes.docs.first.data() as Map<String, dynamic>,
      );
    }

    // Crée une nouvelle sanction
    final sanction = Sanction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tontineId: tontine.id,
      tontineNom: tontine.nom,
      membreId: membre.id,
      membreNom: membre.nom,
      montantInitial: tontine.montant,
      montantDu: montantDu,
      nombreFrequencesRetard: nombreFrequences,
      dateEcheance: dateEcheance,
      dateSanction: DateTime.now(),
      estPayee: false,
    );

    await creerSanction(sanction);

    // Notification
    await creerNotification(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: membre.userId ?? '',
        titre: '⚠️ Sanction de retard',
        message:
            '${membre.nom} doit payer ${Formatage.montant(montantDu)} au lieu de ${Formatage.montant(tontine.montant)} pour $nombreFrequences fréquence(s) de retard dans "${tontine.nom}"',
        date: DateTime.now(),
        type: TypeNotification.retardContribution,
      ),
    );

    return sanction;
  }

  // Récupère la sanction active d'un membre
  Future<Sanction?> getSanctionActive(String tontineId, String membreId) async {
    final snapshot = await _sanctions
        .where('tontineId', isEqualTo: tontineId)
        .where('membreId', isEqualTo: membreId)
        .where('estPayee', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return Sanction.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
  }

  // Envoie un rappel avant l'échéance
  Future<void> envoyerRappelEcheance({
    required Tontine tontine,
    required Membre membre,
  }) async {
    if (!tontine.sanctionsActives) return;

    await creerNotification(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: membre.userId ?? '',
        titre: '⏰ Rappel de cotisation',
        message:
            '${membre.nom}, n\'oubliez pas de payer ${Formatage.montant(tontine.montant)} pour "${tontine.nom}". En cas de retard, une pénalité de 10% sera appliquée !',
        date: DateTime.now(),
        type: TypeNotification.retardContribution,
      ),
    );
  }

  // Supprimer une sanction
  Future<void> supprimerSanction(String sanctionId) async {
    await _sanctions.doc(sanctionId).delete();
  }
  // ════════════════════════════════════════
  //        DEMANDES D'ADHÉSION
  // ════════════════════════════════════════

  CollectionReference get _demandes => _db.collection('demandes_adhesion');

  // Créer une invitation (Marino invite Jean)
  Future<void> envoyerInvitation({
    required Tontine tontine,
    required String userId,
    required String userNom,
    required String gestionnaireId,
    required String gestionnaireNom,
  }) async {
    final demande = DemandeAdhesion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tontineId: tontine.id,
      tontineNom: tontine.nom,
      userId: userId,
      userNom: userNom,
      gestionnaireId: gestionnaireId,
      gestionnaireNom: gestionnaireNom,
      type: TypeDemande.invitation,
      statut: StatutDemande.enAttente,
      date: DateTime.now(),
    );

    await _demandes.doc(demande.id).set(demande.toMap());

    // Ajoute le membre avec statut "en attente"
    final nouveauMembre = Membre(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nom: userNom,
      aPaye: false,
      userId: userId,
      statut: StatutMembre.enAttenteValidationMembre,
    );

    final membresMAJ = [...tontine.membres, nouveauMembre];
    await mettreAJourMembres(tontine.id, membresMAJ);

    // Notification au membre invité
    await creerNotification(
      NotificationModel(
        id: '${demande.id}_notif',
        userId: userId,
        titre: 'Invitation à une tontine',
        message:
            '$gestionnaireNom veut vous ajouter à "${tontine.nom}". Acceptez-vous ?',
        date: DateTime.now(),
        type: TypeNotification.nouveauMembre,
      ),
    );
  }

  // Créer une demande de rejoindre (Jean demande à Marino)
  Future<void> demanderAdhesion({
    required Tontine tontine,
    required String userId,
    required String userNom,
  }) async {
    final demande = DemandeAdhesion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tontineId: tontine.id,
      tontineNom: tontine.nom,
      userId: userId,
      userNom: userNom,
      gestionnaireId: tontine.gestionnaireId,
      gestionnaireNom: tontine.gestionnaire,
      type: TypeDemande.demandeRejoindre,
      statut: StatutDemande.enAttente,
      date: DateTime.now(),
    );

    await _demandes.doc(demande.id).set(demande.toMap());

    // Ajoute le membre avec statut "en attente"
    final nouveauMembre = Membre(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nom: userNom,
      aPaye: false,
      userId: userId,
      statut: StatutMembre.enAttenteValidationGestionnaire,
    );

    final membresMAJ = [...tontine.membres, nouveauMembre];
    await mettreAJourMembres(tontine.id, membresMAJ);

    // Notification au gestionnaire
    await creerNotification(
      NotificationModel(
        id: '${demande.id}_notif',
        userId: tontine.gestionnaireId,
        titre: 'Demande d\'adhésion',
        message: '$userNom veut rejoindre "${tontine.nom}"',
        date: DateTime.now(),
        type: TypeNotification.nouveauMembre,
      ),
    );
  }

  // Récupérer les demandes en attente pour un utilisateur
  // (invitations reçues + demandes à valider en tant que gestionnaire)
  // Divisé en 2 sous-requêtes car les règles Firestore sécurisées
  // exigent que chaque requête filtre explicitement par userId/gestionnaireId.
  Stream<List<DemandeAdhesion>> getDemandesPourUtilisateur(String userId) {
    final controller = StreamController<List<DemandeAdhesion>>.broadcast();

    List<DemandeAdhesion> invitationsRecues = [];
    List<DemandeAdhesion> demandesAValider = [];

    void emettre() {
      if (controller.isClosed) return;
      controller.add([...invitationsRecues, ...demandesAValider]);
    }

    final sub1 = _demandes
        .where('type', isEqualTo: TypeDemande.invitation.index)
        .where('userId', isEqualTo: userId)
        .where('statut', isEqualTo: StatutDemande.enAttente.index)
        .snapshots()
        .listen((snapshot) {
          invitationsRecues = snapshot.docs
              .map(
                (doc) =>
                    DemandeAdhesion.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
          emettre();
        }, onError: controller.addError);

    final sub2 = _demandes
        .where('type', isEqualTo: TypeDemande.demandeRejoindre.index)
        .where('gestionnaireId', isEqualTo: userId)
        .where('statut', isEqualTo: StatutDemande.enAttente.index)
        .snapshots()
        .listen((snapshot) {
          demandesAValider = snapshot.docs
              .map(
                (doc) =>
                    DemandeAdhesion.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
          emettre();
        }, onError: controller.addError);

    controller.onCancel = () async {
      await sub1.cancel();
      await sub2.cancel();
    };

    return controller.stream;
  }

  // Accepter une demande/invitation
  Future<void> accepterDemande(DemandeAdhesion demande) async {
    await _demandes.doc(demande.id).update({
      'statut': StatutDemande.acceptee.index,
    });

    // Met à jour le statut du membre dans la tontine
    final doc = await _tontines.doc(demande.tontineId).get();
    final data = doc.data() as Map<String, dynamic>;
    final membresData = data['membres'] as List<dynamic>;

    final membres = membresData.map((m) {
      final membre = Membre.fromMap(m as Map<String, dynamic>);
      if (membre.userId == demande.userId) {
        return Membre(
          id: membre.id,
          nom: membre.nom,
          aPaye: membre.aPaye,
          userId: membre.userId,
          statut: StatutMembre.actif,
        );
      }
      return membre;
    }).toList();

    await _tontines.doc(demande.tontineId).update({
      'membres': membres.map((m) => m.toMap()).toList(),
    });

    // Notification à l'autre partie
    final destinataireId = demande.type == TypeDemande.invitation
        ? demande.gestionnaireId
        : demande.userId;
    final messageTexte = demande.type == TypeDemande.invitation
        ? '${demande.userNom} a accepté votre invitation pour "${demande.tontineNom}"'
        : 'Vous avez été accepté(e) dans "${demande.tontineNom}"';

    await creerNotification(
      NotificationModel(
        id: '${demande.id}_accept_notif',
        userId: destinataireId,
        titre: 'Demande acceptée',
        message: messageTexte,
        date: DateTime.now(),
        type: TypeNotification.nouveauMembre,
      ),
    );

    // Identifiant non utilisé directement mais conservé pour clarté
    // destinataireId pourrait servir pour des notifs ciblées plus tard
    assert(destinataireId.isNotEmpty);
  }

  // Refuser une demande/invitation
  Future<void> refuserDemande(DemandeAdhesion demande) async {
    await _demandes.doc(demande.id).update({
      'statut': StatutDemande.refusee.index,
    });

    // Retire le membre de la tontine
    final doc = await _tontines.doc(demande.tontineId).get();
    final data = doc.data() as Map<String, dynamic>;
    final membresData = data['membres'] as List<dynamic>;

    final membres = membresData
        .map((m) => Membre.fromMap(m as Map<String, dynamic>))
        .where((m) => m.userId != demande.userId)
        .toList();

    await _tontines.doc(demande.tontineId).update({
      'membres': membres.map((m) => m.toMap()).toList(),
    });

    // Notification
    final destinataireId = demande.type == TypeDemande.invitation
        ? demande.gestionnaireId
        : demande.userId;
    final messageTexte = demande.type == TypeDemande.invitation
        ? '${demande.userNom} a refusé votre invitation pour "${demande.tontineNom}"'
        : 'Votre demande pour "${demande.tontineNom}" a été refusée';

    await creerNotification(
      NotificationModel(
        id: '${demande.id}_refus_notif',
        userId: destinataireId,
        titre: 'Demande refusée',
        message: messageTexte,
        date: DateTime.now(),
        type: TypeNotification.retardContribution,
      ),
    );
  }
}
