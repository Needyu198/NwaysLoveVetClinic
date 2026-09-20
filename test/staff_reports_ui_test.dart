import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:senior_project/data/clinic_api.dart';
import 'package:senior_project/staff/staff_portal.dart';

void main() {
  testWidgets('staff Reports page presents clear type-specific summaries', (
    tester,
  ) async {
    ClinicApi.instance.token = null;
    ClinicApi.instance.clientFactory = null;
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

  testWidgets('staff Reports page displays live Python/Pandas results', (
    tester,
  ) async {
    final api = ClinicApi.instance;
    api.token = 'staff-test-token';
    api.clientFactory = () => MockClient((request) async {
      expect(request.url.path, '/reports/appointments');
      expect(request.headers['authorization'], 'Bearer staff-test-token');
      return http.Response(
        jsonEncode({
          'data': {
            'report': 'appointments',
            'engine': 'python-pandas',
            'metrics': [
              {'label': 'Total bookings', 'value': '42', 'numeric_value': 42},
              {'label': 'Active', 'value': '9', 'numeric_value': 9},
              {'label': 'Completed', 'value': '30', 'numeric_value': 30},
              {'label': 'Cancelled', 'value': '3', 'numeric_value': 3},
            ],
            'insight': 'Pandas found nine appointments requiring follow-up.',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    addTearDown(() {
      api.token = null;
      api.clientFactory = null;
    });

    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: StaffReportsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Python/Pandas • Live data'), findsOneWidget);
    expect(find.text('42'), findsWidgets);
    expect(
      find.text('Pandas found nine appointments requiring follow-up.'),
      findsOneWidget,
    );
  });
}
