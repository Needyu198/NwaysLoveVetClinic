part of 'staff_portal.dart';

class StaffEmergencyPage extends StatelessWidget {
  const StaffEmergencyPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    appBar: _appBar('Emergency Requests', color: const Color(0xFFFFC7C9)),
    body: AnimatedBuilder(
      animation: EmergencyRequestStore.instance,
      builder: (_, _) {
        final requests = EmergencyRequestStore.instance.requests;
        if (requests.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(18),
            children: const [
              _Callout(
                icon: Icons.emergency_rounded,
                text:
                    'No submitted owner requests. The urgent live-queue case remains visible in Queue.',
              ),
            ],
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final request = requests[i];
            return _EmergencyCard(request: request);
          },
        );
      },
    ),
  );
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.request});
  final EmergencyRequest request;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(border: _red),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emergency_rounded, color: _red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${request.pet.name} • ${request.contactPerson}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              _emergencyLabel(request.status),
              style: const TextStyle(color: _red, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${request.symptoms.join(', ')}\n${request.description}\n${request.phone}',
          style: const TextStyle(height: 1.4),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _notice(context, 'Calling ${request.phone}…'),
              icon: const Icon(Icons.call_outlined),
              label: const Text('Call owner'),
            ),
            if (request.status == EmergencyStatus.submitted)
              FilledButton(
                onPressed: () => EmergencyRequestStore.instance.staffUpdate(
                  request,
                  EmergencyStatus.underReview,
                  priority: 'High',
                ),
                child: const Text('Start review'),
              ),
            if (request.status == EmergencyStatus.underReview)
              FilledButton(
                onPressed: () => EmergencyRequestStore.instance.staffUpdate(
                  request,
                  EmergencyStatus.accepted,
                  response:
                      'Dr. Aye Chan assigned. Please travel to the clinic now.',
                ),
                child: const Text('Assign & accept'),
              ),
            if (request.status == EmergencyStatus.accepted)
              FilledButton(
                onPressed: () => EmergencyRequestStore.instance.staffUpdate(
                  request,
                  EmergencyStatus.checkedIn,
                ),
                child: const Text('Mark arrived'),
              ),
          ],
        ),
      ],
    ),
  );
}
