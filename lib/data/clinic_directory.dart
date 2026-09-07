import 'package:flutter/foundation.dart';
import 'database_sync.dart';

/// Public clinic staff identity, with no credentials or private profile fields.
class ClinicDirectory extends ChangeNotifier {
  ClinicDirectory._();
  static final instance = ClinicDirectory._();
  DatabaseRows _people = {};
  List<String> get doctors => _people.values
      .where((p) => p['role'] == 'doctor')
      .map((p) => p['name'] as String)
      .toList();
  void connectDatabase() => DatabaseSync.instance.bind(
    'clinic_directory',
    this,
    () => _people,
    (rows) => _people = rows,
  );
}
