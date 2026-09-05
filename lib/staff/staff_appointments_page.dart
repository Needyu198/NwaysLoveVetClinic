part of 'staff_portal.dart';

class StaffAppointmentsPage extends StatefulWidget {
  const StaffAppointmentsPage({
    this.initialFilter,
    this.standalone = false,
    super.key,
  });
  final String? initialFilter;
  final bool standalone;
  @override
  State<StaffAppointmentsPage> createState() => _StaffAppointmentsPageState();
}

class _StaffAppointmentsPageState extends State<StaffAppointmentsPage> {
  late String _filter = widget.initialFilter ?? 'All';
  String _query = '';
  @override
  Widget build(BuildContext context) => _StaffScaffold(
    title: 'Appointments',
    onBack: widget.standalone ? () => Navigator.pop(context) : null,
    child: AnimatedBuilder(
      animation: Listenable.merge([
        StaffOperationsStore.instance,
        AppointmentStore.instance,
      ]),
      builder: (context, _) {
        var items = StaffOperationsStore.instance.appointments;
        items = items.where((a) {
          final matchesQuery =
              '${a.id} ${a.pet} ${a.owner} ${a.doctor} ${a.service}'
                  .toLowerCase()
                  .contains(_query.toLowerCase());
          final matchesFilter =
              _filter == 'All' ||
              (_filter == 'Today'
                  ? DateUtils.isSameDay(a.date, DateTime.now())
                  : a.status == _filter);
          return matchesQuery && matchesFilter;
        }).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: TextField(
                key: const ValueKey('staff-appointment-search'),
                onChanged: (value) => setState(() => _query = value),
                decoration: _input(
                  'Search ID, owner, pet or doctor',
                  Icons.search_rounded,
                ),
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children:
                    [
                          'All',
                          'Today',
                          'Pending',
                          'Confirmed',
                          'Waiting',
                          'Completed',
                          'Cancelled',
                        ]
                        .map(
                          (value) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(value),
                              selected: _filter == value,
                              selectedColor: _mint,
                              onSelected: (_) =>
                                  setState(() => _filter = value),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No matching appointments'))
                  : ListView.separated(
                      key: const ValueKey('staff-appointments'),
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => _AppointmentTile(
                        item: items[index],
                        onTap: () => _push(
                          context,
                          StaffAppointmentDetailsPage(item: items[index]),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    ),
  );
}

class StaffAppointmentDetailsPage extends StatelessWidget {
  const StaffAppointmentDetailsPage({required this.item, super.key});
  final StaffAppointment item;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: StaffOperationsStore.instance,
    builder: (context, _) => Scaffold(
      backgroundColor: _page,
      appBar: _appBar('Appointment Details'),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _StatusBanner(status: item.status, priority: item.priority),
          const SizedBox(height: 14),
          _InfoCard(
            rows: [
              ('Booking ID', item.id),
              ('Pet', item.pet),
              ('Owner', item.owner),
              ('Contact', item.phone),
              ('Service', item.service),
              ('Reason', item.reason),
              ('Date', _shortDate(item.date)),
              ('Time', item.time),
              ('Doctor', item.doctor),
              if (item.queueNumber.isNotEmpty) ('Queue', item.queueNumber),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Management actions', style: _sectionStyle),
          const SizedBox(height: 10),
          if (item.status == 'Pending')
            _ActionButton(
              label: 'Confirm Appointment',
              icon: Icons.event_available_rounded,
              onTap: () {
                StaffOperationsStore.instance.update(item, status: 'Confirmed');
                _notice(context, 'Appointment confirmed and owner notified.');
              },
            ),
          if (const {'Pending', 'Confirmed'}.contains(item.status))
            _ActionButton(
              label: 'Assign Doctor',
              icon: Icons.medical_services_outlined,
              onTap: () => _chooseDoctor(context, item),
            ),
          if (const {'Pending', 'Confirmed'}.contains(item.status))
            _ActionButton(
              label: 'Reschedule',
              icon: Icons.edit_calendar_outlined,
              onTap: () => _reschedule(context, item),
            ),
          if (const {'Pending', 'Confirmed'}.contains(item.status))
            _ActionButton(
              label: 'Cancel Appointment',
              icon: Icons.cancel_outlined,
              destructive: true,
              onTap: () => _cancel(context, item),
            ),
          if (item.status == 'Waiting')
            _ActionButton(
              label: 'Open Live Queue',
              icon: Icons.format_list_numbered_rounded,
              onTap: () => _push(context, const StaffQueueStandalonePage()),
            ),
        ],
      ),
    ),
  );
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.item, required this.onTap});
  final StaffAppointment item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item.priority == 'Urgent'
                    ? const Color(0xFFFFE4E5)
                    : const Color(0xFFE6FAF2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item.priority == 'Urgent'
                    ? Icons.emergency_rounded
                    : Icons.pets_rounded,
                color: item.priority == 'Urgent' ? _red : _green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.time} • ${item.pet}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.owner} • ${item.service}\n${item.doctor}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _statusColor(item.status),
                  ),
                ),
                const SizedBox(height: 10),
                const Icon(Icons.chevron_right_rounded, color: _muted),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status, required this.priority});
  final String status;
  final String priority;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: priority == 'Urgent'
          ? const Color(0xFFFFE4E5)
          : const Color(0xFFE6FAF2),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(
          priority == 'Urgent'
              ? Icons.emergency_rounded
              : Icons.event_available_rounded,
          color: priority == 'Urgent' ? _red : _green,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            status,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          '$priority priority',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: SizedBox(
      width: double.infinity,
      child: destructive
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(label),
              style: OutlinedButton.styleFrom(foregroundColor: _red),
            )
          : FilledButton.icon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(label),
            ),
    ),
  );
}

Future<void> _chooseDoctor(BuildContext context, StaffAppointment item) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              'Assign an available doctor',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          ..._doctors.map(
            (doctor) => ListTile(
              leading: const CircleAvatar(
                backgroundColor: _mint,
                child: Icon(Icons.medical_services_outlined),
              ),
              title: Text(doctor),
              subtitle: const Text('Available'),
              onTap: () => Navigator.pop(context, doctor),
            ),
          ),
        ],
      ),
    ),
  );
  if (choice != null) {
    StaffOperationsStore.instance.update(item, doctor: choice);
    if (context.mounted) _notice(context, '$choice assigned and notified.');
  }
}

Future<void> _reschedule(BuildContext context, StaffAppointment item) async {
  final date = await showDatePicker(
    context: context,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 120)),
    initialDate: item.date.isBefore(DateTime.now())
        ? DateTime.now()
        : item.date,
  );
  if (date == null || !context.mounted) return;
  final time = await showTimePicker(
    context: context,
    initialTime: const TimeOfDay(hour: 10, minute: 0),
  );
  if (time == null || !context.mounted) return;
  StaffOperationsStore.instance.update(
    item,
    date: date,
    time: time.format(context),
    status: 'Confirmed',
  );
  _notice(context, 'Appointment rescheduled. Owner and doctor notified.');
}

Future<void> _cancel(BuildContext context, StaffAppointment item) async {
  final controller = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cancel appointment?'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 2,
        decoration: _input('Cancellation reason', Icons.notes_rounded),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Keep'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(dialogContext, controller.text.trim());
            }
          },
          style: FilledButton.styleFrom(backgroundColor: _red),
          child: const Text('Cancel appointment'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (reason == null) return;
  if (item.source != null) {
    AppointmentStore.instance.cancelWithDetails(
      item.source!,
      reason: reason,
      initiatedBy: CancellationInitiator.staff,
    );
    StaffOperationsStore.instance.update(item, status: item.source!.status);
  } else {
    StaffOperationsStore.instance.update(item, status: 'Cancelled');
  }
  if (context.mounted) {
    _notice(
      context,
      'Appointment cancelled. Slot released and audit recorded.',
    );
  }
}
