import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/pet_owner/pet_care_booking_page.dart';

void main() {
  tearDown(PetCareBookingStore.instance.clear);

  test('pet-care booking persists the selected staff account identity', () {
    final booking = PetCareBooking(
      id: 'CARE-PROVIDER',
      service: PetCareCatalog.services.first,
      pet: PetCareCatalog.pets.first,
      provider: 'Mya Thu',
      providerId: 'staff-mya',
      date: DateTime(2026, 10, 1),
      time: '10:00 AM',
      location: "Nway's Love Vet Clinic",
    );

    final restored = PetCareBooking.fromDb(booking.toDb());

    expect(restored.provider, 'Mya Thu');
    expect(restored.providerId, 'staff-mya');
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
}
