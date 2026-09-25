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
        DoctorProfileStore.instance,
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
                doctorName: _dashboardDoctorName(),
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
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _DashboardMenuButton(
                            key: const ValueKey('doctor-write-post'),
                            icon: Icons.edit_note_rounded,
                            label: 'Write a post',
                            description: 'Share advice with pet owners',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const DoctorCreatePostPage(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DashboardMenuButton(
                            key: const ValueKey('doctor-manage-posts'),
                            icon: Icons.dashboard_customize_rounded,
                            label: 'Manage posts',
                            description: 'Edit, schedule, or archive',
                            filled: false,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const DoctorPostsManagerPage(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: Text(
                          'New Feeds',
                          style: DoctorStyles.heroSection,
                        ),
                      ),
                      if (DoctorPostStore.instance.posts.isNotEmpty)
                        TextButton(
                          key: const ValueKey('doctor-manage-posts-link'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const DoctorPostsManagerPage(),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: DoctorStyles.green,
                            padding: const EdgeInsets.only(bottom: 5),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('View all'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (DoctorPostStore.instance.posts.isEmpty)
                    _DashboardFeedEmptyState(
                      onWrite: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DoctorCreatePostPage(),
                        ),
                      ),
                    )
                  else
                    for (final post in DoctorPostStore.instance.posts.take(
                      3,
                    )) ...[
                      _DashboardFeedCard(post: post),
                      const SizedBox(height: 16),
                    ],
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
    required this.doctorName,
    required this.emergencyCount,
    required this.waitingCount,
    required this.completedCount,
    required this.totalCount,
    required this.onOpenEmergency,
    required this.onOpenWaiting,
    required this.onOpenCompleted,
    required this.onOpenToday,
  });

  final String doctorName;
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
                        '${_greeting()}, $doctorName',
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

String _dashboardDoctorName() {
  final profileName = DoctorProfileStore.instance.data.name.trim();
  final accountName = (ClinicApi.instance.account?['fullName'] as String? ?? '')
      .trim();
  final name = profileName.isNotEmpty ? profileName : accountName;
  if (name.isEmpty) return 'Doctor';
  if (RegExp(r'^(dr\.?|doctor)(?:\s|$)', caseSensitive: false).hasMatch(name)) {
    return name;
  }
  return 'Dr. $name';
}

class _DashboardMenuButton extends StatelessWidget {
  const _DashboardMenuButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onPressed,
    this.filled = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onPressed;

  /// When true the card uses the solid mint accent; otherwise a white card
  /// with a mint outline, giving the two actions a clear primary/secondary
  /// relationship.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final background = filled ? DoctorStyles.mint : Colors.white;
    final iconBackground = filled ? Colors.white : DoctorStyles.softMint;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      elevation: filled ? 5 : 0,
      shadowColor: const Color(0x40000000),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: filled
                ? null
                : Border.all(color: DoctorStyles.border, width: 1.4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: DoctorStyles.green, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.1,
                  color: DoctorStyles.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.25,
                  color: Color(0xFF5A6864),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardFeedEmptyState extends StatelessWidget {
  const _DashboardFeedEmptyState({required this.onWrite});

  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: DoctorStyles.border),
    ),
    child: Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: DoctorStyles.softMint,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.article_outlined,
            color: DoctorStyles.green,
            size: 28,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'No posts yet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: DoctorStyles.ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Publish helpful pet-care advice and it will appear here for owners.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.35,
            color: Color(0xFF5A6864),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onWrite,
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('Write your first post'),
          style: FilledButton.styleFrom(
            backgroundColor: DoctorStyles.mint,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    ),
  );
}
