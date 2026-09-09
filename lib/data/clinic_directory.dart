import 'package:flutter/foundation.dart';
import 'database_sync.dart';

/// A public directory entry for a clinic doctor/staff member.
class ClinicPerson {
  const ClinicPerson({
    required this.name,
    required this.role,
    this.photoUrl,
    this.specialty,
  });

  final String name;
  final String role;

  /// Public photo (base64 data URI) when the doctor has uploaded one.
  final String? photoUrl;
  final String? specialty;
}

/// Public clinic staff identity, with no credentials or private profile fields.
class ClinicDirectory extends ChangeNotifier {
  ClinicDirectory._();
  static final instance = ClinicDirectory._();
  DatabaseRows _people = {};

  /// Doctor names only (kept for existing callers like the booking page).
  List<String> get doctors => doctorProfiles.map((d) => d.name).toList();

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
        ),
      )
      .toList();

  void connectDatabase() => DatabaseSync.instance.bind(
    'clinic_directory',
    this,
    () => _people,
    (rows) => _people = rows,
  );
}
