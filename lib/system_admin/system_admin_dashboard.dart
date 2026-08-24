import 'package:flutter/material.dart';

import '../login/login_page.dart';
import '../pet_owner/appointment_booking_page.dart';

class SystemAdminDashboardPage extends StatelessWidget {
  const SystemAdminDashboardPage({super.key});

  static const routeName = '/system-admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text('System Administration'),
        backgroundColor: const Color(0xFFA1FDD8),
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            key: const ValueKey('system-admin-logout'),
            tooltip: 'Log Out',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: AppointmentStore.instance,
        builder: (context, _) {
          final appointments = AppointmentStore.instance.appointments;
          final active = appointments
              .where(
                (appointment) => !const {
                  'Cancelled',
                  'Completed',
                }.contains(appointment.status),
              )
              .length;
          return ListView(
            key: const ValueKey('system-admin-dashboard'),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
            children: [
              const Text(
                'Clinic System Overview',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              const Text(
                'Administrator access • Nway’s Love Vet Clinic',
                style: TextStyle(color: Color(0xFF62716C)),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _AdminStatCard(
                      icon: Icons.event_note_rounded,
                      value: '${appointments.length}',
                      label: 'All bookings',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AdminStatCard(
                      icon: Icons.pending_actions_rounded,
                      value: '$active',
                      label: 'Active bookings',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: _AdminStatCard(
                      icon: Icons.medical_services_rounded,
                      value: '1',
                      label: 'Registered doctors',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _AdminStatCard(
                      icon: Icons.health_and_safety_rounded,
                      value: 'Online',
                      label: 'System status',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Administrator Account',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const _AdminInfoCard(
                rows: [
                  ('Role', 'System Administrator'),
                  ('Account', 'admin@nwaysclinic.com'),
                  ('Access', 'Clinic configuration and oversight'),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FAF2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security_rounded, color: Color(0xFF15835F)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This page is available only after a registered system administrator account is authenticated.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFD7E5DF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFE8FAF2),
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(dimension: 40),
        ),
        Transform.translate(
          offset: const Offset(8, -32),
          child: Icon(icon, color: const Color(0xFF15835F), size: 24),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
        ),
        Text(label, style: const TextStyle(color: Color(0xFF62716C))),
      ],
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
      border: Border.all(color: const Color(0xFFD7E5DF)),
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
                  style: const TextStyle(color: Color(0xFF62716C)),
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
