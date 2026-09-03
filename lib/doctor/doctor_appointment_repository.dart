part of 'doctor_portal.dart';

/// The doctor-side state for a single appointment that must survive restarts:
/// the status the doctor set plus any clinical notes captured during a
/// consultation. This is stored separately from the pet-owner booking so it can
/// be attached to both demo and real bookings by appointment id.
class DoctorAppointmentState {
  const DoctorAppointmentState({
    this.status,
    this.consultationNotes = '',
    this.diagnosis = '',
    this.treatment = '',
    this.prescription = '',
    this.vaccination = '',
    this.nextDoseDate = '',
    this.followUp = '',
    this.rescheduleNote = '',
  });

  /// The doctor-applied status. Null means "use the booking's own status".
  final String? status;
  final String consultationNotes;
  final String diagnosis;
  final String treatment;
  final String prescription;
  final String vaccination;
  final String nextDoseDate;
  final String followUp;
  final String rescheduleNote;

  Map<String, dynamic> toMap() => {
    'status': status,
    'consultationNotes': consultationNotes,
    'diagnosis': diagnosis,
    'treatment': treatment,
    'prescription': prescription,
    'vaccination': vaccination,
    'nextDoseDate': nextDoseDate,
    'followUp': followUp,
    'rescheduleNote': rescheduleNote,
    'updatedAt': DateTime.now().toIso8601String(),
  };

  static DoctorAppointmentState fromMap(Map<String, dynamic> map) =>
      DoctorAppointmentState(
        status: map['status'] as String?,
        consultationNotes: map['consultationNotes'] as String? ?? '',
        diagnosis: map['diagnosis'] as String? ?? '',
        treatment: map['treatment'] as String? ?? '',
        prescription: map['prescription'] as String? ?? '',
        vaccination: map['vaccination'] as String? ?? '',
        nextDoseDate: map['nextDoseDate'] as String? ?? '',
        followUp: map['followUp'] as String? ?? '',
        rescheduleNote: map['rescheduleNote'] as String? ?? '',
      );

  static DoctorAppointmentState fromRecord(DoctorAppointmentRecord record) =>
      DoctorAppointmentState(
        // Only persist a status override for demo records; bookings own their
        // own status via AppointmentStore.
        status: record.source == null ? record.status : null,
        consultationNotes: record.consultationNotes,
        diagnosis: record.diagnosis,
        treatment: record.treatment,
        prescription: record.prescription,
        vaccination: record.vaccination,
        nextDoseDate: record.nextDoseDate,
        followUp: record.followUp,
        rescheduleNote: record.rescheduleNote,
      );
}

/// Persists doctor-side appointment state to Firestore under
/// `doctor_appointment_state/{docId}` (a single document keyed by appointment
/// id), with a graceful in-memory fallback so the app keeps working offline,
/// unconfigured, or in tests.
class DoctorAppointmentRepository {
  DoctorAppointmentRepository._();

  static final instance = DoctorAppointmentRepository._();

  bool get _hasFirebase => Firebase.apps.isNotEmpty;

  String get _ownerId {
    final user = _hasFirebase ? FirebaseAuth.instance.currentUser : null;
    return user?.uid ?? 'demo-doctor';
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance
          .collection('doctor_appointment_state')
          .doc(_ownerId)
          .collection('appointments');

  /// Loads all persisted appointment states, keyed by appointment id. Returns
  /// an empty map when Firebase is unavailable.
  Future<Map<String, DoctorAppointmentState>> loadAll() async {
    if (!_hasFirebase) return const {};
    try {
      final snapshot = await _collection.get();
      return {
        for (final doc in snapshot.docs)
          doc.id: DoctorAppointmentState.fromMap(doc.data()),
      };
    } catch (_) {
      return const {};
    }
  }

  /// Persists a single appointment's doctor-side state. Returns true on
  /// success, false when Firebase is unavailable.
  Future<bool> save(String appointmentId, DoctorAppointmentState state) async {
    if (!_hasFirebase) return false;
    try {
      await _collection
          .doc(appointmentId)
          .set(state.toMap(), SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }
}
