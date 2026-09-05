part of 'staff_portal.dart';

class StaffPatientsPage extends StatefulWidget {
  const StaffPatientsPage({super.key});

  @override
  State<StaffPatientsPage> createState() => _StaffPatientsPageState();
}

class _StaffPatientsPageState extends State<StaffPatientsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    appBar: _appBar('Patients & Owners'),
    body: AnimatedBuilder(
      animation: StaffOperationsStore.instance,
      builder: (context, _) {
        // Latest appointment per pet drives the directory row.
        final byPet = <String, StaffAppointment>{};
        for (final item in StaffOperationsStore.instance.appointments) {
          byPet[item.pet] = item;
        }
        final patients = byPet.values.where((item) {
          final q = _query.trim().toLowerCase();
          if (q.isEmpty) return true;
          return '${item.pet} ${item.owner} ${item.phone}'
              .toLowerCase()
              .contains(q);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: TextField(
                key: const ValueKey('staff-patient-search'),
                onChanged: (value) => setState(() => _query = value),
                decoration: _input(
                  'Search owner, phone or pet',
                  Icons.search_rounded,
                ),
              ),
            ),
            Expanded(
              child: patients.isEmpty
                  ? const Center(child: Text('No matching patients'))
                  : ListView.separated(
                      key: const ValueKey('staff-patients-list'),
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      itemCount: patients.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final item = patients[index];
                        return ListTile(
                          key: ValueKey('staff-patient-${item.pet}'),
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: _border),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: item.priority == 'Urgent'
                                ? const Color(0xFFFFE4E5)
                                : const Color(0xFFE6FAF2),
                            child: const Icon(Icons.pets_rounded),
                          ),
                          title: Text(
                            item.pet,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text('${item.owner} • ${item.phone}'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _push(
                            context,
                            StaffPatientDetailPage(petName: item.pet),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
  );
}

class StaffPatientDetailPage extends StatelessWidget {
  const StaffPatientDetailPage({required this.petName, super.key});

  final String petName;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    appBar: _appBar('Patient Profile'),
    body: AnimatedBuilder(
      animation: Listenable.merge([
        StaffOperationsStore.instance,
        HomeVisitStore.instance,
        EmergencyRequestStore.instance,
        ReminderStore.instance,
      ]),
      builder: (context, _) {
        final visits = StaffOperationsStore.instance.appointments
            .where((a) => a.pet == petName)
            .toList();
        final latest = visits.isEmpty ? null : visits.first;
        final owner = latest?.owner ?? 'Registered Owner';
        final phone = latest?.phone ?? 'Not recorded';
        final homeVisits = HomeVisitStore.instance.visits
            .where((v) => v.pet.name == petName)
            .toList();
        final reminders = ReminderStore.instance.reminders
            .where((r) => r.petName == petName)
            .toList();

        return ListView(
          key: const ValueKey('staff-patient-detail'),
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFE6FAF2),
                    child: Icon(Icons.pets_rounded, color: _green, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          petName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$owner • $phone',
                          style: const TextStyle(color: _muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _notice(context, 'Calling $phone…'),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call owner'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('staff-set-reminder'),
                    onPressed: () => _setReminder(context, owner),
                    icon: const Icon(Icons.alarm_add_rounded),
                    label: const Text('Set Reminder'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Appointment history', style: _sectionStyle),
            const SizedBox(height: 8),
            if (visits.isEmpty)
              const _Callout(
                icon: Icons.event_busy_rounded,
                text: 'No appointments recorded for this patient.',
              )
            else
              for (final v in visits) ...[
                _PatientHistoryTile(
                  title: '${v.service} • ${v.doctor}',
                  subtitle: '${_shortDate(v.date)} at ${v.time}',
                  status: v.status,
                ),
                const SizedBox(height: 8),
              ],
            if (homeVisits.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Home visits', style: _sectionStyle),
              const SizedBox(height: 8),
              for (final v in homeVisits) ...[
                _PatientHistoryTile(
                  title: '${v.reason} • ${v.veterinarian}',
                  subtitle: '${_shortDate(v.date)} at ${v.time}',
                  status: _homeLabel(v.status),
                ),
                const SizedBox(height: 8),
              ],
            ],
            if (reminders.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Reminders', style: _sectionStyle),
              const SizedBox(height: 8),
              for (final r in reminders) ...[
                _PatientHistoryTile(
                  title: r.title,
                  subtitle: '${r.type.label} • ${_shortDate(r.dateTime)}',
                  status: r.completed ? 'Done' : 'Upcoming',
                ),
                const SizedBox(height: 8),
              ],
            ],
            const SizedBox(height: 12),
            const _Callout(
              icon: Icons.lock_outline_rounded,
              text:
                  'Diagnoses, prescriptions, and finalized clinical records are read-only for staff.',
            ),
          ],
        );
      },
    ),
  );

  Future<void> _setReminder(BuildContext context, String owner) async {
    final title = TextEditingController();
    var type = ReminderType.checkup;
    var date = DateTime.now().add(const Duration(days: 7));
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Set reminder'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: _input('Reminder title', Icons.title_rounded),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ReminderType>(
                  initialValue: type,
                  decoration: _input('Type', Icons.category_outlined),
                  items: ReminderType.values
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => type = v ?? type),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('Date: ${_shortDate(date)}')),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: date,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() => date = picked);
                        }
                      },
                      child: const Text('Pick'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('confirm-set-reminder'),
              onPressed: () {
                if (title.text.trim().isEmpty) return;
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      ReminderStore.instance.addNew(
        title: title.text.trim(),
        type: type,
        dateTime: DateTime(date.year, date.month, date.day, 10),
        petName: petName,
        createdByStaff: true,
      );
      OwnerNotificationStore.instance.push(
        'New reminder from the clinic',
        '${title.text.trim()} scheduled for $petName on ${_shortDate(date)}.',
      );
      if (context.mounted) {
        _notice(context, 'Reminder set for $petName and $owner notified.');
      }
    }
    title.dispose();
  }
}

class _PatientHistoryTile extends StatelessWidget {
  const _PatientHistoryTile({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: _cardDecoration(),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE6FAF2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: const TextStyle(
              color: _green,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
