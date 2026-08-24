import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senior_project/login/pet_owner_auth_api.dart';
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

    await tester.scrollUntilVisible(
      find.text('Appointments'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
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
    expect(find.text('Cancel Appointment?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-cancel-appointment')));
    await tester.pumpAndSettle();
    expect(appointment.status, 'Cancelled');
    expect(find.text('No upcoming appointments'), findsOneWidget);
    expect(find.text('Book Appointment'), findsOneWidget);
  });

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
