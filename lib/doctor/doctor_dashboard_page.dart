part of 'doctor_portal.dart';

class DoctorDashboardPage extends StatelessWidget {
  const DoctorDashboardPage({
    required this.onOpenAppointments,
    required this.onOpenProfile,
    super.key,
  });

  final ValueChanged<String> onOpenAppointments;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        DoctorAppointmentStore.instance,
        AppointmentStore.instance,
        EmergencyRequestStore.instance,
        DoctorPostStore.instance,
      ]),
      builder: (context, _) {
        final records = DoctorAppointmentStore.instance.appointments;
        final today = records.where((record) {
          return DateUtils.isSameDay(record.date, DateTime.now()) &&
              record.status != 'Cancelled';
        }).toList();
        final completed = today
            .where((record) => record.status == 'Completed')
            .length;
        final waiting = today
            .where((record) => record.status != 'Completed')
            .length;
        final upNext = today.where((record) {
          return !const {
            'Completed',
            'Cancelled',
            'In Consultation',
          }.contains(record.status);
        }).toList();
        final emergencyCases = EmergencyRequestStore.instance.requests.where((
          request,
        ) {
          return !const {
            EmergencyStatus.completed,
            EmergencyStatus.declined,
          }.contains(request.status);
        }).toList();

        return ListView(
          key: const ValueKey('doctor-dashboard'),
          padding: EdgeInsets.zero,
          children: [
            SafeArea(
              bottom: false,
              child: _DoctorDashboardSummary(
                emergencyCount: emergencyCases.length,
                waitingCount: waiting,
                completedCount: completed,
                totalCount: today.length,
                onOpenEmergency: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DoctorEmergencyCasesPage(),
                  ),
                ),
                onOpenWaiting: () => onOpenAppointments('Waiting'),
                onOpenCompleted: () => onOpenAppointments('Completed'),
                onOpenToday: () => onOpenAppointments('Today'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: Text('Up Next', style: DoctorStyles.heroSection),
                      ),
                      TextButton(
                        key: const ValueKey('doctor-view-all-appointments'),
                        onPressed: () => onOpenAppointments('All'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.only(bottom: 5),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                        child: const Text('View All Appointments'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (emergencyCases.isNotEmpty) ...[
                    for (final emergency in emergencyCases.take(2)) ...[
                      _EmergencyQueueCard(request: emergency),
                      const SizedBox(height: 12),
                    ],
                  ],
                  if (upNext.isEmpty && emergencyCases.isEmpty)
                    const _EmptyDoctorState(
                      icon: Icons.event_available_rounded,
                      title: 'No patients waiting',
                      message: 'Today’s active queue is clear.',
                    )
                  else ...[
                    for (
                      var index = 0;
                      index < upNext.length && index < 2;
                      index++
                    ) ...[
                      _UpNextCard(
                        record: upNext[index],
                        canStart: index == 0 && emergencyCases.isEmpty,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  const SizedBox(height: 4),
                  const Text('Quick Menu', style: DoctorStyles.heroSection),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DashboardMenuButton(
                          key: const ValueKey('doctor-write-post'),
                          label: 'Write a post',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const DoctorCreatePostPage(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _DashboardMenuButton(
                          key: const ValueKey('doctor-inventory'),
                          label: 'Inventory',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const StaffInventoryPage(
                                canAdjustStock: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('New Feeds', style: DoctorStyles.heroSection),
                  const SizedBox(height: 16),
                  for (final post in DoctorPostStore.instance.posts.take(
                    3,
                  )) ...[
                    _DashboardFeedCard(post: post),
                    const SizedBox(height: 18),
                  ],
                  const SizedBox.shrink(child: Text('Doctor Dashboard')),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DoctorDashboardSummary extends StatelessWidget {
  const _DoctorDashboardSummary({
    required this.emergencyCount,
    required this.waitingCount,
    required this.completedCount,
    required this.totalCount,
    required this.onOpenEmergency,
    required this.onOpenWaiting,
    required this.onOpenCompleted,
    required this.onOpenToday,
  });

  final int emergencyCount;
  final int waitingCount;
  final int completedCount;
  final int totalCount;
  final VoidCallback onOpenEmergency;
  final VoidCallback onOpenWaiting;
  final VoidCallback onOpenCompleted;
  final VoidCallback onOpenToday;

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
                        '${_greeting()}, Dr. Aye Chan',
                        maxLines: 1,
                        style: DoctorStyles.dashboardGreeting,
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
                  child: Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _DashboardStatCard(
                          key: const ValueKey('doctor-emergency-stat'),
                          label: 'Emergency Cases',
                          value: '$emergencyCount',
                          color: DoctorStyles.emergencyRed,
                          onTap: onOpenEmergency,
                          horizontal: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              child: _DashboardStatCard(
                                key: const ValueKey('doctor-waiting-stat'),
                                label: 'Waiting',
                                value: '$waitingCount',
                                color: DoctorStyles.mint,
                                onTap: onOpenWaiting,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DashboardStatCard(
                                key: const ValueKey('doctor-completed-stat'),
                                label: 'Completed',
                                value: '$completedCount',
                                color: DoctorStyles.mint,
                                onTap: onOpenCompleted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _DashboardStatCard(
                    key: const ValueKey('doctor-total-stat'),
                    label: 'Today Total Appointments',
                    value: '$totalCount',
                    color: DoctorStyles.mint,
                    onTap: onOpenToday,
                    large: true,
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

class _DashboardMenuButton extends StatelessWidget {
  const _DashboardMenuButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: DoctorStyles.mint,
    borderRadius: BorderRadius.circular(30),
    elevation: 5,
    shadowColor: const Color(0x55000000),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        height: 76,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 24, color: Colors.black),
          ),
        ),
      ),
    ),
  );
}
