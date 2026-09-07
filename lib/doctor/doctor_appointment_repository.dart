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

/// Doctor-side state is persisted through the shared PostgreSQL sync service.
class DoctorAppointmentRepository {
  DoctorAppointmentRepository._();
  static final instance = DoctorAppointmentRepository._();
  Future<Map<String, DoctorAppointmentState>> loadAll() async =>
      Map.of(DoctorAppointmentStore.instance._persisted);
  Future<bool> save(String appointmentId, DoctorAppointmentState state) async {
    DoctorAppointmentStore.instance._persisted[appointmentId] = state;
    await DatabaseSync.instance.flush();
    return DatabaseSync.instance.error == null;
  }
}
