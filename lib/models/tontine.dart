import 'dart:math';

// Modèle pour un membre
enum StatutMembre {
  actif,
  enAttenteValidationGestionnaire, // Jean a demandé, Marino valide
  enAttenteValidationMembre, // Marino invite, Jean valide
  refuse,
}

class Membre {
  final String id;
  final String nom;
  final bool aPaye;
  final String? userId;
  final StatutMembre statut;

  Membre({
    required this.id,
    required this.nom,
    required this.aPaye,
    this.userId,
    this.statut = StatutMembre.actif,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'aPaye': aPaye,
      'userId': userId,
      'statut': statut.index,
    };
  }

  factory Membre.fromMap(Map<String, dynamic> data) {
    return Membre(
      id: data['id'],
      nom: data['nom'],
      aPaye: data['aPaye'],
      userId: data['userId'],
      statut: StatutMembre.values[data['statut'] ?? 0],
    );
  }
}

class Tontine {
  final String id;
  final String nom;
  final double montant;
  final String frequence;
  final String prochaineEcheance;
  final String frequenceEcheance;
  final bool enCours;
  final DateTime dateDebut;
  final String ordreReception;
  final int nombreMembres;
  final bool paiementsEnregistres;
  final bool prevuesObligatoires;
  final bool membresVoientHistorique;
  final String gestionnaire;
  final List<Membre> membres;
  final String codeInvitation;
  final double totalCollecte;
  final double totalDistribue;
  final double soldeDisponible;
  final List<Tour> tours;
  final double penaliteParJour;
  final bool sanctionsActives;
  final String gestionnaireId;

  Tontine({
    required this.id,
    required this.nom,
    required this.montant,
    required this.frequence,
    required this.prochaineEcheance,
    required this.frequenceEcheance,
    required this.enCours,
    required this.dateDebut,
    required this.ordreReception,
    required this.nombreMembres,
    required this.paiementsEnregistres,
    required this.prevuesObligatoires,
    required this.membresVoientHistorique,
    required this.gestionnaire,
    required this.membres,
    required this.codeInvitation,
    required this.tours,
    required this.gestionnaireId,
    this.penaliteParJour = 500,
    this.sanctionsActives = false,
    this.totalCollecte = 0,
    this.totalDistribue = 0,
    this.soldeDisponible = 0,
  });

  static String genererCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      6,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'montant': montant,
      'frequence': frequence,
      'frequenceEcheance': frequenceEcheance,
      'prochaineEcheance': prochaineEcheance,
      'enCours': enCours,
      'dateDebut': dateDebut.toIso8601String(),
      'ordreReception': ordreReception,
      'nombreMembres': nombreMembres,
      'paiementsEnregistres': paiementsEnregistres,
      'prevuesObligatoires': prevuesObligatoires,
      'membresVoientHistorique': membresVoientHistorique,
      'gestionnaire': gestionnaire,
      'codeInvitation': codeInvitation,
      'membres': membres.map((m) => m.toMap()).toList(),
      'tours': tours.map((t) => t.toMap()).toList(),
      'totalCollecte': totalCollecte,
      'totalDistribue': totalDistribue,
      'soldeDisponible': soldeDisponible,
      'penaliteParJour': penaliteParJour,
      'sanctionsActives': sanctionsActives,
      'gestionnaireId': gestionnaireId,
    };
  }

  factory Tontine.fromMap(Map<String, dynamic> data) {
    final membresData = data['membres'] as List<dynamic>? ?? [];
    final membres = membresData.map((m) {
      return Membre.fromMap(m as Map<String, dynamic>);
    }).toList();

    final toursData = data['tours'] as List<dynamic>? ?? [];
    final tours = toursData.map((t) {
      return Tour.fromMap(t as Map<String, dynamic>);
    }).toList();

    return Tontine(
      id: data['id'],
      nom: data['nom'],
      montant: (data['montant'] as num).toDouble(),
      frequence: data['frequence'] ?? 'jour',
      frequenceEcheance: data['frequenceEcheance'] ?? 'semaine',
      prochaineEcheance: data['prochaineEcheance'] ?? '',
      enCours: data['enCours'] ?? false,
      dateDebut: DateTime.parse(data['dateDebut']),
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
      penaliteParJour: (data['penaliteParJour'] as num? ?? 500).toDouble(),
      sanctionsActives: data['sanctionsActives'] ?? false,
      gestionnaireId: data['gestionnaireId'] ?? '',
    );
  }
}

// ── Modèle Tour ──
class Tour {
  final int numero;
  final String membreId;
  final String membreNom;
  final DateTime date;
  final bool estComplete;
  final double montantTotal;

  Tour({
    required this.numero,
    required this.membreId,
    required this.membreNom,
    required this.date,
    required this.estComplete,
    required this.montantTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'membreId': membreId,
      'membreNom': membreNom,
      'date': date.toIso8601String(),
      'estComplete': estComplete,
      'montantTotal': montantTotal,
    };
  }

  factory Tour.fromMap(Map<String, dynamic> data) {
    return Tour(
      numero: data['numero'],
      membreId: data['membreId'],
      membreNom: data['membreNom'],
      date: DateTime.parse(data['date']),
      estComplete: data['estComplete'],
      montantTotal: (data['montantTotal'] as num).toDouble(),
    );
  }

  // Génère la liste des tours d'une tontine (ordre défini, ou aléatoire si
  // ordreReception == 'aleatoire'). Logique pure, sans accès à Firestore.
  static List<Tour> genererListe(Tontine tontine) {
    final membres = tontine.membres;
    if (membres.isEmpty) return [];

    final membresOrdonnes = List<Membre>.from(membres);
    if (tontine.ordreReception == 'aleatoire') {
      membresOrdonnes.shuffle();
    }

    final montantTotal = tontine.montant * membres.length;

    return List.generate(membres.length, (index) {
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
  }
}
