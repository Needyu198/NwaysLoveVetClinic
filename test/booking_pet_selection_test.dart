import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/data/clinic_api.dart';
import 'package:senior_project/pet_owner/home_visit_booking_page.dart';
import 'package:senior_project/pet_owner/pet_care_booking_page.dart';
import 'package:senior_project/pet_owner/profile_flows.dart';

void main() {
  setUp(() {
    ClinicApi.instance.token = 'test-token';
    ProfilePetStore.instance.reset();
    ProfilePetStore.instance.add(
      ProfilePet(
        name: 'Milo',
        type: 'Cat',
        breed: 'Domestic Shorthair',
        sex: 'Male',
        dateOfBirth: DateTime(2022, 1, 1),
        weightKg: 4.2,
        color: 'Orange',
        identifyingFeatures: '',
        allergies: 'None',
        conditions: 'None',
        medicines: 'None',
        vaccination: 'Up to date',
      ),
    );
  });

  tearDown(() {
    ClinicApi.instance.token = null;
    ProfilePetStore.instance.reset();
  });

  testWidgets('Home Visit pet keeps its selected state when signed in', (
    tester,
  ) async {
    _setPhoneSize(tester);
    await tester.pumpWidget(const MaterialApp(home: HomeVisitBookingPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Milo'));
    await tester.pump();

    _expectSelected(const ValueKey('home-visit-pet-Milo'), tester);
  });

  for (final service in PetCareCatalog.services) {
    testWidgets('${service.name} pet keeps its selected state when signed in', (
      tester,
    ) async {
      _setPhoneSize(tester);
      await tester.pumpWidget(
        MaterialApp(home: PetCareBookingPage(service: service)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Milo'));
      await tester.pump();

      _expectSelected(const ValueKey('care-pet-Milo'), tester);
    });
  }
}

void _setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(440, 956);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _expectSelected(Key key, WidgetTester tester) {
  expect(
    find.descendant(
      of: find.byKey(key),
      matching: find.byIcon(Icons.check_circle_rounded),
    ),
    findsOneWidget,
  );
}
