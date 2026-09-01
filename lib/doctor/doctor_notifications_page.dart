part of 'doctor_portal.dart';

class DoctorNotificationsPage extends StatelessWidget {
  const DoctorNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DoctorStyles.page,
    appBar: AppBar(
      title: const Text('Doctor Notifications'),
      backgroundColor: DoctorStyles.mint,
      actions: [
        TextButton(
          onPressed: DoctorNotificationStore.instance.markAllRead,
          child: const Text('Mark all read'),
        ),
      ],
    ),
    body: AnimatedBuilder(
      animation: Listenable.merge([
        DoctorNotificationStore.instance,
        AppointmentStore.instance,
        EmergencyRequestStore.instance,
        HomeVisitStore.instance,
        ContactClinicStore.instance,
      ]),
      builder: (context, _) {
        final generated = <(String, String)>[
          if (AppointmentStore.instance.appointments.any(
            (appointment) => appointment.status == 'Pending',
          ))
            ('New appointment request', 'A booking is waiting for review.'),
          if (AppointmentStore.instance.appointments.any(
            (appointment) => appointment.status == 'Cancelled',
          ))
            ('Cancelled appointment', 'A pet owner cancelled a booking.'),
          if (AppointmentStore.instance.appointments.any(
            (appointment) => appointment.status == 'Reschedule Requested',
          ))
            (
              'Rescheduled appointment',
              'A schedule change is waiting for review.',
            ),
          if (EmergencyRequestStore.instance.requests.any(
            (request) => request.status == EmergencyStatus.submitted,
          ))
            ('New emergency request', 'Review and prioritize the emergency.'),
          if (HomeVisitStore.instance.visits.any(
            (visit) => visit.status == HomeVisitStatus.confirmed,
          ))
            ('Upcoming Home Visit', 'A confirmed Home Visit is scheduled.'),
          if (QueueStore.instance.active.any(
            (entry) =>
                entry.status == QueueStatus.called ||
                entry.status == QueueStatus.almostTurn,
          ))
            ('Queue update', 'A patient is ready to be called or consulted.'),
          if (DoctorMedicalRecordStore.instance.records.any(
            (record) => record.finalized && record.followUp.isNotEmpty,
          ))
            ('Follow-up reminder', 'A finalized record recommends follow-up.'),
          if (ContactClinicStore.instance.messages.any(
            (message) => !message.isFromStaff,
          ))
            ('Pet owner message', 'A new clinic message needs a response.'),
        ];
        final saved = DoctorNotificationStore.instance.notifications;
        if (generated.isEmpty && saved.isEmpty) {
          return const _EmptyDoctorState(
            icon: Icons.notifications_none_rounded,
            title: 'No notifications',
            message: 'Clinical and booking alerts will appear here.',
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final item in generated)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(item.$1),
                  subtitle: Text(item.$2),
                ),
              ),
            for (final item in saved)
              Card(
                child: ListTile(
                  leading: Icon(
                    item.read
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_rounded,
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.message),
                ),
              ),
          ],
        );
      },
    ),
  );
}
