import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/pet_owner/appointment_booking_page.dart';
import 'package:senior_project/staff/staff_portal.dart';

void main() {
  testWidgets(
    'staff appointments show every database-backed pet-care service',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      AppointmentStore.instance.clear();
      addTearDown(AppointmentStore.instance.clear);

      AppointmentStore.instance.add(
        BookedAppointment(
          id: 'STAFF-HOME-VISIT',
          createdAt: DateTime.now(),
          pet: const BookingPet(
            name: 'Home Pet',
            species: 'Dog',
            breed: 'Mixed',
            age: '4 years',
            icon: Icons.pets_rounded,
            color: Colors.green,
          ),
          service: const BookingService(
            name: 'Home Visit',
            description: 'Veterinarian home visit.',
            icon: Icons.home_work_rounded,
            homeVisit: true,
            doctors: ['Dr. Home'],
          ),
          veterinarian: 'Dr. Home',
          date: DateTime.now().add(const Duration(days: 1)),
          time: '1:00 PM',
          symptoms: '',
          reason: 'Home consultation',
          notes: '',
          address: 'Test Address',
          status: 'Confirmed',
          ownerName: 'Test Owner',
          ownerPhone: '0912345678',
        ),
      );

      const serviceNames = ['Grooming', 'Bathing', 'Nail Trimming', 'Boarding'];
      for (var index = 0; index < serviceNames.length; index++) {
        final serviceName = serviceNames[index];
        AppointmentStore.instance.add(
          BookedAppointment(
            id: 'STAFF-CARE-$index',
            createdAt: DateTime.now(),
            pet: BookingPet(
              name: 'Pet $index',
              species: 'Dog',
              breed: 'Mixed',
              age: '2 years',
              icon: Icons.pets_rounded,
              color: Colors.blue,
            ),
            service: BookingService(
              name: serviceName,
              description: 'Pet care service.',
              icon: Icons.pets_rounded,
              homeVisit: false,
              doctors: const ['Care Team'],
            ),
            veterinarian: 'Care Team',
            date: DateTime.now().add(const Duration(days: 1)),
            time: '10:00 AM',
            symptoms: 'Pet care service',
            reason: serviceName,
            notes: '',
            address: "Nway's Love Vet Clinic",
            status: 'Confirmed',
            ownerName: 'Test Owner',
            ownerPhone: '0912345678',
          ),
        );
      }

      await tester.pumpWidget(
        const MaterialApp(home: StaffAppointmentsPage(standalone: true)),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('staff-appointment-topic-medical')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('staff-appointment-topic-homeVisit')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('staff-appointment-topic-petCare')),
        findsOneWidget,
      );

      await tester.tap(find.text('Pet Care'));
      await tester.pumpAndSettle();

      expect(find.text('4 appointments'), findsOneWidget);
      for (final serviceName in serviceNames) {
        expect(find.textContaining(serviceName), findsOneWidget);
      }
      expect(find.textContaining('General Checkup'), findsNothing);
    },
  );
}
