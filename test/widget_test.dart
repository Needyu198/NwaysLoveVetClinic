import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senior_project/login/pet_owner_auth_api.dart';
import 'package:senior_project/main.dart';
import 'package:senior_project/pet_owner/appointment_booking_page.dart';
import 'package:senior_project/pet_owner/home_visit_booking_page.dart';
import 'package:senior_project/pet_owner/pet_care_booking_page.dart';

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
  });

  testWidgets('books and completes a pet care service from Clinic categories', (
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
    await tester.tap(find.byKey(const ValueKey('care-time-9:00 AM')));
    await tester.pump();
    await tester.tap(find.text('Hold This Slot'));
    await tester.pump();

    expect(find.text('Special Instructions'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Allergies'),
      'No known allergies',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review Booking'));
    await tester.pumpAndSettle();
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

    await tester.tap(find.text('Check In Pet'));
    await tester.pumpAndSettle();
    expect(find.text('Checked In'), findsOneWidget);
    await tester.tap(find.text('Start Service'));
    await tester.pumpAndSettle();
    expect(find.text('In Progress'), findsOneWidget);
    await tester.tap(find.text('Mark Service Complete'));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsOneWidget);

    await tester.tap(find.text('View Report & Review'));
    await tester.pumpAndSettle();
    expect(find.text('Service Report'), findsOneWidget);
    expect(find.text('Provider notes'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('care-rating-5')));
    await tester.enterText(
      find.widgetWithText(TextField, 'Write a review'),
      'Excellent care.',
    );
    await tester.tap(find.text('Submit Review'));
    await tester.pump();
    expect(find.text('Thank you. Your review was saved.'), findsOneWidget);
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
