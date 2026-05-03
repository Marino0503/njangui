class Paiement {
  final String id;
  final String membreId;
  final String membreNom;
  final double montant;
  final DateTime date;
  final String tontineId;
  final String tontineNom;
  final String statut; // 'paye' ou 'en_retard'

  Paiement({
    required this.id,
    required this.membreId,
    required this.membreNom,
    required this.montant,
    required this.date,
    required this.tontineId,
    required this.tontineNom,
    required this.statut,
  });

  // Convertit un Map en Paiement
  factory Paiement.fromMap(Map<String, dynamic> data) {
    return Paiement(
      id: data['id'],
      membreId: data['membreId'],
      membreNom: data['membreNom'],
      montant: (data['montant'] as num).toDouble(),
      date: DateTime.parse(data['date']),
      tontineId: data['tontineId'],
      tontineNom: data['tontineNom'],
      statut: data['statut'],
    );
  }

  // Convertit un Paiement en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'membreId': membreId,
      'membreNom': membreNom,
      'montant': montant,
      'date': date.toIso8601String(),
      'tontineId': tontineId,
      'tontineNom': tontineNom,
      'statut': statut,
    };
  }
}
