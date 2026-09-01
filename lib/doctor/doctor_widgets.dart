part of 'doctor_portal.dart';

class _DoctorFunctionButton extends StatelessWidget {
  const _DoctorFunctionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(height: 3),
        FittedBox(child: Text(label)),
      ],
    ),
  );
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    this.horizontal = false,
    this.foregroundColor = DoctorStyles.ink,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color foregroundColor;
  final bool horizontal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color == Colors.white ? DoctorStyles.border : color,
          ),
        ),
        child: horizontal
            ? Row(
                children: [
                  Icon(icon, color: foregroundColor, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: DoctorStyles.body.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    value,
                    style: DoctorStyles.stat.copyWith(color: foregroundColor),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: foregroundColor),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: foregroundColor, size: 28),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: DoctorStyles.stat.copyWith(color: foregroundColor),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: DoctorStyles.muted.copyWith(color: foregroundColor),
                  ),
                ],
              ),
      ),
    ),
  );
}

class _UpNextCard extends StatelessWidget {
  const _UpNextCard({required this.record, required this.canStart});

  final DoctorAppointmentRecord record;
  final bool canStart;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: DoctorStyles.mint,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 7,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 29,
          backgroundColor: Colors.white,
          child: Icon(Icons.pets_rounded, size: 29),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(record.petName, style: DoctorStyles.cardTitle),
              Text('Pet Owner: ${record.ownerName}', style: DoctorStyles.body),
              Text(
                '${record.time} • ${record.service}',
                style: DoctorStyles.muted,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (canStart)
          FilledButton(
            key: ValueKey('start-consulting-${record.id}'),
            onPressed: () {
              DoctorAppointmentStore.instance.updateStatus(
                record,
                'In Consultation',
              );
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DoctorConsultationPage(record: record),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: DoctorStyles.ink,
            ),
            child: const Text('Start Consulting'),
          )
        else
          const Chip(
            label: Text('In Queue'),
            backgroundColor: Colors.white,
            side: BorderSide.none,
          ),
      ],
    ),
  );
}

class _EmergencyQueueCard extends StatelessWidget {
  const _EmergencyQueueCard({required this.request, this.showDetails = false});

  final EmergencyRequest request;
  final bool showDetails;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFE8E9),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: showDetails ? () => _showEmergencyDetails(context) : null,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE92832),
              foregroundColor: Colors.white,
              child: Icon(Icons.emergency_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${request.pet.name} • Emergency',
                    style: DoctorStyles.cardTitle,
                  ),
                  Text(
                    request.symptoms.join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DoctorStyles.body,
                  ),
                  Text(
                    '${request.priority} • ${_emergencyLabel(request.status)}',
                    style: const TextStyle(
                      color: Color(0xFFB3261E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (showDetails) const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );

  void _showEmergencyDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${request.pet.name} Emergency'),
        content: Text(
          'Symptoms: ${request.symptoms.join(', ')}\n\n'
          'Description: ${request.description}\n\n'
          'Contact: ${request.contactPerson} • ${request.phone}\n\n'
          'Status: ${_emergencyLabel(request.status)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Pending' => const Color(0xFF9A5B00),
      'Confirmed' || 'Waiting' => const Color(0xFF176B50),
      'Checked In' || 'Called' || 'In Consultation' => const Color(0xFF2358A5),
      'Completed' => const Color(0xFF4D625A),
      _ => const Color(0xFFB3261E),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DoctorDetailsCard extends StatelessWidget {
  const _DoctorDetailsCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: DoctorStyles.border),
    ),
    child: Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 116,
                child: Text(rows[index].$1, style: DoctorStyles.muted),
              ),
              Expanded(
                child: Text(rows[index].$2, style: DoctorStyles.cardValue),
              ),
            ],
          ),
          if (index != rows.length - 1) const Divider(height: 22),
        ],
      ],
    ),
  );
}

class _DoctorNotice extends StatelessWidget {
  const _DoctorNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: DoctorStyles.softMint,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: DoctorStyles.green),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: DoctorStyles.body)),
      ],
    ),
  );
}

class _EmptyDoctorState extends StatelessWidget {
  const _EmptyDoctorState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: DoctorStyles.green),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: DoctorStyles.section),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center, style: DoctorStyles.muted),
        ],
      ),
    ),
  );
}
