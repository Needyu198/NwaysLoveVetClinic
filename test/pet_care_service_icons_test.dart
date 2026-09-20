import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/pet_owner/pet_care_booking_page.dart';

void main() {
  const expectedAssets = {
    'Grooming': 'assets/photos/icon/pet_care_grooming.png',
    'Bathing': 'assets/photos/icon/pet_care_bathing.png',
    'Nail Trimming': 'assets/photos/icon/pet_care_nail_trimming.png',
    'Boarding': 'assets/photos/icon/pet_care_boarding.png',
  };

  testWidgets('pet-care list uses supplied fixed-size icons', (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PetCareServicesPage()));
    await tester.pumpAndSettle();

    for (final entry in expectedAssets.entries) {
      final finder = find.byKey(ValueKey('pet-care-${entry.key}-list-icon'));
      expect(finder, findsOneWidget);

      final box = tester.widget<SizedBox>(finder);
      expect(box.width, 38);
      expect(box.height, 38);

      final image = tester.widget<Image>(
        find.descendant(of: finder, matching: find.byType(Image)),
      );
      expect((image.image as AssetImage).assetName, entry.value);
    }
  });

  testWidgets('every pet-care details page uses a fixed-size service icon', (
    tester,
  ) async {
    for (final service in PetCareCatalog.services) {
      await tester.pumpWidget(
        MaterialApp(home: PetCareServiceDetailsPage(service: service)),
      );
      await tester.pumpAndSettle();

      final finder = find.byKey(
        ValueKey('pet-care-${service.name}-details-icon'),
      );
      expect(finder, findsOneWidget);
      final box = tester.widget<SizedBox>(finder);
      expect(box.width, 42);
      expect(box.height, 42);
    }
  });
}
