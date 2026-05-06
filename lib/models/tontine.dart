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
  final List<Tour> tours;

  Tontine({
    required this.id,
    required this.nom,
    required this.montant,
    required this.frequence,
    required this.prochaineEcheance,
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
  });

  static String genererCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = List.generate(
      6,
      (index) => chars[DateTime.now().microsecondsSinceEpoch % chars.length],
    );
    return random.join();
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
