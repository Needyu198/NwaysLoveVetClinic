part of 'staff_portal.dart';

BoxDecoration _petsOwnersCardDecoration({Color color = Colors.white}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0C0B2F25),
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    );

class _PetsOwnersHeader extends StatelessWidget {
  const _PetsOwnersHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 10, 18, 18),
    decoration: const BoxDecoration(
      color: _mint,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Image.asset(
          'assets/photos/logoandphoto/nways_love_logo.png',
          key: const ValueKey('pets-owners-logo'),
          width: 54,
          height: 54,
          fit: BoxFit.contain,
        ),
      ],
    ),
  );
}

class _PetsOwnersEmpty extends StatelessWidget {
  const _PetsOwnersEmpty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pets_outlined, size: 58, color: _muted),
          SizedBox(height: 12),
          Text('No matching pets', style: _sectionStyle),
          SizedBox(height: 4),
          Text(
            'Try another pet name, owner, or phone number.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
          ),
        ],
      ),
    ),
  );
}

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
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _PetsOwnersHeader(
            title: 'Pets & Owners',
            subtitle: 'Find pet profiles and owner details.',
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                StaffOperationsStore.instance,
                AppointmentStore.instance,
                ProfilePetStore.instance,
              ]),
              builder: (context, _) {
                // Latest appointment per owner + pet drives each directory row.
                final byPet = <String, StaffAppointment>{};
                for (final item in StaffOperationsStore.instance.appointments) {
                  final ownerKey = databaseOwnerOf(item.source) ?? item.owner;
                  byPet['$ownerKey:${item.pet.toLowerCase()}'] = item;
                }
                final pets = byPet.values.where((item) {
                  final q = _query.trim().toLowerCase();
                  if (q.isEmpty) return true;
                  return '${item.pet} ${item.owner} ${item.phone}'
                      .toLowerCase()
                      .contains(q);
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                      child: TextField(
                        key: const ValueKey('staff-patient-search'),
                        onChanged: (value) => setState(() => _query = value),
                        decoration:
                            _input(
                              'Search pet, owner or phone',
                              Icons.search_rounded,
                            ).copyWith(
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: _border),
                              ),
                            ),
                      ),
                    ),
                    Expanded(
                      child: pets.isEmpty
                          ? const _PetsOwnersEmpty()
                          : ListView.separated(
                              key: const ValueKey('staff-patients-list'),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                              itemCount: pets.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, index) {
                                final item = pets[index];
                                final ownerId = databaseOwnerOf(item.source);
                                return Material(
                                  key: ValueKey('staff-patient-${item.pet}'),
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(22),
                                    onTap: () => _push(
                                      context,
                                      StaffPatientDetailPage(
                                        petName: item.pet,
                                        ownerId: ownerId,
                                      ),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(color: _border),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x0C0B2F25),
                                            blurRadius: 12,
                                            offset: Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          ProfilePetAvatar(
                                            petName: item.pet,
                                            ownerId: ownerId,
                                            radius: 29,
                                            fallbackBackground:
                                                item.priority == 'Urgent'
                                                ? const Color(0xFFFFE4E5)
                                                : const Color(0xFFE6FAF2),
                                            photoKey: ValueKey(
                                              'staff-patient-pet-photo-${item.pet}',
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.pet,
                                                  style: _sectionStyle,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item.owner,
                                                  style: const TextStyle(
                                                    color: _green,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  item.phone,
                                                  style: const TextStyle(
                                                    color: _muted,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            color: _muted,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class StaffPatientDetailPage extends StatelessWidget {
  const StaffPatientDetailPage({
    required this.petName,
    this.ownerId,
    super.key,
  });

  final String petName;
  final String? ownerId;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _PetsOwnersHeader(
            title: 'Pet Profile',
            subtitle: 'Owner details and clinic history.',
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                StaffOperationsStore.instance,
                HomeVisitStore.instance,
                EmergencyRequestStore.instance,
                ReminderStore.instance,
                ProfilePetStore.instance,
              ]),
              builder: (context, _) {
                final visits = StaffOperationsStore.instance.appointments
                    .where(
                      (a) =>
                          a.pet == petName &&
                          (ownerId == null ||
                              databaseOwnerOf(a.source) == ownerId),
                    )
                    .toList();
                final latest = visits.isEmpty ? null : visits.first;
                final owner = latest?.owner ?? 'Registered Owner';
                final phone = latest?.phone ?? 'Not recorded';
                final callHistory =
                    visits.expand((visit) => visit.confirmationCalls).toList()
                      ..sort((a, b) => a.calledAt.compareTo(b.calledAt));
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
                      decoration: _petsOwnersCardDecoration(
                        color: const Color(0xFFE8FFF5),
                      ),
                      child: Row(
                        children: [
                          ProfilePetAvatar(
                            petName: petName,
                            ownerId: ownerId,
                            radius: 28,
                            fallbackBackground: const Color(0xFFE6FAF2),
                            fallbackForeground: _green,
                            photoKey: ValueKey(
                              'staff-patient-detail-pet-photo-$petName',
                            ),
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
                            onPressed: latest == null
                                ? null
                                : () => _callOwnerAndRecord(context, latest),
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
                    if (callHistory.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Text('Owner call history', style: _sectionStyle),
                      const SizedBox(height: 8),
                      _ConfirmationCallHistory(calls: callHistory),
                    ],
                    const SizedBox(height: 18),
                    const Text('Appointment history', style: _sectionStyle),
                    const SizedBox(height: 8),
                    if (visits.isEmpty)
                      const _Callout(
                        icon: Icons.event_busy_rounded,
                        text: 'No appointments recorded for this pet.',
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
                          subtitle:
                              '${r.type.label} • ${_shortDate(r.dateTime)}',
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
          ),
        ],
      ),
    ),
  );

  Future<void> _setReminder(BuildContext context, String owner) async {
    final matches = StaffOperationsStore.instance.appointments
        .where((a) => a.pet == petName && a.source != null)
        .toList();
    final ownerIds = matches
        .map((a) => databaseOwnerOf(a.source))
        .whereType<String>()
        .toSet();
    if (DatabaseSync.instance.active && ownerIds.length != 1) {
      _notice(
        context,
        'Select a pet with one linked owner account before creating a reminder.',
      );
      return;
    }
    final ownerId = ownerIds.isEmpty ? null : ownerIds.single;
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
        ownerId: ownerId,
      );
      OwnerNotificationStore.instance.push(
        'New reminder from the clinic',
        ownerId: ownerId,
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
    decoration: _petsOwnersCardDecoration(),
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
