part of 'system_admin_portal.dart';

const _adminMint = Color(0xFFA1FDD8);
const _adminSoftMint = Color(0xFFCFFBE8);
const _adminGreen = Color(0xFF15835F);
const _adminMuted = Color(0xFF62716C);
const _adminBorder = Color(0xFFD7E5DF);

const _adminHeroStyle = TextStyle(
  color: Colors.black,
  fontSize: 25,
  fontWeight: FontWeight.w900,
  letterSpacing: -0.6,
);

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

void _adminNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

InputDecoration _adminInput(String label, IconData icon) => InputDecoration(
  labelText: label,
  prefixIcon: Icon(icon),
  filled: true,
  fillColor: _adminSoftMint,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide.none,
  ),
);

Future<void> _adminShowInfo(
  BuildContext context,
  String title,
  String message,
) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      FilledButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: const Text('Got it'),
      ),
    ],
  ),
);

String _shortDay(DateTime date) {
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _dashboardDate(DateTime date) {
  const months = [
    'january',
    'february',
    'march',
    'april',
    'may',
    'june',
    'july',
    'august',
    'september',
    'october',
    'november',
    'december',
  ];
  return '${date.day}.${months[date.month - 1]}.${date.year}';
}
