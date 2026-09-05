part of 'system_admin_portal.dart';

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
