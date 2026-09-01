part of 'doctor_portal.dart';

class DoctorQueuePage extends StatelessWidget {
  const DoctorQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.page,
      appBar: AppBar(
        title: const Text('Patient Queue'),
        backgroundColor: DoctorStyles.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          DoctorAppointmentStore.instance,
          AppointmentStore.instance,
          QueueStore.instance,
        ]),
        builder: (context, _) {
          final queue = DoctorAppointmentStore.instance.appointments
              .where(
                (record) =>
                    DateUtils.isSameDay(record.date, DateTime.now()) &&
                    !const {
                      'Completed',
                      'Cancelled',
                      'Rejected',
                      'Missed',
                    }.contains(record.status),
              )
              .toList();
          if (queue.isEmpty) {
            return const _EmptyDoctorState(
              icon: Icons.groups_2_outlined,
              title: 'Queue is clear',
              message: 'Waiting and called patients will appear here.',
            );
          }
          final called = queue.where((record) => record.status == 'Called');
          final canCallNext = called.isEmpty;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            itemCount: queue.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final record = queue[index];
              final displayStatus =
                  const {'Pending', 'Confirmed'}.contains(record.status)
                  ? 'Waiting'
                  : record.status;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: DoctorStyles.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: DoctorStyles.softMint,
                          child: Text('Q${index + 1}'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.petName,
                                style: DoctorStyles.cardTitle,
                              ),
                              Text(
                                '${record.time} • ${record.service}',
                                style: DoctorStyles.muted,
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: displayStatus),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (displayStatus == 'Waiting' &&
                            canCallNext &&
                            index == 0)
                          Expanded(
                            child: FilledButton.icon(
                              key: ValueKey('doctor-call-${record.id}'),
                              onPressed: () => DoctorAppointmentStore.instance
                                  .updateStatus(record, 'Called'),
                              icon: const Icon(Icons.campaign_outlined),
                              label: const Text('Call Next'),
                            ),
                          ),
                        if (record.status == 'Called')
                          Expanded(
                            child: FilledButton.icon(
                              key: ValueKey('doctor-queue-start-${record.id}'),
                              onPressed: () {
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
                              },
                              icon: const Icon(Icons.medical_services_outlined),
                              label: const Text('Start Consultation'),
                            ),
                          ),
                        if (record.status != 'In Consultation') ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            key: ValueKey('doctor-missed-${record.id}'),
                            onPressed: () => DoctorAppointmentStore.instance
                                .updateStatus(record, 'Missed'),
                            child: const Text('Missed'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
