import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senior_project/doctor/doctor_portal.dart';
import 'package:senior_project/login/doctor_auth_api.dart';
import 'package:senior_project/login/pet_owner_auth_api.dart';
import 'package:senior_project/login/system_admin_auth_api.dart';
import 'package:senior_project/main.dart';
import 'package:senior_project/pet_owner/appointment_booking_page.dart';
import 'package:senior_project/pet_owner/contact_clinic_page.dart';
import 'package:senior_project/pet_owner/emergency_service_page.dart';
import 'package:senior_project/pet_owner/first_aid_information_page.dart';
import 'package:senior_project/pet_owner/home_visit_booking_page.dart';
import 'package:senior_project/pet_owner/history_page.dart';
import 'package:senior_project/pet_owner/pet_care_booking_page.dart';
import 'package:senior_project/pet_owner/profile_flows.dart';

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

  Future<void> signInAsDoctor(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NwayLoveVetClinicApp());
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('contact-field')),
      DoctorAuthApi.demoEmail,
    );
    await tester.enterText(
      find.byType(TextField).last,
      DoctorAuthApi.demoPassword,
    );
    await tester.ensureVisible(find.text('Sign In'));
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
    expect(find.byKey(const ValueKey('login-role-selector')), findsNothing);
    expect(find.text('Pet Owner'), findsNothing);
    expect(find.text('Doctor'), findsNothing);
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

    await tester.scrollUntilVisible(
      find.text('Appointments'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Appointments'), findsOneWidget);
  });

  testWidgets('doctor credentials open the three-page doctor portal', (
    WidgetTester tester,
  ) async {
    DoctorAppointmentStore.instance.clearDemoSchedule();
    await signInAsDoctor(tester);

    expect(find.text('Doctor Dashboard'), findsOneWidget);
    expect(find.textContaining('Dr. Aye Chan'), findsOneWidget);
    expect(find.byKey(const ValueKey('doctor-dashboard')), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byKey(const ValueKey('doctor-navigation-bar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('doctor-appointments-tab')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('doctor-profile-tab')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('doctor-appointments-tab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('doctor-appointments')), findsOneWidget);
    expect(find.text('Bruno'), findsWidgets);

    final firstAppointment = DoctorAppointmentStore.instance.appointments.first;
    await tester.tap(
      find.byKey(ValueKey('doctor-pet-photo-${firstAppointment.id}')).last,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('doctor-pet-details')), findsOneWidget);
    expect(find.text('Name : ${firstAppointment.petName}'), findsOneWidget);
    expect(find.text('Allergies'), findsOneWidget);
    expect(find.text('Clinic History'), findsOneWidget);
    expect(find.text('Additional Information'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('doctor-open-clinic-history')));
    await tester.pumpAndSettle();
    expect(find.text('Medical History'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('doctor-medical-history-list')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('doctor-vaccination-history-tab')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vaccination History'), findsOneWidget);
    expect(find.text('No vaccination history yet'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('doctor-pet-history-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('doctor-pet-details-back')));
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .byKey(
            ValueKey(
              'doctor-appointment-${DoctorAppointmentStore.instance.appointments.first.id}',
            ),
          )
          .last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Appointment Details'), findsOneWidget);
    expect(find.text('General Checkup'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('doctor-update-status')));
    await tester.pumpAndSettle();
    expect(find.text('Update appointment status?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-doctor-status')));
    await tester.pumpAndSettle();
    expect(find.text('Checked In'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('doctor-appointment-details-back')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('doctor-profile-tab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('doctor-profile')), findsOneWidget);
    expect(find.text('doctor@nwaysclinic.com'), findsOneWidget);
    expect(find.text('General Veterinarian'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('doctor-logout')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('doctor-logout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-doctor-logout')));
    await tester.pumpAndSettle();
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('doctor dashboard drives queue consultation and quick actions', (
    WidgetTester tester,
  ) async {
    DoctorAppointmentStore.instance.clearDemoSchedule();
    EmergencyRequestStore.instance.clear();
    await signInAsDoctor(tester);

    expect(find.text('Emergency Cases'), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Today Total Appointments'), findsOneWidget);
    expect(find.text('Up Next'), findsOneWidget);
    expect(find.text('View All Appointments'), findsOneWidget);

    final next = DoctorAppointmentStore.instance.appointments.first;
    final startButton = find.byKey(ValueKey('start-consulting-${next.id}'));
    await tester.scrollUntilVisible(
      startButton,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(
      find.byKey(const ValueKey('doctor-dashboard')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(startButton);
    await tester.pumpAndSettle();
    expect(find.text('Consultation'), findsOneWidget);
    expect(next.status, 'In Consultation');
    expect(find.byKey(const ValueKey('consultation-notes')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('consultation-diagnosis')),
      'Mild digestive upset',
    );
    await tester.enterText(
      find.byKey(const ValueKey('consultation-treatment')),
      'Supportive care and dietary monitoring',
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('complete-doctor-consultation')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('confirm-complete-consultation')),
    );
    await tester.pumpAndSettle();
    expect(next.status, 'Completed');
    expect(
      DoctorMedicalRecordStore.instance.records.any(
        (record) => record.appointmentId == next.id && record.finalized,
      ),
      isTrue,
    );
    expect(find.text('Doctor Dashboard'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('doctor-write-post')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('doctor-write-post')));
    await tester.pumpAndSettle();
    expect(find.text('Create Post'), findsOneWidget);
    expect(find.byKey(const ValueKey('doctor-post-title')), findsOneWidget);
  });

  testWidgets('doctor saves, publishes, and expands a feed post', (
    WidgetTester tester,
  ) async {
    DoctorPostStore.instance.reset();
    await signInAsDoctor(tester);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('doctor-write-post')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('doctor-write-post')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('doctor-post-cover')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey(
          'doctor-post-asset-assets/photos/logoandphoto/pets_transparent.png',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('doctor-post-title')),
      'Healthy pets are happy pets',
    );
    await tester.enterText(
      find.byKey(const ValueKey('doctor-post-content')),
      'Daily play, fresh water, and regular checkups make a lasting difference.',
    );
    await tester.tap(find.byKey(const ValueKey('attach-post-images')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add clinic gallery'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('save-doctor-post-draft')),
    );
    await tester.tap(find.byKey(const ValueKey('save-doctor-post-draft')));
    await tester.pumpAndSettle();
    expect(DoctorPostStore.instance.draft, isNotNull);

    await tester.ensureVisible(
      find.byKey(const ValueKey('publish-doctor-post')),
    );
    await tester.tap(find.byKey(const ValueKey('publish-doctor-post')));
    await tester.pumpAndSettle();

    expect(
      DoctorPostStore.instance.posts.first.title,
      'Healthy pets are happy pets',
    );
    await tester.scrollUntilVisible(
      find.text('Healthy pets are happy pets'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(
        ValueKey('open-doctor-post-${DoctorPostStore.instance.posts.first.id}'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        ValueKey(
          'expand-doctor-post-${DoctorPostStore.instance.posts.first.id}',
        ),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        ValueKey(
          'expand-doctor-post-${DoctorPostStore.instance.posts.first.id}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        ValueKey(
          'collapse-doctor-post-${DoctorPostStore.instance.posts.first.id}',
        ),
      ),
      findsOneWidget,
    );
    expect(
      DoctorPostStore.instance.posts.first.content,
      'Daily play, fresh water, and regular checkups make a lasting difference.',
    );
    DoctorPostStore.instance.reset();
  });

  testWidgets('doctor accepts appointments and controls the patient queue', (
    WidgetTester tester,
  ) async {
    DoctorAppointmentStore.instance.clearDemoSchedule();
    await signInAsDoctor(tester);
    await tester.tap(find.byKey(const ValueKey('doctor-appointments-tab')));
    await tester.pumpAndSettle();

    final pending = DoctorAppointmentStore.instance.appointments.firstWhere(
      (record) => record.status == 'Pending',
    );
    await tester.tap(find.byKey(ValueKey('doctor-appointment-${pending.id}')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('doctor-accept-appointment')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('doctor-accept-appointment')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-doctor-decision')));
    await tester.pumpAndSettle();
    expect(pending.status, 'Confirmed');

    await tester.tap(
      find.byKey(const ValueKey('doctor-appointment-details-back')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('doctor-open-queue')));
    await tester.pumpAndSettle();
    expect(find.text('Patient Queue'), findsOneWidget);
    final first = DoctorAppointmentStore.instance.appointments.first;
    await tester.tap(find.byKey(ValueKey('doctor-call-${first.id}')));
    await tester.pumpAndSettle();
    expect(first.status, 'Called');
    await tester.tap(find.byKey(ValueKey('doctor-queue-start-${first.id}')));
    await tester.pumpAndSettle();
    expect(first.status, 'In Consultation');
    expect(find.text('Consultation'), findsOneWidget);
  });

  testWidgets('doctor appointments use the ongoing card workflow', (
    WidgetTester tester,
  ) async {
    DoctorAppointmentStore.instance.clearDemoSchedule();
    EmergencyRequestStore.instance.clear();
    await signInAsDoctor(tester);

    await tester.tap(find.byKey(const ValueKey('doctor-appointments-tab')));
    await tester.pumpAndSettle();
    expect(find.text('Appointments'), findsWidgets);
    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('Records'), findsOneWidget);
    expect(find.text('Visits'), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('doctor-appointments-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('doctor-dashboard')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('doctor-appointments-tab')));
    await tester.pumpAndSettle();
    final confirmed = DoctorAppointmentStore.instance.appointments.firstWhere(
      (record) => record.status == 'Confirmed',
    );
    await tester.tap(
      find.byKey(ValueKey('doctor-appointment-action-${confirmed.id}')),
    );
    await tester.pumpAndSettle();
    expect(confirmed.status, 'In Consultation');
    expect(find.text('Consultation'), findsOneWidget);
  });

  testWidgets('doctor appointment filter chips narrow the list', (
    WidgetTester tester,
  ) async {
    DoctorAppointmentStore.instance.clearDemoSchedule();
    EmergencyRequestStore.instance.clear();
    await signInAsDoctor(tester);
    await tester.tap(find.byKey(const ValueKey('doctor-appointments-tab')));
    await tester.pumpAndSettle();

    // The first filters are visible without scrolling.
    expect(find.byKey(const ValueKey('doctor-filter-All')), findsOneWidget);

    final filterScrollable = find.descendant(
      of: find.byKey(const ValueKey('doctor-appointment-filters')),
      matching: find.byType(Scrollable),
    );

    // The demo schedule has a Pending appointment (Mimi) and Confirmed ones.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('doctor-filter-Pending')),
      120,
      scrollable: filterScrollable,
    );
    await tester.tap(find.byKey(const ValueKey('doctor-filter-Pending')));
    await tester.pumpAndSettle();
    expect(find.text('Mimi'), findsOneWidget);
    expect(find.text('Bruno'), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('doctor-filter-Confirmed')),
      120,
      scrollable: filterScrollable,
    );
    await tester.tap(find.byKey(const ValueKey('doctor-filter-Confirmed')));
    await tester.pumpAndSettle();
    expect(find.text('Bruno'), findsWidgets);
    expect(find.text('Mimi'), findsNothing);
  });

  test('doctor appointment state round-trips through the map', () {
    const state = DoctorAppointmentState(
      status: 'Completed',
      consultationNotes: 'Stable',
      diagnosis: 'Mild upset',
      treatment: 'Rest',
      followUp: 'One week',
    );
    final restored = DoctorAppointmentState.fromMap(state.toMap());
    expect(restored.status, 'Completed');
    expect(restored.consultationNotes, 'Stable');
    expect(restored.diagnosis, 'Mild upset');
    expect(restored.treatment, 'Rest');
    expect(restored.followUp, 'One week');
  });

  testWidgets('doctor dashboard prioritizes active emergency cases', (
    WidgetTester tester,
  ) async {
    DoctorAppointmentStore.instance.clearDemoSchedule();
    EmergencyRequestStore.instance.clear();
    EmergencyRequestStore.instance.add(
      EmergencyRequest(
        id: 'DOCTOR-EMERGENCY-1',
        createdAt: DateTime.now(),
        pet: const EmergencyPet(
          name: 'Lucky',
          breed: 'Mixed Breed',
          age: '3 years',
          medicalHistory: 'No known allergies',
          color: Colors.red,
        ),
        symptoms: const ['Difficulty breathing'],
        description: 'Sudden breathing difficulty',
        contactPerson: 'Pet Owner',
        phone: '09-123456789',
      ),
    );
    await signInAsDoctor(tester);

    expect(find.text('Lucky • Emergency'), findsOneWidget);
    expect(find.text('Difficulty breathing'), findsOneWidget);
    expect(find.byKey(const ValueKey('doctor-emergency-stat')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('doctor-emergency-stat')));
    await tester.pumpAndSettle();
    expect(find.text('Emergency Cases'), findsOneWidget);
    expect(find.text('Lucky • Emergency'), findsOneWidget);
    await tester.tap(find.text('Lucky • Emergency'));
    await tester.pumpAndSettle();
    expect(find.text('Emergency Case'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('doctor-accept-emergency')));
    await tester.pumpAndSettle();
    expect(
      EmergencyRequestStore.instance.requests.first.status,
      EmergencyStatus.accepted,
    );
    EmergencyRequestStore.instance.clear();
  });

  testWidgets('doctor updates Home Visit travel and profile settings', (
    WidgetTester tester,
  ) async {
    HomeVisitStore.instance.clear();
    final visit = HomeVisit(
      id: 'DOCTOR-HOME-1',
      pet: const HomeVisitPet(
        name: 'Max',
        breed: 'Golden Retriever',
        age: '2 years',
        medicalHistory: 'Vaccinations current',
        color: Colors.blue,
      ),
      veterinarian: DoctorAppointmentStore.doctorName,
      date: DateTime.now().add(const Duration(days: 1)),
      time: '1:00 PM',
      reason: 'Mobility concern',
      symptoms: 'Limping',
      address: 'No. 18, Chindwin Street, Nay Pyi Taw',
      contactPerson: 'Pet Owner',
      phone: '09-123456789',
    );
    HomeVisitStore.instance.add(visit);
    await signInAsDoctor(tester);
    await tester.tap(find.byKey(const ValueKey('doctor-appointments-tab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('doctor-open-home-visits')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('doctor-home-visit-DOCTOR-HOME-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home Visit Details'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('doctor-update-home-visit')));
    await tester.pumpAndSettle();
    expect(visit.status, HomeVisitStatus.onTheWay);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('doctor-profile-tab')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('edit-doctor-profile')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-doctor-profile')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('doctor-availability-setting')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('doctor-availability-setting')),
      findsOneWidget,
    );
    HomeVisitStore.instance.clear();
  });

  test('doctor authentication rejects incorrect credentials', () async {
    const api = DoctorAuthApi();
    final result = await api.login(
      username: DoctorAuthApi.demoEmail,
      password: 'wrong-password',
    );
    expect(result.isSuccess, isFalse);
    expect(result.message, 'Invalid doctor username or password.');
  });

  testWidgets('registered administrator email opens the admin dashboard', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NwayLoveVetClinicApp());
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('contact-field')),
      SystemAdminAuthApi.demoEmail,
    );
    await tester.enterText(
      find.byType(TextField).last,
      SystemAdminAuthApi.demoPassword,
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('System Administration'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('system-admin-dashboard')),
      findsOneWidget,
    );
    expect(find.text('System Administrator'), findsOneWidget);
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
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -520),
    );
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

  testWidgets('owner profile edits and verifies changed contact details', (
    WidgetTester tester,
  ) async {
    OwnerProfileStore.instance.reset();
    await signIn(tester);
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('owner-edit-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Edit Profile'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('edit-owner-name')),
      'Nee Yu Aung',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-owner-phone')),
      '09911122233',
    );
    await tester.tap(find.byKey(const ValueKey('save-owner-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Verify Contact Information'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('owner-verification-code')),
      '111111',
    );
    await tester.tap(find.byKey(const ValueKey('verify-owner-contact')));
    await tester.pump();
    expect(find.text('Incorrect verification code'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('owner-verification-code')),
      '123456',
    );
    await tester.tap(find.byKey(const ValueKey('verify-owner-contact')));
    await tester.pumpAndSettle();
    expect(find.text('Nee Yu Aung'), findsOneWidget);
    expect(find.text('09911122233'), findsOneWidget);
    expect(find.text('Profile updated successfully'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('owner-edit-profile')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('edit-owner-name')),
      'Unsaved Name',
    );
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Nee Yu Aung'), findsOneWidget);
    expect(find.text('Unsaved Name'), findsNothing);
  });

  testWidgets('profile quick actions open location and emergency safeguards', (
    WidgetTester tester,
  ) async {
    await signIn(tester);
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profile-location-action')));
    await tester.pumpAndSettle();
    expect(find.text('Clinic Location'), findsOneWidget);
    expect(find.text('8:00 AM–10:00 PM'), findsOneWidget);
    expect(find.text(ContactClinicPage.address), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('get-clinic-directions')));
    await tester.pumpAndSettle();
    expect(find.text('Choose navigation option'), findsOneWidget);
    expect(find.text('Copy clinic address'), findsOneWidget);
    await tester.tap(find.text('Copy clinic address'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Clinic Location'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profile-emergency-action')));
    await tester.pumpAndSettle();
    expect(find.text('Emergency Notice'), findsOneWidget);
    expect(find.text('Call Clinic Now'), findsOneWidget);
    expect(find.textContaining('should not be delayed'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('emergency-call-clinic-now')));
    await tester.pumpAndSettle();
    expect(find.text('Call Clinic Now?'), findsOneWidget);
    expect(find.text('Confirm Call'), findsOneWidget);
  });

  testWidgets('profile adds a pet and opens the created pet profile', (
    WidgetTester tester,
  ) async {
    ProfilePetStore.instance.reset();
    await signIn(tester);
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('profile-add-pet')));
    await tester.tap(find.byKey(const ValueKey('profile-add-pet')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('add-pet-name')), 'Milo');
    await tester.tap(find.byKey(const ValueKey('add-pet-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cat').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cat breed *'),
      'Siamese',
    );
    await tester.tap(find.byKey(const ValueKey('add-pet-sex')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-pet-dob')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('add-pet-weight')));
    await tester.enterText(find.byKey(const ValueKey('add-pet-weight')), '4.5');
    await tester.ensureVisible(find.byKey(const ValueKey('review-add-pet')));
    await tester.tap(find.byKey(const ValueKey('review-add-pet')));
    await tester.pumpAndSettle();
    expect(find.text('Review Pet'), findsWidgets);
    expect(find.textContaining('Milo'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-add-pet')));
    await tester.pumpAndSettle();
    expect(find.text('Pet Profile'), findsOneWidget);
    expect(find.text('Milo'), findsWidgets);
    expect(
      ProfilePetStore.instance.pets.any((pet) => pet.name == 'Milo'),
      isTrue,
    );
  });

  testWidgets('profile displays and manages upcoming appointments', (
    WidgetTester tester,
  ) async {
    AppointmentStore.instance.clear();
    final appointment = BookedAppointment(
      id: 'PROFILE-1',
      createdAt: DateTime.now(),
      pet: const BookingPet(
        name: 'Max',
        species: 'Dog',
        breed: 'Golden Retriever',
        age: '2 years',
        icon: Icons.pets,
        color: Colors.blue,
      ),
      service: const BookingService(
        name: 'General Checkup',
        description: 'Routine examination',
        icon: Icons.health_and_safety,
        homeVisit: false,
        doctors: ['Dr. Aye Chan'],
      ),
      veterinarian: 'Dr. Aye Chan',
      date: DateTime.now().add(const Duration(days: 2)),
      time: '10:00 AM',
      symptoms: 'Low appetite',
      reason: 'Checkup',
      notes: '',
      address: '',
      status: 'Confirmed',
    );
    AppointmentStore.instance.add(appointment);
    await signIn(tester);
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profile-appointment-PROFILE-1')),
      350,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Max • General Checkup'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('appointment-reminder-PROFILE-1')),
    );
    await tester.pump();
    expect(find.textContaining('Reminder scheduled'), findsOneWidget);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('appointment-reschedule-PROFILE-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reschedule Appointment'), findsOneWidget);
    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pump();
    await tester.tap(find.text('9:00 AM'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-reschedule')));
    await tester.pumpAndSettle();
    expect(appointment.time, '9:00 AM');
    await tester.ensureVisible(
      find.byKey(const ValueKey('appointment-cancel-PROFILE-1')),
    );
    await tester.tap(
      find.byKey(const ValueKey('appointment-cancel-PROFILE-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cancel Booking'), findsOneWidget);
    expect(find.text('Cancellation policy'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cancellation-reason-Other')));
    await tester.pump();
    await tester.drag(find.byType(ListView).last, const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('review-cancellation')),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(
      find.byKey(const ValueKey('other-cancellation-reason')),
      'Family schedule changed',
    );
    tester.testTextInput.hide();
    await tester.pump();
    await tester.drag(find.byType(ListView).last, const Offset(0, -250));
    await tester.pumpAndSettle();
    tester
        .widget<FilledButton>(find.byKey(const ValueKey('review-cancellation')))
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Cancellation Summary'), findsOneWidget);
    expect(find.text('MMK 0 — No cancellation fee'), findsOneWidget);
    expect(
      find.text('MMK 0 — No payment collected; no refund required'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('confirm-cancellation')));
    await tester.pumpAndSettle();
    expect(find.text('Final Confirmation'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('yes-cancel-booking')));
    await tester.pumpAndSettle();
    expect(appointment.status, 'Cancelled');
    expect(appointment.cancellation?.reason, 'Other');
    expect(
      appointment.cancellation?.additionalReason,
      'Family schedule changed',
    );
    expect(find.text('Booking Cancelled'), findsOneWidget);
    expect(find.textContaining('Cancellation ID: CAN-'), findsOneWidget);
    expect(
      AppointmentStore.instance.isSlotAvailable(
        veterinarian: appointment.veterinarian,
        date: appointment.date,
        time: appointment.time,
      ),
      isTrue,
    );
    expect(QueueStore.instance.existingEntryFor(appointment), isNull);
  });

  test('cancellation rules prevent duplicates and started cancellations', () {
    AppointmentStore.instance.clear();
    BookedAppointment appointment(String id, DateTime date) =>
        BookedAppointment(
          id: id,
          createdAt: DateTime.now(),
          pet: const BookingPet(
            name: 'Max',
            species: 'Dog',
            breed: 'Golden Retriever',
            age: '2 years',
            icon: Icons.pets,
            color: Colors.blue,
          ),
          service: const BookingService(
            name: 'General Checkup',
            description: 'Routine examination',
            icon: Icons.health_and_safety,
            homeVisit: false,
            doctors: ['Dr. Aye Chan'],
          ),
          veterinarian: 'Dr. Aye Chan',
          date: date,
          time: '10:00 AM',
          symptoms: 'Low appetite',
          reason: 'Checkup',
          notes: '',
          address: '',
          status: 'Confirmed',
        );

    final cancellable = appointment(
      'CANCEL-RULE-1',
      DateTime.now().add(const Duration(days: 3)),
    );
    AppointmentStore.instance.add(cancellable);
    final first = AppointmentStore.instance.cancelWithDetails(
      cancellable,
      reason: 'Schedule conflict',
    );
    expect(first, isNotNull);
    expect(
      AppointmentStore.instance.cancelWithDetails(
        cancellable,
        reason: 'Personal reason',
      ),
      isNull,
    );
    expect(
      AppointmentStore.instance.reschedule(
        cancellable,
        date: DateTime.now().add(const Duration(days: 4)),
        time: '11:00 AM',
      ),
      isFalse,
    );

    final started = appointment(
      'CANCEL-RULE-2',
      DateTime.now().add(const Duration(days: 3)),
    );
    AppointmentStore.instance.add(started);
    QueueStore.instance.syncConfirmedAppointments([started]);
    final entry = QueueStore.instance.existingEntryFor(started)!;
    QueueStore.instance.staffUpdate(entry, QueueStatus.inConsultation);
    expect(
      AppointmentStore.instance.cancellationEligibility(started).allowed,
      isFalse,
    );
    expect(
      AppointmentStore.instance.cancelWithDetails(
        started,
        reason: 'Staff cancellation',
        initiatedBy: CancellationInitiator.staff,
      ),
      isNull,
    );

    final sameDay = appointment('CANCEL-RULE-3', DateTime.now());
    expect(
      AppointmentStore.instance.cancellationEligibility(sameDay).late,
      isTrue,
    );
    AppointmentStore.instance.clear();
  });

  testWidgets(
    'profile medical summary opens read-only vaccine treatment records',
    (WidgetTester tester) async {
      await signIn(tester);
      await tester.tap(find.byTooltip('Profile'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Vaccines'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.drag(
        find.byKey(const ValueKey('owner-profile-scroll')),
        const Offset(0, -150),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vaccines'));
      await tester.pumpAndSettle();

      expect(find.text('Vaccination Summary'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.textContaining('read-only'), findsOneWidget);
      await tester.tap(find.text('Rabies Vaccination'));
      await tester.pumpAndSettle();
      expect(find.text('Record Details'), findsOneWidget);
      expect(find.text('Dose'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('view-medical-document')));
      await tester.pumpAndSettle();
      expect(find.text('Vaccination Certificate'), findsWidgets);
      expect(find.text('Clinic-issued read-only document'), findsOneWidget);
      Navigator.of(
        tester.element(find.text('Clinic-issued read-only document')),
      ).pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('Record Details'))).pop();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('book-vaccination')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const ValueKey('book-vaccination')));
      await tester.pumpAndSettle();
      expect(find.text('Select Veterinarian'), findsOneWidget);
      Navigator.of(tester.element(find.text('Select Veterinarian'))).pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('Vaccination Summary'))).pop();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Treatments'));
      await tester.tap(find.text('Treatments'));
      await tester.pumpAndSettle();
      expect(find.text('Treatment History'), findsOneWidget);
      expect(find.text('Follow-up Required'), findsOneWidget);
      await tester.tap(find.text('Skin Irritation Treatment'));
      await tester.pumpAndSettle();
      expect(find.text('Diagnosis'), findsOneWidget);
      expect(find.text('Recommendations'), findsOneWidget);
      expect(find.text('View Prescription'), findsOneWidget);
      Navigator.of(tester.element(find.text('Record Details'))).pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('Treatment History'))).pop();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Records'));
      await tester.tap(find.text('Records'));
      await tester.pumpAndSettle();
      expect(find.text('Medical Records'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('medical-record-search')),
        findsOneWidget,
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('medical-category-prescription')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dermatitis Prescription'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    },
  );

  testWidgets(
    'profile account tools save address notifications support and logout',
    (WidgetTester tester) async {
      await signIn(tester);
      await tester.tap(find.byTooltip('Profile'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Saved Addresses'),
        500,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.drag(
        find.byKey(const ValueKey('owner-profile-scroll')),
        const Offset(0, -180),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saved Addresses'));
      await tester.pumpAndSettle();
      expect(find.text('Saved Addresses'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('add-saved-address')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-address')));
      await tester.pump();
      expect(find.text('This field is required'), findsWidgets);

      const addressValues = [
        'Mya Mya',
        '09912345678',
        'No. 24',
        'Thazin Street',
        'Zabuthiri',
        'Nay Pyi Taw',
      ];
      for (var index = 0; index < addressValues.length; index++) {
        await tester.enterText(
          find.byType(TextFormField).at(index),
          addressValues[index],
        );
      }
      await tester.ensureVisible(find.byKey(const ValueKey('save-address')));
      await tester.tap(find.byKey(const ValueKey('save-address')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Thazin Street'), findsOneWidget);
      Navigator.of(tester.element(find.text('Saved Addresses').first)).pop();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Notification Settings'));
      await tester.tap(find.text('Notification Settings'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Always enabled'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('save-notification-settings')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Notification settings updated'), findsOneWidget);

      await tester.ensureVisible(find.text('Help & Support'));
      await tester.tap(find.text('Help & Support'));
      await tester.pumpAndSettle();
      expect(find.text('Technical Support'), findsOneWidget);
      expect(find.text('Payment'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('contact-support')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('support-subject')),
        'Cannot open a record',
      );
      await tester.enterText(
        find.byKey(const ValueKey('support-description')),
        'The medical record page needs assistance.',
      );
      await tester.tap(find.byKey(const ValueKey('submit-support-request')));
      await tester.pumpAndSettle();
      expect(find.text('Support request submitted'), findsOneWidget);
      expect(find.textContaining('Reference number'), findsOneWidget);
      await tester.tap(find.text('View Requests'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cannot open a record'), findsOneWidget);
      Navigator.of(tester.element(find.text('Help & Support'))).pop();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Log Out'));
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();
      expect(find.text('Log Out?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm-profile-logout')));
      await tester.pumpAndSettle();
      expect(find.text('Log in'), findsOneWidget);
    },
  );

  testWidgets('product details are browse-only', (WidgetTester tester) async {
    await signIn(tester);

    await tester.tap(find.byTooltip('Products'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dog Food 01'));
    await tester.tap(find.text('Dog Food 01'));
    await tester.pumpAndSettle();

    expect(find.text('Add to Cart'), findsNothing);
    expect(find.text('Buy Now'), findsNothing);
    expect(find.text('Quantity'), findsNothing);
  });

  testWidgets('books an appointment and shows it in My Appointments', (
    WidgetTester tester,
  ) async {
    AppointmentStore.instance.clear();
    await signIn(tester);

    await tester.tap(find.byTooltip('Clinic'));
    await tester.pumpAndSettle();

    final bookingCategory = find.byKey(
      const ValueKey('clinic-booking-category'),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1400));
    await tester.pumpAndSettle();
    await tester.tap(bookingCategory);
    await tester.pumpAndSettle();

    expect(find.text('Choose Pet'), findsOneWidget);
    await tester.tap(find.text('Max').last);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('General Checkup'));
    await tester.pump();
    await tester.tap(find.text('Find Veterinarians'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dr. Aye Chan'));
    await tester.pump();
    await tester.tap(find.text('Choose Date'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pump();
    await tester.tap(find.text('View Time Slots'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('appointment-time-9:00 AM')));
    await tester.pump();
    await tester.tap(find.text('Enter Appointment Details'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('appointment-symptoms')),
      'Low appetite',
    );
    await tester.enterText(
      find.byKey(const ValueKey('appointment-reason')),
      'Routine health assessment',
    );
    await tester.tap(find.text('Review Booking'));
    await tester.pumpAndSettle();

    expect(find.text('Booking Summary'), findsOneWidget);
    await tester.tap(find.text('Confirm Appointment'));
    await tester.pumpAndSettle();

    expect(find.text('Your booking is confirmed!'), findsOneWidget);
    expect(find.textContaining('Booking ID: #NWAY'), findsOneWidget);

    await tester.tap(find.text('View My Appointments'));
    await tester.pumpAndSettle();

    expect(find.text('My Appointments'), findsOneWidget);
    expect(find.text('General Checkup'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.textContaining('Max • Dr. Aye Chan'), findsOneWidget);

    await tester.tap(find.text('General Checkup'));
    await tester.pumpAndSettle();
    expect(find.text('Appointment Details'), findsOneWidget);
    expect(
      find.textContaining('Pet owners can only view these updates.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Open My Queue'));
    await tester.pumpAndSettle();
    expect(find.text('My Queue'), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);
    expect(find.textContaining('2 pets ahead'), findsOneWidget);

    final queueEntry = QueueStore.instance.active.single;
    await tester.tap(find.text(queueEntry.queueNumber));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Pet owners cannot change it manually.'),
      findsOneWidget,
    );
    expect(find.text('Check In'), findsNothing);

    QueueStore.instance.staffUpdate(queueEntry, QueueStatus.almostTurn);
    await tester.pumpAndSettle();
    expect(find.text('Almost Your Turn'), findsOneWidget);
    expect(find.textContaining('Almost your turn.'), findsOneWidget);

    QueueStore.instance.staffUpdate(
      queueEntry,
      QueueStatus.called,
      room: 'Consultation Room 2',
    );
    await tester.pumpAndSettle();
    expect(find.text('Called'), findsOneWidget);
    expect(find.text('Consultation Room 2'), findsWidgets);

    QueueStore.instance.staffUpdate(queueEntry, QueueStatus.inConsultation);
    await tester.pumpAndSettle();
    expect(find.text('In Consultation'), findsOneWidget);

    QueueStore.instance.staffUpdate(queueEntry, QueueStatus.completed);
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsOneWidget);
    await tester.ensureVisible(find.text('Consultation Record'));
    await tester.pumpAndSettle();
    expect(find.text('Consultation Record'), findsOneWidget);
    expect(find.text('Diagnosis'), findsOneWidget);
    expect(find.text('Recommendations'), findsOneWidget);

    Navigator.of(tester.element(find.text('Consultation Record'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Queue History'));
    await tester.pumpAndSettle();
    expect(find.text('Queue History'), findsOneWidget);
    expect(find.textContaining('Completed appointment'), findsOneWidget);
  });

  testWidgets('books pet care and shows staff-managed status', (
    WidgetTester tester,
  ) async {
    PetCareBookingStore.instance.clear();
    await signIn(tester);

    await tester.tap(find.byTooltip('Clinic'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1400));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).at(1), const Offset(-520, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pet Care Services'));
    await tester.pumpAndSettle();

    expect(find.text('Care made comfortable'), findsOneWidget);
    expect(find.text('Grooming'), findsOneWidget);
    expect(find.text('From 7,000 MMK'), findsWidgets);
    expect(find.text('Home Care'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('pet-care-service-Grooming')));
    await tester.pumpAndSettle();
    expect(find.text('Grooming Services'), findsOneWidget);
    expect(find.text('Shaving'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('start-service-booking')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('care-pet-Max')));
    await tester.pump();
    await tester.tap(find.text('Check Eligibility'));
    await tester.pumpAndSettle();

    expect(find.text('Eligible for Grooming'), findsOneWidget);
    await tester.tap(find.text('May Thazin'));
    await tester.pump();
    await tester.tap(find.text('Select Schedule'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pump();
    expect(find.byKey(const ValueKey('care-time-12:00 PM')), findsOneWidget);
    expect(find.byKey(const ValueKey('care-time-5:00 PM')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('care-time-9:00 AM')));
    await tester.pump();
    await tester.tap(find.text('Hold This Slot'));
    await tester.pump();

    expect(find.text('Special Instructions'), findsNothing);
    expect(find.text('Booking Summary'), findsOneWidget);
    expect(
      find.textContaining('No online payment is required.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Confirm Service'));
    await tester.pumpAndSettle();
    expect(find.text('Service booking confirmed!'), findsOneWidget);
    expect(find.textContaining('Booking number: #CARE'), findsOneWidget);

    await tester.tap(find.text('View Service Booking'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Status is updated by clinic staff.'), findsOneWidget);
    expect(find.text('Check In Pet'), findsNothing);
    expect(find.text('Start Service'), findsNothing);
    expect(find.text('Mark Service Complete'), findsNothing);
  });

  testWidgets('Clinic Queue category opens read-only My Queue', (
    WidgetTester tester,
  ) async {
    AppointmentStore.instance.clear();
    await signIn(tester);

    await tester.tap(find.byTooltip('Clinic'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('clinic-queue-category')));
    await tester.pumpAndSettle();

    expect(find.text('My Queue'), findsOneWidget);
    expect(find.text('No active queue'), findsOneWidget);
    expect(find.byTooltip('Queue History'), findsOneWidget);
  });

  testWidgets('History filters records and opens medical follow-up', (
    WidgetTester tester,
  ) async {
    AppointmentStore.instance.clear();
    PetCareBookingStore.instance.clear();
    HomeVisitStore.instance.clear();
    HistoryReviewStore.instance.clear();

    final appointment = BookedAppointment(
      id: 'TEST-HISTORY',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      pet: const BookingPet(
        name: 'Max',
        species: 'Dog',
        breed: 'Golden Retriever',
        age: '2 years',
        icon: Icons.pets_rounded,
        color: Color(0xFF2F80FF),
      ),
      service: const BookingService(
        name: 'General Checkup',
        description: 'Routine health assessment',
        icon: Icons.health_and_safety_outlined,
        homeVisit: false,
        doctors: ['Dr. Aye Chan'],
      ),
      veterinarian: 'Dr. Aye Chan',
      date: DateTime.now().add(const Duration(days: 1)),
      time: '9:00 AM',
      symptoms: 'Low appetite',
      reason: 'Routine assessment',
      notes: '',
      address: '',
      status: 'Confirmed',
    );
    AppointmentStore.instance.add(appointment);
    QueueStore.instance.syncConfirmedAppointments([appointment]);
    final queueEntry = QueueStore.instance.entryFor(appointment)!;
    QueueStore.instance.staffUpdate(queueEntry, QueueStatus.completed);

    PetCareBookingStore.instance.add(
      PetCareBooking(
        id: 'CARE-HISTORY',
        service: PetCareCatalog.services.first,
        pet: PetCareCatalog.pets.first,
        provider: 'May Thazin',
        date: DateTime.now().subtract(const Duration(days: 5)),
        time: '10:00 AM',
        location: "Nway's Love Vet Clinic",
      ),
    );
    final homeVisit = HomeVisit(
      id: 'HOME-HISTORY',
      pet: const HomeVisitPet(
        name: 'Max',
        breed: 'Golden Retriever',
        age: '2 years',
        medicalHistory: 'Vaccinations current',
        color: Color(0xFF2F80FF),
      ),
      veterinarian: 'Dr. Cindy Lynn',
      date: DateTime.now().subtract(const Duration(days: 10)),
      time: '1:00 PM',
      reason: 'Follow-up',
      symptoms: 'Tiredness',
      address: 'Popba Thiri Township, Nay Pyi Taw',
      contactPerson: 'Nee Yu',
      phone: '09-5312717',
    );
    HomeVisitStore.instance.add(homeVisit);

    await signIn(tester);
    await tester.tap(find.byTooltip('Clinic'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1700));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('clinic-history-category')));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('history-pet-Max')));
    await tester.pumpAndSettle();
    expect(find.text('Max Records'), findsOneWidget);
    expect(find.text('Appointments'), findsOneWidget);
    expect(find.text('Medical Services'), findsOneWidget);
    expect(find.text('Pet Care Services'), findsOneWidget);
    expect(find.text('Home Visits'), findsOneWidget);
    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('Payments'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('history-search')),
      'Aye Chan',
    );
    await tester.pumpAndSettle();
    expect(find.text('General Checkup'), findsOneWidget);
    await tester.tap(find.text('General Checkup'));
    await tester.pumpAndSettle();
    expect(find.text('History Details'), findsOneWidget);
    expect(find.text('Booking date'), findsOneWidget);
    expect(find.text('Appointment date'), findsOneWidget);
    expect(find.text('Routine assessment'), findsOneWidget);

    Navigator.of(tester.element(find.text('History Details'))).pop();
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('history-search')), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-category-medical')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('General Checkup'));
    await tester.pumpAndSettle();

    expect(find.text('Diagnosis'), findsOneWidget);
    expect(find.text('Treatment'), findsOneWidget);
    expect(find.text('Prescription'), findsOneWidget);
    expect(find.text('Recommendations'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('view-history-medical-record')),
    );
    await tester.tap(find.byKey(const ValueKey('view-history-medical-record')));
    await tester.pumpAndSettle();
    expect(find.text('Medical Record'), findsOneWidget);
    Navigator.of(tester.element(find.text('Medical Record'))).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('history-rating-5')));
    await tester.tap(find.byKey(const ValueKey('history-rating-5')));
    await tester.enterText(
      find.widgetWithText(TextField, 'Write a review'),
      'Helpful consultation.',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Review'));
    await tester.tap(find.text('Save Review'));
    await tester.pumpAndSettle();
    expect(find.text('5 / 5'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('book-history-follow-up')),
    );
    await tester.tap(find.byKey(const ValueKey('book-history-follow-up')));
    await tester.pumpAndSettle();
    expect(find.text('Choose Pet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Select Service'), findsOneWidget);
  });

  testWidgets('books and completes a Home Visit from Clinic categories', (
    WidgetTester tester,
  ) async {
    HomeVisitStore.instance.clear();
    await signIn(tester);

    await tester.tap(find.byTooltip('Clinic'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('clinic-home-visit-category')));
    await tester.pumpAndSettle();

    expect(find.text('Book a Home Visit'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-visit-pet-Max')));
    await tester.pump();
    await tester.tap(find.text('Select Veterinarian'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dr. Hnin Thiri Aung'));
    await tester.pump();
    await tester.tap(find.text('View Available Dates'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pump();
    await tester.tap(find.text('View Home Visit Times'));
    await tester.pumpAndSettle();

    expect(find.textContaining('12:00 PM and 3:00 PM'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-visit-time-12:00 PM')));
    await tester.pump();
    await tester.tap(find.text('Hold This Slot'));
    await tester.pump();

    await tester.tap(find.text('General Checkup'));
    await tester.enterText(
      find.byKey(const ValueKey('home-visit-symptoms')),
      'Low appetite and tiredness',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm Visit Address'));
    await tester.pumpAndSettle();

    expect(find.text('Saved Address'), findsOneWidget);
    await tester.tap(find.text('Validate Address'));
    await tester.pumpAndSettle();
    expect(find.text('Contact Details'), findsOneWidget);
    await tester.tap(find.text('Review Home Visit'));
    await tester.pumpAndSettle();

    expect(find.text('Home Visit Summary'), findsOneWidget);
    expect(
      find.textContaining('No online payment is required.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Confirm Home Visit'));
    await tester.pumpAndSettle();

    expect(find.text('Home Visit confirmed!'), findsOneWidget);
    expect(find.textContaining('Booking ID: #HOME'), findsOneWidget);
    await tester.tap(find.text('Open Visit Reminder'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.textContaining('Reminder:'), findsOneWidget);
    await tester.tap(find.text('Veterinarian On the Way'));
    await tester.pumpAndSettle();
    expect(find.text('On the Way'), findsOneWidget);

    await tester.tap(find.text('Confirm Veterinarian Arrived'));
    await tester.pumpAndSettle();
    expect(find.text('Arrived'), findsOneWidget);
    await tester.tap(find.text('Begin Home Consultation'));
    await tester.pumpAndSettle();
    expect(find.text('Consultation'), findsOneWidget);

    await tester.tap(find.text('Record Findings'));
    await tester.pumpAndSettle();
    expect(find.text('Treatment Proposed'), findsOneWidget);
    expect(find.text('Proposed treatment'), findsOneWidget);
    await tester.ensureVisible(find.text('Approve Treatment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve Treatment'));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsOneWidget);

    await tester.tap(find.text('Open Medical Record'));
    await tester.pumpAndSettle();
    expect(find.text('Home Visit Medical Record'), findsOneWidget);
    expect(find.text('Treatment notes'), findsOneWidget);
    expect(find.text('Medicines'), findsOneWidget);
    expect(find.text('Recommendations'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('home-visit-rating-5')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-visit-rating-5')));
    await tester.enterText(
      find.widgetWithText(TextField, 'Write a review'),
      'The veterinarian was very helpful.',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Submit Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit Review'));
    await tester.pump();
    expect(
      find.text('Thank you. Your Home Visit review was saved.'),
      findsOneWidget,
    );
  });

  testWidgets('submits and tracks a staff-managed emergency request', (
    WidgetTester tester,
  ) async {
    EmergencyRequestStore.instance.clear();
    await signIn(tester);

    await tester.tap(find.byTooltip('Clinic'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1700));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('clinic-emergency-services-category')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Emergency Notice'), findsOneWidget);
    expect(find.text('Clinic Hours'), findsOneWidget);
    expect(find.text('Emergency Contact'), findsOneWidget);
    await tester.tap(find.text('Continue Emergency Request'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('emergency-pet-Max')));
    await tester.pump();
    await tester.tap(find.text('Select Emergency Symptoms'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('emergency-symptom-Breathing Difficulty')),
    );
    await tester.pump();
    await tester.tap(find.text('Describe the Emergency'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('emergency-description')),
      'Max is breathing rapidly and appears weak.',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm Contact Details'));
    await tester.pumpAndSettle();
    expect(find.text('Contact Details'), findsOneWidget);
    await tester.tap(find.text('Review Emergency Request'));
    await tester.pumpAndSettle();

    expect(find.text('Emergency Summary'), findsOneWidget);
    expect(find.text('Breathing Difficulty'), findsOneWidget);
    await tester.tap(find.text('Submit Emergency Request'));
    await tester.pumpAndSettle();
    expect(find.text('Emergency request submitted'), findsOneWidget);
    expect(find.textContaining('Request ID: #ER'), findsOneWidget);
    expect(
      find.textContaining('Bring your pet to the clinic immediately.'),
      findsOneWidget,
    );
    expect(
      find.text('Clinic staff have been notified immediately.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Open Emergency Status'));
    await tester.pumpAndSettle();
    expect(find.text('Submitted'), findsOneWidget);
    expect(
      find.textContaining('Pet owners cannot change them manually.'),
      findsOneWidget,
    );

    final request = EmergencyRequestStore.instance.requests.single;
    EmergencyRequestStore.instance.staffUpdate(
      request,
      EmergencyStatus.underReview,
      priority: 'Critical',
    );
    await tester.pumpAndSettle();
    expect(find.text('Under Staff Review'), findsOneWidget);
    expect(find.textContaining('Critical'), findsWidgets);

    EmergencyRequestStore.instance.staffUpdate(
      request,
      EmergencyStatus.accepted,
    );
    await tester.pumpAndSettle();
    expect(find.text('Accepted by Clinic'), findsOneWidget);
    expect(find.textContaining('clinic can accept'), findsOneWidget);

    EmergencyRequestStore.instance.staffUpdate(
      request,
      EmergencyStatus.checkedIn,
    );
    await tester.pumpAndSettle();
    expect(find.text('Checked In'), findsOneWidget);
    EmergencyRequestStore.instance.staffUpdate(
      request,
      EmergencyStatus.assessment,
    );
    await tester.pumpAndSettle();
    expect(find.text('Emergency Assessment'), findsOneWidget);
    EmergencyRequestStore.instance.staffUpdate(
      request,
      EmergencyStatus.waiting,
      priority: 'Critical',
    );
    await tester.pumpAndSettle();
    expect(find.text('Emergency Queue'), findsOneWidget);
    EmergencyRequestStore.instance.staffUpdate(
      request,
      EmergencyStatus.consultation,
    );
    await tester.pumpAndSettle();
    expect(find.text('Emergency Consultation'), findsOneWidget);

    EmergencyRequestStore.instance.staffUpdate(
      request,
      EmergencyStatus.treatmentProposed,
    );
    await tester.pumpAndSettle();
    expect(find.text('Treatment Approval Required'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('approve-emergency-treatment')),
    );
    await tester.tap(find.byKey(const ValueKey('approve-emergency-treatment')));
    await tester.pumpAndSettle();
    expect(
      find.text('Owner treatment consent has been recorded.'),
      findsOneWidget,
    );

    EmergencyRequestStore.instance.staffUpdate(
      request,
      EmergencyStatus.treatmentInProgress,
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 900));
    await tester.pumpAndSettle();
    expect(find.text('Emergency Treatment'), findsOneWidget);
    EmergencyRequestStore.instance.staffUpdate(
      request,
      EmergencyStatus.completed,
    );
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Open Medical Record'));
    await tester.tap(find.text('Open Medical Record'));
    await tester.pumpAndSettle();
    expect(find.text('Emergency Medical Record'), findsOneWidget);
    expect(find.text('Diagnosis'), findsOneWidget);
    expect(find.text('Treatment'), findsOneWidget);
    expect(find.text('Recommendations'), findsOneWidget);
    Navigator.of(tester.element(find.text('Emergency Medical Record'))).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Book Follow-up'));
    await tester.tap(find.text('Book Follow-up'));
    await tester.pumpAndSettle();
    expect(find.text('Choose Pet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Select Service'), findsOneWidget);
    Navigator.of(tester.element(find.text('Select Service'))).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Open Emergency History'));
    await tester.tap(find.text('Open Emergency History'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-pet-Max')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-900, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-category-emergency')));
    await tester.pumpAndSettle();
    expect(find.text('Emergency Service'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('Medical Services is a browse-only clinic catalog', (
    WidgetTester tester,
  ) async {
    await signIn(tester);

    await tester.tap(find.byTooltip('Clinic'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1400));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).at(1), const Offset(-360, 0));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('clinic-medical-services-category')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Medical Services'), findsOneWidget);
    expect(find.text('Diagnostic Services'), findsOneWidget);
    expect(find.text('Rapid Test'), findsOneWidget);
    expect(find.text('Ultra Sound'), findsOneWidget);
    expect(find.text('Blood Testing'), findsOneWidget);
    expect(find.text('Select Pet'), findsNothing);
    expect(find.text('Confirm Appointment'), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('medical-services-catalog')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    expect(find.text('Preventive Care'), findsOneWidget);
    expect(find.text('Rabies Vaccination'), findsOneWidget);
    expect(find.text('Operational Services'), findsOneWidget);
    expect(find.text('Neutering (Birth Control)'), findsOneWidget);
  });

  testWidgets('First Aid provides offline read-only emergency guidance', (
    WidgetTester tester,
  ) async {
    FirstAidSavedStore.instance.clear();
    await signIn(tester);

    await tester.tap(find.byTooltip('Clinic'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1700));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).at(2), const Offset(-250, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('clinic-first-aid-category')));
    await tester.pumpAndSettle();

    expect(find.text('First Aid Information'), findsOneWidget);
    expect(find.text('Choose pet type'), findsOneWidget);
    expect(
      find.text(
        'Read-only guidance available without a booking or internet connection.',
      ),
      findsOneWidget,
    );
    expect(find.text('Bleeding'), findsOneWidget);
    expect(find.text('Select Pet'), findsNothing);
    expect(find.text('Confirm Booking'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('first-aid-pet-Cat')));
    await tester.tap(find.byKey(const ValueKey('first-aid-topic-bleeding')));
    await tester.pumpAndSettle();

    expect(find.text('Cat guide'), findsOneWidget);
    expect(find.text('Possible signs'), findsOneWidget);
    expect(find.text('What to do'), findsOneWidget);
    expect(
      find.textContaining('does not replace veterinary treatment'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('save-first-aid-guide')));
    await tester.pump();
    expect(FirstAidSavedStore.instance.contains('bleeding'), isTrue);

    await tester.tap(find.byKey(const ValueKey('share-first-aid-guide')));
    await tester.pumpAndSettle();
    expect(find.text('Share First Aid Guide'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('copy-first-aid-guide')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('first-aid-guide-content')),
      const Offset(0, -1800),
    );
    await tester.pumpAndSettle();
    expect(find.text('Do not'), findsOneWidget);
    expect(find.text('Helpful materials'), findsOneWidget);
    expect(find.textContaining('Do not apply powders'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('first-aid-call-clinic')),
    );
    await tester.tap(find.byKey(const ValueKey('first-aid-call-clinic')));
    await tester.pumpAndSettle();
    expect(find.text('Call Clinic?'), findsOneWidget);
    expect(find.text('Confirm Call'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('first-aid-directions')));
    await tester.pumpAndSettle();
    expect(find.text('Clinic Directions'), findsOneWidget);
    expect(find.textContaining('Popba Thiri Township'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('first-aid-emergency-service')));
    await tester.pumpAndSettle();
    expect(find.text('Emergency Service'), findsOneWidget);
  });

  testWidgets(
    'Contact Clinic provides contact actions and saved chat history',
    (WidgetTester tester) async {
      ContactClinicStore.instance.clear();
      await signIn(tester);

      await tester.tap(find.byTooltip('Clinic'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1700));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).at(2), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('clinic-contact-category')));
      await tester.pumpAndSettle();

      expect(find.text('Contact Clinic'), findsOneWidget);
      expect(find.text("Nway's Love Vet Clinic"), findsOneWidget);
      expect(find.text('8:00 AM–10:00 PM'), findsOneWidget);
      expect(find.text(ContactClinicPage.email), findsOneWidget);
      expect(find.text('Call Clinic'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Email'), findsWidgets);
      expect(find.text('Directions'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('contact-call')));
      await tester.pumpAndSettle();
      expect(find.text('Call Clinic?'), findsOneWidget);
      await tester.tap(find.text('Confirm Call'));
      await tester.pumpAndSettle();
      expect(find.text('Clinic phone number'), findsOneWidget);
      expect(find.textContaining('call manually'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('contact-chat')));
      await tester.pumpAndSettle();
      expect(find.text('Chat with Clinic'), findsOneWidget);
      expect(
        find.textContaining('does not replace an examination'),
        findsOneWidget,
      );
      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.text('Payment'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('contact-send-message')));
      await tester.pump();
      expect(find.text('Enter a message before sending'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('contact-message-field')),
        'Bella needs an appointment tomorrow.',
      );
      await tester.tap(find.byKey(const ValueKey('contact-select-pet')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bella').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('contact-message-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appointment').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('contact-send-message')));
      await tester.pump();

      expect(find.text('Bella needs an appointment tomorrow.'), findsOneWidget);
      expect(find.text('Pet: Bella'), findsOneWidget);
      expect(find.text('Appointment • Sent'), findsOneWidget);

      final message = ContactClinicStore.instance.messages.single;
      ContactClinicStore.instance.staffUpdateStatus(
        message.id,
        ContactMessageStatus.read,
      );
      ContactClinicStore.instance.staffReply(
        'Please bring Bella at 10:00 AM. Staff will confirm the appointment.',
      );
      await tester.pump();
      expect(find.text('Appointment • Read'), findsOneWidget);
      expect(find.text('Clinic Staff'), findsOneWidget);
      expect(find.textContaining('Please bring Bella'), findsOneWidget);
      expect(find.text('Edit Reply'), findsNothing);
      expect(find.text('Delete Reply'), findsNothing);

      Navigator.of(tester.element(find.text('Chat with Clinic'))).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('contact-emergency-service')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('contact-emergency-service')));
      await tester.pumpAndSettle();
      expect(find.text('Emergency Notice'), findsOneWidget);
    },
  );

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
