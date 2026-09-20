import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/staff/staff_portal.dart';

void main() {
  testWidgets('all staff Management cards use fixed-size image icons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: StaffPortalPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('staff-management-tab')));
    await tester.pumpAndSettle();

    for (final name in [
      'appointments',
      'queue',
      'inventory',
      'medical-records',
      'emergency-cases',
      'home-visits',
    ]) {
      final finder = find.byKey(ValueKey('staff-management-$name-icon'));
      expect(finder, findsOneWidget);

      final box = tester.widget<SizedBox>(finder);
      expect(box.width, 36);
      expect(box.height, 36);
      expect(
        find.descendant(of: finder, matching: find.byType(Image)),
        findsOneWidget,
      );
    }
  });
}
