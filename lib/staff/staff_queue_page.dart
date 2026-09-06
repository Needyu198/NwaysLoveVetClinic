part of 'staff_portal.dart';

class StaffQueuePage extends StatelessWidget {
  const StaffQueuePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: Colors.white, body: _QueueBody());
}

class StaffQueueStandalonePage extends StatelessWidget {
  const StaffQueueStandalonePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: Colors.white, body: _QueueBody());
}

class _QueueBody extends StatefulWidget {
  const _QueueBody();
  @override
  State<_QueueBody> createState() => _QueueBodyState();
}

class _QueueBodyState extends State<_QueueBody> {
  String _filter = 'All';

  // Chip label -> matcher. 'Consulting' maps to the 'In Consultation' status.
  static const _filters = ['All', 'Urgent', 'Waiting', 'Called', 'Consulting'];

  bool _matches(StaffAppointment a, String filter) => switch (filter) {
    'All' => true,
    'Urgent' => a.priority == 'Urgent',
    'Consulting' => a.status == 'In Consultation',
    _ => a.status == filter,
  };

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const _QueueHeader(),
      Expanded(
        child: AnimatedBuilder(
          animation: StaffOperationsStore.instance,
          builder: (context, _) {
            final all =
                StaffOperationsStore.instance.appointments
                    .where(
                      (a) =>
                          a.queueNumber.isNotEmpty &&
                          !const {
                            'Completed',
                            'Missed',
                            'Cancelled',
                          }.contains(a.status),
                    )
                    .toList()
                  ..sort(
                    (a, b) => a.priority == b.priority
                        ? a.queueNumber.compareTo(b.queueNumber)
                        : (a.priority == 'Urgent' ? -1 : 1),
                  );
            final entries = all.where((a) => _matches(a, _filter)).toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                  child: SizedBox(
                    height: 42,
                    child: ListView.separated(
                      key: const ValueKey('staff-queue-filters'),
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final value = _filters[index];
                        return _QueueFilterChip(
                          label: value,
                          selected: _filter == value,
                          onTap: () => setState(() => _filter = value),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? const _QueueEmpty()
                      : ListView.separated(
                          key: const ValueKey('staff-queue'),
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                          itemCount: entries.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (_, index) =>
                              _QueueCard(item: entries[index]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    ],
  );
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader();

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.chevron_left_rounded, size: 30),
          ),
          const Expanded(
            child: Text(
              'Live Queue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: _ink,
              ),
            ),
          ),
          Image.asset(
            'assets/photos/logoandphoto/nways_love_logo.png',
            width: 52,
            height: 52,
            fit: BoxFit.contain,
          ),
        ],
      ),
    ),
  );
}

class _QueueFilterChip extends StatelessWidget {
  const _QueueFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFF5C518) : _mint,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('staff-queue-filter-$label'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}

class _QueueEmpty extends StatelessWidget {
  const _QueueEmpty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.groups_rounded, size: 52, color: _muted),
          SizedBox(height: 12),
          Text(
            'No patients in the live queue',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4),
          Text(
            'Checked-in patients will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
          ),
        ],
      ),
    ),
  );
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.item});
  final StaffAppointment item;

  bool get _urgent => item.priority == 'Urgent';

  (String, Color, Color) get _statusStyle {
    if (_urgent) {
      return ('Urgent', _red, const Color(0xFFFFD9DC));
    }
    return switch (item.status) {
      'In Consultation' => (
        'Consulting',
        Colors.black,
        const Color(0xFFF5C518),
      ),
      'Called' => ('Called', const Color(0xFF2358A5), const Color(0xFFD7E6FF)),
      _ => ('Waiting', _green, _mint),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusText, statusBg) = _statusStyle;
    final showCall = item.status == 'Waiting';
    final showArrived = item.status == 'Called';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _urgent ? const Color(0xFFFF6B72) : _mint,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  item.queueNumber,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _urgent ? Colors.white : _green,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.pet} . ${item.owner}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.doctor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusText,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (_urgent) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Waiting',
                      style: TextStyle(color: _ink, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const Divider(height: 22),
          if (showCall)
            _QueueActionButton(
              key: ValueKey('queue-call-${item.id}'),
              label: 'Call Patient',
              onTap: () {
                StaffOperationsStore.instance.update(item, status: 'Called');
                _notice(context, '${item.queueNumber} called. Owner notified.');
              },
            )
          else if (showArrived)
            _QueueActionButton(
              key: ValueKey('queue-arrived-${item.id}'),
              label: 'Room Arrived',
              onTap: () => StaffOperationsStore.instance.update(
                item,
                status: 'In Consultation',
              ),
            )
          else
            _QueueOverflowMenu(item: item),
        ],
      ),
    );
  }
}

class _QueueActionButton extends StatelessWidget {
  const _QueueActionButton({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: _mint,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    ),
  );
}

class _QueueOverflowMenu extends StatelessWidget {
  const _QueueOverflowMenu({required this.item});
  final StaffAppointment item;

  @override
  Widget build(BuildContext context) => Center(
    child: PopupMenuButton<String>(
      key: ValueKey('queue-menu-${item.id}'),
      icon: const Icon(Icons.more_horiz_rounded, color: _muted),
      onSelected: (value) {
        if (value == 'Missed') {
          StaffOperationsStore.instance.update(item, status: 'Missed');
        }
        if (value == 'Reassign') _chooseDoctor(context, item);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'Reassign', child: Text('Reassign doctor')),
        PopupMenuItem(value: 'Missed', child: Text('Mark missed')),
      ],
    ),
  );
}
