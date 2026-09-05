part of 'system_admin_portal.dart';

const _adminMint = Color(0xFFA1FDD8);
const _adminSoftMint = Color(0xFFCFFBE8);
const _adminGreen = Color(0xFF15835F);
const _adminEmergencyRed = Color(0xFFEF2734);
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
