import '../models/tontine.dart';

class TontinesData {
  static final TontinesData _instance = TontinesData._internal();
  factory TontinesData() => _instance;
  TontinesData._internal();

  final List<Tontine> tontines = [
    Tontine(
      id: '1',
      nom: 'Famille cité verte',
      montant: 10000,
      frequence: 'mois',
      prochaineEcheance: '12 Jan',
      enCours: false,
      dateDebut: DateTime(2024, 2, 1),
      ordreReception: 'aleatoire',
      nombreMembres: 3,
      paiementsEnregistres: true,
      prevuesObligatoires: true,
      membresVoientHistorique: true,
      gestionnaire: 'Emmanuel',
      codeInvitation: 'FAM001',
      membres: [
        Membre(id: '1', nom: 'Marie', aPaye: true),
        Membre(id: '2', nom: 'Jean-Paul', aPaye: false),
        Membre(id: '3', nom: 'Josiane', aPaye: true),
      ],
      tours: [],
    ),
    Tontine(
      id: '2',
      nom: 'Cotisation camarade',
      montant: 2500,
      frequence: 'semaine',
      prochaineEcheance: 'En cours',
      enCours: true,
      dateDebut: DateTime(2024, 1, 15),
      ordreReception: 'defini',
      nombreMembres: 2,
      paiementsEnregistres: true,
      prevuesObligatoires: false,
      membresVoientHistorique: true,
      gestionnaire: 'Emmanuel',
      codeInvitation: 'COT002',
      membres: [
        Membre(id: '1', nom: 'Paul', aPaye: true),
        Membre(id: '2', nom: 'Sophie', aPaye: false),
      ],
      tours: [],
    ),
  ];

  void ajouterTontine(Tontine tontine) {
    tontines.add(tontine);
  }

  void supprimerTontine(String id) {
    tontines.removeWhere((t) => t.id == id);
  }

  // Cherche une tontine par son code d'invitation
  Tontine? trouverParCode(String code) {
    try {
      return tontines.firstWhere(
        (t) => t.codeInvitation.toUpperCase() == code.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
