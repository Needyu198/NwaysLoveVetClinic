import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/pet_owner/booking_slot_time.dart';

void main() {
  test('same-day slots must start in the future', () {
    final today = DateTime(2026, 9, 22);
    final now = DateTime(2026, 9, 22, 13, 30);

    expect(isFutureBookingSlot(today, '12:00 PM', now: now), isFalse);
    expect(isFutureBookingSlot(today, '1:00 PM', now: now), isFalse);
    expect(isFutureBookingSlot(today, '2:00 PM', now: now), isTrue);
    expect(
      isFutureBookingSlot(
        today.add(const Duration(days: 1)),
        '8:00 AM',
        now: now,
      ),
      isTrue,
    );
  });
}
