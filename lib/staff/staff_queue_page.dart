part of 'staff_portal.dart';

class StaffQueuePage extends StatelessWidget {
  const StaffQueuePage({super.key});
  @override
  Widget build(BuildContext context) => const _QueueBody(withAppBar: true);
}

class StaffQueueStandalonePage extends StatelessWidget {
  const StaffQueueStandalonePage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: _page,
    body: SafeArea(child: _QueueBody(withAppBar: false)),
  );
}

class _QueueBody extends StatefulWidget {
  const _QueueBody({required this.withAppBar});
  final bool withAppBar;
  @override
  State<_QueueBody> createState() => _QueueBodyState();
}

class _QueueBodyState extends State<_QueueBody> {
  var _filter = 'All';
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: StaffOperationsStore.instance,
    builder: (context, _) {
      var entries = StaffOperationsStore.instance.appointments
          .where(
            (a) =>
                a.queueNumber.isNotEmpty &&
                !const {'Completed', 'Missed', 'Cancelled'}.contains(a.status),
          )
          .toList();
      entries.sort(
        (a, b) => a.priority == b.priority
            ? a.queueNumber.compareTo(b.queueNumber)
            : (a.priority == 'Urgent' ? -1 : 1),
      );
      if (_filter != 'All') {
        entries = entries
            .where((a) => a.status == _filter || a.priority == _filter)
            .toList();
      }
      final body = Column(
        children: [
          if (widget.withAppBar)
            const _InlineHeader(
              title: 'Live Queue',
              subtitle: 'Emergency cases are shown first',
            ),
          if (!widget.withAppBar)
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Text('Live Queue', style: _titleStyle),
              ],
            ),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children:
                  ['All', 'Urgent', 'Waiting', 'Called', 'In Consultation']
                      .map(
                        (value) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(value),
                            selected: _filter == value,
                            selectedColor: _mint,
                            onSelected: (_) => setState(() => _filter = value),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('No patients in the live queue'))
                : ListView.separated(
                    key: const ValueKey('staff-queue'),
                    padding: const EdgeInsets.all(18),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) => _QueueCard(item: entries[index]),
                  ),
          ),
        ],
      );
      return widget.withAppBar ? SafeArea(child: body) : body;
    },
  );
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.item});
  final StaffAppointment item;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(
      border: item.priority == 'Urgent' ? _red : _border,
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.priority == 'Urgent'
                    ? const Color(0xFFFFE4E5)
                    : const Color(0xFFE6FAF2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                item.queueNumber,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: item.priority == 'Urgent' ? _red : _green,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.pet} • ${item.owner}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${item.doctor}\n${item.status}',
                    style: const TextStyle(color: _muted, height: 1.4),
                  ),
                ],
              ),
            ),
            if (item.priority == 'Urgent')
              const Chip(
                label: Text('URGENT'),
                backgroundColor: Color(0xFFFFC7C9),
              ),
          ],
        ),
        const Divider(height: 24),
        Row(
          children: [
            if (item.status == 'Waiting')
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    // update(status: 'Called') already notifies the owner.
                    StaffOperationsStore.instance.update(
                      item,
                      status: 'Called',
                    );
                    _notice(
                      context,
                      '${item.queueNumber} called. Owner notified.',
                    );
                  },
                  icon: const Icon(Icons.campaign_rounded),
                  label: const Text('Call Patient'),
                ),
              ),
            if (item.status == 'Called')
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => StaffOperationsStore.instance.update(
                    item,
                    status: 'In Consultation',
                  ),
                  icon: const Icon(Icons.meeting_room_outlined),
                  label: const Text('Room arrived'),
                ),
              ),
            if (item.status == 'In Consultation')
              const Expanded(
                child: Text(
                  'Consultation in progress',
                  style: TextStyle(color: _green, fontWeight: FontWeight.w800),
                ),
              ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'Missed') {
                  StaffOperationsStore.instance.update(item, status: 'Missed');
                }
                if (value == 'Reassign') _chooseDoctor(context, item);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'Reassign',
                  child: Text('Reassign doctor'),
                ),
                PopupMenuItem(value: 'Missed', child: Text('Mark missed')),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
