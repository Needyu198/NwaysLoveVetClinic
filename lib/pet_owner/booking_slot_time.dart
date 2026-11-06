/// Whether a booking slot starts after the current local time.
bool isFutureBookingSlot(DateTime date, String time, {DateTime? now}) {
  final minutes = bookingTimeMinutes(time);
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  final start = DateTime(date.year, date.month, date.day, hour, minute);
  return start.isAfter(now ?? DateTime.now());
}

int bookingTimeMinutes(String time) {
  final parts = time.trim().split(RegExp(r'\s+'));
  final clock = parts[0].split(':');
  final hour =
      int.parse(clock[0]) % 12 +
      (parts.length > 1 && parts[1].toUpperCase() == 'PM' ? 12 : 0);
  return hour * 60 + int.parse(clock[1]);
}

String formatBookingTime(int minutes) {
  final normalized = minutes % (24 * 60);
  final hour = normalized ~/ 60;
  final minute = normalized % 60;
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} '
      '${hour < 12 ? 'AM' : 'PM'}';
}

bool bookingSlotFitsWindow({
  required String time,
  required int durationMinutes,
  required int startMinutes,
  required int endMinutes,
  int? breakStartMinutes,
  int? breakEndMinutes,
}) {
  final slotStart = bookingTimeMinutes(time);
  final slotEnd = slotStart + durationMinutes;
  if (slotStart < startMinutes || slotEnd > endMinutes) return false;
  if (breakStartMinutes != null && breakEndMinutes != null) {
    final overlapsBreak =
        slotStart < breakEndMinutes && slotEnd > breakStartMinutes;
    if (overlapsBreak) return false;
  }
  return true;
}

bool bookingSlotsOverlap({
  required String firstTime,
  required int firstDurationMinutes,
  required String secondTime,
  required int secondDurationMinutes,
}) {
  final firstStart = bookingTimeMinutes(firstTime);
  final secondStart = bookingTimeMinutes(secondTime);
  return firstStart < secondStart + secondDurationMinutes &&
      firstStart + firstDurationMinutes > secondStart;
}

class AppointmentSlotSuggestion {
  const AppointmentSlotSuggestion({
    required this.date,
    required this.time,
    required this.remainingCapacity,
    required this.reason,
  });

  final DateTime date;
  final String time;
  final int remainingCapacity;
  final String reason;
}
