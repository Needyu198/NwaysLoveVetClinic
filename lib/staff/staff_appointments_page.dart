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
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

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
          final callsDue = all
              .where((item) => item.confirmationCallDue())
              .length;
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
              if (callsDue > 0)
                Container(
                  key: const ValueKey('appointment-calls-due'),
                  margin: const EdgeInsets.fromLTRB(18, 2, 18, 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3C4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_in_talk_rounded, color: _ink),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$callsDue owner ${callsDue == 1 ? 'call is' : 'calls are'} due now',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const Text('30 min reminder'),
                    ],
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
      body: Column(
        children: [
          const _StaffMintHeader(
            title: 'Appointment Details',
            subtitle: 'Review and manage this booking',
            icon: Icons.calendar_month_outlined,
            logoKey: ValueKey('staff-appointment-details-logo'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
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
                    if (item.queueNumber.isNotEmpty)
                      ('Queue', item.queueNumber),
                  ],
                ),
                const SizedBox(height: 18),
                _ActionButton(
                  label: item.confirmationCallDue()
                      ? 'Call Owner Now'
                      : 'Call Owner',
                  icon: Icons.phone_in_talk_rounded,
                  onTap: () => _callOwnerAndRecord(context, item),
                ),
                if (item.confirmationCalls.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Confirmation call history', style: _sectionStyle),
                  const SizedBox(height: 10),
                  _ConfirmationCallHistory(calls: item.confirmationCalls),
                  const SizedBox(height: 18),
                ],
                const Text('Management actions', style: _sectionStyle),
                const SizedBox(height: 10),
                if (item.status == 'Pending')
                  _ActionButton(
                    label: 'Confirm Appointment',
                    icon: Icons.event_available_rounded,
                    onTap: () {
                      StaffOperationsStore.instance.update(
                        item,
                        status: 'Confirmed',
                      );
                      _notice(
                        context,
                        'Appointment confirmed and owner notified.',
                      );
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
                if (item.status == 'Confirmed')
                  _ActionButton(
                    label: 'Check In Patient',
                    icon: Icons.login_rounded,
                    onTap: () async {
                      try {
                        if (item.source case final source?) {
                          await QueueStore.instance.checkIn(
                            source,
                            priority: item.priority.toLowerCase(),
                          );
                        } else {
                          StaffOperationsStore.instance.update(
                            item,
                            status: 'Checked In',
                          );
                        }
                        if (context.mounted) {
                          _notice(
                            context,
                            'Patient checked in and added to the live queue.',
                          );
                        }
                      } on ClinicApiException catch (error) {
                        if (context.mounted) _notice(context, error.message);
                      }
                    },
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
                    onTap: () =>
                        _push(context, const StaffQueueStandalonePage()),
                  ),
              ],
            ),
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
              ProfilePetAvatar(
                petName: item.pet,
                radius: 30,
                fallbackBackground: Colors.white,
                fallbackForeground: const Color(0xFF16855E),
                photoKey: ValueKey('staff-appointment-pet-photo-${item.pet}'),
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
                    if (item.confirmationCallDue()) ...[
                      const SizedBox(height: 4),
                      Container(
                        key: ValueKey('call-due-${item.id}'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.confirmationCallOverdue()
                              ? 'Call overdue'
                              : 'Call owner now',
                          style: const TextStyle(
                            color: Color(0xFF8A5A00),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
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
  final doctors = _availableDoctorProfiles;
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
          if (doctors.isEmpty)
            const ListTile(
              leading: Icon(Icons.event_busy_outlined),
              title: Text('No doctors are currently available'),
            ),
          ...doctors.map(
            (doctor) => ListTile(
              key: ValueKey('appointment-doctor-${doctor.id}'),
              leading: _PersonPhoto(
                key: ValueKey('appointment-doctor-photo-${doctor.id}'),
                source: doctor.photoUrl,
                fallbackText: _initialFor(doctor.name),
                size: 48,
              ),
              title: Text(
                doctor.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                (doctor.specialty?.trim().isNotEmpty ?? false)
                    ? doctor.specialty!.trim()
                    : 'Available veterinarian',
              ),
              onTap: () => Navigator.pop(context, doctor.name),
            ),
          ),
        ],
      ),
    ),
  );
  if (choice != null) {
    try {
      final entry = item.source == null
          ? null
          : QueueStore.instance.existingEntryFor(item.source!);
      if (entry != null) {
        await QueueStore.instance.transition(
          entry,
          entry.status,
          assignedDoctor: choice,
        );
      } else {
        StaffOperationsStore.instance.update(item, doctor: choice);
      }
      if (context.mounted) _notice(context, '$choice assigned and notified.');
    } on ClinicApiException catch (error) {
      if (context.mounted) _notice(context, error.message);
    }
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
  var enteredReason = '';
  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cancel appointment?'),
      content: TextField(
        key: const ValueKey('staff-cancellation-reason'),
        autofocus: true,
        maxLines: 2,
        onChanged: (value) => enteredReason = value,
        decoration: _input('Cancellation reason', Icons.notes_rounded).copyWith(
          labelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          floatingLabelStyle: const TextStyle(
            color: _green,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('keep-staff-appointment'),
          onPressed: () => Navigator.pop(dialogContext),
          style: TextButton.styleFrom(
            foregroundColor: _ink,
            backgroundColor: const Color(0xFFE8FFF5),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
          child: const Text('Keep'),
        ),
        FilledButton(
          key: const ValueKey('confirm-staff-cancellation'),
          onPressed: () {
            final value = enteredReason.trim();
            if (value.isNotEmpty) {
              Navigator.pop(dialogContext, value);
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Cancel appointment'),
        ),
      ],
    ),
  );
  if (reason == null) return;

  final previousStatus = item.status;
  final source = item.source;
  final previousSourceStatus = source?.status;
  final previousCancellation = source?.cancellation;
  try {
    if (source != null) {
      final cancellation = AppointmentStore.instance.cancelWithDetails(
        source,
        reason: reason,
        initiatedBy: CancellationInitiator.staff,
      );
      if (cancellation == null) {
        if (context.mounted) {
          _notice(
            context,
            'This appointment can no longer be cancelled. Refresh and review its current status.',
          );
        }
        return;
      }
      StaffOperationsStore.instance.update(item, status: source.status);
    } else {
      StaffOperationsStore.instance.update(item, status: 'Cancelled');
    }

    if (DatabaseSync.instance.active) {
      await DatabaseSync.instance.flushOrThrow();
    }
    if (context.mounted) {
      _notice(
        context,
        'Appointment cancelled. Slot released and owner notified.',
      );
    }
  } on ClinicApiException catch (error) {
    item.status = previousStatus;
    if (source != null) {
      source
        ..status = previousSourceStatus!
        ..cancellation = previousCancellation;
      AppointmentStore.instance.databaseChanged();
    }
    StaffOperationsStore.instance.databaseChanged();
    if (DatabaseSync.instance.active) {
      await DatabaseSync.instance.flush();
    }
    if (context.mounted) {
      _notice(context, 'Could not cancel appointment: ${error.message}');
    }
  }
}

Future<void> _callOwnerAndRecord(
  BuildContext context,
  StaffAppointment item,
) async {
  if (item.phone.trim().isEmpty || item.phone == 'Not recorded') {
    _notice(context, 'No phone number is recorded for this owner.');
    return;
  }
  final opened = await openClinicPhoneApp(item.phone);
  if (!context.mounted) return;
  if (!opened) {
    _notice(context, 'This device could not open the phone app.');
    return;
  }

  final outcome = await showModalBottomSheet<AppointmentCallOutcome>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              'Record call result',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            subtitle: Text('Choose what the owner told you.'),
          ),
          for (final value in AppointmentCallOutcome.values)
            ListTile(
              leading: Icon(switch (value) {
                AppointmentCallOutcome.confirmed =>
                  Icons.check_circle_outline_rounded,
                AppointmentCallOutcome.runningLate => Icons.schedule_rounded,
                AppointmentCallOutcome.cannotCome => Icons.event_busy_rounded,
                AppointmentCallOutcome.noAnswer => Icons.phone_missed_rounded,
                AppointmentCallOutcome.callAgainLater => Icons.replay_rounded,
              }),
              title: Text(value.label),
              onTap: () => Navigator.pop(sheetContext, value),
            ),
        ],
      ),
    ),
  );
  if (outcome == null || !context.mounted) return;

  final notesController = TextEditingController();
  final notes = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(outcome.label),
      content: TextField(
        controller: notesController,
        maxLines: 3,
        decoration: _input(
          outcome == AppointmentCallOutcome.runningLate
              ? 'Expected arrival time or note'
              : 'Optional note',
          Icons.notes_rounded,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, ''),
          child: const Text('Skip note'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(dialogContext, notesController.text.trim()),
          child: const Text('Save result'),
        ),
      ],
    ),
  );
  notesController.dispose();
  if (notes == null) return;
  final retry = const {
    AppointmentCallOutcome.noAnswer,
    AppointmentCallOutcome.callAgainLater,
  }.contains(outcome);
  StaffOperationsStore.instance.recordConfirmationCall(
    item,
    AppointmentConfirmationCall(
      calledAt: DateTime.now(),
      outcome: outcome,
      staffName: StaffProfileStore.instance.firstName,
      notes: notes,
      retryAt: retry ? DateTime.now().add(const Duration(minutes: 15)) : null,
    ),
  );
  if (context.mounted) {
    _notice(
      context,
      retry
          ? 'Call result saved. Retry due in 15 minutes.'
          : 'Call result saved.',
    );
  }
}

class _ConfirmationCallHistory extends StatelessWidget {
  const _ConfirmationCallHistory({required this.calls});

  final List<AppointmentConfirmationCall> calls;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8E5)),
    ),
    child: Column(
      children: [
        for (var index = calls.length - 1; index >= 0; index--) ...[
          if (index != calls.length - 1)
            const Divider(height: 1, indent: 16, endIndent: 16),
          Builder(
            builder: (context) {
              final call = calls[index];
              final time = TimeOfDay.fromDateTime(
                call.calledAt,
              ).format(context);
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: _mint,
                  child: Icon(Icons.phone_in_talk_rounded, color: _green),
                ),
                title: Text(
                  call.outcome.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  [
                    '${_shortDate(call.calledAt)} at $time • ${call.staffName}',
                    if (call.notes.isNotEmpty) call.notes,
                    if (call.retryAt != null)
                      'Retry at ${TimeOfDay.fromDateTime(call.retryAt!).format(context)}',
                  ].join('\n'),
                ),
              );
            },
          ),
        ],
      ],
    ),
  );
}
