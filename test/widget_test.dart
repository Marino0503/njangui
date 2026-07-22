import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:njangui/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState affiche le titre, le message et le bouton', (
    WidgetTester tester,
  ) async {
    var boutonPresse = false;

    await tester.pumpWidget(
      MaterialApp(
        home: EmptyState(
          icon: Icons.group,
          titre: 'Aucune tontine',
          message: 'Créez votre première tontine',
          boutonTexte: 'Créer',
          onBoutonPressed: () => boutonPresse = true,
        ),
      ),
    );

    expect(find.text('Aucune tontine'), findsOneWidget);
    expect(find.text('Créez votre première tontine'), findsOneWidget);
    expect(find.text('Créer'), findsOneWidget);

    await tester.tap(find.text('Créer'));
    expect(boutonPresse, isTrue);
  });

  testWidgets('EmptyState n\'affiche pas de bouton si aucun n\'est fourni', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EmptyState(
          icon: Icons.group,
          titre: 'Aucune tontine',
          message: 'Créez votre première tontine',
        ),
      ),
    );

    expect(find.byType(ElevatedButton), findsNothing);
  });
}
