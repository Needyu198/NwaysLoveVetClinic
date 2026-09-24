import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/pet_owner/appointment_booking_page.dart';

void main() {
  test('queue services are divided into the three clinic groups', () {
    expect(
      queueServiceGroupForName('General Checkup'),
      QueueServiceGroup.medicalService,
    );
    expect(
      queueServiceGroupForName('Vaccination'),
      QueueServiceGroup.medicalService,
    );
    expect(
      queueServiceGroupForName('Pet Care - Grooming'),
      QueueServiceGroup.petCareService,
    );
    expect(
      queueServiceGroupForName('Boarding'),
      QueueServiceGroup.petCareService,
    );
    expect(
      queueServiceGroupForName('General Checkup', walkIn: true),
      QueueServiceGroup.walkInService,
    );
  });

  test(
    'daily queue accepts only today and calculates position per group',
    () async {
      QueueStore.instance.clear();
      addTearDown(QueueStore.instance.clear);

      BookedAppointment appointment(String id, String service, DateTime date) =>
          BookedAppointment(
            id: id,
            createdAt: DateTime.now(),
            pet: const BookingPet(
              name: 'Milo',
              species: 'Cat',
              breed: 'Domestic',
              age: '2 years',
              icon: Icons.pets,
              color: Colors.blue,
            ),
            service: BookingService(
              name: service,
              description: service,
              icon: Icons.medical_services,
              homeVisit: false,
              doctors: const ['Dr. Test'],
            ),
            veterinarian: 'Dr. Test',
            date: date,
            time: '10:00 AM',
            symptoms: '',
            reason: '',
            notes: '',
            address: '',
            status: 'Confirmed',
          );

      final today = DateTime.now();
      final medical = await QueueStore.instance.checkIn(
        appointment('medical-today', 'General Checkup', today),
      );
      final petCare = await QueueStore.instance.checkIn(
        appointment('care-today', 'Grooming', today),
      );
      final yesterday = await QueueStore.instance.checkIn(
        appointment(
          'medical-yesterday',
          'General Checkup',
          today.subtract(const Duration(days: 1)),
        ),
      );

      expect(yesterday, isNull);
      expect(medical?.position, 1);
      expect(petCare?.position, 1);
      expect(medical?.serviceGroup, QueueServiceGroup.medicalService);
      expect(petCare?.serviceGroup, QueueServiceGroup.petCareService);
      expect(QueueStore.instance.active, hasLength(2));
    },
  );
}
