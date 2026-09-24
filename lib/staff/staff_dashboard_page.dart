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
        StaffProfileStore.instance,
        ClinicDirectory.instance,
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
        final queueCount = StaffOperationsStore.instance.appointments
            .where(
              (a) =>
                  a.queueNumber.isNotEmpty &&
                  !const {
                    'Completed',
                    'Missed',
                    'Cancelled',
                  }.contains(a.status),
            )
            .length;
        final callsDue = today
            .where((appointment) => appointment.confirmationCallDue())
            .toList();
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
                                    value: '$queueCount',
                                    label: 'Queue',
                                    horizontal: true,
                                    onTap: () => _push(
                                      context,
                                      const StaffQueueStandalonePage(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (callsDue.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Material(
                        color: const Color(0xFFFFF3C4),
                        borderRadius: BorderRadius.circular(20),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: const ValueKey('dashboard-calls-due'),
                          onTap: () => _push(
                            context,
                            const StaffAppointmentsPage(standalone: true),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.phone_in_talk_rounded,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${callsDue.length} confirmation ${callsDue.length == 1 ? 'call' : 'calls'} due',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const Text(
                                        'Appointments starting within 30 minutes',
                                        style: TextStyle(color: _muted),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
                            imageAsset:
                                'assets/photos/icon/staff_dashboard_walk_in.png',
                            label: 'Walk in',
                            onTap: () =>
                                _push(context, const StaffWalkInPage()),
                          ),
                          _QuickAction(
                            icon: Icons.format_list_numbered_rounded,
                            imageAsset:
                                'assets/photos/icon/staff_management_queue.png',
                            label: 'Queue',
                            onTap: () => _push(
                              context,
                              const StaffQueueStandalonePage(),
                            ),
                          ),
                          _QuickAction(
                            icon: Icons.home_work_outlined,
                            imageAsset:
                                'assets/photos/icon/clinic_home_visit.png',
                            label: 'Home Visit',
                            onTap: () =>
                                _push(context, const StaffHomeVisitsPage()),
                          ),
                          _QuickAction(
                            icon: Icons.person_search_rounded,
                            imageAsset:
                                'assets/photos/icon/staff_dashboard_pet_owners.png',
                            label: 'Pets & Owners',
                            onTap: () =>
                                _push(context, const StaffPatientsPage()),
                          ),
                          _QuickAction(
                            icon: Icons.bar_chart_rounded,
                            imageAsset:
                                'assets/photos/icon/staff_dashboard_reports.png',
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
                '${_greeting()}, ${StaffProfileStore.instance.firstName}',
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

  (String, Color) get _statusStyle {
    if (item.priority == 'Urgent') {
      return ('Emergency', const Color(0xFFE11D1D));
    }
    return switch (item.status) {
      'In Consultation' => ('Consulting', const Color(0xFF2358A5)),
      'Completed' => ('Completed', _green),
      'Cancelled' || 'Missed' => (item.status, _red),
      'Waiting' ||
      'Called' ||
      'Checked In' => (item.status, const Color(0xFF9A5B00)),
      _ => (item.status, _green),
    };
  }

  @override
  Widget build(BuildContext context) {
    final urgent = item.priority == 'Urgent';
    final (statusLabel, statusColor) = _statusStyle;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 1.5,
      shadowColor: const Color(0x22000000),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored accent bar signals urgency at a glance.
              Container(width: 6, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          ProfilePetAvatar(
                            petName: item.pet,
                            ownerId: databaseOwnerOf(item.source),
                            radius: 26,
                            photoKey: ValueKey(
                              'staff-dashboard-pet-photo-${item.id}',
                            ),
                          ),
                          if (urgent)
                            Positioned(
                              right: -1,
                              bottom: -1,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.emergency_rounded,
                                  size: 15,
                                  color: _red,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 14,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.time,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.pet,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: _ink,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.owner} • ${item.service}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _muted,
                              ),
                            ),
                            Text(
                              item.doctor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _muted,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
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
    this.imageAsset,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? imageAsset;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 98,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: SizedBox.square(
                key: ValueKey(
                  'staff-${label.toLowerCase().replaceAll(' ', '-').replaceAll('&', 'and')}-dashboard-icon',
                ),
                dimension: 42,
                child: imageAsset == null
                    ? Icon(icon, color: _green, size: 36)
                    : Image.asset(imageAsset!, fit: BoxFit.contain),
              ),
            ),
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
  Widget build(BuildContext context) {
    // Always prefer the live doctor directory so the card reflects each
    // doctor's own availability (their "accepting appointments" setting). The
    // demo roster is only used offline when no real doctor data exists yet.
    final liveDoctors = ClinicDirectory.instance.doctorProfiles;
    final doctors = liveDoctors.isNotEmpty
        ? liveDoctors
        : (DatabaseSync.instance.active
              ? const <ClinicPerson>[]
              : _demoDoctors
                    .map((name) => ClinicPerson(name: name, role: 'doctor'))
                    .toList());
    final availableCount = doctors.where((d) => d.available).length;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: doctors.isEmpty
          ? const _Callout(
              icon: Icons.event_busy_outlined,
              text: 'No doctor profiles are available.',
            )
          : Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.medical_services_outlined,
                      size: 18,
                      color: _muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$availableCount of ${doctors.length} available',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                for (var index = 0; index < doctors.length; index++) ...[
                  _AvailabilityRow(doctor: doctors[index]),
                  if (index < doctors.length - 1) const Divider(),
                ],
              ],
            ),
    );
  }
}

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({required this.doctor});

  final ClinicPerson doctor;

  @override
  Widget build(BuildContext context) {
    final color = doctor.available ? _green : _red;
    final status = doctor.available ? 'Available' : 'Unavailable';
    final initial = doctor.name
        .replaceFirst(RegExp(r'^Dr\.\s*'), '')
        .trim()
        .characters
        .firstOrNull;
    return Row(
      key: ValueKey('doctor-availability-${doctor.name}'),
      children: [
        _PersonPhoto(
          key: ValueKey('doctor-photo-${doctor.id}-${doctor.name}'),
          source: doctor.photoUrl,
          fallbackText: initial?.toUpperCase() ?? 'D',
          size: 42,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if ((doctor.specialty ?? '').trim().isNotEmpty)
                Text(
                  doctor.specialty!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
            ],
          ),
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
}
