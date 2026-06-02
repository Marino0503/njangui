class Sanction {
  final String id;
  final String tontineId;
  final String tontineNom;
  final String membreId;
  final String membreNom;
  final double montantInitial;
  final double montantDu;
  final int nombreFrequencesRetard;
  final DateTime dateEcheance;
  final DateTime dateSanction;
  final bool estPayee;

  Sanction({
    required this.id,
    required this.tontineId,
    required this.tontineNom,
    required this.membreId,
    required this.membreNom,
    required this.montantInitial,
    required this.montantDu,
    required this.nombreFrequencesRetard,
    required this.dateEcheance,
    required this.dateSanction,
    required this.estPayee,
  });

  // Calcule le montant dû selon le nombre de fréquences de retard
  static double calculerMontantDu(
    double montantInitial,
    int nombreFrequencesRetard,
  ) {
    return montantInitial + (montantInitial * 0.10 * nombreFrequencesRetard);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tontineId': tontineId,
      'tontineNom': tontineNom,
      'membreId': membreId,
      'membreNom': membreNom,
      'montantInitial': montantInitial,
      'montantDu': montantDu,
      'nombreFrequencesRetard': nombreFrequencesRetard,
      'dateEcheance': dateEcheance.toIso8601String(),
      'dateSanction': dateSanction.toIso8601String(),
      'estPayee': estPayee,
    };
  }

  factory Sanction.fromMap(Map<String, dynamic> data) {
    return Sanction(
      id: data['id'],
      tontineId: data['tontineId'],
      tontineNom: data['tontineNom'],
      membreId: data['membreId'],
      membreNom: data['membreNom'],
      montantInitial: (data['montantInitial'] as num).toDouble(),
      montantDu: (data['montantDu'] as num).toDouble(),
      nombreFrequencesRetard: data['nombreFrequencesRetard'],
      dateEcheance: DateTime.parse(data['dateEcheance']),
      dateSanction: DateTime.parse(data['dateSanction']),
      estPayee: data['estPayee'] ?? false,
    );
  }
}
