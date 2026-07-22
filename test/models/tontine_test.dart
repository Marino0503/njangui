import 'package:flutter_test/flutter_test.dart';
import 'package:njangui/models/tontine.dart';

Tontine _creerTontine({
  required List<Membre> membres,
  String ordreReception = 'defini',
  double montant = 5000,
}) {
  return Tontine(
    id: 't1',
    nom: 'Tontine Test',
    montant: montant,
    frequence: 'mois',
    prochaineEcheance: '',
    frequenceEcheance: 'mois',
    enCours: true,
    dateDebut: DateTime(2026, 1, 15),
    ordreReception: ordreReception,
    nombreMembres: membres.length,
    paiementsEnregistres: true,
    prevuesObligatoires: true,
    membresVoientHistorique: true,
    gestionnaire: 'Marino',
    membres: membres,
    codeInvitation: 'ABC123',
    tours: const [],
    gestionnaireId: 'g1',
  );
}

void main() {
  group('Tontine.genererCode', () {
    test('génère un code de 6 caractères', () {
      expect(Tontine.genererCode().length, 6);
    });

    test('utilise uniquement des lettres majuscules et des chiffres', () {
      final code = Tontine.genererCode();
      expect(RegExp(r'^[A-Z0-9]{6}$').hasMatch(code), isTrue);
    });

    test('deux appels successifs ne donnent (presque) jamais le même code', () {
      final codes = List.generate(100, (_) => Tontine.genererCode());
      expect(codes.toSet().length, 100);
    });
  });

  group('Tour.genererListe', () {
    final membres = [
      Membre(id: 'm1', nom: 'Jean', aPaye: false),
      Membre(id: 'm2', nom: 'Awa', aPaye: false),
      Membre(id: 'm3', nom: 'Paul', aPaye: false),
    ];

    test('retourne une liste vide si la tontine n\'a aucun membre', () {
      final tours = Tour.genererListe(_creerTontine(membres: []));
      expect(tours, isEmpty);
    });

    test('génère un tour par membre', () {
      final tours = Tour.genererListe(_creerTontine(membres: membres));
      expect(tours.length, 3);
    });

    test('respecte l\'ordre défini des membres quand ordreReception == defini', () {
      final tours = Tour.genererListe(
        _creerTontine(membres: membres, ordreReception: 'defini'),
      );
      expect(tours.map((t) => t.membreId).toList(), ['m1', 'm2', 'm3']);
    });

    test('numérote les tours à partir de 1, sans trou ni doublon', () {
      final tours = Tour.genererListe(_creerTontine(membres: membres));
      expect(tours.map((t) => t.numero).toList(), [1, 2, 3]);
    });

    test('le montant total par tour = montant de la tontine × nombre de membres', () {
      final tours = Tour.genererListe(
        _creerTontine(membres: membres, montant: 5000),
      );
      expect(tours.every((t) => t.montantTotal == 15000), isTrue);
    });

    test('aucun tour n\'est marqué complet à la génération', () {
      final tours = Tour.genererListe(_creerTontine(membres: membres));
      expect(tours.every((t) => t.estComplete == false), isTrue);
    });

    test('le tirage aléatoire ne perd ni ne duplique de membre', () {
      final tours = Tour.genererListe(
        _creerTontine(membres: membres, ordreReception: 'aleatoire'),
      );
      expect(
        tours.map((t) => t.membreId).toSet(),
        {'m1', 'm2', 'm3'},
      );
    });
  });
}
