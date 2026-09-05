part of 'staff_portal.dart';

const _mint = Color(0xFFA1FDD8);
const _green = Color(0xFF147D5B);
const _ink = Color(0xFF17201D);
const _page = Color(0xFFF5F8F6);
const _border = Color(0xFFD9E6E1);
const _muted = Color(0xFF66756F);
const _red = Color(0xFFD9343B);

const _titleStyle = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.w900,
  color: _ink,
);
const _sectionStyle = TextStyle(
  fontSize: 19,
  fontWeight: FontWeight.w900,
  color: _ink,
);
const _doctors = ['Dr. Aye Chan', 'Dr. Cindy Lynn', 'Dr. Myat Noe'];

BoxDecoration _cardDecoration({Color border = _border}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(17),
  border: Border.all(color: border),
);
InputDecoration _input(String label, IconData icon) => InputDecoration(
  labelText: label,
  prefixIcon: Icon(icon),
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(color: _border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(color: _border),
  ),
);
AppBar _appBar(String title, {Color color = _mint}) => AppBar(
  title: Text(title),
  backgroundColor: color,
  surfaceTintColor: Colors.transparent,
);
void _push(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
void _notice(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
void _showInfo(BuildContext context, String title, String text) =>
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );

String _greeting() {
  final hour = DateTime.now().hour;
  return hour < 12
      ? 'Good Morning'
      : hour < 17
      ? 'Good Afternoon'
      : 'Good Evening';
}

String _fullDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
String _emergencyLabel(EmergencyStatus value) => switch (value) {
  EmergencyStatus.submitted => 'Submitted',
  EmergencyStatus.underReview => 'Reviewing',
  EmergencyStatus.accepted => 'Accepted',
  EmergencyStatus.declined => 'Referred',
  EmergencyStatus.checkedIn => 'Arrived',
  EmergencyStatus.assessment => 'Assessing',
  EmergencyStatus.waiting => 'Waiting',
  EmergencyStatus.consultation => 'Consultation',
  EmergencyStatus.treatmentProposed => 'Treatment proposed',
  EmergencyStatus.treatmentInProgress => 'In treatment',
  EmergencyStatus.completed => 'Completed',
};
String _homeLabel(HomeVisitStatus value) => switch (value) {
  HomeVisitStatus.confirmed => 'Confirmed',
  HomeVisitStatus.onTheWay => 'On the way',
  HomeVisitStatus.arrived => 'Arrived',
  HomeVisitStatus.consultation => 'In consultation',
  HomeVisitStatus.treatmentProposed => 'Treatment proposed',
  HomeVisitStatus.completed => 'Completed',
};
