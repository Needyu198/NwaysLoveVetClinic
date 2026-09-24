import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/pet_owner/appointment_booking_page.dart';
import 'package:senior_project/pet_owner/home_visit_booking_page.dart';
import 'package:senior_project/pet_owner/pet_care_booking_page.dart';

void main() {
  final date = DateTime(2030, 1, 2);

  tearDown(() {
    AppointmentStore.instance.clear();
    HomeVisitStore.instance.clear();
    PetCareBookingStore.instance.clear();
  });

  test('clinic appointment blocks the same active pet/date/time', () {
    const pet = BookingPet(
      id: 'max:2024-01-01',
      name: 'Max',
      species: 'Dog',
      breed: 'Retriever',
      age: '2 years',
      icon: Icons.pets,
      color: Colors.blue,
    );
    AppointmentStore.instance.add(
      BookedAppointment(
        id: 'appointment-1',
        createdAt: DateTime(2029),
        pet: pet,
        service: const BookingService(
          name: 'Checkup',
          description: 'Routine checkup',
          icon: Icons.medical_services,
          homeVisit: false,
          doctors: ['Dr. One'],
        ),
        veterinarian: 'Dr. One',
        date: date,
        time: '10:00 AM',
        symptoms: 'None',
        reason: 'Checkup',
        notes: '',
        address: '',
        status: 'Confirmed',
      ),
    );

    expect(
      AppointmentStore.instance.hasDuplicateBooking(
        pet: pet,
        date: date,
        time: '10:00 AM',
      ),
      isTrue,
    );
    expect(
      AppointmentStore.instance.hasDuplicateBooking(
        pet: const BookingPet(
          name: 'Max',
          species: 'Dog',
          breed: 'Retriever',
          age: '2 years',
          icon: Icons.pets,
          color: Colors.blue,
        ),
        date: date,
        time: '10:00 AM',
      ),
      isTrue,
    );
    expect(
      AppointmentStore.instance.hasDuplicateBooking(
        pet: pet,
        date: date,
        time: '10:30 AM',
      ),
      isFalse,
    );
    AppointmentStore.instance.appointments.single.status = 'Cancelled';
    expect(
      AppointmentStore.instance.hasDuplicateBooking(
        pet: pet,
        date: date,
        time: '10:00 AM',
      ),
      isFalse,
    );
  });

  test('home visit blocks the same pet even with another doctor', () {
    const pet = HomeVisitPet(
      name: 'Max',
      breed: 'Retriever',
      age: '2 years',
      medicalHistory: '',
      color: Colors.blue,
      petKey: 'max:2024-01-01',
    );
    final visit = HomeVisit(
      id: 'home-1',
      pet: pet,
      veterinarian: 'Dr. One',
      date: date,
      time: '11:00 AM',
      reason: 'Unwell',
      symptoms: 'Tired',
      address: 'Home',
      contactPerson: 'Owner',
      phone: '091234567',
    );
    HomeVisitStore.instance.add(visit);

    expect(
      HomeVisitStore.instance.hasDuplicateBooking(
        pet: pet,
        date: date,
        time: '11:00 AM',
      ),
      isTrue,
    );
    visit.status = HomeVisitStatus.completed;
    expect(
      HomeVisitStore.instance.hasDuplicateBooking(
        pet: pet,
        date: date,
        time: '11:00 AM',
      ),
      isFalse,
    );
  });

  test('pet care blocks the same pet even with another provider', () {
    const pet = CarePet(
      name: 'Max',
      breed: 'Retriever',
      age: '2 years',
      health: 'Healthy',
      color: Colors.blue,
      petKey: 'max:2024-01-01',
    );
    final booking = PetCareBooking(
      id: 'care-1',
      service: PetCareCatalog.services.first,
      pet: pet,
      provider: 'Provider One',
      providerId: 'provider-1',
      date: date,
      time: '01:00 PM',
      location: "Nway's Love Vet Clinic",
    );
    PetCareBookingStore.instance.add(booking);

    expect(
      PetCareBookingStore.instance.hasDuplicateBooking(
        pet: pet,
        date: date,
        time: '01:00 PM',
      ),
      isTrue,
    );
    booking.status = PetCareStatus.completed;
    expect(
      PetCareBookingStore.instance.hasDuplicateBooking(
        pet: pet,
        date: date,
        time: '01:00 PM',
      ),
      isFalse,
    );
  });
}
