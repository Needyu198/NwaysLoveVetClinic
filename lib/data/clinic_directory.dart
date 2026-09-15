import 'package:flutter/foundation.dart';
import 'database_sync.dart';

/// A public directory entry for a clinic doctor/staff member.
class ClinicPerson {
  const ClinicPerson({
    required this.name,
    required this.role,
    this.photoUrl,
    this.specialty,
    this.available = true,
  });

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
  List<ClinicPerson> get doctorProfiles => _people.values
      .where((p) => p['role'] == 'doctor')
      .where((p) => (p['name'] as String?)?.trim().isNotEmpty ?? false)
      .map(
        (p) => ClinicPerson(
          name: p['name'] as String,
          role: p['role'] as String,
          photoUrl: p['photoUrl'] as String?,
          specialty: p['specialty'] as String?,
          available: p['available'] as bool? ?? true,
        ),
      )
      .toList();

  List<ClinicPerson> get availableDoctorProfiles => doctorProfiles
      .where((doctor) => doctor.available)
      .toList(growable: false);

  /// Public staff entries used by owner-facing non-medical service booking.
  List<ClinicPerson> get staffProfiles => _people.values
      .where((person) => person['role'] == 'staff')
      .where(
        (person) => (person['name'] as String?)?.trim().isNotEmpty ?? false,
      )
      .map(
        (person) => ClinicPerson(
          name: person['name'] as String,
          role: person['role'] as String,
          photoUrl: person['photoUrl'] as String?,
          specialty: person['specialty'] as String?,
          available: person['available'] as bool? ?? false,
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
