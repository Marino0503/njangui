enum StatutPret { enAttente, accepte, refuse, enCours, rembourse }

class Remboursement {
  final String id;
  final double montant;
  final DateTime date;
  final String note;

  Remboursement({
    required this.id,
    required this.montant,
    required this.date,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'montant': montant,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Remboursement.fromMap(Map<String, dynamic> data) {
    return Remboursement(
      id: data['id'],
      montant: (data['montant'] as num).toDouble(),
      date: DateTime.parse(data['date']),
      note: data['note'] ?? '',
    );
  }
}

class Pret {
  final String id;
  final String tontineId;
  final String tontineNom;
  final String membreId;
  final String membreNom;
  final double montant;
  final double tauxInteret; // en pourcentage
  final int dureeEnMois;
  final DateTime dateDemande;
  final DateTime? dateAcceptation;
  final DateTime? dateEcheance;
  final StatutPret statut;
  final String motif;
  final List<Remboursement> remboursements;

  Pret({
    required this.id,
    required this.tontineId,
    required this.tontineNom,
    required this.membreId,
    required this.membreNom,
    required this.montant,
    required this.tauxInteret,
    required this.dureeEnMois,
    required this.dateDemande,
    this.dateAcceptation,
    this.dateEcheance,
    required this.statut,
    required this.motif,
    required this.remboursements,
  });

  // Montant total à rembourser avec intérêts
  double get montantTotal => montant + (montant * tauxInteret / 100);

  // Montant déjà remboursé
  double get montantRembourse =>
      remboursements.fold(0, (sum, r) => sum + r.montant);

  // Montant restant à rembourser
  double get montantRestant => montantTotal - montantRembourse;

  // Progression du remboursement en pourcentage
  double get progressionRemboursement =>
      montantTotal > 0 ? montantRembourse / montantTotal : 0;

  // Vérifie si le prêt est totalement remboursé
  bool get estRembourse => montantRestant <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tontineId': tontineId,
      'tontineNom': tontineNom,
      'membreId': membreId,
      'membreNom': membreNom,
      'montant': montant,
      'tauxInteret': tauxInteret,
      'dureeEnMois': dureeEnMois,
      'dateDemande': dateDemande.toIso8601String(),
      'dateAcceptation': dateAcceptation?.toIso8601String(),
      'dateEcheance': dateEcheance?.toIso8601String(),
      'statut': statut.index,
      'motif': motif,
      'remboursements': remboursements.map((r) => r.toMap()).toList(),
    };
  }

  factory Pret.fromMap(Map<String, dynamic> data) {
    final rembData = data['remboursements'] as List<dynamic>? ?? [];
    return Pret(
      id: data['id'],
      tontineId: data['tontineId'],
      tontineNom: data['tontineNom'],
      membreId: data['membreId'],
      membreNom: data['membreNom'],
      montant: (data['montant'] as num).toDouble(),
      tauxInteret: (data['tauxInteret'] as num).toDouble(),
      dureeEnMois: data['dureeEnMois'],
      dateDemande: DateTime.parse(data['dateDemande']),
      dateAcceptation: data['dateAcceptation'] != null
          ? DateTime.parse(data['dateAcceptation'])
          : null,
      dateEcheance: data['dateEcheance'] != null
          ? DateTime.parse(data['dateEcheance'])
          : null,
      statut: StatutPret.values[data['statut']],
      motif: data['motif'] ?? '',
      remboursements: rembData
          .map((r) => Remboursement.fromMap(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
