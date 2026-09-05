part of 'system_admin_portal.dart';

class _AdminManagementTab extends StatelessWidget {
  const _AdminManagementTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _AdminSimpleHeader(title: 'Management'),
        Expanded(
          child: AnimatedBuilder(
            animation: AppointmentStore.instance,
            builder: (context, _) {
              final appointments = AppointmentStore.instance.appointments;
              if (appointments.isEmpty) {
                return const _AdminEmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'No bookings yet',
                  message: 'Bookings across the clinic will appear here.',
                );
              }
              return ListView.separated(
                key: const ValueKey('system-admin-bookings'),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                itemCount: appointments.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _AdminAppointmentCard(appointment: appointments[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdminAppointmentCard extends StatelessWidget {
  const _AdminAppointmentCard({required this.appointment});

  final BookedAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final emergency = appointment.status == 'Waiting';
    final cardColor = emergency ? _adminEmergencyRed : _adminSoftMint;
    final primaryText = emergency ? Colors.white : Colors.black;
    final subText = emergency ? Colors.white70 : _adminMuted;
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/photos/logoandphoto/nways_photo.png',
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  alignment: Alignment.topRight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${appointment.time} . ${appointment.pet.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lynn Htet . ${appointment.service.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: subText, fontSize: 12),
                    ),
                    Text(
                      appointment.veterinarian,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: subText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _statusLabel(appointment.status),
                    style: TextStyle(
                      color: emergency
                          ? const Color(0xFFFFE14D)
                          : _statusColor(appointment.status),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: primaryText,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'Checked In' => 'Checked in',
    'In Consultation' => 'In consult',
    _ => status,
  };

  Color _statusColor(String status) => switch (status) {
    'Pending' => const Color(0xFF9A5B00),
    'Confirmed' => const Color(0xFF2358A5),
    'Checked In' || 'Called' || 'In Consultation' => const Color(0xFF2358A5),
    'Completed' => const Color(0xFF4D625A),
    _ => _adminGreen,
  };
}
