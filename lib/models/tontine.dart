// Modèle pour un membre
class Membre {
  final String id;
  final String nom;
  final bool aPaye;

  Membre({required this.id, required this.nom, required this.aPaye});
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
    this.penaliteParJour = 500,
    this.sanctionsActives = false,
    this.totalCollecte = 0,
    this.totalDistribue = 0,
    this.soldeDisponible = 0,
  });

  static String genererCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = List.generate(
      6,
      (index) => chars[DateTime.now().microsecondsSinceEpoch % chars.length],
    );
    return random.join();
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
      'membres': membres
          .map((m) => {'id': m.id, 'nom': m.nom, 'aPaye': m.aPaye})
          .toList(),
      'tours': tours.map((t) => t.toMap()).toList(),
      'totalCollecte': totalCollecte,
      'totalDistribue': totalDistribue,
      'soldeDisponible': soldeDisponible,
      'penaliteParJour': penaliteParJour,
      'sanctionsActives': sanctionsActives,
    };
  }

  factory Tontine.fromMap(Map<String, dynamic> data) {
    final membresData = data['membres'] as List<dynamic>? ?? [];
    final membres = membresData.map((m) {
      return Membre(id: m['id'], nom: m['nom'], aPaye: m['aPaye']);
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
}
