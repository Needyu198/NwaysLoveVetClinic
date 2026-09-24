import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/pet_owner/appointment_booking_page.dart';
import 'package:senior_project/staff/staff_portal.dart';

void main() {
  BookedAppointment booking(DateTime date, String time) => BookedAppointment(
    id: 'CALL-1',
    createdAt: date,
    pet: const BookingPet(
      name: 'Milo',
      species: 'Cat',
      breed: 'Domestic',
      age: '2 years',
      icon: Icons.pets,
      color: Colors.orange,
    ),
    service: const BookingService(
      name: 'General Checkup',
      description: 'Checkup',
      icon: Icons.medical_services,
      homeVisit: false,
      doctors: ['Dr. Test'],
    ),
    veterinarian: 'Dr. Test',
    date: date,
    time: time,
    symptoms: '',
    reason: 'Review',
    notes: '',
    address: '',
    status: 'Confirmed',
    ownerName: 'Aye Aye',
    ownerPhone: '09 123 456 789',
  );

  test(
    'staff appointment exposes owner contact and becomes due 30 minutes before',
    () {
      final appointment = StaffAppointment.fromBooking(
        booking(DateTime(2026, 9, 24), '10:00 AM'),
      );

      expect(appointment.owner, 'Aye Aye');
      expect(appointment.phone, '09 123 456 789');
      expect(
        appointment.confirmationCallDue(now: DateTime(2026, 9, 24, 9, 29)),
        isFalse,
      );
      expect(
        appointment.confirmationCallDue(now: DateTime(2026, 9, 24, 9, 30)),
        isTrue,
      );
    },
  );

  test('resolved confirmation call removes the reminder and persists', () {
    final source = booking(DateTime(2026, 9, 24), '10:00 AM');
    source.confirmationCalls.add(
      AppointmentConfirmationCall(
        calledAt: DateTime(2026, 9, 24, 9, 35),
        outcome: AppointmentCallOutcome.confirmed,
        staffName: 'Mya',
        notes: 'On the way',
      ),
    );

    final restored = BookedAppointment.fromDb(source.toDb());
    final appointment = StaffAppointment.fromBooking(restored);

    expect(restored.ownerName, 'Aye Aye');
    expect(restored.confirmationCalls.single.notes, 'On the way');
    expect(
      appointment.confirmationCallDue(now: DateTime(2026, 9, 24, 9, 40)),
      isFalse,
    );
  });

  test('unanswered call waits until its retry time', () {
    final appointment = StaffAppointment.fromBooking(
      booking(DateTime(2026, 9, 24), '10:00 AM'),
    );
    appointment.confirmationCalls.add(
      AppointmentConfirmationCall(
        calledAt: DateTime(2026, 9, 24, 9, 31),
        outcome: AppointmentCallOutcome.noAnswer,
        staffName: 'Mya',
        retryAt: DateTime(2026, 9, 24, 9, 46),
      ),
    );

    expect(
      appointment.confirmationCallDue(now: DateTime(2026, 9, 24, 9, 40)),
      isFalse,
    );
    expect(
      appointment.confirmationCallDue(now: DateTime(2026, 9, 24, 9, 46)),
      isTrue,
    );
  });
}
