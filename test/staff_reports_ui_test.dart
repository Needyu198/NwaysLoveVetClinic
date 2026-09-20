import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/staff/staff_portal.dart';

void main() {
  testWidgets('staff Reports page presents clear type-specific summaries', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: StaffReportsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Operational Reports'), findsOneWidget);
    expect(find.text('At a glance'), findsOneWidget);
    expect(find.text('Total bookings'), findsWidgets);
    expect(find.text('Activity breakdown'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('staff-report-type-Payments')));
    await tester.pumpAndSettle();

    expect(find.text('Invoices'), findsWidgets);
    expect(find.text('Collected'), findsWidgets);
    expect(find.text('Export Payments Report'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('staff-report-type-Home Visits')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total visits'), findsWidgets);
    expect(find.text('In progress'), findsWidgets);
  });
}
