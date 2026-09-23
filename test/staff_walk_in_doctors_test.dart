import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/data/clinic_directory.dart';
import 'package:senior_project/data/database_sync.dart';
import 'package:senior_project/pet_owner/profile_flows.dart';
import 'package:senior_project/staff/staff_portal.dart';

void main() {
  tearDown(() {
    DatabaseSync.instance.active = false;
    ClinicDirectory.instance.replaceForTesting({});
    ProfilePetStore.instance.reset();
  });

  testWidgets('walk-in picker uses available doctors from doctor data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    DatabaseSync.instance.active = true;
    ClinicDirectory.instance.replaceForTesting({
      'doctor-available': {
        'name': 'Dr. Live Available',
        'role': 'doctor',
        'available': true,
      },
      'doctor-unavailable': {
        'name': 'Dr. Not Accepting',
        'role': 'doctor',
        'available': false,
      },
      'staff': {'name': 'Clinic Staff', 'role': 'staff'},
    });

    await tester.pumpWidget(const MaterialApp(home: StaffWalkInPage()));

    expect(find.text('Dr. Live Available'), findsOneWidget);
    expect(find.text('Dr. Not Accepting'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('register-walk-in')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('walk-in registration is disabled without an available doctor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    DatabaseSync.instance.active = true;
    ClinicDirectory.instance.replaceForTesting({
      'doctor-unavailable': {
        'name': 'Dr. Not Accepting',
        'role': 'doctor',
        'available': false,
      },
    });

    await tester.pumpWidget(const MaterialApp(home: StaffWalkInPage()));

    expect(
      find.byKey(const ValueKey('no-available-walk-in-doctors')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('register-walk-in')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('staff dashboard availability comes from doctor profiles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    DatabaseSync.instance.active = true;
    ClinicDirectory.instance.replaceForTesting({
      'available': {
        'name': 'Dr. Database Available',
        'role': 'doctor',
        'specialty': 'Surgery',
        'available': true,
        'photoUrl':
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      },
      'unavailable': {
        'name': 'Dr. Database Away',
        'role': 'doctor',
        'available': false,
      },
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StaffDashboardPage(onOpenProfile: () {})),
      ),
    );
    final queueIcon = find.byKey(const ValueKey('staff-queue-dashboard-icon'));
    expect(queueIcon, findsOneWidget);
    expect(
      tester
          .widget<Icon>(
            find.descendant(of: queueIcon, matching: find.byType(Icon)),
          )
          .icon,
      Icons.format_list_numbered_rounded,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('doctor-availability-Dr. Database Available')),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Dr. Database Available'), findsOneWidget);
    expect(find.text('Dr. Database Away'), findsOneWidget);
    expect(find.text('Surgery'), findsOneWidget);
    final doctorPhoto = find.byKey(
      const ValueKey('doctor-photo-available-Dr. Database Available'),
    );
    expect(doctorPhoto, findsOneWidget);
    expect(
      find.descendant(of: doctorPhoto, matching: find.byType(Image)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('doctor-availability-Dr. Aye Chan')),
      findsNothing,
    );
  });

  testWidgets('Pets & Owners uses owner-updated pet photos and booking UI', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ProfilePetStore.instance.add(
      ProfilePet(
        name: 'Bruno',
        type: 'Dog',
        breed: 'Pug',
        sex: 'Male',
        dateOfBirth: DateTime(2022, 1, 1),
        weightKg: 8,
        color: 'Fawn',
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

    await tester.pumpWidget(const MaterialApp(home: StaffPatientsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Pets & Owners'), findsOneWidget);
    expect(find.text('Patients & Owners'), findsNothing);
    expect(find.byKey(const ValueKey('pets-owners-logo')), findsOneWidget);
    final listPhoto = find.byKey(
      const ValueKey('staff-patient-pet-photo-Bruno'),
    );
    expect(
      find.descendant(of: listPhoto, matching: find.byType(Image)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('staff-patient-Bruno')));
    await tester.pumpAndSettle();
    expect(find.text('Pet Profile'), findsOneWidget);
    final detailPhoto = find.byKey(
      const ValueKey('staff-patient-detail-pet-photo-Bruno'),
    );
    expect(
      find.descendant(of: detailPhoto, matching: find.byType(Image)),
      findsOneWidget,
    );
  });
}
