import 'package:flutter/material.dart';

import '../login/login_page.dart';
import '../pet_owner/appointment_booking_page.dart';

class DoctorPortalPage extends StatefulWidget {
  const DoctorPortalPage({super.key});

  static const routeName = '/doctor';

  @override
  State<DoctorPortalPage> createState() => _DoctorPortalPageState();
}

class _DoctorPortalPageState extends State<DoctorPortalPage> {
  var _index = 0;

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
        children: const [
          DoctorDashboardPage(),
          DoctorAppointmentsPage(),
          DoctorProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: Colors.white,
        indicatorColor: DoctorStyles.mint,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            key: ValueKey('doctor-dashboard-tab'),
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            key: ValueKey('doctor-appointments-tab'),
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Appointments',
          ),
          NavigationDestination(
            key: ValueKey('doctor-profile-tab'),
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
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
  const DoctorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        DoctorAppointmentStore.instance,
        AppointmentStore.instance,
      ]),
      builder: (context, _) {
        final records = DoctorAppointmentStore.instance.appointments;
        final today = records
            .where((record) => DateUtils.isSameDay(record.date, DateTime.now()))
            .toList();
        final completed = today
            .where((record) => record.status == 'Completed')
            .length;
        final active = today
            .where(
              (record) =>
                  !const {'Completed', 'Cancelled'}.contains(record.status),
            )
            .length;
        final next = today.cast<DoctorAppointmentRecord?>().firstWhere(
          (record) =>
              record != null &&
              !const {'Completed', 'Cancelled'}.contains(record.status),
          orElse: () => null,
        );
        return ListView(
          key: const ValueKey('doctor-dashboard'),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
          children: [
            const Text('Good day, Dr. Aye Chan', style: DoctorStyles.title),
            const SizedBox(height: 5),
            Text(_fullDate(DateTime.now()), style: DoctorStyles.muted),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: "Today's appointments",
                    value: '${today.length}',
                    icon: Icons.calendar_today_rounded,
                    color: const Color(0xFF176B50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Waiting / active',
                    value: '$active',
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFFB26A00),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatCard(
              label: 'Completed today',
              value: '$completed',
              icon: Icons.task_alt_rounded,
              color: const Color(0xFF2358A5),
              horizontal: true,
            ),
            const SizedBox(height: 24),
            const Text('Next Appointment', style: DoctorStyles.section),
            const SizedBox(height: 10),
            if (next == null)
              const _EmptyDoctorState(
                icon: Icons.event_available_rounded,
                title: 'No more appointments today',
                message: 'Your remaining schedule is clear.',
              )
            else
              DoctorAppointmentCard(record: next),
            const SizedBox(height: 24),
            const Text("Today's Schedule", style: DoctorStyles.section),
            const SizedBox(height: 10),
            for (final record in today) ...[
              DoctorAppointmentCard(record: record, compact: true),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({super.key});

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  String _filter = 'All';
  static const _filters = [
    'All',
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
        final records = _filter == 'All'
            ? all
            : all.where((record) => record.status == _filter).toList();
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.horizontal = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool horizontal;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: DoctorStyles.border),
    ),
    child: horizontal
        ? Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: DoctorStyles.body)),
              Text(value, style: DoctorStyles.stat),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 14),
              Text(value, style: DoctorStyles.stat),
              const SizedBox(height: 3),
              Text(label, style: DoctorStyles.muted),
            ],
          ),
  );
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
