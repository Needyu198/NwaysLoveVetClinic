import 'package:flutter/material.dart';

import '../login/login_page.dart';
import '../pet_owner/appointment_booking_page.dart';
import '../pet_owner/contact_clinic_page.dart';
import '../pet_owner/emergency_service_page.dart';
import '../pet_owner/home_visit_booking_page.dart';

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
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DoctorNotificationsPage(),
                ),
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
  String allergies = 'No known allergies recorded';
  String existingConditions = 'No existing medical conditions recorded';
  String prescription = '';
  String vaccination = '';
  String nextDoseDate = '';
  String followUp = '';
  String rescheduleNote = '';

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

class DoctorMedicalRecord {
  DoctorMedicalRecord({
    required this.id,
    required this.appointmentId,
    required this.petName,
    required this.ownerName,
    required this.service,
    required this.date,
    required this.symptoms,
    required this.findings,
    required this.diagnosis,
    required this.treatment,
    required this.prescription,
    required this.vaccination,
    required this.nextDoseDate,
    required this.followUp,
    required this.testResult,
    required this.finalized,
  });

  final String id;
  final String appointmentId;
  final String petName;
  final String ownerName;
  final String service;
  final DateTime date;
  final String symptoms;
  String findings;
  String diagnosis;
  String treatment;
  String prescription;
  String vaccination;
  String nextDoseDate;
  String followUp;
  String testResult;
  bool finalized;
}

class DoctorMedicalRecordStore extends ChangeNotifier {
  DoctorMedicalRecordStore._();

  static final instance = DoctorMedicalRecordStore._();
  final List<DoctorMedicalRecord> _records = [];

  List<DoctorMedicalRecord> get records => List.unmodifiable(_records.reversed);

  List<DoctorMedicalRecord> recordsFor(String petName) => _records
      .where(
        (record) =>
            record.petName.toLowerCase() == petName.toLowerCase() &&
            record.finalized,
      )
      .toList();

  void saveFromConsultation(
    DoctorAppointmentRecord appointment, {
    required bool finalized,
    required String testResult,
  }) {
    final existing = _records.cast<DoctorMedicalRecord?>().firstWhere(
      (record) => record?.appointmentId == appointment.id,
      orElse: () => null,
    );
    if (existing == null) {
      _records.add(
        DoctorMedicalRecord(
          id: 'MED-${appointment.id}',
          appointmentId: appointment.id,
          petName: appointment.petName,
          ownerName: appointment.ownerName,
          service: appointment.service,
          date: DateTime.now(),
          symptoms: appointment.symptoms,
          findings: appointment.consultationNotes,
          diagnosis: appointment.diagnosis,
          treatment: appointment.treatment,
          prescription: appointment.prescription,
          vaccination: appointment.vaccination,
          nextDoseDate: appointment.nextDoseDate,
          followUp: appointment.followUp,
          testResult: testResult,
          finalized: finalized,
        ),
      );
    } else {
      existing
        ..findings = appointment.consultationNotes
        ..diagnosis = appointment.diagnosis
        ..treatment = appointment.treatment
        ..prescription = appointment.prescription
        ..vaccination = appointment.vaccination
        ..nextDoseDate = appointment.nextDoseDate
        ..followUp = appointment.followUp
        ..testResult = testResult
        ..finalized = finalized;
    }
    notifyListeners();
  }

  @visibleForTesting
  void clear() {
    _records.clear();
    notifyListeners();
  }
}

class DoctorNotification {
  DoctorNotification({
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
  });

  final String title;
  final String message;
  final DateTime createdAt;
  bool read;
}

class DoctorNotificationStore extends ChangeNotifier {
  DoctorNotificationStore._();

  static final instance = DoctorNotificationStore._();
  final List<DoctorNotification> _notifications = [];

  List<DoctorNotification> get notifications =>
      List.unmodifiable(_notifications.reversed);
  int get unreadCount => _notifications.where((item) => !item.read).length;

  void add(String title, String message) {
    _notifications.add(
      DoctorNotification(
        title: title,
        message: message,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void markAllRead() {
    for (final item in _notifications) {
      item.read = true;
    }
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
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DoctorMedicalRecordsPage(),
                      ),
                    ),
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
    'Called',
    'In Consultation',
    'Completed',
    'Cancelled',
    'Rejected',
    'Reschedule Requested',
    'Missed',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
              child: Row(
                children: [
                  Expanded(
                    child: _DoctorFunctionButton(
                      key: const ValueKey('doctor-open-queue'),
                      label: 'Queue',
                      icon: Icons.groups_2_outlined,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DoctorQueuePage(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DoctorFunctionButton(
                      key: const ValueKey('doctor-open-medical-records'),
                      label: 'Records',
                      icon: Icons.medical_information_outlined,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DoctorMedicalRecordsPage(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DoctorFunctionButton(
                      key: const ValueKey('doctor-open-home-visits'),
                      label: 'Visits',
                      icon: Icons.home_work_outlined,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DoctorHomeVisitsPage(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            if (record.status == 'Pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('doctor-reject-appointment'),
                      onPressed: () => _confirmDecision(
                        context,
                        status: 'Rejected',
                        title: 'Reject appointment?',
                      ),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB3261E),
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('doctor-accept-appointment'),
                      onPressed: () => _confirmDecision(
                        context,
                        status: 'Confirmed',
                        title: 'Accept appointment?',
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Accept'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (const {'Pending', 'Confirmed'}.contains(record.status)) ...[
              OutlinedButton.icon(
                key: const ValueKey('doctor-request-reschedule'),
                onPressed: () => _requestReschedule(context),
                icon: const Icon(Icons.event_repeat_rounded),
                label: const Text('Request Rescheduling'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (record.status == 'In Consultation')
              FilledButton.icon(
                key: const ValueKey('open-consultation-workspace'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DoctorConsultationPage(record: record),
                  ),
                ),
                icon: const Icon(Icons.medical_services_outlined),
                label: const Text('Open Consultation Workspace'),
              )
            else if (_nextStatus(record.status) case final nextStatus?)
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
      if (status == 'In Consultation' && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DoctorConsultationPage(record: record),
          ),
        );
      }
    }
  }

  Future<void> _confirmDecision(
    BuildContext context, {
    required String status,
    required String title,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(
          'The appointment status will change to $status and the pet owner will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-doctor-decision'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      DoctorAppointmentStore.instance.updateStatus(record, status);
      DoctorNotificationStore.instance.add(
        '$status appointment for ${record.petName}',
        'The pet owner was notified about booking #${record.id}.',
      );
    }
  }

  Future<void> _requestReschedule(BuildContext context) async {
    final controller = TextEditingController();
    final requested = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request Rescheduling'),
        content: TextField(
          key: const ValueKey('doctor-reschedule-note'),
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason or preferred schedule',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-doctor-reschedule'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
    if (requested == true && controller.text.trim().isNotEmpty) {
      record.rescheduleNote = controller.text.trim();
      DoctorAppointmentStore.instance.updateStatus(
        record,
        'Reschedule Requested',
      );
      DoctorNotificationStore.instance.add(
        'Reschedule requested for ${record.petName}',
        record.rescheduleNote,
      );
    }
    controller.dispose();
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
  late final _medicine = TextEditingController();
  late final _dosage = TextEditingController();
  late final _frequency = TextEditingController();
  late final _duration = TextEditingController();
  late final _vaccination = TextEditingController(
    text: widget.record.vaccination,
  );
  late final _nextDose = TextEditingController(
    text: widget.record.nextDoseDate,
  );
  late final _followUp = TextEditingController(text: widget.record.followUp);
  String _testResult = '';

  @override
  void dispose() {
    _notes.dispose();
    _diagnosis.dispose();
    _treatment.dispose();
    _medicine.dispose();
    _dosage.dispose();
    _frequency.dispose();
    _duration.dispose();
    _vaccination.dispose();
    _nextDose.dispose();
    _followUp.dispose();
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
              ('Allergies', record.allergies),
              ('Existing conditions', record.existingConditions),
              (
                'Previous records',
                DoctorMedicalRecordStore.instance
                        .recordsFor(record.petName)
                        .isEmpty
                    ? 'No previous finalized records'
                    : '${DoctorMedicalRecordStore.instance.recordsFor(record.petName).length} record(s) available',
              ),
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
          const SizedBox(height: 18),
          const Text('Prescription', style: DoctorStyles.section),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('consultation-medicine'),
            controller: _medicine,
            decoration: const InputDecoration(
              labelText: 'Medicine name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('consultation-dosage'),
                  controller: _dosage,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const ValueKey('consultation-frequency'),
                  controller: _frequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('consultation-duration'),
            controller: _duration,
            decoration: const InputDecoration(
              labelText: 'Duration',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Vaccination and Follow-up', style: DoctorStyles.section),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('consultation-vaccine'),
            controller: _vaccination,
            decoration: const InputDecoration(
              labelText: 'Administered vaccine (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('consultation-next-dose'),
            controller: _nextDose,
            decoration: const InputDecoration(
              labelText: 'Next-dose date',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('consultation-follow-up'),
            controller: _followUp,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Follow-up recommendation',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('upload-consultation-result'),
            onPressed: () => setState(
              () => _testResult = 'Diagnostic test result attachment added',
            ),
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(
              _testResult.isEmpty ? 'Upload Test Result' : 'Test Result Added',
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            key: const ValueKey('save-consultation-draft'),
            onPressed: _saveDraft,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Draft'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 10),
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
    if (_diagnosis.text.trim().isEmpty || _treatment.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the diagnosis and treatment before finalizing.'),
        ),
      );
      return;
    }
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
      ..treatment = _treatment.text.trim()
      ..prescription = _prescriptionText()
      ..vaccination = _vaccination.text.trim()
      ..nextDoseDate = _nextDose.text.trim()
      ..followUp = _followUp.text.trim();
    DoctorMedicalRecordStore.instance.saveFromConsultation(
      widget.record,
      finalized: true,
      testResult: _testResult,
    );
    DoctorAppointmentStore.instance.updateStatus(widget.record, 'Completed');
    DoctorNotificationStore.instance.add(
      'Medical record finalized',
      '${widget.record.petName}’s consultation record is available in History.',
    );
    Navigator.of(context).pop();
  }

  void _saveDraft() {
    widget.record
      ..consultationNotes = _notes.text.trim()
      ..diagnosis = _diagnosis.text.trim()
      ..treatment = _treatment.text.trim()
      ..prescription = _prescriptionText()
      ..vaccination = _vaccination.text.trim()
      ..nextDoseDate = _nextDose.text.trim()
      ..followUp = _followUp.text.trim();
    DoctorMedicalRecordStore.instance.saveFromConsultation(
      widget.record,
      finalized: false,
      testResult: _testResult,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Consultation draft saved.')));
  }

  String _prescriptionText() {
    if (_medicine.text.trim().isEmpty) return '';
    return '${_medicine.text.trim()} • ${_dosage.text.trim()} • '
        '${_frequency.text.trim()} • ${_duration.text.trim()}';
  }
}

class DoctorQueuePage extends StatelessWidget {
  const DoctorQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.page,
      appBar: AppBar(
        title: const Text('Patient Queue'),
        backgroundColor: DoctorStyles.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          DoctorAppointmentStore.instance,
          AppointmentStore.instance,
          QueueStore.instance,
        ]),
        builder: (context, _) {
          final queue = DoctorAppointmentStore.instance.appointments
              .where(
                (record) =>
                    DateUtils.isSameDay(record.date, DateTime.now()) &&
                    !const {
                      'Completed',
                      'Cancelled',
                      'Rejected',
                      'Missed',
                    }.contains(record.status),
              )
              .toList();
          if (queue.isEmpty) {
            return const _EmptyDoctorState(
              icon: Icons.groups_2_outlined,
              title: 'Queue is clear',
              message: 'Waiting and called patients will appear here.',
            );
          }
          final called = queue.where((record) => record.status == 'Called');
          final canCallNext = called.isEmpty;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            itemCount: queue.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final record = queue[index];
              final displayStatus =
                  const {'Pending', 'Confirmed'}.contains(record.status)
                  ? 'Waiting'
                  : record.status;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: DoctorStyles.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: DoctorStyles.softMint,
                          child: Text('Q${index + 1}'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.petName,
                                style: DoctorStyles.cardTitle,
                              ),
                              Text(
                                '${record.time} • ${record.service}',
                                style: DoctorStyles.muted,
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: displayStatus),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (displayStatus == 'Waiting' &&
                            canCallNext &&
                            index == 0)
                          Expanded(
                            child: FilledButton.icon(
                              key: ValueKey('doctor-call-${record.id}'),
                              onPressed: () => DoctorAppointmentStore.instance
                                  .updateStatus(record, 'Called'),
                              icon: const Icon(Icons.campaign_outlined),
                              label: const Text('Call Next'),
                            ),
                          ),
                        if (record.status == 'Called')
                          Expanded(
                            child: FilledButton.icon(
                              key: ValueKey('doctor-queue-start-${record.id}'),
                              onPressed: () {
                                DoctorAppointmentStore.instance.updateStatus(
                                  record,
                                  'In Consultation',
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        DoctorConsultationPage(record: record),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.medical_services_outlined),
                              label: const Text('Start Consultation'),
                            ),
                          ),
                        if (record.status != 'In Consultation') ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            key: ValueKey('doctor-missed-${record.id}'),
                            onPressed: () => DoctorAppointmentStore.instance
                                .updateStatus(record, 'Missed'),
                            child: const Text('Missed'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DoctorMedicalRecordsPage extends StatefulWidget {
  const DoctorMedicalRecordsPage({super.key});

  @override
  State<DoctorMedicalRecordsPage> createState() =>
      _DoctorMedicalRecordsPageState();
}

class _DoctorMedicalRecordsPageState extends State<DoctorMedicalRecordsPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.page,
      appBar: AppBar(
        title: const Text('Medical Records'),
        backgroundColor: DoctorStyles.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: DoctorMedicalRecordStore.instance,
        builder: (context, _) {
          final query = _search.text.trim().toLowerCase();
          final records = DoctorMedicalRecordStore.instance.records
              .where(
                (record) =>
                    query.isEmpty ||
                    record.petName.toLowerCase().contains(query) ||
                    record.id.toLowerCase().contains(query),
              )
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  key: const ValueKey('doctor-medical-search'),
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search pet or medical record ID',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: records.isEmpty
                    ? const _EmptyDoctorState(
                        icon: Icons.medical_information_outlined,
                        title: 'No medical records found',
                        message:
                            'Saved consultation drafts and finalized records appear here.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                        itemCount: records.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return ListTile(
                            key: ValueKey('doctor-medical-${record.id}'),
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(
                                color: DoctorStyles.border,
                              ),
                            ),
                            leading: const CircleAvatar(
                              backgroundColor: DoctorStyles.softMint,
                              child: Icon(Icons.description_outlined),
                            ),
                            title: Text(record.petName),
                            subtitle: Text(
                              '${record.service} • ${record.finalized ? 'Finalized' : 'Draft'}',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => DoctorMedicalRecordDetailsPage(
                                  record: record,
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
    );
  }
}

class DoctorMedicalRecordDetailsPage extends StatelessWidget {
  const DoctorMedicalRecordDetailsPage({required this.record, super.key});

  final DoctorMedicalRecord record;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DoctorStyles.page,
    appBar: AppBar(
      title: const Text('Medical Record'),
      backgroundColor: DoctorStyles.mint,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _DoctorDetailsCard(
          rows: [
            ('Record ID', record.id),
            ('Pet', record.petName),
            ('Owner', record.ownerName),
            ('Status', record.finalized ? 'Finalized' : 'Draft'),
            ('Symptoms', record.symptoms),
            ('Findings', _orNotRecorded(record.findings)),
            ('Diagnosis', _orNotRecorded(record.diagnosis)),
            ('Treatment', _orNotRecorded(record.treatment)),
            ('Prescription', _orNotRecorded(record.prescription)),
            ('Vaccination', _orNotRecorded(record.vaccination)),
            ('Next dose', _orNotRecorded(record.nextDoseDate)),
            ('Follow-up', _orNotRecorded(record.followUp)),
            ('Test result', _orNotRecorded(record.testResult)),
          ],
        ),
      ],
    ),
  );
}

class DoctorNotificationsPage extends StatelessWidget {
  const DoctorNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DoctorStyles.page,
    appBar: AppBar(
      title: const Text('Doctor Notifications'),
      backgroundColor: DoctorStyles.mint,
      actions: [
        TextButton(
          onPressed: DoctorNotificationStore.instance.markAllRead,
          child: const Text('Mark all read'),
        ),
      ],
    ),
    body: AnimatedBuilder(
      animation: Listenable.merge([
        DoctorNotificationStore.instance,
        AppointmentStore.instance,
        EmergencyRequestStore.instance,
        HomeVisitStore.instance,
        ContactClinicStore.instance,
      ]),
      builder: (context, _) {
        final generated = <(String, String)>[
          if (AppointmentStore.instance.appointments.any(
            (appointment) => appointment.status == 'Pending',
          ))
            ('New appointment request', 'A booking is waiting for review.'),
          if (AppointmentStore.instance.appointments.any(
            (appointment) => appointment.status == 'Cancelled',
          ))
            ('Cancelled appointment', 'A pet owner cancelled a booking.'),
          if (AppointmentStore.instance.appointments.any(
            (appointment) => appointment.status == 'Reschedule Requested',
          ))
            (
              'Rescheduled appointment',
              'A schedule change is waiting for review.',
            ),
          if (EmergencyRequestStore.instance.requests.any(
            (request) => request.status == EmergencyStatus.submitted,
          ))
            ('New emergency request', 'Review and prioritize the emergency.'),
          if (HomeVisitStore.instance.visits.any(
            (visit) => visit.status == HomeVisitStatus.confirmed,
          ))
            ('Upcoming Home Visit', 'A confirmed Home Visit is scheduled.'),
          if (QueueStore.instance.active.any(
            (entry) =>
                entry.status == QueueStatus.called ||
                entry.status == QueueStatus.almostTurn,
          ))
            ('Queue update', 'A patient is ready to be called or consulted.'),
          if (DoctorMedicalRecordStore.instance.records.any(
            (record) => record.finalized && record.followUp.isNotEmpty,
          ))
            ('Follow-up reminder', 'A finalized record recommends follow-up.'),
          if (ContactClinicStore.instance.messages.any(
            (message) => !message.isFromStaff,
          ))
            ('Pet owner message', 'A new clinic message needs a response.'),
        ];
        final saved = DoctorNotificationStore.instance.notifications;
        if (generated.isEmpty && saved.isEmpty) {
          return const _EmptyDoctorState(
            icon: Icons.notifications_none_rounded,
            title: 'No notifications',
            message: 'Clinical and booking alerts will appear here.',
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final item in generated)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(item.$1),
                  subtitle: Text(item.$2),
                ),
              ),
            for (final item in saved)
              Card(
                child: ListTile(
                  leading: Icon(
                    item.read
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_rounded,
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.message),
                ),
              ),
          ],
        );
      },
    ),
  );
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
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      DoctorEmergencyCaseDetailsPage(request: cases[index]),
                ),
              ),
              child: _EmergencyQueueCard(
                request: cases[index],
                showDetails: false,
              ),
            ),
          );
        },
      ),
    );
  }
}

class DoctorEmergencyCaseDetailsPage extends StatefulWidget {
  const DoctorEmergencyCaseDetailsPage({required this.request, super.key});

  final EmergencyRequest request;

  @override
  State<DoctorEmergencyCaseDetailsPage> createState() =>
      _DoctorEmergencyCaseDetailsPageState();
}

class _DoctorEmergencyCaseDetailsPageState
    extends State<DoctorEmergencyCaseDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Scaffold(
      backgroundColor: DoctorStyles.page,
      appBar: AppBar(
        title: const Text('Emergency Case'),
        backgroundColor: const Color(0xFFFFCDD0),
      ),
      body: AnimatedBuilder(
        animation: EmergencyRequestStore.instance,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _DoctorDetailsCard(
              rows: [
                ('Request ID', '#${request.id}'),
                ('Pet', request.pet.name),
                ('Breed and age', '${request.pet.breed} • ${request.pet.age}'),
                ('Medical history', request.pet.medicalHistory),
                ('Symptoms', request.symptoms.join(', ')),
                ('Description', request.description),
                ('Contact', '${request.contactPerson} • ${request.phone}'),
                ('Priority', request.priority),
                ('Status', _emergencyLabel(request.status)),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const ValueKey('doctor-emergency-priority'),
              initialValue:
                  const {
                    'Low',
                    'Medium',
                    'High',
                    'Critical',
                  }.contains(request.priority)
                  ? request.priority
                  : 'High',
              decoration: const InputDecoration(
                labelText: 'Case priority',
                border: OutlineInputBorder(),
              ),
              items: const ['Low', 'Medium', 'High', 'Critical']
                  .map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(priority),
                    ),
                  )
                  .toList(),
              onChanged: (priority) =>
                  EmergencyRequestStore.instance.staffUpdate(
                    request,
                    EmergencyStatus.underReview,
                    priority: priority,
                  ),
            ),
            const SizedBox(height: 16),
            if (const {
              EmergencyStatus.submitted,
              EmergencyStatus.underReview,
            }.contains(request.status))
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('doctor-refer-emergency'),
                      onPressed: () => EmergencyRequestStore.instance.staffUpdate(
                        request,
                        EmergencyStatus.declined,
                        response:
                            'Referred to the nearest equipped emergency hospital.',
                      ),
                      icon: const Icon(Icons.alt_route_rounded),
                      label: const Text('Refer Case'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('doctor-accept-emergency'),
                      onPressed: () => EmergencyRequestStore.instance
                          .staffUpdate(request, EmergencyStatus.accepted),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Accept Case'),
                    ),
                  ),
                ],
              )
            else if (_nextEmergencyStatus(request.status)
                case final nextStatus?)
              FilledButton.icon(
                key: const ValueKey('doctor-advance-emergency'),
                onPressed: () {
                  EmergencyRequestStore.instance.staffUpdate(
                    request,
                    nextStatus,
                  );
                  if (nextStatus == EmergencyStatus.completed) {
                    DoctorNotificationStore.instance.add(
                      'Emergency treatment completed',
                      '${request.pet.name}’s emergency record was finalized.',
                    );
                  }
                },
                icon: const Icon(Icons.emergency_rounded),
                label: Text(_emergencyAction(nextStatus)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE92832),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
              )
            else
              _DoctorNotice(
                text: request.status == EmergencyStatus.declined
                    ? 'This case was referred to another emergency provider.'
                    : 'The emergency case record is complete.',
              ),
          ],
        ),
      ),
    );
  }
}

class DoctorHomeVisitsPage extends StatelessWidget {
  const DoctorHomeVisitsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DoctorStyles.page,
    appBar: AppBar(
      title: const Text('Home Visits'),
      backgroundColor: DoctorStyles.mint,
    ),
    body: AnimatedBuilder(
      animation: HomeVisitStore.instance,
      builder: (context, _) {
        final visits = HomeVisitStore.instance.visits;
        if (visits.isEmpty) {
          return const _EmptyDoctorState(
            icon: Icons.home_work_outlined,
            title: 'No Home Visits',
            message: 'Assigned and upcoming visits will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: visits.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final visit = visits[index];
            return ListTile(
              key: ValueKey('doctor-home-visit-${visit.id}'),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: DoctorStyles.border),
              ),
              leading: const CircleAvatar(
                backgroundColor: DoctorStyles.softMint,
                child: Icon(Icons.home_work_outlined),
              ),
              title: Text(visit.pet.name),
              subtitle: Text(
                '${_fullDate(visit.date)} • ${visit.time}\n${_doctorHomeVisitLabel(visit.status)}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DoctorHomeVisitDetailsPage(visit: visit),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class DoctorHomeVisitDetailsPage extends StatefulWidget {
  const DoctorHomeVisitDetailsPage({required this.visit, super.key});

  final HomeVisit visit;

  @override
  State<DoctorHomeVisitDetailsPage> createState() =>
      _DoctorHomeVisitDetailsPageState();
}

class _DoctorHomeVisitDetailsPageState
    extends State<DoctorHomeVisitDetailsPage> {
  late final _findings = TextEditingController(text: widget.visit.findings);
  late final _treatment = TextEditingController(
    text: widget.visit.treatmentNotes,
  );
  late final _medicines = TextEditingController(text: widget.visit.medicines);
  late final _recommendations = TextEditingController(
    text: widget.visit.recommendations,
  );

  @override
  void dispose() {
    _findings.dispose();
    _treatment.dispose();
    _medicines.dispose();
    _recommendations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    return Scaffold(
      backgroundColor: DoctorStyles.page,
      appBar: AppBar(
        title: const Text('Home Visit Details'),
        backgroundColor: DoctorStyles.mint,
      ),
      body: AnimatedBuilder(
        animation: HomeVisitStore.instance,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _DoctorDetailsCard(
              rows: [
                ('Booking ID', '#${visit.id}'),
                ('Pet', '${visit.pet.name} • ${visit.pet.breed}'),
                ('Medical history', visit.pet.medicalHistory),
                ('Date and time', '${_fullDate(visit.date)} • ${visit.time}'),
                ('Address', visit.address),
                ('Contact', '${visit.contactPerson} • ${visit.phone}'),
                ('Reason', visit.reason),
                ('Symptoms', visit.symptoms),
                ('Status', _doctorHomeVisitLabel(visit.status)),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('doctor-home-directions'),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening directions to ${visit.address}'),
                ),
              ),
              icon: const Icon(Icons.directions_outlined),
              label: const Text('Open Directions'),
            ),
            const SizedBox(height: 16),
            if (visit.status == HomeVisitStatus.consultation ||
                visit.status == HomeVisitStatus.treatmentProposed) ...[
              TextField(
                key: const ValueKey('home-visit-findings'),
                controller: _findings,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Examination findings',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey('home-visit-treatment'),
                controller: _treatment,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Treatment results',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _medicines,
                decoration: const InputDecoration(
                  labelText: 'Medicines',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _recommendations,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Recommendations',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (_nextHomeVisitStatus(visit.status) case final nextStatus?)
              FilledButton.icon(
                key: const ValueKey('doctor-update-home-visit'),
                onPressed: () => _advanceVisit(nextStatus),
                icon: const Icon(Icons.update_rounded),
                label: Text(_homeVisitAction(nextStatus)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              )
            else
              const _DoctorNotice(
                text: 'This Home Visit and its clinical record are complete.',
              ),
          ],
        ),
      ),
    );
  }

  void _advanceVisit(HomeVisitStatus status) {
    if (status == HomeVisitStatus.completed) {
      widget.visit
        ..findings = _findings.text.trim()
        ..treatmentNotes = _treatment.text.trim()
        ..medicines = _medicines.text.trim()
        ..recommendations = _recommendations.text.trim();
      HomeVisitStore.instance.updateStatus(widget.visit, status);
      DoctorNotificationStore.instance.add(
        'Home Visit completed',
        '${widget.visit.pet.name}’s visit results were saved.',
      );
    } else {
      HomeVisitStore.instance.updateStatus(widget.visit, status);
    }
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

class DoctorProfileStore extends ChangeNotifier {
  DoctorProfileStore._();

  static final instance = DoctorProfileStore._();
  String name = 'Dr. Aye Chan';
  String specialty = 'General Veterinarian';
  String license = 'VET-MM-1042';
  String experience = '8 years';
  String biography =
      'Compassionate veterinarian focused on preventive care and clear communication with pet owners.';
  String phone = '09-5312717';
  String email = 'doctor@nwaysclinic.com';
  bool acceptingAppointments = true;
  bool notificationsEnabled = true;

  void save({
    required String name,
    required String specialty,
    required String biography,
    required String phone,
    required String email,
  }) {
    this.name = name;
    this.specialty = specialty;
    this.biography = biography;
    this.phone = phone;
    this.email = email;
    notifyListeners();
  }

  void setAvailability(bool value) {
    acceptingAppointments = value;
    notifyListeners();
  }

  void setNotifications(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }
}

class DoctorProfilePage extends StatelessWidget {
  const DoctorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DoctorProfileStore.instance,
      builder: (context, _) {
        final profile = DoctorProfileStore.instance;
        return ListView(
          key: const ValueKey('doctor-profile'),
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 36),
          children: [
            const CircleAvatar(
              radius: 52,
              backgroundColor: DoctorStyles.mint,
              child: Icon(Icons.medical_services_rounded, size: 52),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile photo picker opened.')),
              ),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Change Photo'),
            ),
            Text(
              profile.name,
              textAlign: TextAlign.center,
              style: DoctorStyles.title,
            ),
            Text(
              profile.specialty,
              textAlign: TextAlign.center,
              style: DoctorStyles.muted,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('edit-doctor-profile'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EditDoctorProfilePage(),
                ),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile'),
            ),
            const SizedBox(height: 14),
            _DoctorDetailsCard(
              rows: [
                ('License', profile.license),
                ('Clinic', "Nway's Love Vet Clinic"),
                ('Email', profile.email),
                ('Phone', profile.phone),
                ('Experience', profile.experience),
                ('Biography', profile.biography),
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
            const SizedBox(height: 14),
            SwitchListTile(
              key: const ValueKey('doctor-availability-setting'),
              value: profile.acceptingAppointments,
              onChanged: profile.setAvailability,
              title: const Text('Accepting appointments'),
              subtitle: const Text('Allow new bookings in available slots'),
            ),
            SwitchListTile(
              key: const ValueKey('doctor-notification-setting'),
              value: profile.notificationsEnabled,
              onChanged: profile.setNotifications,
              title: const Text('Doctor notifications'),
              subtitle: const Text('Appointments, emergencies and Home Visits'),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded),
              title: const Text('Help and Support'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clinic support: 09-5312717')),
              ),
            ),
            const SizedBox(height: 14),
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
      },
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

class EditDoctorProfilePage extends StatefulWidget {
  const EditDoctorProfilePage({super.key});

  @override
  State<EditDoctorProfilePage> createState() => _EditDoctorProfilePageState();
}

class _EditDoctorProfilePageState extends State<EditDoctorProfilePage> {
  late final _name = TextEditingController(
    text: DoctorProfileStore.instance.name,
  );
  late final _specialty = TextEditingController(
    text: DoctorProfileStore.instance.specialty,
  );
  late final _biography = TextEditingController(
    text: DoctorProfileStore.instance.biography,
  );
  late final _phone = TextEditingController(
    text: DoctorProfileStore.instance.phone,
  );
  late final _email = TextEditingController(
    text: DoctorProfileStore.instance.email,
  );

  @override
  void dispose() {
    _name.dispose();
    _specialty.dispose();
    _biography.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DoctorStyles.page,
    appBar: AppBar(
      title: const Text('Edit Doctor Profile'),
      backgroundColor: DoctorStyles.mint,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final field in <(String, TextEditingController, int)>[
          ('Full name', _name, 1),
          ('Specialty', _specialty, 1),
          ('Biography', _biography, 4),
          ('Phone number', _phone, 1),
          ('Email', _email, 1),
        ]) ...[
          TextField(
            controller: field.$2,
            maxLines: field.$3,
            decoration: InputDecoration(
              labelText: field.$1,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton(
          key: const ValueKey('save-doctor-profile'),
          onPressed: () {
            if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) return;
            DoctorProfileStore.instance.save(
              name: _name.text.trim(),
              specialty: _specialty.text.trim(),
              biography: _biography.text.trim(),
              phone: _phone.text.trim(),
              email: _email.text.trim(),
            );
            Navigator.of(context).pop();
          },
          child: const Text('Save Changes'),
        ),
      ],
    ),
  );
}

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
  'Confirmed' => 'Checked In',
  'Checked In' => 'Called',
  'Called' => 'In Consultation',
  _ => null,
};

String _statusAction(String status) => switch (status) {
  'Confirmed' => 'Confirm Appointment',
  'Checked In' => 'Check In Patient',
  'Called' => 'Call Patient',
  'In Consultation' => 'Start Consultation',
  'Completed' => 'Complete Consultation',
  _ => 'Update Status',
};

IconData _statusIcon(String status) => switch (status) {
  'Confirmed' => Icons.event_available_rounded,
  'Checked In' => Icons.login_rounded,
  'Called' => Icons.campaign_outlined,
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

EmergencyStatus? _nextEmergencyStatus(EmergencyStatus status) =>
    switch (status) {
      EmergencyStatus.accepted => EmergencyStatus.assessment,
      EmergencyStatus.checkedIn ||
      EmergencyStatus.waiting => EmergencyStatus.assessment,
      EmergencyStatus.assessment => EmergencyStatus.consultation,
      EmergencyStatus.consultation => EmergencyStatus.treatmentProposed,
      EmergencyStatus.treatmentProposed => EmergencyStatus.treatmentInProgress,
      EmergencyStatus.treatmentInProgress => EmergencyStatus.completed,
      _ => null,
    };

String _emergencyAction(EmergencyStatus status) => switch (status) {
  EmergencyStatus.assessment => 'Start Assessment',
  EmergencyStatus.consultation => 'Start Emergency Consultation',
  EmergencyStatus.treatmentProposed => 'Record Proposed Treatment',
  EmergencyStatus.treatmentInProgress => 'Start Emergency Treatment',
  EmergencyStatus.completed => 'Complete Emergency Case',
  _ => 'Update Emergency Case',
};

HomeVisitStatus? _nextHomeVisitStatus(HomeVisitStatus status) =>
    switch (status) {
      HomeVisitStatus.confirmed => HomeVisitStatus.onTheWay,
      HomeVisitStatus.onTheWay => HomeVisitStatus.arrived,
      HomeVisitStatus.arrived => HomeVisitStatus.consultation,
      HomeVisitStatus.consultation ||
      HomeVisitStatus.treatmentProposed => HomeVisitStatus.completed,
      HomeVisitStatus.completed => null,
    };

String _doctorHomeVisitLabel(HomeVisitStatus status) => switch (status) {
  HomeVisitStatus.confirmed => 'Confirmed',
  HomeVisitStatus.onTheWay => 'On the Way',
  HomeVisitStatus.arrived => 'Arrived',
  HomeVisitStatus.consultation ||
  HomeVisitStatus.treatmentProposed => 'In Progress',
  HomeVisitStatus.completed => 'Completed',
};

String _homeVisitAction(HomeVisitStatus status) => switch (status) {
  HomeVisitStatus.onTheWay => 'Start Travel',
  HomeVisitStatus.arrived => 'Mark Arrived',
  HomeVisitStatus.consultation => 'Start Home Consultation',
  HomeVisitStatus.completed => 'Complete Home Visit',
  _ => 'Update Visit',
};

String _orNotRecorded(String value) =>
    value.trim().isEmpty ? 'Not recorded' : value;
