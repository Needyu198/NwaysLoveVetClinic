import 'package:flutter/foundation.dart';
import 'database_sync.dart';

/// A public directory entry for a clinic doctor/staff member.
class ClinicPerson {
  const ClinicPerson({
    this.id = '',
    required this.name,
    required this.role,
    this.photoUrl,
    this.specialty,
    this.available = true,
    this.schedule = const {},
    this.leaveDates = const [],
  });

  /// Stable account identifier used when a booking selects this provider.
  final String id;
  final String name;
  final String role;

  /// Public photo (base64 data URI) when the doctor has uploaded one.
  final String? photoUrl;
  final String? specialty;
  final bool available;
  final Map<int, ClinicDayAvailability> schedule;
  final List<DateTime> leaveDates;

  bool get hasPublishedSchedule => schedule.isNotEmpty;

  bool isOnLeave(DateTime date) => leaveDates.any(
    (leave) =>
        leave.year == date.year &&
        leave.month == date.month &&
        leave.day == date.day,
  );
}

class ClinicDayAvailability {
  const ClinicDayAvailability({
    required this.isWorking,
    required this.startMinutes,
    required this.endMinutes,
    this.breakStartMinutes,
    this.breakEndMinutes,
  });

  factory ClinicDayAvailability.fromMap(Map<String, dynamic> value) =>
      ClinicDayAvailability(
        isWorking: value['isWorking'] as bool? ?? false,
        startMinutes: (value['startMinutes'] as num?)?.toInt() ?? 9 * 60,
        endMinutes: (value['endMinutes'] as num?)?.toInt() ?? 16 * 60,
        breakStartMinutes: (value['breakStartMinutes'] as num?)?.toInt(),
        breakEndMinutes: (value['breakEndMinutes'] as num?)?.toInt(),
      );

  final bool isWorking;
  final int startMinutes;
  final int endMinutes;
  final int? breakStartMinutes;
  final int? breakEndMinutes;
}

Map<int, ClinicDayAvailability> _parseSchedule(Object? raw) {
  if (raw is! Map) return const {};
  const weekdays = {
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
    'sunday': DateTime.sunday,
  };
  final result = <int, ClinicDayAvailability>{};
  for (final entry in weekdays.entries) {
    final value = raw[entry.key];
    if (value is Map) {
      result[entry.value] = ClinicDayAvailability.fromMap(
        value.cast<String, dynamic>(),
      );
    }
  }
  return result;
}

List<DateTime> _parseLeaveDates(Object? raw) => raw is List
    ? raw
          .map((value) => DateTime.tryParse('$value'))
          .whereType<DateTime>()
          .toList()
    : const [];

/// Public clinic staff identity, with no credentials or private profile fields.
class ClinicDirectory extends ChangeNotifier {
  ClinicDirectory._();
  static final instance = ClinicDirectory._();
  DatabaseRows _people = {};

  /// Doctor names only (kept for existing callers like the booking page).
  List<String> get doctors => doctorProfiles.map((d) => d.name).toList();

  /// Doctors who currently accept appointments and walk-ins.
  List<String> get availableDoctors => availableDoctorProfiles
      .map((doctor) => doctor.name)
      .toList(growable: false);

  /// Full doctor entries (name + photo + specialty) for the clinic page.
  List<ClinicPerson> get doctorProfiles => _people.entries
      .where((entry) => entry.value['role'] == 'doctor')
      .where(
        (entry) => (entry.value['name'] as String?)?.trim().isNotEmpty ?? false,
      )
      .map(
        (entry) => ClinicPerson(
          id: entry.value['id'] as String? ?? entry.key,
          name: entry.value['name'] as String,
          role: entry.value['role'] as String,
          photoUrl: entry.value['photoUrl'] as String?,
          specialty: entry.value['specialty'] as String?,
          available: entry.value['available'] as bool? ?? true,
          schedule: _parseSchedule(entry.value['schedule']),
          leaveDates: _parseLeaveDates(entry.value['leaveDates']),
        ),
      )
      .toList();

  List<ClinicPerson> get availableDoctorProfiles => doctorProfiles
      .where((doctor) => doctor.available)
      .toList(growable: false);

  /// Public staff entries used by owner-facing non-medical service booking.
  List<ClinicPerson> get staffProfiles => _people.entries
      .where((entry) => entry.value['role'] == 'staff')
      .where(
        (entry) => (entry.value['name'] as String?)?.trim().isNotEmpty ?? false,
      )
      .map(
        (entry) => ClinicPerson(
          id: entry.value['id'] as String? ?? entry.key,
          name: entry.value['name'] as String,
          role: entry.value['role'] as String,
          photoUrl: entry.value['photoUrl'] as String?,
          specialty: entry.value['specialty'] as String?,
          available: entry.value['available'] as bool? ?? false,
        ),
      )
      .toList(growable: false);

  List<ClinicPerson> get availableStaffProfiles =>
      staffProfiles.where((staff) => staff.available).toList(growable: false);

  void connectDatabase() => DatabaseSync.instance.bind(
    'clinic_directory',
    this,
    () => _people,
    (rows) => _people = rows,
  );

  @visibleForTesting
  void replaceForTesting(DatabaseRows people) {
    _people = people;
    notifyListeners();
  }
}
