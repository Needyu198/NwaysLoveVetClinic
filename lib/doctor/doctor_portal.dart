import 'package:flutter/material.dart';

import '../login/login_page.dart';
import '../pet_owner/appointment_booking_page.dart';
import '../pet_owner/emergency_service_page.dart';

class DoctorPortalPage extends StatefulWidget {
  const DoctorPortalPage({super.key});

  static const routeName = '/doctor';

  @override
  State<DoctorPortalPage> createState() => _DoctorPortalPageState();
}

class _DoctorPortalPageState extends State<DoctorPortalPage> {
  var _index = 0;
  var _appointmentFilter = 'All';

  static const _titles = ['Doctor Dashboard', 'Appointments', 'Doctor Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.page,
      appBar: AppBar(
        title: Text(_titles[_index]),
        backgroundColor: DoctorStyles.mint,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_index != 2)
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new staff notifications.')),
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          DoctorDashboardPage(
            onOpenAppointments: _openAppointments,
            onOpenProfile: () => setState(() => _index = 2),
          ),
          DoctorAppointmentsPage(
            key: ValueKey('doctor-appointments-$_appointmentFilter'),
            initialFilter: _appointmentFilter,
          ),
          const DoctorProfilePage(),
        ],
      ),
      bottomNavigationBar: DoctorNavigationBar(
        selectedIndex: _index,
        onSelected: (index) => setState(() => _index = index),
      ),
    );
  }

  void _openAppointments(String filter) {
    setState(() {
      _appointmentFilter = filter;
      _index = 1;
    });
  }
}

class DoctorNavigationBar extends StatelessWidget {
  const DoctorNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _DoctorNavigationItem(
      label: 'Dashboard',
      icon: Icons.desktop_windows_outlined,
      keyValue: 'doctor-dashboard-tab',
      color: Color(0xFF789A93),
    ),
    _DoctorNavigationItem(
      label: 'Appointments',
      icon: Icons.add_rounded,
      keyValue: 'doctor-appointments-tab',
      color: Color(0xFFEF4E43),
    ),
    _DoctorNavigationItem(
      label: 'Profile',
      icon: Icons.account_circle_outlined,
      keyValue: 'doctor-profile-tab',
      color: Color(0xFF789A93),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DoctorStyles.page,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          key: const ValueKey('doctor-navigation-bar'),
          height: 78,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(42),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 9,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var index = 0; index < _items.length; index++)
                Expanded(
                  flex: selectedIndex == index ? 5 : 2,
                  child: _DoctorNavigationDestination(
                    item: _items[index],
                    selected: selectedIndex == index,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorNavigationItem {
  const _DoctorNavigationItem({
    required this.label,
    required this.icon,
    required this.keyValue,
    required this.color,
  });

  final String label;
  final IconData icon;
  final String keyValue;
  final Color color;
}

class _DoctorNavigationDestination extends StatelessWidget {
  const _DoctorNavigationDestination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _DoctorNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: item.label,
      button: true,
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          key: ValueKey(item.keyValue),
          color: selected ? const Color(0xFFF8FAF9) : Colors.transparent,
          borderRadius: BorderRadius.circular(34),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 14 : 8,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, color: item.color, size: selected ? 35 : 38),
                  if (selected) ...[
                    const SizedBox(width: 9),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DoctorAppointmentRecord {
  DoctorAppointmentRecord({
    required this.id,
    required this.petName,
    required this.petDetails,
    required this.ownerName,
    required this.service,
    required this.date,
    required this.time,
    required this.reason,
    required this.symptoms,
    required String initialStatus,
    this.source,
  }) : _status = initialStatus;

  factory DoctorAppointmentRecord.fromBooking(BookedAppointment booking) {
    return DoctorAppointmentRecord(
      id: booking.id,
      petName: booking.pet.name,
      petDetails: '${booking.pet.species} • ${booking.pet.breed}',
      ownerName: 'Pet Owner',
      service: booking.service.name,
      date: booking.date,
      time: booking.time,
      reason: booking.reason,
      symptoms: booking.symptoms,
      initialStatus: booking.status,
      source: booking,
    );
  }

  final String id;
  final String petName;
  final String petDetails;
  final String ownerName;
  final String service;
  final DateTime date;
  final String time;
  final String reason;
  final String symptoms;
  final BookedAppointment? source;
  String _status;
  String consultationNotes = '';
  String diagnosis = '';
  String treatment = '';

  String get status => source?.status ?? _status;
  set status(String value) => _status = value;
}

class DoctorAppointmentStore extends ChangeNotifier {
  DoctorAppointmentStore._();

  static final instance = DoctorAppointmentStore._();
  static const doctorName = 'Dr. Aye Chan';

  final List<DoctorAppointmentRecord> _demoRecords = [];

  void ensureDemoSchedule() {
    if (_demoRecords.isNotEmpty) return;
    final today = DateTime.now();
    _demoRecords.addAll([
      DoctorAppointmentRecord(
        id: 'DOC-${today.year}${today.month}${today.day}-01',
        petName: 'Bruno',
        petDetails: 'Dog • Pug',
        ownerName: 'Lynn Kyaw',
        service: 'General Checkup',
        date: today,
        time: '9:00 AM',
        reason: 'Routine health assessment',
        symptoms: 'Reduced appetite',
        initialStatus: 'Confirmed',
      ),
      DoctorAppointmentRecord(
        id: 'DOC-${today.year}${today.month}${today.day}-02',
        petName: 'Mimi',
        petDetails: 'Cat • Ragdoll',
        ownerName: 'May Zin',
        service: 'Vaccination',
        date: today,
        time: '11:00 AM',
        reason: 'Annual vaccination',
        symptoms: 'No current symptoms',
        initialStatus: 'Pending',
      ),
      DoctorAppointmentRecord(
        id: 'DOC-${today.year}${today.month}${today.day}-03',
        petName: 'Sugar',
        petDetails: 'Dog • Pomeranian',
        ownerName: 'Thiri Win',
        service: 'Follow-up',
        date: today.add(const Duration(days: 1)),
        time: '2:00 PM',
        reason: 'Treatment follow-up',
        symptoms: 'Skin irritation improving',
        initialStatus: 'Confirmed',
      ),
    ]);
  }

  List<DoctorAppointmentRecord> get appointments {
    ensureDemoSchedule();
    final ownerRecords = AppointmentStore.instance.appointments
        .where((appointment) => appointment.veterinarian == doctorName)
        .where(
          (appointment) =>
              !_demoRecords.any((record) => record.id == appointment.id),
        )
        .map(DoctorAppointmentRecord.fromBooking);
    final result = [..._demoRecords, ...ownerRecords];
    result.sort((a, b) {
      final dateComparison = a.date.compareTo(b.date);
      return dateComparison != 0
          ? dateComparison
          : _timeMinutes(a.time).compareTo(_timeMinutes(b.time));
    });
    return result;
  }

  void updateStatus(DoctorAppointmentRecord record, String status) {
    if (record.source case final source?) {
      AppointmentStore.instance.staffSetStatus(source, status);
    } else {
      record.status = status;
    }
    notifyListeners();
  }

  @visibleForTesting
  void clearDemoSchedule() {
    _demoRecords.clear();
    notifyListeners();
  }
}

class DoctorDashboardPage extends StatelessWidget {
  const DoctorDashboardPage({
    required this.onOpenAppointments,
    required this.onOpenProfile,
    super.key,
  });

  final ValueChanged<String> onOpenAppointments;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        DoctorAppointmentStore.instance,
        AppointmentStore.instance,
        EmergencyRequestStore.instance,
      ]),
      builder: (context, _) {
        final records = DoctorAppointmentStore.instance.appointments;
        final today = records
            .where(
              (record) =>
                  DateUtils.isSameDay(record.date, DateTime.now()) &&
                  record.status != 'Cancelled',
            )
            .toList();
        final completed = today
            .where((record) => record.status == 'Completed')
            .length;
        final waiting = today
            .where((record) => record.status != 'Completed')
            .length;
        final upNext = today
            .where(
              (record) => !const {
                'Completed',
                'Cancelled',
                'In Consultation',
              }.contains(record.status),
            )
            .toList();
        final emergencyCases = EmergencyRequestStore.instance.requests
            .where(
              (request) => !const {
                EmergencyStatus.completed,
                EmergencyStatus.declined,
              }.contains(request.status),
            )
            .toList();
        return ListView(
          key: const ValueKey('doctor-dashboard'),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
          children: [
            Text('${_greeting()}, Dr. Aye Chan', style: DoctorStyles.title),
            const SizedBox(height: 5),
            Text(_fullDate(DateTime.now()), style: DoctorStyles.muted),
            const SizedBox(height: 22),
            _DashboardStatCard(
              key: const ValueKey('doctor-emergency-stat'),
              label: 'Emergency Cases',
              value: '${emergencyCases.length}',
              icon: Icons.emergency_rounded,
              color: const Color(0xFFE92832),
              foregroundColor: Colors.white,
              horizontal: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DoctorEmergencyCasesPage(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DashboardStatCard(
                    key: const ValueKey('doctor-waiting-stat'),
                    label: 'Waiting',
                    value: '$waiting',
                    icon: Icons.groups_2_outlined,
                    color: DoctorStyles.mint,
                    onTap: () => onOpenAppointments('Waiting'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DashboardStatCard(
                    key: const ValueKey('doctor-completed-stat'),
                    label: 'Completed',
                    value: '$completed',
                    icon: Icons.task_alt_rounded,
                    color: DoctorStyles.mint,
                    onTap: () => onOpenAppointments('Completed'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DashboardStatCard(
              key: const ValueKey('doctor-total-stat'),
              label: 'Today Total Appointments',
              value: '${today.length}',
              icon: Icons.calendar_today_rounded,
              color: DoctorStyles.mint,
              horizontal: true,
              onTap: () => onOpenAppointments('Today'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text('Up Next', style: DoctorStyles.section),
                ),
                TextButton(
                  key: const ValueKey('doctor-view-all-appointments'),
                  onPressed: () => onOpenAppointments('All'),
                  child: const Text('View All Appointments'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (emergencyCases.isNotEmpty) ...[
              for (final emergency in emergencyCases.take(2)) ...[
                _EmergencyQueueCard(request: emergency),
                const SizedBox(height: 10),
              ],
            ],
            if (upNext.isEmpty && emergencyCases.isEmpty)
              const _EmptyDoctorState(
                icon: Icons.event_available_rounded,
                title: 'No patients waiting',
                message: 'Today’s active queue is clear.',
              )
            else ...[
              for (var index = 0; index < upNext.length; index++) ...[
                _UpNextCard(
                  record: upNext[index],
                  canStart: index == 0 && emergencyCases.isEmpty,
                ),
                const SizedBox(height: 10),
              ],
            ],
            const SizedBox(height: 18),
            const Text('Quick Menu', style: DoctorStyles.section),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('doctor-write-post'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DoctorCreatePostPage(),
                      ),
                    ),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Write a Post'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('doctor-medical-records'),
                    onPressed: () => onOpenAppointments('Completed'),
                    icon: const Icon(Icons.medical_information_outlined),
                    label: const Text('Medical Records'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey('doctor-dashboard-profile'),
              onPressed: onOpenProfile,
              icon: const Icon(Icons.manage_accounts_outlined),
              label: const Text('Profile & Account Settings'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({this.initialFilter = 'All', super.key});

  final String initialFilter;

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  late String _filter = widget.initialFilter;
  static const _filters = [
    'All',
    'Today',
    'Waiting',
    'Pending',
    'Confirmed',
    'Checked In',
    'In Consultation',
    'Completed',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        DoctorAppointmentStore.instance,
        AppointmentStore.instance,
      ]),
      builder: (context, _) {
        final all = DoctorAppointmentStore.instance.appointments;
        final records = switch (_filter) {
          'All' => all,
          'Today' =>
            all
                .where(
                  (record) => DateUtils.isSameDay(record.date, DateTime.now()),
                )
                .toList(),
          'Waiting' =>
            all
                .where(
                  (record) =>
                      DateUtils.isSameDay(record.date, DateTime.now()) &&
                      !const {'Completed', 'Cancelled'}.contains(record.status),
                )
                .toList(),
          _ => all.where((record) => record.status == _filter).toList(),
        };
        return Column(
          key: const ValueKey('doctor-appointments'),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  for (final filter in _filters) ...[
                    ChoiceChip(
                      key: ValueKey('doctor-filter-$filter'),
                      label: Text(filter),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Expanded(
              child: records.isEmpty
                  ? const _EmptyDoctorState(
                      icon: Icons.event_busy_outlined,
                      title: 'No appointments',
                      message: 'There are no appointments with this status.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                      itemCount: records.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, index) =>
                          DoctorAppointmentCard(record: records[index]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class DoctorAppointmentCard extends StatelessWidget {
  const DoctorAppointmentCard({
    required this.record,
    this.compact = false,
    super.key,
  });

  final DoctorAppointmentRecord record;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: ValueKey('doctor-appointment-${record.id}'),
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DoctorAppointmentDetailsPage(record: record),
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(compact ? 14 : 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DoctorStyles.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: DoctorStyles.softMint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(_month(record.date), style: DoctorStyles.small),
                    Text('${record.date.day}', style: DoctorStyles.cardTitle),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.petName,
                            style: DoctorStyles.cardTitle,
                          ),
                        ),
                        _StatusBadge(status: record.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(record.service, style: DoctorStyles.body),
                    const SizedBox(height: 5),
                    Text(
                      '${record.time} • ${record.ownerName}',
                      style: DoctorStyles.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class DoctorAppointmentDetailsPage extends StatelessWidget {
  const DoctorAppointmentDetailsPage({required this.record, super.key});

  final DoctorAppointmentRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.page,
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: DoctorStyles.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          DoctorAppointmentStore.instance,
          AppointmentStore.instance,
        ]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
          children: [
            _DoctorDetailsCard(
              rows: [
                ('Booking ID', '#${record.id}'),
                ('Patient', record.petName),
                ('Pet details', record.petDetails),
                ('Pet owner', record.ownerName),
                ('Service', record.service),
                ('Date', _fullDate(record.date)),
                ('Time', record.time),
                ('Status', record.status),
                ('Visit reason', record.reason),
                ('Symptoms', record.symptoms),
              ],
            ),
            const SizedBox(height: 16),
            const _DoctorNotice(
              text:
                  'Only clinic staff and the assigned veterinarian can update this appointment. Pet owners see these statuses as read-only.',
            ),
            const SizedBox(height: 20),
            if (_nextStatus(record.status) case final nextStatus?)
              FilledButton.icon(
                key: const ValueKey('doctor-update-status'),
                onPressed: () => _confirmStatus(context, nextStatus),
                icon: Icon(_statusIcon(nextStatus)),
                label: Text(_statusAction(nextStatus)),
                style: FilledButton.styleFrom(
                  backgroundColor: DoctorStyles.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
              )
            else
              _DoctorNotice(
                text: record.status == 'Cancelled'
                    ? 'This booking was cancelled. No further status changes are available.'
                    : 'This appointment workflow is complete.',
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmStatus(BuildContext context, String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update appointment status?'),
        content: Text(
          'Change ${record.petName}’s appointment to “$status”? The pet owner will see the update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            key: const ValueKey('confirm-doctor-status'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Update Status'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      DoctorAppointmentStore.instance.updateStatus(record, status);
    }
  }
}

class DoctorConsultationPage extends StatefulWidget {
  const DoctorConsultationPage({required this.record, super.key});

  final DoctorAppointmentRecord record;

  @override
  State<DoctorConsultationPage> createState() => _DoctorConsultationPageState();
}

class _DoctorConsultationPageState extends State<DoctorConsultationPage> {
  late final _notes = TextEditingController(
    text: widget.record.consultationNotes,
  );
  late final _diagnosis = TextEditingController(text: widget.record.diagnosis);
  late final _treatment = TextEditingController(text: widget.record.treatment);

  @override
  void dispose() {
    _notes.dispose();
    _diagnosis.dispose();
    _treatment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    return Scaffold(
      backgroundColor: DoctorStyles.page,
      appBar: AppBar(
        title: const Text('Consultation'),
        backgroundColor: DoctorStyles.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: DoctorStyles.softMint,
                child: Icon(Icons.pets_rounded, size: 30),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.petName, style: DoctorStyles.title),
                    Text(record.petDetails, style: DoctorStyles.muted),
                    Text(
                      'Owner: ${record.ownerName}',
                      style: DoctorStyles.body,
                    ),
                  ],
                ),
              ),
              const _StatusBadge(status: 'In Consultation'),
            ],
          ),
          const SizedBox(height: 20),
          _DoctorDetailsCard(
            rows: [
              ('Booking ID', '#${record.id}'),
              ('Service', record.service),
              ('Date and time', '${_fullDate(record.date)} • ${record.time}'),
              ('Visit reason', record.reason),
              ('Symptoms', record.symptoms),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            key: const ValueKey('consultation-notes'),
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Examination notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            key: const ValueKey('consultation-diagnosis'),
            controller: _diagnosis,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Diagnosis',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            key: const ValueKey('consultation-treatment'),
            controller: _treatment,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Treatment and recommendations',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const ValueKey('complete-doctor-consultation'),
            onPressed: _completeConsultation,
            icon: const Icon(Icons.task_alt_rounded),
            label: const Text('Complete Consultation'),
            style: FilledButton.styleFrom(
              backgroundColor: DoctorStyles.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeConsultation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete consultation?'),
        content: const Text(
          'The appointment will move to Completed and today’s dashboard totals will update automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continue Consulting'),
          ),
          FilledButton(
            key: const ValueKey('confirm-complete-consultation'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    widget.record
      ..consultationNotes = _notes.text.trim()
      ..diagnosis = _diagnosis.text.trim()
      ..treatment = _treatment.text.trim();
    DoctorAppointmentStore.instance.updateStatus(widget.record, 'Completed');
    Navigator.of(context).pop();
  }
}

class DoctorEmergencyCasesPage extends StatelessWidget {
  const DoctorEmergencyCasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.page,
      appBar: AppBar(
        title: const Text('Emergency Cases'),
        backgroundColor: const Color(0xFFFFCDD0),
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: EmergencyRequestStore.instance,
        builder: (context, _) {
          final cases = EmergencyRequestStore.instance.requests
              .where(
                (request) => !const {
                  EmergencyStatus.completed,
                  EmergencyStatus.declined,
                }.contains(request.status),
              )
              .toList();
          if (cases.isEmpty) {
            return const _EmptyDoctorState(
              icon: Icons.health_and_safety_outlined,
              title: 'No active emergency cases',
              message: 'New accepted emergency requests will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: cases.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) =>
                _EmergencyQueueCard(request: cases[index], showDetails: true),
          );
        },
      ),
    );
  }
}

class DoctorCreatePostPage extends StatefulWidget {
  const DoctorCreatePostPage({super.key});

  @override
  State<DoctorCreatePostPage> createState() => _DoctorCreatePostPageState();
}

class _DoctorCreatePostPageState extends State<DoctorCreatePostPage> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  var _category = 'Pet Health';

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.page,
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: DoctorStyles.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
        children: [
          const Text('Share Clinic Information', style: DoctorStyles.title),
          const SizedBox(height: 6),
          const Text(
            'Create an educational update for pet owners.',
            style: DoctorStyles.muted,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: const ['Pet Health', 'Clinic News', 'First Aid', 'Pet Care']
                .map(
                  (category) =>
                      DropdownMenuItem(value: category, child: Text(category)),
                )
                .toList(),
            onChanged: (value) => setState(() => _category = value!),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('doctor-post-title'),
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Post title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('doctor-post-content'),
            controller: _content,
            minLines: 7,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'Post content',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const ValueKey('publish-doctor-post'),
            onPressed: _publish,
            icon: const Icon(Icons.publish_rounded),
            label: const Text('Publish Post'),
            style: FilledButton.styleFrom(
              backgroundColor: DoctorStyles.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }

  void _publish() {
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title and post content.')),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$_category post published.')));
    Navigator.of(context).pop();
  }
}

class DoctorProfilePage extends StatelessWidget {
  const DoctorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('doctor-profile'),
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 36),
      children: [
        const CircleAvatar(
          radius: 52,
          backgroundColor: DoctorStyles.mint,
          child: Icon(Icons.medical_services_rounded, size: 52),
        ),
        const SizedBox(height: 14),
        const Text(
          'Dr. Aye Chan',
          textAlign: TextAlign.center,
          style: DoctorStyles.title,
        ),
        const Text(
          'General Veterinarian',
          textAlign: TextAlign.center,
          style: DoctorStyles.muted,
        ),
        const SizedBox(height: 24),
        const _DoctorDetailsCard(
          rows: [
            ('License', 'VET-MM-1042'),
            ('Clinic', "Nway's Love Vet Clinic"),
            ('Email', 'doctor@nwaysclinic.com'),
            ('Phone', '09-5312717'),
            ('Experience', '8 years'),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Clinic Schedule', style: DoctorStyles.section),
        const SizedBox(height: 10),
        const _DoctorDetailsCard(
          rows: [
            ('Monday–Friday', '9:00 AM – 5:00 PM'),
            ('Saturday', '9:00 AM – 1:00 PM'),
            ('Sunday', 'Off duty'),
          ],
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          key: const ValueKey('doctor-logout'),
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB3261E),
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will return to the clinic login page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-doctor-logout'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(LoginPage.routeName, (_) => false);
    }
  }
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
      'Confirmed' => const Color(0xFF176B50),
      'Checked In' || 'In Consultation' => const Color(0xFF2358A5),
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

class DoctorStyles {
  const DoctorStyles._();

  static const page = Color(0xFFF5F8F6);
  static const mint = Color(0xFFA1FDD8);
  static const softMint = Color(0xFFE8FAF2);
  static const green = Color(0xFF15835F);
  static const ink = Color(0xFF17201D);
  static const border = Color(0xFFD7E5DF);
  static const title = TextStyle(
    color: ink,
    fontSize: 25,
    fontWeight: FontWeight.w900,
  );
  static const section = TextStyle(
    color: ink,
    fontSize: 19,
    fontWeight: FontWeight.w900,
  );
  static const cardTitle = TextStyle(
    color: ink,
    fontSize: 17,
    fontWeight: FontWeight.w900,
  );
  static const cardValue = TextStyle(
    color: ink,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  static const body = TextStyle(color: ink, fontSize: 14, height: 1.35);
  static const muted = TextStyle(color: Color(0xFF61716B), fontSize: 13);
  static const small = TextStyle(
    color: Color(0xFF61716B),
    fontSize: 11,
    fontWeight: FontWeight.w800,
  );
  static const stat = TextStyle(
    color: ink,
    fontSize: 28,
    fontWeight: FontWeight.w900,
  );
}

String? _nextStatus(String status) => switch (status) {
  'Pending' => 'Confirmed',
  'Confirmed' => 'Checked In',
  'Checked In' => 'In Consultation',
  'In Consultation' => 'Completed',
  _ => null,
};

String _statusAction(String status) => switch (status) {
  'Confirmed' => 'Confirm Appointment',
  'Checked In' => 'Check In Patient',
  'In Consultation' => 'Start Consultation',
  'Completed' => 'Complete Consultation',
  _ => 'Update Status',
};

IconData _statusIcon(String status) => switch (status) {
  'Confirmed' => Icons.event_available_rounded,
  'Checked In' => Icons.login_rounded,
  'In Consultation' => Icons.medical_services_outlined,
  'Completed' => Icons.task_alt_rounded,
  _ => Icons.update_rounded,
};

String _fullDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
}

String _month(DateTime date) => const [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
][date.month - 1];

int _timeMinutes(String value) {
  final parts = value.split(RegExp(r'[: ]'));
  if (parts.length < 3) return 0;
  var hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  if (parts[2].toUpperCase() == 'PM' && hour != 12) hour += 12;
  if (parts[2].toUpperCase() == 'AM' && hour == 12) hour = 0;
  return hour * 60 + minute;
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

String _emergencyLabel(EmergencyStatus status) => switch (status) {
  EmergencyStatus.submitted => 'Submitted',
  EmergencyStatus.underReview => 'Under Review',
  EmergencyStatus.accepted => 'Accepted',
  EmergencyStatus.declined => 'Declined',
  EmergencyStatus.checkedIn => 'Checked In',
  EmergencyStatus.assessment => 'Assessment',
  EmergencyStatus.waiting => 'Waiting',
  EmergencyStatus.consultation => 'Consultation',
  EmergencyStatus.treatmentProposed => 'Treatment Proposed',
  EmergencyStatus.treatmentInProgress => 'Treatment In Progress',
  EmergencyStatus.completed => 'Completed',
};
