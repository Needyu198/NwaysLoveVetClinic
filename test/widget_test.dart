import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senior_project/login/pet_owner_auth_api.dart';
import 'package:senior_project/main.dart';

void main() {
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

    expect(find.text('My Pets'), findsWidgets);
    expect(find.text('Reminders'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();

    expect(find.text('Appointments'), findsOneWidget);
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
