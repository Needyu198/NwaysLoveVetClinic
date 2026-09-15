import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/pet_owner/emergency_service_page.dart';
import 'package:senior_project/pet_owner/pet_owner_home_page.dart';
import 'package:senior_project/pet_owner/pet_profile_page.dart';

void main() {
  const catProfile = PetProfile(
    name: 'Milo',
    species: 'Cat',
    breed: 'Siamese',
    sex: 'Male',
    weight: '4.5 kg',
    age: '3 years',
    imageAsset: PetOwnerHomePage.dogAsset,
  );

  testWidgets('basic info hides age and uses the selected species icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/blank': (_) => const SizedBox(),
          PetProfilePage.routeName: (_) => const PetProfilePage(),
        },
        initialRoute: '/blank',
      ),
    );

    final context = tester.element(find.byType(SizedBox));
    Navigator.of(
      context,
    ).pushNamed(PetProfilePage.routeName, arguments: catProfile);
    await tester.pumpAndSettle();

    expect(find.text('Basic Info'), findsOneWidget);
    expect(find.text('Age'), findsNothing);
    expect(
      find.byKey(const ValueKey('pet-profile-species-cat-icon')),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const ValueKey('pet-profile-species-dog-icon')),
      findsNothing,
    );
  });

  testWidgets('dog profile uses dog icons and emergency button opens flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          EmergencyServicePage.routeName: (_) => const EmergencyServicePage(),
        },
        home: const PetProfilePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('pet-profile-species-dog-icon')),
      findsNWidgets(2),
    );

    final emergencyButton = find.byKey(
      const ValueKey('pet-profile-emergency-button'),
    );
    await tester.scrollUntilVisible(
      emergencyButton,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(emergencyButton);
    await tester.pumpAndSettle();

    expect(find.text('Emergency Service'), findsOneWidget);
    expect(find.text('Emergency Notice'), findsOneWidget);
  });
}
