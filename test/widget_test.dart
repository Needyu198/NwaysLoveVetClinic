import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senior_project/login/pet_owner_auth_api.dart';
import 'package:senior_project/main.dart';

void main() {
  Future<void> signIn(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const NwayLoveVetClinicApp(authApi: _SuccessfulPetOwnerAuthApi()),
    );

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('contact-field')),
      'Lynn198',
    );
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const NwayLoveVetClinicApp());

    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('login button opens sign in panel', (WidgetTester tester) async {
    await tester.pumpWidget(const NwayLoveVetClinicApp());

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Email or Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('phone icon switches contact field mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NwayLoveVetClinicApp());

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Use phone number'));
    await tester.pumpAndSettle();

    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Enter your phone number'), findsOneWidget);

    await tester.tap(find.byTooltip('Use email or username'));
    await tester.pumpAndSettle();

    expect(find.text('Email or Username'), findsOneWidget);
    expect(find.text('Enter your Email or Username'), findsOneWidget);
  });

  testWidgets('sign in opens pet owner home', (WidgetTester tester) async {
    await signIn(tester);

    expect(find.text('My Pets'), findsWidgets);
    expect(find.text('Reminders'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();

    expect(find.text('Appointments'), findsOneWidget);
  });

  testWidgets('bottom navigation opens main pet owner sections', (
    WidgetTester tester,
  ) async {
    await signIn(tester);

    await tester.tap(find.byTooltip('Clinic'));
    await tester.pumpAndSettle();
    expect(find.text('Clinic'), findsWidgets);
    expect(find.text('Doctor Profiles'), findsOneWidget);

    await tester.tap(find.byTooltip('Products'));
    await tester.pumpAndSettle();
    expect(find.text('Dog Food 01'), findsOneWidget);
    expect(find.byTooltip('Filter and sort'), findsOneWidget);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Nee Yu'), findsOneWidget);

    await tester.tap(find.byTooltip('My Pets'));
    await tester.pumpAndSettle();
    expect(find.text('Healthy days start here'), findsOneWidget);
  });

  testWidgets('pet profile opens reminders and add reminder validation', (
    WidgetTester tester,
  ) async {
    await signIn(tester);

    await tester.tap(find.text('Max').first);
    await tester.pumpAndSettle();
    expect(find.text('Pet Profile'), findsOneWidget);
    expect(find.text('Basic Info'), findsOneWidget);

    final reminderButton = find.widgetWithText(TextButton, 'Reminder');
    await tester.drag(find.byType(CustomScrollView).last, const Offset(0, -520));
    await tester.pumpAndSettle();
    await tester.ensureVisible(reminderButton);
    await tester.tap(reminderButton);
    await tester.pumpAndSettle();
    expect(find.text('Pet care tasks and visits'), findsOneWidget);
    expect(find.text('Annual Rabies Vaccination'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Add Reminder'), findsWidgets);

    await tester.tap(find.text('Add Reminder').last);
    await tester.pumpAndSettle();
    expect(find.text('Please enter a reminder title.'), findsOneWidget);
    expect(find.text('Please choose both date and time.'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Annual Rabies Vaccination'), findsOneWidget);
  });

  testWidgets('product checkout flow reaches payment and returns home', (
    WidgetTester tester,
  ) async {
    await signIn(tester);

    await tester.tap(find.byTooltip('Products'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dog Food 01'));
    await tester.tap(find.text('Dog Food 01'));
    await tester.pumpAndSettle();

    expect(find.text('Add to Cart'), findsOneWidget);
    expect(find.text('Buy Now'), findsOneWidget);

    await tester.tap(find.text('Buy Now'));
    await tester.pumpAndSettle();
    expect(find.text('Check Out'), findsWidgets);

    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();
    expect(find.text('Payment Method'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Complete Payment in 00:20:00'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(find.text('Thank You !'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Healthy days start here'), findsOneWidget);
  });

  testWidgets('login screen fits common phone sizes', (
    WidgetTester tester,
  ) async {
    const phoneSizes = [
      Size(360, 640),
      Size(375, 812),
      Size(390, 844),
      Size(414, 896),
      Size(440, 956),
      Size(640, 360),
      Size(844, 390),
      Size(896, 414),
    ];

    for (final phoneSize in phoneSizes) {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const NwayLoveVetClinicApp());

      expect(find.text('Log in'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

class _SuccessfulPetOwnerAuthApi extends PetOwnerAuthApi {
  const _SuccessfulPetOwnerAuthApi();

  @override
  Future<PetOwnerLoginResult> login({
    required String username,
    required String password,
  }) async {
    return const PetOwnerLoginResult.success();
  }
}
