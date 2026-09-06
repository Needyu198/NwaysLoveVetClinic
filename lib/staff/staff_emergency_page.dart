part of 'staff_portal.dart';

class StaffEmergencyPage extends StatefulWidget {
  const StaffEmergencyPage({super.key});

  @override
  State<StaffEmergencyPage> createState() => _StaffEmergencyPageState();
}

class _StaffEmergencyPageState extends State<StaffEmergencyPage> {
  String _filter = 'All';

  static const _filters = ['All', 'New', 'Reviewing', 'Accepted', 'Arrived'];

  bool _matches(EmergencyRequest r, String filter) => switch (filter) {
    'All' => true,
    'New' => r.status == EmergencyStatus.submitted,
    'Reviewing' => r.status == EmergencyStatus.underReview,
    'Accepted' => r.status == EmergencyStatus.accepted,
    'Arrived' => r.status == EmergencyStatus.checkedIn,
    _ => true,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    body: Column(
      children: [
        const _StaffMintHeader(
          title: 'Emergency Cases',
          subtitle: 'Review and coordinate urgent care',
          icon: Icons.emergency_outlined,
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: EmergencyRequestStore.instance,
            builder: (_, _) {
              final all = EmergencyRequestStore.instance.requests;
              final requests = all.where((r) => _matches(r, _filter)).toList();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
                    child: SizedBox(
                      height: 42,
                      child: ListView.separated(
                        key: const ValueKey('staff-emergency-filters'),
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final value = _filters[index];
                          return _EmergencyFilterChip(
                            label: value,
                            count: all.where((r) => _matches(r, value)).length,
                            selected: _filter == value,
                            onTap: () => setState(() => _filter = value),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: requests.isEmpty
                        ? const _StaffEmptyState(
                            icon: Icons.emergency_outlined,
                            title: 'No emergency cases',
                            message:
                                'Submitted owner emergencies will appear here.',
                          )
                        : ListView.separated(
                            key: const ValueKey('staff-emergency-list'),
                            padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                            itemCount: requests.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 14),
                            itemBuilder: (_, i) =>
                                _EmergencyCard(request: requests[i]),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _EmergencyFilterChip extends StatelessWidget {
  const _EmergencyFilterChip({
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
      key: ValueKey('staff-emergency-filter-$label'),
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

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.request});
  final EmergencyRequest request;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFFC7C9)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFFFE9EA),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFFF6B72),
                foregroundColor: Colors.white,
                child: Icon(Icons.emergency_rounded, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      request.contactPerson,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _emergencyLabel(request.status),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _red,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (request.priority.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.priority_high_rounded,
                        size: 16,
                        color: _red,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${request.priority} priority',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _red,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (request.symptoms.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in request.symptoms)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB3261E),
                          ),
                        ),
                      ),
                  ],
                ),
              if (request.description.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(request.description, style: const TextStyle(height: 1.4)),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 15, color: _muted),
                  const SizedBox(width: 6),
                  Text(
                    request.phone,
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        _notice(context, 'Calling ${request.phone}…'),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Call owner'),
                  ),
                  if (request.status == EmergencyStatus.submitted)
                    FilledButton(
                      key: ValueKey('emergency-review-${request.id}'),
                      onPressed: () =>
                          EmergencyRequestStore.instance.staffUpdate(
                            request,
                            EmergencyStatus.underReview,
                            priority: 'High',
                          ),
                      child: const Text('Start review'),
                    ),
                  if (request.status == EmergencyStatus.underReview)
                    FilledButton(
                      key: ValueKey('emergency-accept-${request.id}'),
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
                      key: ValueKey('emergency-arrived-${request.id}'),
                      onPressed: () => EmergencyRequestStore.instance
                          .staffUpdate(request, EmergencyStatus.checkedIn),
                      child: const Text('Mark arrived'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
