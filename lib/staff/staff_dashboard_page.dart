part of 'staff_portal.dart';

class StaffDashboardPage extends StatelessWidget {
  const StaffDashboardPage({required this.onOpenProfile, super.key});
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        StaffOperationsStore.instance,
        AppointmentStore.instance,
        EmergencyRequestStore.instance,
        HomeVisitStore.instance,
        ContactClinicStore.instance,
      ]),
      builder: (context, _) {
        final items = StaffOperationsStore.instance.appointments;
        final today = items
            .where(
              (a) =>
                  DateUtils.isSameDay(a.date, DateTime.now()) &&
                  a.status != 'Cancelled',
            )
            .toList();
        final emergencies =
            today.where((a) => a.priority == 'Urgent').length +
            EmergencyRequestStore.instance.requests
                .where(
                  (r) =>
                      r.status != EmergencyStatus.completed &&
                      r.status != EmergencyStatus.declined,
                )
                .length;
        final pendingPayments = StaffOperationsStore.instance.payments
            .where((p) => p.status != 'Paid')
            .length;
        return CustomScrollView(
          key: const ValueKey('staff-dashboard'),
          slivers: [
            SliverToBoxAdapter(
              child: _DashboardHeader(onProfile: onOpenProfile),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 190,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 4,
                            child: _DashboardMetric(
                              value: '${today.length}',
                              label: 'Today Total\nAppointments',
                              large: true,
                              onTap: () => _push(
                                context,
                                const StaffAppointmentsPage(
                                  initialFilter: 'Today',
                                  standalone: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _DashboardMetric(
                                          value: '—',
                                          label: 'Staff',
                                          onTap: () => _showInfo(
                                            context,
                                            'Staff attendance',
                                            'Staff attendance is not yet tracked.',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _DashboardMetric(
                                          value: '*$emergencies',
                                          label: 'Emergency',
                                          color: Color(0xFFFF0000),
                                          onTap: () => _push(
                                            context,
                                            const StaffEmergencyPage(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Expanded(
                                  flex: 2,
                                  child: _DashboardMetric(
                                    value: '$pendingPayments',
                                    label: 'Pending Payments',
                                    horizontal: true,
                                    onTap: () => _push(
                                      context,
                                      const StaffPaymentsPage(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Quick Actions', style: _sectionStyle),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 116,
                      child: ListView(
                        key: const ValueKey('staff-quick-actions'),
                        scrollDirection: Axis.horizontal,
                        children: [
                          _QuickAction(
                            icon: Icons.add_circle_outline_rounded,
                            label: 'Walk in',
                            onTap: () =>
                                _push(context, const StaffWalkInPage()),
                          ),
                          _QuickAction(
                            icon: Icons.groups_rounded,
                            label: 'Queue',
                            onTap: () => _push(
                              context,
                              const StaffQueueStandalonePage(),
                            ),
                          ),
                          _QuickAction(
                            icon: Icons.home_work_outlined,
                            label: 'Home Visit',
                            onTap: () =>
                                _push(context, const StaffHomeVisitsPage()),
                          ),
                          _QuickAction(
                            icon: Icons.person_search_rounded,
                            label: 'Pet Owners',
                            onTap: () =>
                                _push(context, const StaffPatientsPage()),
                          ),
                          _QuickAction(
                            icon: Icons.forum_rounded,
                            label: 'Messages',
                            badgeCount:
                                ContactClinicStore.instance.staffUnreadCount,
                            onTap: () => _push(
                              context,
                              const StaffMessagesPage(standalone: true),
                            ),
                          ),
                          _QuickAction(
                            icon: Icons.bar_chart_rounded,
                            label: 'Reports',
                            onTap: () =>
                                _push(context, const StaffReportsPage()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Today’s Appointments",
                            style: _sectionStyle,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _push(
                            context,
                            const StaffAppointmentsPage(
                              initialFilter: 'Today',
                              standalone: true,
                            ),
                          ),
                          child: const Text(
                            'View All Appointments',
                            style: TextStyle(color: Colors.black, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (today.isEmpty)
                      const _EmptyCard(
                        icon: Icons.event_busy_rounded,
                        text: 'No appointments scheduled today',
                      )
                    else
                      ...today
                          .take(3)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _DashboardAppointment(
                                item: item,
                                onTap: () => _push(
                                  context,
                                  StaffAppointmentDetailsPage(item: item),
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),
                    const Text('Doctor Availability', style: _sectionStyle),
                    const SizedBox(height: 10),
                    const _DoctorAvailability(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onProfile});
  final VoidCallback onProfile;
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: EdgeInsets.fromLTRB(
      24,
      MediaQuery.paddingOf(context).top + 24,
      24,
      4,
    ),
    child: Row(
      children: [
        InkWell(
          onTap: onProfile,
          child: Image.asset(
            'assets/photos/logoandphoto/nways_love_logo.png',
            width: 90,
            height: 110,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, Mya',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _fullDate(DateTime.now()),
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.value,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFFB0FCE0),
    this.large = false,
    this.horizontal = false,
  });
  final String value, label;
  final VoidCallback onTap;
  final Color color;
  final bool large, horizontal;
  @override
  Widget build(BuildContext context) {
    final number = Text(
      value,
      style: TextStyle(
        height: 1.1,
        fontSize: large ? 64 : 30,
        fontWeight: FontWeight.w800,
        color: Colors.black,
      ),
    );
    final caption = Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        height: 1.2,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: horizontal
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    number,
                    const SizedBox(width: 12),
                    Flexible(child: caption),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(child: number),
                    const SizedBox(height: 4),
                    caption,
                  ],
                ),
        ),
      ),
    );
  }
}

class _DashboardAppointment extends StatelessWidget {
  const _DashboardAppointment({required this.item, required this.onTap});
  final StaffAppointment item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final urgent = item.priority == 'Urgent';
    return Material(
      color: urgent ? const Color(0xFFFF0000) : const Color(0xFFB0FCE0),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 27,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage(
                  'assets/photos/logoandphoto/nways_pets.png',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.time.replaceAll(' AM', '').replaceAll(' PM', '')} . ${item.pet}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${item.owner} . ${item.service}',
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.doctor,
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  children: [
                    Text(
                      item.status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: urgent ? Colors.yellow : const Color(0xFF493CFF),
                        height: 1.2,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 98,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey),
                ),
                child: Icon(icon, color: const Color(0xFF00EF92), size: 34),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    constraints: const BoxConstraints(minWidth: 20),
                    decoration: BoxDecoration(
                      color: _red,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class _DoctorAvailability extends StatelessWidget {
  const _DoctorAvailability();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: _cardDecoration(),
    child: const Column(
      children: [
        _AvailabilityRow(
          name: 'Dr. Aye Chan',
          status: 'Available',
          color: _green,
        ),
        Divider(),
        _AvailabilityRow(
          name: 'Dr. Cindy Lynn',
          status: 'Consulting',
          color: Color(0xFFE09300),
        ),
        Divider(),
        _AvailabilityRow(
          name: 'Dr. Myat Noe',
          status: 'Available',
          color: _green,
        ),
      ],
    ),
  );
}

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({
    required this.name,
    required this.status,
    required this.color,
  });
  final String name;
  final String status;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFE6FAF2),
        child: Text(name.substring(4, 5)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
