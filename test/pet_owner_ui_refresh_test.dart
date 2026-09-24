import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/data/clinic_api.dart';
import 'package:senior_project/data/clinic_directory.dart';
import 'package:senior_project/pet_owner/emergency_service_page.dart';
import 'package:senior_project/pet_owner/pet_owner_clinic_page.dart';
import 'package:senior_project/pet_owner/pet_care_booking_page.dart';
import 'package:senior_project/pet_owner/pet_products_page.dart';
import 'package:senior_project/pet_owner/profile_flows.dart';

void main() {
  tearDown(() {
    ProfilePetStore.instance.reset();
    ClinicDirectory.instance.replaceForTesting({});
    ClinicApi.instance.token = null;
    ClinicApi.instance.account = null;
  });

  testWidgets('Products uses booking-style header with clinic logo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ClinicApi.instance.token = 'test-session';

    await tester.pumpWidget(const MaterialApp(home: PetProductsPage()));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pet-products-header')),
        matching: find.text('Products'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pet-products-header')),
        matching: find.byTooltip('Back'),
      ),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('pet-products-logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('pet-products-search')), findsOneWidget);
  });

  testWidgets('Emergency Select Pet shows owner-updated photo and logo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ClinicApi.instance.token = 'test-session';
    ProfilePetStore.instance.add(
      ProfilePet(
        name: 'Photo Emergency Pet',
        type: 'Cat',
        breed: 'Siamese',
        sex: 'Female',
        dateOfBirth: DateTime(2023, 1, 1),
        weightKg: 4,
        color: 'Cream',
        identifyingFeatures: '',
        allergies: 'None',
        conditions: 'None',
        medicines: 'None',
        vaccination: 'Current',
        hasCustomPhoto: true,
        photoUrl:
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: EmergencyServicePage()));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('emergency-service-logo')),
      findsOneWidget,
    );
    await tester.tap(find.text('Continue Emergency Request'));
    await tester.pumpAndSettle();

    final photo = find.byKey(
      const ValueKey('emergency-pet-photo-Photo Emergency Pet'),
    );
    expect(photo, findsOneWidget);
    expect(
      find.descendant(of: photo, matching: find.byType(Image)),
      findsOneWidget,
    );
  });

  testWidgets('Clinic Information has compact friendly header and actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PetOwnerClinicPage()));
    await tester.pumpAndSettle();

    expect(find.text('Clinic Information'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('clinic-information-logo')),
      findsOneWidget,
    );
    expect(find.text('Open today'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Directions'), findsOneWidget);
    expect(find.text('Book'), findsOneWidget);
  });

  testWidgets('Pet care uses owner pets, photos, options, and staff data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ClinicApi.instance.token = 'test-session';
    ProfilePetStore.instance.add(
      ProfilePet(
        name: 'Mochi',
        type: 'Cat',
        breed: 'British Shorthair',
        sex: 'Female',
        dateOfBirth: DateTime(2022, 6, 1),
        weightKg: 4.2,
        color: 'Gray',
        identifyingFeatures: '',
        allergies: 'None',
        conditions: 'None',
        medicines: 'None',
        vaccination: 'Vaccinations current',
        hasCustomPhoto: true,
        photoUrl:
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
    ClinicDirectory.instance.replaceForTesting({
      'staff-mya': {
        'id': 'staff-mya',
        'name': 'Mya Thu',
        'role': 'staff',
        'photoUrl':
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/lZkAAAAASUVORK5CYII=',
        'specialty': 'Morning • 8:00 AM–4:00 PM',
        'available': true,
      },
    });

    await tester.pumpWidget(
      MaterialApp(
        home: PetCareServiceDetailsPage(service: PetCareCatalog.services.first),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Grooming Services'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pet-care-grooming-logo')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('care-option-Bath Only')));
    await tester.tap(find.byKey(const ValueKey('start-service-booking')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('book-grooming-logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('care-pet-Mochi')), findsOneWidget);
    final photo = find.byKey(const ValueKey('care-pet-photo-Mochi'));
    expect(
      find.descendant(of: photo, matching: find.byType(Image)),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('care-pet-Mochi')));
    await tester.pump();
    await tester.tap(find.text('Check Eligibility'));
    await tester.pumpAndSettle();

    expect(find.text('Eligible for Grooming'), findsOneWidget);
    expect(find.text('Mya Thu'), findsOneWidget);
    expect(find.textContaining('Morning • 8:00 AM–4:00 PM'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('care-provider-staff-mya')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<CircleAvatar>(
            find.byKey(const ValueKey('care-provider-photo-staff-mya')),
          )
          .backgroundImage,
      isA<MemoryImage>(),
    );
    await tester.tap(find.byKey(const ValueKey('care-provider-staff-mya')));
    await tester.pump();
    await tester.tap(find.text('Select Schedule'));
    await tester.pumpAndSettle();
    expect(find.text('Available dates'), findsOneWidget);
  });
}
