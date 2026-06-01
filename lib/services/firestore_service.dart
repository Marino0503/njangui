import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tontine.dart';
import '../models/notification_model.dart';
import '../models/paiement.dart';
import '../models/pret.dart';

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
      'membres': tontine.membres
          .map((m) => {'id': m.id, 'nom': m.nom, 'aPaye': m.aPaye})
          .toList(),
      'tours': tontine.tours.map((t) => t.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'totalCollecte': 0,
      'totalDistribue': 0,
      'soldeDisponible': 0,
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
}
