import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/main.dart';

void main() {
  testWidgets('the app uses SF Pro Rounded across all routes', (tester) async {
    await tester.pumpWidget(const NwayLoveVetClinicApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.textTheme.bodyMedium?.fontFamily, '.SF NS Rounded');
    expect(app.theme?.textTheme.titleLarge?.fontFamily, '.SF NS Rounded');
    expect(app.theme?.textTheme.labelLarge?.fontFamily, '.SF NS Rounded');
  });
}
