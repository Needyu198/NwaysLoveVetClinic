part of 'doctor_portal.dart';

class DoctorQueuePage extends StatelessWidget {
  const DoctorQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _DoctorSubpageHeader(title: 'Patient Queue'),
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  DoctorAppointmentStore.instance,
                  AppointmentStore.instance,
                  QueueStore.instance,
                ]),
                builder: (context, _) {
                  final doctorRecords =
                      DoctorAppointmentStore.instance.appointments;
                  final tickets =
                      QueueStore.instance.active
                          .where(
                            (entry) =>
                                DateUtils.isSameDay(
                                  entry.clinicDate,
                                  DateTime.now(),
                                ) &&
                                (entry.assignedDoctor.isEmpty ||
                                    entry.assignedDoctor ==
                                        DoctorAppointmentStore.doctorName),
                          )
                          .toList()
                        ..sort((a, b) {
                          if (a.priority != b.priority) {
                            return a.priority == 'urgent' ? -1 : 1;
                          }
                          return a.sequence.compareTo(b.sequence);
                        });
                  final queue = <(DoctorAppointmentRecord, QueueEntry?)>[];
                  for (final ticket in tickets) {
                    final record = doctorRecords
                        .cast<DoctorAppointmentRecord?>()
                        .firstWhere(
                          (item) => item?.id == ticket.appointment.id,
                          orElse: () => null,
                        );
                    if (record != null) queue.add((record, ticket));
                  }
                  if (queue.isEmpty && ClinicApi.instance.token == null) {
                    queue.addAll(
                      doctorRecords
                          .where(
                            (record) =>
                                DateUtils.isSameDay(
                                  record.date,
                                  DateTime.now(),
                                ) &&
                                !const {
                                  'Completed',
                                  'Cancelled',
                                  'Rejected',
                                  'Missed',
                                }.contains(record.status),
                          )
                          .map((record) => (record, null)),
                    );
                  }
                  if (queue.isEmpty) {
                    return const _EmptyDoctorState(
                      icon: Icons.groups_2_outlined,
                      title: 'Queue is clear',
                      message: 'Waiting and called patients will appear here.',
                    );
                  }
                  final called = queue.where(
                    (item) =>
                        item.$2?.status == QueueStatus.called ||
                        item.$1.status == 'Called',
                  );
                  final canCallNext = called.isEmpty;
                  return ListView.separated(
                    key: const ValueKey('doctor-patient-queue'),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    itemCount: queue.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _QueueSummaryCard(
                          total: queue.length,
                          called: called.length,
                        );
                      }
                      final queueIndex = index - 1;
                      final (record, ticket) = queue[queueIndex];
                      final displayStatus = ticket == null
                          ? const {
                                  'Pending',
                                  'Confirmed',
                                }.contains(record.status)
                                ? 'Waiting'
                                : record.status
                          : _doctorQueueStatusLabel(ticket.status);
                      return _DoctorQueueCard(
                        record: record,
                        ticket: ticket,
                        fallbackPosition: queueIndex + 1,
                        displayStatus: displayStatus,
                        canCall:
                            displayStatus == 'Waiting' &&
                            canCallNext &&
                            queueIndex == 0,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueSummaryCard extends StatelessWidget {
  const _QueueSummaryCard({required this.total, required this.called});

  final int total;
  final int called;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
    decoration: BoxDecoration(
      color: DoctorStyles.mint,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Row(
      children: [
        const Icon(Icons.groups_2_outlined, size: 34),
        const SizedBox(width: 13),
        const Expanded(
          child: Text(
            "Today's Queue",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          '$total waiting • $called called',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _DoctorQueueCard extends StatelessWidget {
  const _DoctorQueueCard({
    required this.record,
    required this.ticket,
    required this.fallbackPosition,
    required this.displayStatus,
    required this.canCall,
  });

  final DoctorAppointmentRecord record;
  final QueueEntry? ticket;
  final int fallbackPosition;
  final String displayStatus;
  final bool canCall;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: DoctorStyles.mint,
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 7,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                ticket?.queueNumber ?? 'Q$fallbackPosition',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.petName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${record.time} • ${record.service}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DoctorStyles.muted,
                  ),
                ],
              ),
            ),
            _StatusBadge(status: displayStatus),
          ],
        ),
        if (ticket?.status != QueueStatus.inConsultation &&
            record.status != 'In Consultation') ...[
          const SizedBox(height: 13),
          Row(
            children: [
              if (canCall)
                Expanded(
                  child: FilledButton.icon(
                    key: ValueKey('doctor-call-${record.id}'),
                    onPressed: () {
                      final value = ticket;
                      if (value == null) {
                        DoctorAppointmentStore.instance.updateStatus(
                          record,
                          'Called',
                        );
                      } else {
                        unawaited(
                          QueueStore.instance.transition(
                            value,
                            QueueStatus.called,
                            room: value.room.isEmpty
                                ? 'Consultation Room 2'
                                : value.room,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('Call Next'),
                    style: _queueFilledStyle(),
                  ),
                ),
              if (ticket?.status == QueueStatus.called ||
                  ticket?.status == QueueStatus.arrived ||
                  record.status == 'Called')
                Expanded(
                  child: FilledButton.icon(
                    key: ValueKey('doctor-queue-start-${record.id}'),
                    onPressed: () {
                      final value = ticket;
                      if (value == null) {
                        DoctorAppointmentStore.instance.updateStatus(
                          record,
                          'In Consultation',
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                DoctorConsultationPage(record: record),
                          ),
                        );
                        return;
                      }
                      final confirmingArrival =
                          value.status == QueueStatus.called;
                      unawaited(
                        QueueStore.instance.transition(
                          value,
                          confirmingArrival
                              ? QueueStatus.arrived
                              : QueueStatus.inConsultation,
                        ),
                      );
                      if (confirmingArrival) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              DoctorConsultationPage(record: record),
                        ),
                      );
                    },
                    icon: const Icon(Icons.medical_services_outlined),
                    label: Text(
                      ticket?.status == QueueStatus.called
                          ? 'Confirm Arrival'
                          : 'Start Consultation',
                    ),
                    style: _queueFilledStyle(),
                  ),
                ),
              if (canCall ||
                  ticket?.status == QueueStatus.called ||
                  ticket?.status == QueueStatus.arrived ||
                  record.status == 'Called')
                const SizedBox(width: 8),
              OutlinedButton(
                key: ValueKey('doctor-missed-${record.id}'),
                onPressed: () {
                  final value = ticket;
                  if (value == null) {
                    DoctorAppointmentStore.instance.updateStatus(
                      record,
                      'Missed',
                    );
                  } else {
                    unawaited(
                      QueueStore.instance.transition(value, QueueStatus.missed),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB3261E),
                  side: const BorderSide(color: Color(0xFFB3261E)),
                  minimumSize: const Size(94, 48),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Missed'),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

ButtonStyle _queueFilledStyle() => FilledButton.styleFrom(
  backgroundColor: Colors.white,
  foregroundColor: Colors.black,
  minimumSize: const Size.fromHeight(48),
  shape: const StadiumBorder(),
  textStyle: const TextStyle(fontWeight: FontWeight.w800),
);

String _doctorQueueStatusLabel(QueueStatus status) => switch (status) {
  QueueStatus.waiting => 'Waiting',
  QueueStatus.called => 'Called',
  QueueStatus.arrived => 'Arrived',
  QueueStatus.inConsultation => 'In Consultation',
  QueueStatus.completed => 'Completed',
  QueueStatus.missed => 'Missed',
  QueueStatus.cancelled => 'Cancelled',
};
