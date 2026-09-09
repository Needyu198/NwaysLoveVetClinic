import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/data/clinic_api.dart';
import 'package:senior_project/pet_owner/pet_products_page.dart';

void main() {
  testWidgets('related product cards fit without overflowing', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    ClinicApi.instance.token = null;
    await tester.pumpWidget(const MaterialApp(home: ProductDetailsPage()));
    await tester.pumpAndSettle();

    expect(find.text('More for you'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
