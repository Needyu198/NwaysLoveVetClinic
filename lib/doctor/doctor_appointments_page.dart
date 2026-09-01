part of 'doctor_portal.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({
    this.initialFilter = 'All',
    this.onBack,
    super.key,
  });

  final String initialFilter;
  final VoidCallback? onBack;

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  late final String _filter = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        DoctorAppointmentStore.instance,
        AppointmentStore.instance,
        EmergencyRequestStore.instance,
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
        final ongoing = records
            .where((record) => record.status == 'In Consultation')
            .toList();
        final waiting = records
            .where((record) => record.status != 'In Consultation')
            .toList();
        final emergencies = EmergencyRequestStore.instance.requests
            .where(
              (request) => !const {
                EmergencyStatus.completed,
                EmergencyStatus.declined,
              }.contains(request.status),
            )
            .toList();

        return ColoredBox(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Column(
              key: const ValueKey('doctor-appointments'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                  child: Row(
                    children: [
                      IconButton(
                        key: const ValueKey('doctor-appointments-back'),
                        onPressed: widget.onBack,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 34,
                          minHeight: 44,
                        ),
                        icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        key: const ValueKey('doctor-open-home-visits'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DoctorHomeVisitsPage(),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Appointments',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 10, 26, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        key: const ValueKey('doctor-open-queue'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DoctorQueuePage(),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(70, 36),
                          alignment: Alignment.centerLeft,
                        ),
                        child: const Text('Ongoing'),
                      ),
                      TextButton(
                        key: const ValueKey('doctor-open-medical-records'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DoctorMedicalRecordsPage(),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(70, 36),
                          alignment: Alignment.centerRight,
                        ),
                        child: const Text('Records'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: records.isEmpty && emergencies.isEmpty
                      ? const _EmptyDoctorState(
                          icon: Icons.event_busy_outlined,
                          title: 'No appointments',
                          message:
                              'There are no appointments with this status.',
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 26),
                          children: [
                            for (final record in ongoing) ...[
                              DoctorAppointmentCard(record: record),
                              const SizedBox(height: 9),
                            ],
                            if (waiting.isNotEmpty || emergencies.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  9,
                                ),
                                child: Text(
                                  _filter == 'Completed'
                                      ? 'Completed'
                                      : 'Waiting',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            for (final emergency in emergencies) ...[
                              _DoctorEmergencyAppointmentCard(
                                request: emergency,
                              ),
                              const SizedBox(height: 10),
                            ],
                            for (final record in waiting) ...[
                              DoctorAppointmentCard(record: record),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
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
      color: DoctorStyles.mint,
      borderRadius: BorderRadius.circular(30),
      elevation: 4,
      shadowColor: const Color(0x44000000),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('doctor-appointment-${record.id}'),
        borderRadius: BorderRadius.circular(30),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DoctorAppointmentDetailsPage(record: record),
          ),
        ),
        child: SizedBox(
          height: compact ? 72 : 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            child: Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: Image.asset(
                      'assets/photos/logoandphoto/nways_photo.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topRight,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          record.petName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pet Owner : ${record.ownerName}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _AppointmentAction(record: record),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentAction extends StatelessWidget {
  const _AppointmentAction({required this.record});

  final DoctorAppointmentRecord record;

  String get label => switch (record.status) {
    'In Consultation' => 'Finish',
    'Confirmed' || 'Checked In' || 'Called' => 'Start Consulting',
    'Completed' => 'Completed',
    _ => 'In Queue',
  };

  bool get enabled => const {
    'In Consultation',
    'Confirmed',
    'Checked In',
    'Called',
  }.contains(record.status);

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    elevation: 3,
    shadowColor: const Color(0x44000000),
    child: InkWell(
      key: ValueKey('doctor-appointment-action-${record.id}'),
      onTap: enabled ? () => _openConsultation(context) : null,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 117,
        height: 36,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  void _openConsultation(BuildContext context) {
    if (record.status != 'In Consultation') {
      DoctorAppointmentStore.instance.updateStatus(record, 'In Consultation');
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DoctorConsultationPage(record: record),
      ),
    );
  }
}

class _DoctorEmergencyAppointmentCard extends StatelessWidget {
  const _DoctorEmergencyAppointmentCard({required this.request});

  final EmergencyRequest request;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFF1017),
    borderRadius: BorderRadius.circular(30),
    elevation: 4,
    shadowColor: const Color(0x44000000),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const DoctorEmergencyCasesPage(),
        ),
      ),
      child: SizedBox(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: Image.asset(
                    'assets/photos/logoandphoto/nways_photo.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topRight,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.pet.name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Pet Owner : ${request.contactPerson}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 117,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text('Emergency'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
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
