import 'package:flutter/material.dart';

import '../login/login_page.dart';
import '../pet_owner/appointment_booking_page.dart';
import '../pet_owner/emergency_service_page.dart';

part 'system_admin_navigation_bar.dart';

const _adminMint = Color(0xFFA1FDD8);
const _adminSoftMint = Color(0xFFCFFBE8);
const _adminGreen = Color(0xFF15835F);
const _adminEmergencyRed = Color(0xFFEF2734);
const _adminMuted = Color(0xFF62716C);
const _adminBorder = Color(0xFFD7E5DF);

class SystemAdminDashboardPage extends StatefulWidget {
  const SystemAdminDashboardPage({super.key});

  static const routeName = '/system-admin';

  @override
  State<SystemAdminDashboardPage> createState() =>
      _SystemAdminDashboardPageState();
}

class _SystemAdminDashboardPageState extends State<SystemAdminDashboardPage> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _index,
        children: [
          const _AdminDashboardTab(),
          const _AdminBookingsTab(),
          _AdminAccountTab(onLogout: () => _logout(context)),
        ],
      ),
      bottomNavigationBar: SystemAdminNavigationBar(
        selectedIndex: _index,
        onSelected: (index) => setState(() => _index = index),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('End the system administrator session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-system-admin-logout'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(LoginPage.routeName, (_) => false);
    }
  }
}

// ---------------------------------------------------------------------------
// Dashboard tab
// ---------------------------------------------------------------------------

class _AdminDashboardTab extends StatelessWidget {
  const _AdminDashboardTab();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppointmentStore.instance,
        EmergencyRequestStore.instance,
      ]),
      builder: (context, _) {
        final appointments = AppointmentStore.instance.appointments;
        final today = appointments
            .where(
              (appointment) =>
                  DateUtils.isSameDay(appointment.date, DateTime.now()) &&
                  appointment.status != 'Cancelled',
            )
            .toList();
        final waiting = today
            .where(
              (appointment) => !const {
                'Completed',
                'Cancelled',
              }.contains(appointment.status),
            )
            .length;
        final emergencies = EmergencyRequestStore.instance.requests
            .where(
              (request) => !const {
                EmergencyStatus.completed,
                EmergencyStatus.declined,
              }.contains(request.status),
            )
            .length;
        final pendingPayments = appointments
            .where((appointment) => appointment.status == 'Completed')
            .length;

        return ListView(
          key: const ValueKey('system-admin-dashboard'),
          padding: EdgeInsets.zero,
          children: [
            SafeArea(
              bottom: false,
              child: _AdminDashboardSummary(
                totalCount: today.length,
                waitingCount: waiting,
                emergencyCount: emergencies,
                pendingPaymentCount: pendingPayments,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions', style: _adminHeroStyle),
                  const SizedBox(height: 16),
                  const _AdminQuickActions(),
                  const SizedBox(height: 26),
                  const Text("Today's Appointments", style: _adminHeroStyle),
                  const SizedBox(height: 14),
                  if (today.isEmpty)
                    const _AdminEmptyState(
                      icon: Icons.event_available_rounded,
                      title: 'No appointments today',
                      message: 'New bookings will show up here.',
                    )
                  else
                    for (final appointment in today.take(6)) ...[
                      _AdminAppointmentCard(appointment: appointment),
                      const SizedBox(height: 12),
                    ],
                  const SizedBox(height: 14),
                  const Text('Doctor Availability', style: _adminHeroStyle),
                  const SizedBox(height: 14),
                  const _AdminDoctorAvailabilityCard(
                    name: 'Dr. Aye Chan',
                    specialty: 'General Veterinarian',
                    available: true,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

const _adminHeroStyle = TextStyle(
  color: Colors.black,
  fontSize: 25,
  fontWeight: FontWeight.w900,
  letterSpacing: -0.6,
);

class _AdminDashboardSummary extends StatelessWidget {
  const _AdminDashboardSummary({
    required this.totalCount,
    required this.waitingCount,
    required this.emergencyCount,
    required this.pendingPaymentCount,
  });

  final int totalCount;
  final int waitingCount;
  final int emergencyCount;
  final int pendingPaymentCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/photos/logoandphoto/nways_love_logo.png',
                width: 62,
                height: 62,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_greeting()}, Mr.Admin',
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dashboardDate(DateTime.now()),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 166,
            child: Row(
              children: [
                Expanded(
                  child: _AdminStatCard(
                    key: const ValueKey('system-admin-total-stat'),
                    label: 'Today Total\nAppointments',
                    value: '$totalCount',
                    color: _adminMint,
                    large: true,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _AdminStatCard(
                                key: const ValueKey(
                                  'system-admin-waiting-stat',
                                ),
                                label: 'Waiting',
                                value: '$waitingCount',
                                color: _adminMint,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _AdminStatCard(
                                key: const ValueKey(
                                  'system-admin-emergency-stat',
                                ),
                                label: 'Emergency',
                                value: '*$emergencyCount',
                                color: _adminEmergencyRed,
                                onDark: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _AdminStatCard(
                          key: const ValueKey('system-admin-payments-stat'),
                          label: 'Pending Payments',
                          value: '$pendingPaymentCount',
                          color: _adminMint,
                          horizontal: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.label,
    required this.value,
    required this.color,
    this.large = false,
    this.horizontal = false,
    this.onDark = false,
    super.key,
  });

  final String label;
  final String value;
  final Color color;
  final bool large;
  final bool horizontal;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final valueColor = onDark ? Colors.white : Colors.black;
    final labelColor = onDark ? Colors.white : Colors.black;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      elevation: 4,
      shadowColor: const Color(0x44000000),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal ? 14 : 8,
          vertical: 8,
        ),
        child: horizontal
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 14,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: large ? 48 : 29,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: large ? 12 : 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: large ? 16 : 14,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AdminQuickActions extends StatelessWidget {
  const _AdminQuickActions();

  @override
  Widget build(BuildContext context) {
    const actions = <(IconData, String)>[
      (Icons.login_rounded, 'Check in'),
      (Icons.add_circle_outline_rounded, 'Walk in'),
      (Icons.groups_2_rounded, 'Queue'),
      (Icons.home_work_outlined, 'Home Visit'),
      (Icons.payments_outlined, 'Payments'),
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: actions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _AdminQuickAction(icon: action.$1, label: action.$2);
        },
      ),
    );
  }
}

class _AdminQuickAction extends StatelessWidget {
  const _AdminQuickAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 3,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          onTap: () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$label is coming soon.'))),
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 62,
            height: 62,
            child: Icon(icon, size: 30, color: _adminGreen),
          ),
        ),
      ),
      const SizedBox(height: 7),
      Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class _AdminAppointmentCard extends StatelessWidget {
  const _AdminAppointmentCard({required this.appointment});

  final BookedAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final emergency = appointment.status == 'Waiting';
    final cardColor = emergency ? _adminEmergencyRed : _adminSoftMint;
    final primaryText = emergency ? Colors.white : Colors.black;
    final subText = emergency ? Colors.white70 : _adminMuted;
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/photos/logoandphoto/nways_photo.png',
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  alignment: Alignment.topRight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${appointment.time} . ${appointment.pet.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lynn Htet . ${appointment.service.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: subText, fontSize: 12),
                    ),
                    Text(
                      appointment.veterinarian,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: subText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _statusLabel(appointment.status),
                    style: TextStyle(
                      color: emergency
                          ? const Color(0xFFFFE14D)
                          : _statusColor(appointment.status),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: primaryText,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'Checked In' => 'Checked in',
    'In Consultation' => 'In consult',
    _ => status,
  };

  Color _statusColor(String status) => switch (status) {
    'Pending' => const Color(0xFF9A5B00),
    'Confirmed' => const Color(0xFF2358A5),
    'Checked In' || 'Called' || 'In Consultation' => const Color(0xFF2358A5),
    'Completed' => const Color(0xFF4D625A),
    _ => _adminGreen,
  };
}

class _AdminDoctorAvailabilityCard extends StatelessWidget {
  const _AdminDoctorAvailabilityCard({
    required this.name,
    required this.specialty,
    required this.available,
  });

  final String name;
  final String specialty;
  final bool available;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _adminBorder),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 26,
          backgroundColor: _adminSoftMint,
          foregroundColor: _adminGreen,
          child: Icon(Icons.medical_services_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(specialty, style: const TextStyle(color: _adminMuted)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: available ? _adminSoftMint : const Color(0xFFFFE8E9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                available
                    ? Icons.check_circle_rounded
                    : Icons.pause_circle_rounded,
                size: 16,
                color: available ? _adminGreen : const Color(0xFFB3261E),
              ),
              const SizedBox(width: 6),
              Text(
                available ? 'Available' : 'Off duty',
                style: TextStyle(
                  color: available ? _adminGreen : const Color(0xFFB3261E),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Bookings tab
// ---------------------------------------------------------------------------

class _AdminBookingsTab extends StatelessWidget {
  const _AdminBookingsTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _AdminSimpleHeader(title: 'Management'),
        Expanded(
          child: AnimatedBuilder(
            animation: AppointmentStore.instance,
            builder: (context, _) {
              final appointments = AppointmentStore.instance.appointments;
              if (appointments.isEmpty) {
                return const _AdminEmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'No bookings yet',
                  message: 'Bookings across the clinic will appear here.',
                );
              }
              return ListView.separated(
                key: const ValueKey('system-admin-bookings'),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                itemCount: appointments.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _AdminAppointmentCard(appointment: appointments[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Account tab
// ---------------------------------------------------------------------------

class _AdminAccountTab extends StatelessWidget {
  const _AdminAccountTab({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminSimpleHeader(
          title: 'Account',
          trailing: IconButton(
            key: const ValueKey('system-admin-logout'),
            tooltip: 'Log Out',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ),
        Expanded(
          child: ListView(
            key: const ValueKey('system-admin-account'),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            children: [
              const _AdminInfoCard(
                rows: [
                  ('Role', 'System Administrator'),
                  ('Account', 'admin@nwaysclinic.com'),
                  ('Access', 'Clinic configuration and oversight'),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _adminSoftMint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security_rounded, color: _adminGreen),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This page is available only after a registered system administrator account is authenticated.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const ValueKey('system-admin-account-logout'),
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log Out'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF1017),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _AdminSimpleHeader extends StatelessWidget {
  const _AdminSimpleHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 8, 12, 14),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      boxShadow: [
        BoxShadow(
          color: Color(0x28000000),
          blurRadius: 7,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: SafeArea(
      bottom: false,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}

class _AdminEmptyState extends StatelessWidget {
  const _AdminEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: _adminGreen),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _adminMuted),
          ),
        ],
      ),
    ),
  );
}

class _AdminInfoCard extends StatelessWidget {
  const _AdminInfoCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _adminBorder),
    ),
    child: Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 95,
                child: Text(
                  rows[index].$1,
                  style: const TextStyle(color: _adminMuted),
                ),
              ),
              Expanded(
                child: Text(
                  rows[index].$2,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (index != rows.length - 1) const Divider(height: 22),
        ],
      ],
    ),
  );
}

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
