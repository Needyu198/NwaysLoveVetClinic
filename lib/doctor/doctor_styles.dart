part of 'doctor_portal.dart';

class DoctorStyles {
  const DoctorStyles._();

  static const page = Color(0xFFF5F8F6);
  static const mint = Color(0xFFA1FDD8);
  static const softMint = Color(0xFFE8FAF2);
  static const green = Color(0xFF15835F);
  static const ink = Color(0xFF17201D);
  static const border = Color(0xFFD7E5DF);
  static const title = TextStyle(
    color: ink,
    fontSize: 25,
    fontWeight: FontWeight.w900,
  );
  static const section = TextStyle(
    color: ink,
    fontSize: 19,
    fontWeight: FontWeight.w900,
  );
  static const cardTitle = TextStyle(
    color: ink,
    fontSize: 17,
    fontWeight: FontWeight.w900,
  );
  static const cardValue = TextStyle(
    color: ink,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  static const body = TextStyle(color: ink, fontSize: 14, height: 1.35);
  static const muted = TextStyle(color: Color(0xFF61716B), fontSize: 13);
  static const small = TextStyle(
    color: Color(0xFF61716B),
    fontSize: 11,
    fontWeight: FontWeight.w800,
  );
  static const stat = TextStyle(
    color: ink,
    fontSize: 28,
    fontWeight: FontWeight.w900,
  );
}

String? _nextStatus(String status) => switch (status) {
  'Confirmed' => 'Checked In',
  'Checked In' => 'Called',
  'Called' => 'In Consultation',
  _ => null,
};

String _statusAction(String status) => switch (status) {
  'Confirmed' => 'Confirm Appointment',
  'Checked In' => 'Check In Patient',
  'Called' => 'Call Patient',
  'In Consultation' => 'Start Consultation',
  'Completed' => 'Complete Consultation',
  _ => 'Update Status',
};

IconData _statusIcon(String status) => switch (status) {
  'Confirmed' => Icons.event_available_rounded,
  'Checked In' => Icons.login_rounded,
  'Called' => Icons.campaign_outlined,
  'In Consultation' => Icons.medical_services_outlined,
  'Completed' => Icons.task_alt_rounded,
  _ => Icons.update_rounded,
};

String _fullDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
}

String _month(DateTime date) => const [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
][date.month - 1];

int _timeMinutes(String value) {
  final parts = value.split(RegExp(r'[: ]'));
  if (parts.length < 3) return 0;
  var hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  if (parts[2].toUpperCase() == 'PM' && hour != 12) hour += 12;
  if (parts[2].toUpperCase() == 'AM' && hour == 12) hour = 0;
  return hour * 60 + minute;
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

String _emergencyLabel(EmergencyStatus status) => switch (status) {
  EmergencyStatus.submitted => 'Submitted',
  EmergencyStatus.underReview => 'Under Review',
  EmergencyStatus.accepted => 'Accepted',
  EmergencyStatus.declined => 'Declined',
  EmergencyStatus.checkedIn => 'Checked In',
  EmergencyStatus.assessment => 'Assessment',
  EmergencyStatus.waiting => 'Waiting',
  EmergencyStatus.consultation => 'Consultation',
  EmergencyStatus.treatmentProposed => 'Treatment Proposed',
  EmergencyStatus.treatmentInProgress => 'Treatment In Progress',
  EmergencyStatus.completed => 'Completed',
};

EmergencyStatus? _nextEmergencyStatus(EmergencyStatus status) =>
    switch (status) {
      EmergencyStatus.accepted => EmergencyStatus.assessment,
      EmergencyStatus.checkedIn ||
      EmergencyStatus.waiting => EmergencyStatus.assessment,
      EmergencyStatus.assessment => EmergencyStatus.consultation,
      EmergencyStatus.consultation => EmergencyStatus.treatmentProposed,
      EmergencyStatus.treatmentProposed => EmergencyStatus.treatmentInProgress,
      EmergencyStatus.treatmentInProgress => EmergencyStatus.completed,
      _ => null,
    };

String _emergencyAction(EmergencyStatus status) => switch (status) {
  EmergencyStatus.assessment => 'Start Assessment',
  EmergencyStatus.consultation => 'Start Emergency Consultation',
  EmergencyStatus.treatmentProposed => 'Record Proposed Treatment',
  EmergencyStatus.treatmentInProgress => 'Start Emergency Treatment',
  EmergencyStatus.completed => 'Complete Emergency Case',
  _ => 'Update Emergency Case',
};

HomeVisitStatus? _nextHomeVisitStatus(HomeVisitStatus status) =>
    switch (status) {
      HomeVisitStatus.confirmed => HomeVisitStatus.onTheWay,
      HomeVisitStatus.onTheWay => HomeVisitStatus.arrived,
      HomeVisitStatus.arrived => HomeVisitStatus.consultation,
      HomeVisitStatus.consultation ||
      HomeVisitStatus.treatmentProposed => HomeVisitStatus.completed,
      HomeVisitStatus.completed => null,
    };

String _doctorHomeVisitLabel(HomeVisitStatus status) => switch (status) {
  HomeVisitStatus.confirmed => 'Confirmed',
  HomeVisitStatus.onTheWay => 'On the Way',
  HomeVisitStatus.arrived => 'Arrived',
  HomeVisitStatus.consultation ||
  HomeVisitStatus.treatmentProposed => 'In Progress',
  HomeVisitStatus.completed => 'Completed',
};

String _homeVisitAction(HomeVisitStatus status) => switch (status) {
  HomeVisitStatus.onTheWay => 'Start Travel',
  HomeVisitStatus.arrived => 'Mark Arrived',
  HomeVisitStatus.consultation => 'Start Home Consultation',
  HomeVisitStatus.completed => 'Complete Home Visit',
  _ => 'Update Visit',
};

String _orNotRecorded(String value) =>
    value.trim().isEmpty ? 'Not recorded' : value;
