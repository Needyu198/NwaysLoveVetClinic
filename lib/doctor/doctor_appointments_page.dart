part of 'doctor_portal.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({this.initialFilter = 'All', super.key});

  final String initialFilter;

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  late String _filter = widget.initialFilter;
  static const _filters = [
    'All',
    'Today',
    'Waiting',
    'Pending',
    'Confirmed',
    'Checked In',
    'Called',
    'In Consultation',
    'Completed',
    'Cancelled',
    'Rejected',
    'Reschedule Requested',
    'Missed',
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        DoctorAppointmentStore.instance,
        AppointmentStore.instance,
      ]),
      builder: (context, _) {
        final all = DoctorAppointmentStore.instance.appointments;
        final records = switch (_filter) {
          'All' => all,
          'Today' =>
            all
                .where(
                  (record) => DateUtils.isSameDay(record.date, DateTime.now()),
                )
                .toList(),
          'Waiting' =>
            all
                .where(
                  (record) =>
                      DateUtils.isSameDay(record.date, DateTime.now()) &&
                      !const {'Completed', 'Cancelled'}.contains(record.status),
                )
                .toList(),
          _ => all.where((record) => record.status == _filter).toList(),
        };
        return Column(
          key: const ValueKey('doctor-appointments'),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
              child: Row(
                children: [
                  Expanded(
                    child: _DoctorFunctionButton(
                      key: const ValueKey('doctor-open-queue'),
                      label: 'Queue',
                      icon: Icons.groups_2_outlined,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DoctorQueuePage(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DoctorFunctionButton(
                      key: const ValueKey('doctor-open-medical-records'),
                      label: 'Records',
                      icon: Icons.medical_information_outlined,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DoctorMedicalRecordsPage(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DoctorFunctionButton(
                      key: const ValueKey('doctor-open-home-visits'),
                      label: 'Visits',
                      icon: Icons.home_work_outlined,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DoctorHomeVisitsPage(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  for (final filter in _filters) ...[
                    ChoiceChip(
                      key: ValueKey('doctor-filter-$filter'),
                      label: Text(filter),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Expanded(
              child: records.isEmpty
                  ? const _EmptyDoctorState(
                      icon: Icons.event_busy_outlined,
                      title: 'No appointments',
                      message: 'There are no appointments with this status.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                      itemCount: records.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, index) =>
                          DoctorAppointmentCard(record: records[index]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class DoctorAppointmentCard extends StatelessWidget {
  const DoctorAppointmentCard({
    required this.record,
    this.compact = false,
    super.key,
  });

  final DoctorAppointmentRecord record;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: ValueKey('doctor-appointment-${record.id}'),
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DoctorAppointmentDetailsPage(record: record),
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(compact ? 14 : 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DoctorStyles.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: DoctorStyles.softMint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(_month(record.date), style: DoctorStyles.small),
                    Text('${record.date.day}', style: DoctorStyles.cardTitle),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.petName,
                            style: DoctorStyles.cardTitle,
                          ),
                        ),
                        _StatusBadge(status: record.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(record.service, style: DoctorStyles.body),
                    const SizedBox(height: 5),
                    Text(
                      '${record.time} • ${record.ownerName}',
                      style: DoctorStyles.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class DoctorAppointmentDetailsPage extends StatelessWidget {
  const DoctorAppointmentDetailsPage({required this.record, super.key});

  final DoctorAppointmentRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.page,
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: DoctorStyles.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          DoctorAppointmentStore.instance,
          AppointmentStore.instance,
        ]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
          children: [
            _DoctorDetailsCard(
              rows: [
                ('Booking ID', '#${record.id}'),
                ('Patient', record.petName),
                ('Pet details', record.petDetails),
                ('Pet owner', record.ownerName),
                ('Service', record.service),
                ('Date', _fullDate(record.date)),
                ('Time', record.time),
                ('Status', record.status),
                ('Visit reason', record.reason),
                ('Symptoms', record.symptoms),
              ],
            ),
            const SizedBox(height: 16),
            const _DoctorNotice(
              text:
                  'Only clinic staff and the assigned veterinarian can update this appointment. Pet owners see these statuses as read-only.',
            ),
            const SizedBox(height: 20),
            if (record.status == 'Pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('doctor-reject-appointment'),
                      onPressed: () => _confirmDecision(
                        context,
                        status: 'Rejected',
                        title: 'Reject appointment?',
                      ),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB3261E),
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('doctor-accept-appointment'),
                      onPressed: () => _confirmDecision(
                        context,
                        status: 'Confirmed',
                        title: 'Accept appointment?',
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Accept'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (const {'Pending', 'Confirmed'}.contains(record.status)) ...[
              OutlinedButton.icon(
                key: const ValueKey('doctor-request-reschedule'),
                onPressed: () => _requestReschedule(context),
                icon: const Icon(Icons.event_repeat_rounded),
                label: const Text('Request Rescheduling'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (record.status == 'In Consultation')
              FilledButton.icon(
                key: const ValueKey('open-consultation-workspace'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DoctorConsultationPage(record: record),
                  ),
                ),
                icon: const Icon(Icons.medical_services_outlined),
                label: const Text('Open Consultation Workspace'),
              )
            else if (_nextStatus(record.status) case final nextStatus?)
              FilledButton.icon(
                key: const ValueKey('doctor-update-status'),
                onPressed: () => _confirmStatus(context, nextStatus),
                icon: Icon(_statusIcon(nextStatus)),
                label: Text(_statusAction(nextStatus)),
                style: FilledButton.styleFrom(
                  backgroundColor: DoctorStyles.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
              )
            else
              _DoctorNotice(
                text: record.status == 'Cancelled'
                    ? 'This booking was cancelled. No further status changes are available.'
                    : 'This appointment workflow is complete.',
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmStatus(BuildContext context, String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update appointment status?'),
        content: Text(
          'Change ${record.petName}’s appointment to “$status”? The pet owner will see the update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            key: const ValueKey('confirm-doctor-status'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Update Status'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      DoctorAppointmentStore.instance.updateStatus(record, status);
      if (status == 'In Consultation' && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DoctorConsultationPage(record: record),
          ),
        );
      }
    }
  }

  Future<void> _confirmDecision(
    BuildContext context, {
    required String status,
    required String title,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(
          'The appointment status will change to $status and the pet owner will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-doctor-decision'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      DoctorAppointmentStore.instance.updateStatus(record, status);
      DoctorNotificationStore.instance.add(
        '$status appointment for ${record.petName}',
        'The pet owner was notified about booking #${record.id}.',
      );
    }
  }

  Future<void> _requestReschedule(BuildContext context) async {
    final controller = TextEditingController();
    final requested = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request Rescheduling'),
        content: TextField(
          key: const ValueKey('doctor-reschedule-note'),
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason or preferred schedule',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-doctor-reschedule'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
    if (requested == true && controller.text.trim().isNotEmpty) {
      record.rescheduleNote = controller.text.trim();
      DoctorAppointmentStore.instance.updateStatus(
        record,
        'Reschedule Requested',
      );
      DoctorNotificationStore.instance.add(
        'Reschedule requested for ${record.petName}',
        record.rescheduleNote,
      );
    }
    controller.dispose();
  }
}
