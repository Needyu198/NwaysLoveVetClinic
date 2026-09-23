import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/doctor/doctor_portal.dart';
import 'package:senior_project/pet_owner/pet_owner_nav_bar.dart';
import 'package:senior_project/staff/staff_portal.dart';
import 'package:senior_project/system_admin/system_admin_portal.dart';

void main() {
  Future<double> transitionOffset(
    WidgetTester tester, {
    required PetOwnerNavItem from,
    required PetOwnerNavItem to,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => navigatePetOwnerTab(
              context,
              from: from,
              to: to,
              routeName: '/destination',
              builder: (_) => const Scaffold(
                body: Center(
                  child: Text('Destination', key: ValueKey('destination')),
                ),
              ),
            ),
            child: const Text('Go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    final transition = tester.widget<SlideTransition>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('destination')),
            matching: find.byType(SlideTransition),
          )
          .first,
    );
    return transition.position.value.dx;
  }

  testWidgets('right pet-owner tab enters from the right', (tester) async {
    final offset = await transitionOffset(
      tester,
      from: PetOwnerNavItem.pets,
      to: PetOwnerNavItem.profile,
    );
    expect(offset, greaterThan(0));
  });

  testWidgets('left pet-owner tab enters from the left', (tester) async {
    final offset = await transitionOffset(
      tester,
      from: PetOwnerNavItem.profile,
      to: PetOwnerNavItem.pets,
    );
    expect(offset, lessThan(0));
  });

  Future<void> expectPortalMovesBothDirections(
    WidgetTester tester, {
    required Widget portal,
    required Key pageViewKey,
    required Key rightTabKey,
    required Key leftTabKey,
  }) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: portal));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(rightTabKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    var controller = tester
        .widget<PageView>(find.byKey(pageViewKey))
        .controller!;
    expect(controller.page, greaterThan(0));
    await tester.pumpAndSettle();
    expect(controller.page, 2);

    await tester.tap(find.byKey(leftTabKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    controller = tester.widget<PageView>(find.byKey(pageViewKey)).controller!;
    expect(controller.page, lessThan(2));
    await tester.pumpAndSettle();
    expect(controller.page, 0);
  }

  testWidgets('staff tabs animate right and left', (tester) async {
    await expectPortalMovesBothDirections(
      tester,
      portal: const StaffPortalPage(),
      pageViewKey: const ValueKey('staff-directional-pages'),
      rightTabKey: const ValueKey('staff-profile-tab'),
      leftTabKey: const ValueKey('staff-dashboard-tab'),
    );
  });

  testWidgets('doctor tabs animate right and left', (tester) async {
    await expectPortalMovesBothDirections(
      tester,
      portal: const DoctorPortalPage(),
      pageViewKey: const ValueKey('doctor-directional-pages'),
      rightTabKey: const ValueKey('doctor-profile-tab'),
      leftTabKey: const ValueKey('doctor-dashboard-tab'),
    );
  });

  testWidgets('administrator tabs animate right and left', (tester) async {
    await expectPortalMovesBothDirections(
      tester,
      portal: const SystemAdminDashboardPage(),
      pageViewKey: const ValueKey('system-admin-directional-pages'),
      rightTabKey: const ValueKey('system-admin-account-tab'),
      leftTabKey: const ValueKey('system-admin-dashboard-tab'),
    );
  });
}
