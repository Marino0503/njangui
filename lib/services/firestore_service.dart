import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tontine.dart';
import '../models/notification_model.dart';

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
      'membres': tontine.membres
          .map((m) => {'id': m.id, 'nom': m.nom, 'aPaye': m.aPaye})
          .toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Récupérer toutes les tontines en temps réel
  Stream<List<Tontine>> getTontines() {
    return _tontines.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _tontineFromMap(data);
      }).toList();
    });
  }

  // Mettre à jour les membres d'une tontine
  Future<void> mettreAJourMembres(
    String tontineId,
    List<Membre> membres,
  ) async {
    await _tontines.doc(tontineId).update({
      'membres': membres
          .map((m) => {'id': m.id, 'nom': m.nom, 'aPaye': m.aPaye})
          .toList(),
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

  // ════════════════════════════════════════
  //           NOTIFICATIONS
  // ════════════════════════════════════════

  // Créer une notification
  Future<void> creerNotification(NotificationModel notif) async {
    await _notifications.doc(notif.id).set({
      'id': notif.id,
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
    return _notifications
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return NotificationModel(
              id: data['id'],
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
    final snapshot = await _notifications.where('lu', isEqualTo: false).get();

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
      return Membre(id: m['id'], nom: m['nom'], aPaye: m['aPaye']);
    }).toList();

    return Tontine(
      id: data['id'],
      nom: data['nom'],
      montant: (data['montant'] as num).toDouble(),
      frequence: data['frequence'],
      prochaineEcheance: data['prochaineEcheance'],
      enCours: data['enCours'],
      dateDebut: DateTime.parse(data['dateDebut']),
      ordreReception: data['ordreReception'],
      nombreMembres: data['nombreMembres'],
      paiementsEnregistres: data['paiementsEnregistres'],
      prevuesObligatoires: data['prevuesObligatoires'],
      membresVoientHistorique: data['membresVoientHistorique'],
      gestionnaire: data['gestionnaire'],
      codeInvitation: data['codeInvitation'],
      membres: membres,
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
}
