import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/doctor/doctor_portal.dart';
import 'package:senior_project/pet_owner/pet_owner_clinic_page.dart';
import 'package:senior_project/pet_owner/pet_owner_home_page.dart';
import 'package:senior_project/pet_owner/pet_owner_profile_page.dart';
import 'package:senior_project/pet_owner/pet_products_page.dart';
import 'package:senior_project/staff/staff_portal.dart';

Widget _ownerApp(Widget page) => MaterialApp(
  home: page,
  routes: {PetOwnerHomePage.routeName: (_) => const PetOwnerHomePage()},
);

Future<void> _expectOwnerLogoOpensMyPets(
  WidgetTester tester,
  Widget page,
  Key logoKey,
) async {
  await tester.pumpWidget(_ownerApp(page));
  await tester.tap(find.byKey(logoKey));
  await tester.pumpAndSettle();

  expect(find.text('My Pets'), findsWidgets);
}

void main() {
  testWidgets('clinic logo opens the pet owner My Pets page', (tester) async {
    await _expectOwnerLogoOpensMyPets(
      tester,
      const PetOwnerClinicPage(),
      const ValueKey('clinic-information-logo'),
    );
  });

  testWidgets('products logo opens the pet owner My Pets page', (tester) async {
    await _expectOwnerLogoOpensMyPets(
      tester,
      const PetProductsPage(),
      const ValueKey('pet-products-logo'),
    );
  });

  testWidgets('profile logo opens the pet owner My Pets page', (tester) async {
    await _expectOwnerLogoOpensMyPets(
      tester,
      const PetOwnerProfilePage(),
      const ValueKey('pet-owner-profile-logo'),
    );
  });

  testWidgets('doctor appointment logo returns to doctor dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DoctorPortalPage()));
    await tester.tap(find.byKey(const ValueKey('doctor-appointments-tab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('doctor-appointments')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('doctor-appointments-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('doctor-dashboard')), findsOneWidget);
  });

  testWidgets('doctor profile logo returns to doctor dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DoctorPortalPage()));
    await tester.tap(find.byKey(const ValueKey('doctor-profile-tab')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('doctor-profile-logo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('doctor-dashboard')), findsOneWidget);
  });

  testWidgets('staff management logo returns to staff dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StaffPortalPage()));
    await tester.tap(find.byKey(const ValueKey('staff-management-tab')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('staff-management-logo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('staff-dashboard')), findsOneWidget);
  });

  testWidgets('staff profile logo returns to staff dashboard', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StaffPortalPage()));
    await tester.tap(find.byKey(const ValueKey('staff-profile-tab')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('staff-staff-profile-logo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('staff-dashboard')), findsOneWidget);
  });
}
