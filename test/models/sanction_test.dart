import 'package:flutter_test/flutter_test.dart';
import 'package:njangui/models/sanction.dart';

void main() {
  group('Sanction.calculerMontantDu', () {
    test('aucun retard : montant dû = montant initial', () {
      expect(Sanction.calculerMontantDu(10000, 0), 10000);
    });

    test('1 fréquence de retard : +10%', () {
      expect(Sanction.calculerMontantDu(10000, 1), 11000);
    });

    test('3 fréquences de retard : +30%', () {
      expect(Sanction.calculerMontantDu(10000, 3), 13000);
    });

    test('fonctionne avec un montant non entier', () {
      expect(Sanction.calculerMontantDu(1500.5, 2), closeTo(1800.6, 0.001));
    });
  });
}
