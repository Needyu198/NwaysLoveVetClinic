part of 'staff_portal.dart';

class StaffAppointmentsPage extends StatefulWidget {
  const StaffAppointmentsPage({
    this.initialFilter,
    this.standalone = false,
    super.key,
  });
  final String? initialFilter;
  final bool standalone;
  @override
  State<StaffAppointmentsPage> createState() => _StaffAppointmentsPageState();
}

class _StaffAppointmentsPageState extends State<StaffAppointmentsPage> {
  late String _filter = _normalizeFilter(widget.initialFilter);

  static const _filters = ['All', 'Consulting', 'In Queue', 'Emergency'];

  static String _normalizeFilter(String? value) =>
      _filters.contains(value) ? value! : 'All';

  bool _matchesFilter(StaffAppointment a) => switch (_filter) {
    'Consulting' => a.status == 'In Consultation',
    'In Queue' =>
      a.priority != 'Urgent' &&
          const {
            'Pending',
            'Confirmed',
            'Checked In',
            'Called',
            'Waiting',
          }.contains(a.status),
    'Emergency' => a.priority == 'Urgent',
    _ => true,
  };

  bool _matchesLabel(StaffAppointment a, String filter) => switch (filter) {
    'Consulting' => a.status == 'In Consultation',
    'In Queue' =>
      a.priority != 'Urgent' &&
          const {
            'Pending',
            'Confirmed',
            'Checked In',
            'Called',
            'Waiting',
          }.contains(a.status),
    'Emergency' => a.priority == 'Urgent',
    _ => true,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          StaffOperationsStore.instance,
          AppointmentStore.instance,
        ]),
        builder: (context, _) {
          final all = StaffOperationsStore.instance.appointments;
          final items = all.where(_matchesFilter).toList();
          return Column(
            children: [
              _StaffAppointmentsHeader(
                onBack: widget.standalone ? () => Navigator.pop(context) : null,
                onRecords: () =>
                    _push(context, const StaffMedicalRecordsPage()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                child: SizedBox(
                  height: 42,
                  child: ListView.separated(
                    key: const ValueKey('staff-appointment-filters'),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final value = _filters[index];
                      final count = all
                          .where((a) => _matchesLabel(a, value))
                          .length;
                      return _AppointmentFilterChip(
                        label: value,
                        count: count,
                        selected: _filter == value,
                        onTap: () => setState(() => _filter = value),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    items.length == 1
                        ? '1 appointment'
                        : '${items.length} appointments',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.event_busy_rounded,
                                size: 52,
                                color: _muted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No ${_filter.toLowerCase()} appointments',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'They will appear here once available.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _muted),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        key: const ValueKey('staff-appointments'),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) => _AppointmentTile(
                          item: items[index],
                          onTap: () => _push(
                            context,
                            StaffAppointmentDetailsPage(item: items[index]),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _StaffAppointmentsHeader extends StatelessWidget {
  const _StaffAppointmentsHeader({this.onBack, required this.onRecords});

  final VoidCallback? onBack;
  final VoidCallback onRecords;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 10, 16, 6),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack ?? () => Navigator.maybePop(context),
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
        ),
        const Expanded(
          child: Text(
            'Appointments',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              color: _ink,
            ),
          ),
        ),
        TextButton.icon(
          key: const ValueKey('staff-appointments-records'),
          onPressed: onRecords,
          icon: const Icon(Icons.folder_shared_outlined, size: 18),
          label: const Text('Records'),
          style: TextButton.styleFrom(
            foregroundColor: _green,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AppointmentFilterChip extends StatelessWidget {
  const _AppointmentFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFF5C518) : _mint,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('staff-appointment-filter-$label'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.black.withValues(alpha: 0.16)
                    : Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class StaffAppointmentDetailsPage extends StatelessWidget {
  const StaffAppointmentDetailsPage({required this.item, super.key});
  final StaffAppointment item;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: StaffOperationsStore.instance,
    builder: (context, _) => Scaffold(
      backgroundColor: _page,
      appBar: _appBar('Appointment Details'),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _StatusBanner(status: item.status, priority: item.priority),
          const SizedBox(height: 14),
          _InfoCard(
            rows: [
              ('Booking ID', item.id),
              ('Pet', item.pet),
              ('Owner', item.owner),
              ('Contact', item.phone),
              ('Service', item.service),
              ('Reason', item.reason),
              ('Date', _shortDate(item.date)),
              ('Time', item.time),
              ('Doctor', item.doctor),
              if (item.queueNumber.isNotEmpty) ('Queue', item.queueNumber),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Management actions', style: _sectionStyle),
          const SizedBox(height: 10),
          if (item.status == 'Pending')
            _ActionButton(
              label: 'Confirm Appointment',
              icon: Icons.event_available_rounded,
              onTap: () {
                StaffOperationsStore.instance.update(item, status: 'Confirmed');
                _notice(context, 'Appointment confirmed and owner notified.');
              },
            ),
          if (const {'Pending', 'Confirmed'}.contains(item.status))
            _ActionButton(
              label: 'Assign Doctor',
              icon: Icons.medical_services_outlined,
              onTap: () => _chooseDoctor(context, item),
            ),
          if (const {'Pending', 'Confirmed'}.contains(item.status))
            _ActionButton(
              label: 'Reschedule',
              icon: Icons.edit_calendar_outlined,
              onTap: () => _reschedule(context, item),
            ),
          if (const {'Pending', 'Confirmed'}.contains(item.status))
            _ActionButton(
              label: 'Cancel Appointment',
              icon: Icons.cancel_outlined,
              destructive: true,
              onTap: () => _cancel(context, item),
            ),
          if (item.status == 'Waiting')
            _ActionButton(
              label: 'Open Live Queue',
              icon: Icons.format_list_numbered_rounded,
              onTap: () => _push(context, const StaffQueueStandalonePage()),
            ),
        ],
      ),
    ),
  );
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.item, required this.onTap});
  final StaffAppointment item;
  final VoidCallback onTap;

  String get _statusLabel {
    if (item.priority == 'Urgent') return 'Emergency';
    return switch (item.status) {
      'In Consultation' => 'Consulting',
      'Completed' => 'Completed',
      'Cancelled' => 'Cancelled',
      'Missed' => 'Missed',
      _ => 'In Queue',
    };
  }

  @override
  Widget build(BuildContext context) {
    final emergency = item.priority == 'Urgent';
    final consulting = !emergency && item.status == 'In Consultation';
    final cardColor = emergency ? const Color(0xFFFF1919) : _mint;
    final onCard = emergency ? Colors.white : Colors.black;
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(34),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: const Color(0x33000000),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: const AssetImage(
                  'assets/photos/logoandphoto/nways_pets.png',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 15, color: onCard),
                        const SizedBox(width: 4),
                        Text(
                          item.time,
                          style: TextStyle(
                            color: onCard,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.pet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onCard,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.owner} • ${item.service}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: emergency ? Colors.white70 : _muted,
                        fontSize: 13,
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
                    constraints: const BoxConstraints(minWidth: 100),
                    height: 38,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: consulting
                          ? const Color(0xFFF5C518)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      _statusLabel,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          color: emergency ? Colors.white70 : _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: emergency ? Colors.white70 : _muted,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status, required this.priority});
  final String status;
  final String priority;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: priority == 'Urgent'
          ? const Color(0xFFFFE4E5)
          : const Color(0xFFE6FAF2),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(
          priority == 'Urgent'
              ? Icons.emergency_rounded
              : Icons.event_available_rounded,
          color: priority == 'Urgent' ? _red : _green,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            status,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          '$priority priority',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: SizedBox(
      width: double.infinity,
      child: destructive
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(label),
              style: OutlinedButton.styleFrom(foregroundColor: _red),
            )
          : FilledButton.icon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(label),
            ),
    ),
  );
}

Future<void> _chooseDoctor(BuildContext context, StaffAppointment item) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              'Assign an available doctor',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          ..._doctors.map(
            (doctor) => ListTile(
              leading: const CircleAvatar(
                backgroundColor: _mint,
                child: Icon(Icons.medical_services_outlined),
              ),
              title: Text(doctor),
              subtitle: const Text('Available'),
              onTap: () => Navigator.pop(context, doctor),
            ),
          ),
        ],
      ),
    ),
  );
  if (choice != null) {
    StaffOperationsStore.instance.update(item, doctor: choice);
    if (context.mounted) _notice(context, '$choice assigned and notified.');
  }
}

Future<void> _reschedule(BuildContext context, StaffAppointment item) async {
  final date = await showDatePicker(
    context: context,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 120)),
    initialDate: item.date.isBefore(DateTime.now())
        ? DateTime.now()
        : item.date,
  );
  if (date == null || !context.mounted) return;
  final time = await showTimePicker(
    context: context,
    initialTime: const TimeOfDay(hour: 10, minute: 0),
  );
  if (time == null || !context.mounted) return;
  StaffOperationsStore.instance.update(
    item,
    date: date,
    time: time.format(context),
    status: 'Confirmed',
  );
  _notice(context, 'Appointment rescheduled. Owner and doctor notified.');
}

Future<void> _cancel(BuildContext context, StaffAppointment item) async {
  final controller = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cancel appointment?'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 2,
        decoration: _input('Cancellation reason', Icons.notes_rounded),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Keep'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(dialogContext, controller.text.trim());
            }
          },
          style: FilledButton.styleFrom(backgroundColor: _red),
          child: const Text('Cancel appointment'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (reason == null) return;
  if (item.source != null) {
    AppointmentStore.instance.cancelWithDetails(
      item.source!,
      reason: reason,
      initiatedBy: CancellationInitiator.staff,
    );
    StaffOperationsStore.instance.update(item, status: item.source!.status);
  } else {
    StaffOperationsStore.instance.update(item, status: 'Cancelled');
  }
  if (context.mounted) {
    _notice(
      context,
      'Appointment cancelled. Slot released and audit recorded.',
    );
  }
}
