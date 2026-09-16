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
  });

  /// Stable account identifier used when a booking selects this provider.
  final String id;
  final String name;
  final String role;

  /// Public photo (base64 data URI) when the doctor has uploaded one.
  final String? photoUrl;
  final String? specialty;
  final bool available;
}

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
