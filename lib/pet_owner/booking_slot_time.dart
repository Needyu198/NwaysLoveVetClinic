/// Whether a booking slot starts after the current local time.
bool isFutureBookingSlot(DateTime date, String time, {DateTime? now}) {
  final parts = time.split(' ');
  final clock = parts[0].split(':');
  final hour = int.parse(clock[0]) % 12 + (parts[1] == 'PM' ? 12 : 0);
  final minute = int.parse(clock[1]);
  final start = DateTime(date.year, date.month, date.day, hour, minute);
  return start.isAfter(now ?? DateTime.now());
}
