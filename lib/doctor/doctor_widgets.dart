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
    required this.color,
    required this.onTap,
    this.horizontal = false,
    this.large = false,
    super.key,
  });

  final String label;
  final String value;
  final Color color;
  final bool horizontal;
  final bool large;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(22),
    elevation: 5,
    shadowColor: const Color(0x55000000),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal ? 14 : 6,
          vertical: 8,
        ),
        child: horizontal
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: large ? 48 : 29,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: large ? 15 : 7),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: large ? 16 : 14,
                        height: 1.15,
                      ),
                    ),
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
    height: 86,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: DoctorStyles.mint,
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 7,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 58,
            height: 58,
            child: Image.asset(
              'assets/photos/logoandphoto/nways_photo.png',
              fit: BoxFit.cover,
              alignment: Alignment.topRight,
            ),
          ),
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pet Owner : ${record.ownerName}',
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          elevation: 4,
          shadowColor: const Color(0x55000000),
          child: InkWell(
            key: canStart ? ValueKey('start-consulting-${record.id}') : null,
            onTap: canStart
                ? () {
                    DoctorAppointmentStore.instance.updateStatus(
                      record,
                      'In Consultation',
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DoctorConsultationPage(record: record),
                      ),
                    );
                  }
                : null,
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              width: canStart ? 122 : 110,
              height: 42,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      canStart ? 'Start Consulting' : 'In Queue',
                      style: const TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
