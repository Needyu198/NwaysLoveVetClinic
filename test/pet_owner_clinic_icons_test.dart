import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/pet_owner/pet_owner_clinic_page.dart';

void main() {
  testWidgets('clinic category artwork uses one fixed icon size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PetOwnerClinicPage()));
    await tester.pumpAndSettle();

    for (final category in [
      'Booking',
      'Home Visit',
      'Medical Services',
      'History',
      'First Aid Info',
      'Emergency Services',
    ]) {
      final finder = find.byKey(ValueKey('clinic-$category-icon'));
      expect(finder, findsOneWidget);

      final box = tester.widget<SizedBox>(finder);
      expect(box.width, 56);
      expect(box.height, 56);
      expect(
        find.descendant(of: finder, matching: find.byType(Image)),
        findsOneWidget,
      );
    }
  });
}
