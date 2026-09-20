import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/pet_owner/pet_add_reminder_page.dart';

void main() {
  testWidgets('reminder type choices use fixed-size supplied icon assets', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PetAddReminderPage()));
    await tester.pumpAndSettle();

    for (final type in ['vaccine', 'medicine', 'checkup']) {
      final finder = find.byKey(ValueKey('add-reminder-$type-choice-icon'));
      expect(finder, findsOneWidget);

      final box = tester.widget<SizedBox>(finder);
      expect(box.width, 34);
      expect(box.height, 34);
      expect(
        find.descendant(of: finder, matching: find.byType(Image)),
        findsOneWidget,
      );
    }

    final selectedHint = find.byKey(
      const ValueKey('add-reminder-vaccine-hint-icon'),
    );
    final hintBox = tester.widget<SizedBox>(selectedHint);
    expect(hintBox.width, 25);
    expect(hintBox.height, 25);
  });
}
