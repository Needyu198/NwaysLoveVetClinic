import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/data/clinic_directory.dart';
import 'package:senior_project/pet_owner/appointment_booking_page.dart';

void main() {
  const pet = BookingPet(
    id: 'pet-smart',
    name: 'Max',
    species: 'Dog',
    breed: 'Retriever',
    age: '2 years',
    icon: Icons.pets,
    color: Colors.blue,
  );
  const service = BookingService(
    name: 'Checkup',
    description: 'Routine checkup',
    icon: Icons.medical_services,
    homeVisit: false,
    doctors: ['Dr. Smart'],
    durationMinutes: 60,
  );

  tearDown(AppointmentStore.instance.clear);

  test(
    'suggestions respect schedule, breaks, leave, conflicts and workload',
    () {
      final monday = DateTime(2030, 1, 7);
      final tuesday = monday.add(const Duration(days: 1));
      final doctor = ClinicPerson(
        id: 'doctor-smart',
        name: 'Dr. Smart',
        role: 'doctor',
        schedule: const {
          DateTime.monday: ClinicDayAvailability(
            isWorking: true,
            startMinutes: 9 * 60,
            endMinutes: 17 * 60,
            breakStartMinutes: 12 * 60,
            breakEndMinutes: 13 * 60,
          ),
          DateTime.tuesday: ClinicDayAvailability(
            isWorking: true,
            startMinutes: 9 * 60,
            endMinutes: 17 * 60,
          ),
        },
        leaveDates: [tuesday],
      );
      AppointmentStore.instance.add(
        BookedAppointment(
          id: 'existing-doctor-slot',
          createdAt: DateTime(2029),
          pet: const BookingPet(
            id: 'other-pet',
            name: 'Bella',
            species: 'Dog',
            breed: 'Mixed',
            age: '1 year',
            icon: Icons.pets,
            color: Colors.red,
          ),
          service: service,
          veterinarian: 'Dr. Smart',
          veterinarianId: 'doctor-smart',
          date: monday,
          time: '9:00 AM',
          symptoms: '',
          reason: '',
          notes: '',
          address: '',
          status: 'Confirmed',
        ),
      );
      AppointmentStore.instance.add(
        BookedAppointment(
          id: 'clinic-load',
          createdAt: DateTime(2029),
          pet: const BookingPet(
            id: 'third-pet',
            name: 'Luna',
            species: 'Cat',
            breed: 'Mixed',
            age: '3 years',
            icon: Icons.pets,
            color: Colors.purple,
          ),
          service: service,
          veterinarian: 'Dr. Other',
          date: monday,
          time: '10:00 AM',
          symptoms: '',
          reason: '',
          notes: '',
          address: '',
          status: 'Confirmed',
        ),
      );

      final suggestions = AppointmentStore.instance.suggestSlots(
        dates: [monday, tuesday],
        times: const ['9:00 AM', '10:00 AM', '12:00 PM', '1:00 PM'],
        pet: pet,
        veterinarian: 'Dr. Smart',
        durationMinutes: 60,
        doctor: doctor,
        now: DateTime(2030, 1, 6),
      );

      expect(suggestions.map((slot) => slot.time), ['1:00 PM', '10:00 AM']);
      expect(suggestions.every((slot) => slot.date == monday), isTrue);
      expect(suggestions.first.reason, contains('least busy'));
    },
  );

  test('duration prevents a slot from crossing a break or shift end', () {
    expect(
      AppointmentStore.instance.isDoctorAvailableForSlot(
        date: DateTime(2030, 1, 7),
        time: '11:30 AM',
        durationMinutes: 60,
        veterinarian: 'Dr. Smart',
        doctor: const ClinicPerson(
          name: 'Dr. Smart',
          role: 'doctor',
          schedule: {
            DateTime.monday: ClinicDayAvailability(
              isWorking: true,
              startMinutes: 9 * 60,
              endMinutes: 12 * 60,
            ),
          },
        ),
      ),
      isFalse,
    );
  });
}
