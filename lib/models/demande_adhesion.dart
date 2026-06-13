enum TypeDemande {
  demandeRejoindre, // Jean demande à rejoindre (via code)
  invitation, // Marino invite Jean directement
}

enum StatutDemande { enAttente, acceptee, refusee }

class DemandeAdhesion {
  final String id;
  final String tontineId;
  final String tontineNom;
  final String userId; // celui qui doit accepter/refuser ou qui a demandé
  final String userNom;
  final String gestionnaireId;
  final String gestionnaireNom;
  final TypeDemande type;
  final StatutDemande statut;
  final DateTime date;

  DemandeAdhesion({
    required this.id,
    required this.tontineId,
    required this.tontineNom,
    required this.userId,
    required this.userNom,
    required this.gestionnaireId,
    required this.gestionnaireNom,
    required this.type,
    required this.statut,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tontineId': tontineId,
      'tontineNom': tontineNom,
      'userId': userId,
      'userNom': userNom,
      'gestionnaireId': gestionnaireId,
      'gestionnaireNom': gestionnaireNom,
      'type': type.index,
      'statut': statut.index,
      'date': date.toIso8601String(),
    };
  }

  factory DemandeAdhesion.fromMap(Map<String, dynamic> data) {
    return DemandeAdhesion(
      id: data['id'],
      tontineId: data['tontineId'],
      tontineNom: data['tontineNom'],
      userId: data['userId'],
      userNom: data['userNom'],
      gestionnaireId: data['gestionnaireId'],
      gestionnaireNom: data['gestionnaireNom'],
      type: TypeDemande.values[data['type']],
      statut: StatutDemande.values[data['statut']],
      date: DateTime.parse(data['date']),
    );
  }
}
