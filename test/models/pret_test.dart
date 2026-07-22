import 'package:flutter_test/flutter_test.dart';
import 'package:njangui/models/pret.dart';

Pret _creerPret({
  double montant = 100000,
  double tauxInteret = 10,
  List<Remboursement> remboursements = const [],
}) {
  return Pret(
    id: '1',
    tontineId: 't1',
    tontineNom: 'Tontine Test',
    membreId: 'm1',
    membreNom: 'Jean',
    montant: montant,
    tauxInteret: tauxInteret,
    dureeEnMois: 3,
    dateDemande: DateTime(2026, 1, 1),
    statut: StatutPret.enCours,
    motif: 'Test',
    remboursements: remboursements,
  );
}

void main() {
  group('Pret', () {
    test('montantTotal ajoute les intérêts au montant emprunté', () {
      final pret = _creerPret(montant: 100000, tauxInteret: 10);
      expect(pret.montantTotal, 110000);
    });

    test('montantRembourse fait la somme des remboursements', () {
      final pret = _creerPret(
        remboursements: [
          Remboursement(id: 'r1', montant: 30000, date: DateTime(2026, 2, 1), note: ''),
          Remboursement(id: 'r2', montant: 20000, date: DateTime(2026, 3, 1), note: ''),
        ],
      );
      expect(pret.montantRembourse, 50000);
    });

    test('montantRestant = montantTotal - montantRembourse', () {
      final pret = _creerPret(
        montant: 100000,
        tauxInteret: 10,
        remboursements: [
          Remboursement(id: 'r1', montant: 40000, date: DateTime(2026, 2, 1), note: ''),
        ],
      );
      expect(pret.montantRestant, 70000);
    });

    test('progressionRemboursement est le ratio remboursé/total', () {
      final pret = _creerPret(
        montant: 100000,
        tauxInteret: 0,
        remboursements: [
          Remboursement(id: 'r1', montant: 25000, date: DateTime(2026, 2, 1), note: ''),
        ],
      );
      expect(pret.progressionRemboursement, 0.25);
    });

    test('estRembourse est faux tant que le montant restant est positif', () {
      final pret = _creerPret(montant: 100000, tauxInteret: 0);
      expect(pret.estRembourse, isFalse);
    });

    test('estRembourse est vrai une fois le montant total couvert', () {
      final pret = _creerPret(
        montant: 100000,
        tauxInteret: 0,
        remboursements: [
          Remboursement(id: 'r1', montant: 100000, date: DateTime(2026, 2, 1), note: ''),
        ],
      );
      expect(pret.estRembourse, isTrue);
    });

    test('estRembourse est vrai même en cas de trop-perçu', () {
      final pret = _creerPret(
        montant: 100000,
        tauxInteret: 0,
        remboursements: [
          Remboursement(id: 'r1', montant: 120000, date: DateTime(2026, 2, 1), note: ''),
        ],
      );
      expect(pret.estRembourse, isTrue);
    });
  });
}
