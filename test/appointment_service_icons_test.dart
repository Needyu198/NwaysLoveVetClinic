import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/pet_owner/appointment_booking_page.dart';

void main() {
  const services = [
    BookingService(
      name: 'General Checkup',
      description: 'Routine examination.',
      icon: Icons.health_and_safety_rounded,
      homeVisit: false,
      doctors: ['Doctor'],
    ),
    BookingService(
      name: 'Vaccination',
      description: 'Vaccines and boosters.',
      icon: Icons.vaccines_rounded,
      homeVisit: false,
      doctors: ['Doctor'],
    ),
    BookingService(
      name: 'Emergency',
      description: 'Urgent assessment.',
      icon: Icons.emergency_rounded,
      homeVisit: false,
      doctors: ['Doctor'],
    ),
    BookingService(
      name: 'Home Visit',
      description: 'Veterinarian home visit.',
      icon: Icons.home_work_rounded,
      homeVisit: true,
      doctors: ['Doctor'],
    ),
  ];

  testWidgets('Book Appointment service choices use fixed-size artwork', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AppointmentBookingPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Max').last);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    for (final service in services) {
      _expectFixedIcon(tester, service.name, 'selection');
    }
  });

  testWidgets('My Appointments cards use fixed-size service artwork', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    AppointmentStore.instance.clear();
    addTearDown(AppointmentStore.instance.clear);

    for (var index = 0; index < services.length; index++) {
      AppointmentStore.instance.add(
        BookedAppointment(
          id: 'ICON-$index',
          createdAt: DateTime.now(),
          pet: const BookingPet(
            name: 'Max',
            species: 'Dog',
            breed: 'Golden Retriever',
            age: '2 years',
            icon: Icons.pets,
            color: Colors.blue,
          ),
          service: services[index],
          veterinarian: 'Doctor',
          date: DateTime.now().add(const Duration(days: 1)),
          time: '10:00 AM',
          symptoms: '',
          reason: '',
          notes: '',
          address: '',
          status: 'Confirmed',
        ),
      );
    }

    await tester.pumpWidget(const MaterialApp(home: MyAppointmentsPage()));
    await tester.pumpAndSettle();

    for (final service in services) {
      _expectFixedIcon(tester, service.name, 'appointment-card');
    }
  });
}

void _expectFixedIcon(
  WidgetTester tester,
  String serviceName,
  String placement,
) {
  final finder = find.byKey(
    ValueKey('appointment-service-$serviceName-$placement-icon'),
  );
  expect(finder, findsOneWidget);
  expect(tester.widget<SizedBox>(finder).width, 34);
  expect(tester.widget<SizedBox>(finder).height, 34);
  expect(
    find.descendant(of: finder, matching: find.byType(Image)),
    findsOneWidget,
  );
}
