import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/pet_owner/appointment_booking_page.dart';
import 'package:senior_project/pet_owner/pet_care_booking_page.dart';
import 'package:senior_project/staff/staff_portal.dart';

void main() {
  tearDown(() {
    PetCareBookingStore.instance.clear();
    AppointmentStore.instance.clear();
  });

  test('pet-care booking persists the selected staff account identity', () {
    final booking = PetCareBooking(
      id: 'CARE-PROVIDER',
      service: PetCareCatalog.services.first,
      pet: PetCareCatalog.pets.first,
      provider: 'Mya Thu',
      providerId: 'staff-mya',
      linkedAppointmentId: 'CARE-PROVIDER',
      date: DateTime(2026, 10, 1),
      time: '10:00 AM',
      location: "Nway's Love Vet Clinic",
    );

    final restored = PetCareBooking.fromDb(booking.toDb());

    expect(restored.provider, 'Mya Thu');
    expect(restored.providerId, 'staff-mya');
    expect(restored.linkedAppointmentId, 'CARE-PROVIDER');
  });

  test('slot conflicts use provider ID even when staff names match', () {
    final date = DateTime(2026, 10, 1);
    PetCareBookingStore.instance.add(
      PetCareBooking(
        id: 'CARE-BOOKED',
        service: PetCareCatalog.services.first,
        pet: PetCareCatalog.pets.first,
        provider: 'Clinic Staff',
        providerId: 'staff-one',
        date: date,
        time: '10:00 AM',
        location: "Nway's Love Vet Clinic",
      ),
    );

    expect(
      PetCareBookingStore.instance.isSlotAvailable(
        provider: 'Clinic Staff',
        providerId: 'staff-one',
        date: date,
        time: '10:00 AM',
      ),
      isFalse,
    );
    expect(
      PetCareBookingStore.instance.isSlotAvailable(
        provider: 'Clinic Staff',
        providerId: 'staff-two',
        date: date,
        time: '10:00 AM',
      ),
      isTrue,
    );
  });

  test('pet-care booking participates in the main appointment workflow', () {
    final booking = PetCareBooking(
      id: 'CARE-LINKED',
      service: PetCareCatalog.services.first,
      option: 'Shaving',
      pet: PetCareCatalog.pets.first,
      provider: 'Mya Thu',
      providerId: 'staff-mya',
      date: DateTime(2026, 10, 2),
      time: '11:00 AM',
      location: "Nway's Love Vet Clinic",
      linkedAppointmentId: 'CARE-LINKED',
    );
    final appointment = booking.toMainAppointment(
      ownerName: 'Mya Mya',
      ownerPhone: '09-123456789',
      species: 'Dog',
    );

    AppointmentStore.instance.add(appointment);
    PetCareBookingStore.instance.add(booking);

    final staffItem = StaffOperationsStore.instance.appointments.firstWhere(
      (item) => item.id == booking.id,
    );
    expect(staffItem.service, 'Grooming');
    expect(staffItem.owner, 'Mya Mya');
    expect(staffItem.phone, '09-123456789');
    expect(staffItem.doctor, 'Mya Thu');
    expect(staffItem.queueServiceGroup, QueueServiceGroup.petCareService);

    appointment.status = 'Checked In';
    AppointmentStore.instance.databaseChanged();
    expect(booking.displayStatus, PetCareStatus.checkedIn);

    appointment.status = 'In Consultation';
    appointment
      ..date = DateTime(2026, 10, 3)
      ..time = '1:00 PM';
    AppointmentStore.instance.databaseChanged();
    expect(booking.displayStatus, PetCareStatus.inProgress);
    expect(booking.date, DateTime(2026, 10, 3));
    expect(booking.time, '1:00 PM');

    appointment.status = 'Completed';
    AppointmentStore.instance.databaseChanged();
    expect(booking.displayStatus, PetCareStatus.completed);
    expect(booking.isActive, isFalse);
  });
}
