import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/staff/staff_portal.dart';

void main() {
  testWidgets('staff dashboard and navigation use fixed-size supplied icons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: StaffPortalPage()));
    await tester.pumpAndSettle();

    for (final key in [
      'staff-dashboard-nav-icon',
      'staff-management-nav-icon',
    ]) {
      final finder = find.byKey(ValueKey(key));
      expect(finder, findsOneWidget);
      final sizeBox = find.descendant(
        of: finder,
        matching: find.byType(SizedBox),
      );
      expect(tester.widget<SizedBox>(sizeBox).width, 30);
      expect(tester.widget<SizedBox>(sizeBox).height, 30);
      expect(
        find.descendant(of: finder, matching: find.byType(Image)),
        findsOneWidget,
      );
    }

    for (final action in [
      'walk-in',
      'queue',
      'home-visit',
      'pets-and-owners',
      'reports',
    ]) {
      final finder = find.byKey(ValueKey('staff-$action-dashboard-icon'));
      expect(finder, findsOneWidget);
      expect(tester.widget<SizedBox>(finder).width, 42);
      expect(tester.widget<SizedBox>(finder).height, 42);
      expect(
        find.descendant(of: finder, matching: find.byType(Image)),
        findsOneWidget,
      );
    }
  });
}
