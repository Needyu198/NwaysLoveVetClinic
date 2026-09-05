import 'package:flutter/material.dart';

import '../doctor/doctor_portal.dart';
import '../login/login_page.dart';
import '../pet_owner/appointment_booking_page.dart';
import '../pet_owner/contact_clinic_page.dart';
import '../pet_owner/emergency_service_page.dart';
import '../pet_owner/home_visit_booking_page.dart';

const _mint = Color(0xFFA1FDD8);
const _green = Color(0xFF147D5B);
const _ink = Color(0xFF17201D);
const _page = Color(0xFFF5F8F6);
const _border = Color(0xFFD9E6E1);
const _muted = Color(0xFF66756F);
const _red = Color(0xFFD9343B);

class StaffPortalPage extends StatefulWidget {
  const StaffPortalPage({super.key});

  static const routeName = '/staff/dashboard';

  @override
  State<StaffPortalPage> createState() => _StaffPortalPageState();
}

class _StaffPortalPageState extends State<StaffPortalPage> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      body: IndexedStack(
        index: _index,
        children: [
          StaffDashboardPage(onOpenProfile: () => setState(() => _index = 2)),
          const StaffManagementPage(),
          const StaffProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        key: const ValueKey('staff-navigation-bar'),
        selectedIndex: _index,
        indicatorColor: _mint,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            key: ValueKey('staff-management-tab'),
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Management',
          ),
          NavigationDestination(
            key: ValueKey('staff-profile-tab'),
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class StaffManagementPage extends StatelessWidget {
  const StaffManagementPage({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        const _InlineHeader(
          title: 'Management',
          subtitle: 'Clinic operations and patient services',
        ),
        Expanded(
          child: GridView.count(
            key: const ValueKey('staff-management-menu'),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            crossAxisCount: 2,
            childAspectRatio: 1.08,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _ManagementCard(
                title: 'Appointments',
                subtitle: 'Confirm, assign and check in',
                icon: Icons.event_note_rounded,
                color: _mint,
                onTap: () => _push(
                  context,
                  const StaffAppointmentsPage(standalone: true),
                ),
              ),
              _ManagementCard(
                title: 'Queue',
                subtitle: 'Manage the live clinic queue',
                icon: Icons.format_list_numbered_rounded,
                color: const Color(0xFFFFE3A8),
                onTap: () => _push(context, const StaffQueueStandalonePage()),
              ),
              _ManagementCard(
                title: 'Messages',
                subtitle: 'Owner conversations and triage',
                icon: Icons.chat_bubble_rounded,
                color: const Color(0xFFCFE0FF),
                onTap: () =>
                    _push(context, const StaffMessagesPage(standalone: true)),
              ),
              _ManagementCard(
                key: const ValueKey('staff-inventory-card'),
                title: 'Inventory',
                subtitle: 'Stock, alerts and restock requests',
                icon: Icons.inventory_2_rounded,
                color: const Color(0xFFE2D4FF),
                onTap: () => _push(context, const StaffInventoryPage()),
              ),
              _ManagementCard(
                title: 'Medical Records',
                subtitle: 'View finalized clinical records',
                icon: Icons.folder_shared_rounded,
                color: const Color(0xFFD8F3ED),
                onTap: () => _push(context, const StaffMedicalRecordsPage()),
              ),
              _ManagementCard(
                title: 'Emergency Cases',
                subtitle: 'Review and coordinate urgent care',
                icon: Icons.emergency_rounded,
                color: const Color(0xFFFFC7C9),
                onTap: () => _push(context, const StaffEmergencyPage()),
              ),
              _ManagementCard(
                title: 'Home Visits',
                subtitle: 'Verify and coordinate visits',
                icon: Icons.home_work_rounded,
                color: const Color(0xFFFFE8C7),
                onTap: () => _push(context, const StaffHomeVisitsPage()),
              ),
              _ManagementCard(
                title: 'Health Posts',
                subtitle: 'Review clinic education posts',
                icon: Icons.article_rounded,
                color: const Color(0xFFD6E8FF),
                onTap: () => _push(context, const StaffHealthPostsPage()),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class StaffOperationsStore extends ChangeNotifier {
  StaffOperationsStore._() {
    _seed();
  }
  static final instance = StaffOperationsStore._();

  final List<StaffAppointment> _demo = [];
  final List<StaffPayment> payments = [
    StaffPayment(
      id: 'INV-24091',
      owner: 'Lynn Htet',
      pet: 'Bruno',
      amount: 45000,
      status: 'Unpaid',
    ),
    StaffPayment(
      id: 'INV-24088',
      owner: 'Thiri Win',
      pet: 'Sugar',
      amount: 28000,
      status: 'Partially Paid',
    ),
    StaffPayment(
      id: 'INV-24077',
      owner: 'May Zin',
      pet: 'Luna',
      amount: 32000,
      status: 'Paid',
    ),
  ];
  final List<InventoryItem> inventory = [
    InventoryItem(
      id: 'MED-001',
      name: 'Amoxicillin 250 mg',
      category: 'Medicine',
      quantity: 18,
      reorderLevel: 20,
      unit: 'capsules',
      expiresOn: DateTime.now().add(const Duration(days: 180)),
    ),
    InventoryItem(
      id: 'MED-014',
      name: 'Meloxicam Oral Suspension',
      category: 'Medicine',
      quantity: 7,
      reorderLevel: 10,
      unit: 'bottles',
      expiresOn: DateTime.now().add(const Duration(days: 75)),
    ),
    InventoryItem(
      id: 'SUP-008',
      name: 'Sterile Examination Gloves',
      category: 'Supply',
      quantity: 240,
      reorderLevel: 100,
      unit: 'pairs',
      expiresOn: DateTime.now().add(const Duration(days: 700)),
    ),
    InventoryItem(
      id: 'SUP-021',
      name: 'Wound Dressing 10 cm',
      category: 'Supply',
      quantity: 0,
      reorderLevel: 25,
      unit: 'packs',
      expiresOn: DateTime.now().subtract(const Duration(days: 12)),
    ),
  ];

  void adjustStock(InventoryItem item, int quantity, String reason) {
    item.quantity = quantity.clamp(0, 999999);
    item.lastAudit = '$reason • Mya Thu • ${_shortDate(DateTime.now())}';
    notifyListeners();
  }

  void requestRestock(InventoryItem item, int quantity, String note) {
    item.restockRequested = true;
    item.restockQuantity = quantity;
    item.restockNote = note;
    notifyListeners();
  }

  List<StaffAppointment> get appointments {
    final linked = AppointmentStore.instance.appointments.map(
      StaffAppointment.fromBooking,
    );
    return [..._demo, ...linked]..sort((a, b) {
      final day = a.date.compareTo(b.date);
      return day == 0 ? a.time.compareTo(b.time) : day;
    });
  }

  void _seed() {
    final now = DateTime.now();
    _demo.addAll([
      StaffAppointment(
        id: 'APT-1042',
        pet: 'Bruno',
        owner: 'Lynn Htet',
        phone: '09 421 555 018',
        service: 'General Checkup',
        doctor: 'Dr. Aye Chan',
        date: now,
        time: '09:30 AM',
        reason: 'Loss of appetite',
        status: 'Confirmed',
        priority: 'Normal',
      ),
      StaffAppointment(
        id: 'APT-1043',
        pet: 'Milo',
        owner: 'Nandar Moe',
        phone: '09 770 123 882',
        service: 'Vaccination',
        doctor: 'Dr. Cindy Lynn',
        date: now,
        time: '10:15 AM',
        reason: 'Annual vaccination',
        status: 'Checked In',
        priority: 'Normal',
        queueNumber: 'Q12',
      ),
      StaffAppointment(
        id: 'APT-1044',
        pet: 'Luna',
        owner: 'May Zin',
        phone: '09 450 920 111',
        service: 'Emergency Care',
        doctor: 'Dr. Myat Noe',
        date: now,
        time: '10:30 AM',
        reason: 'Breathing difficulty',
        status: 'Waiting',
        priority: 'Urgent',
        queueNumber: 'E01',
      ),
      StaffAppointment(
        id: 'APT-1045',
        pet: 'Sugar',
        owner: 'Thiri Win',
        phone: '09 790 440 201',
        service: 'Follow-up',
        doctor: 'Unassigned',
        date: now.add(const Duration(days: 1)),
        time: '02:00 PM',
        reason: 'Skin follow-up',
        status: 'Pending',
        priority: 'Normal',
      ),
    ]);
  }

  void update(
    StaffAppointment item, {
    String? status,
    String? doctor,
    DateTime? date,
    String? time,
  }) {
    if (status != null) item.status = status;
    if (doctor != null) item.doctor = doctor;
    if (date != null) item.date = date;
    if (time != null) item.time = time;
    final source = item.source;
    if (source != null) {
      if (doctor != null) source.veterinarian = doctor;
      if (date != null) source.date = date;
      if (time != null) source.time = time;
      if (status != null) {
        AppointmentStore.instance.staffSetStatus(source, status);
      }
    }
    notifyListeners();
  }

  void checkIn(StaffAppointment item) {
    if (item.queueNumber.isEmpty) {
      item.queueNumber = item.priority == 'Urgent'
          ? 'E${_demo.length + 1}'
          : 'Q${12 + appointments.where((a) => a.queueNumber.isNotEmpty).length}';
    }
    update(item, status: 'Waiting');
  }

  void addWalkIn({
    required String owner,
    required String pet,
    required String service,
    required String doctor,
    required String reason,
    required bool urgent,
  }) {
    final timestamp = DateTime.now();
    _demo.add(
      StaffAppointment(
        id: 'WALK-${timestamp.microsecondsSinceEpoch}',
        pet: pet,
        owner: owner,
        phone: 'Not recorded',
        service: service,
        doctor: doctor,
        date: timestamp,
        time:
            '${timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour)}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.hour >= 12 ? 'PM' : 'AM'}',
        reason: reason,
        status: 'Waiting',
        priority: urgent ? 'Urgent' : 'Normal',
        queueNumber: urgent ? 'E${_demo.length + 1}' : 'Q${13 + _demo.length}',
      ),
    );
    notifyListeners();
  }
}

class StaffAppointment {
  StaffAppointment({
    required this.id,
    required this.pet,
    required this.owner,
    required this.phone,
    required this.service,
    required this.doctor,
    required this.date,
    required this.time,
    required this.reason,
    required this.status,
    required this.priority,
    this.queueNumber = '',
    this.source,
  });

  factory StaffAppointment.fromBooking(BookedAppointment value) =>
      StaffAppointment(
        id: value.id,
        pet: value.pet.name,
        owner: 'Registered Owner',
        phone: 'Owner account',
        service: value.service.name,
        doctor: value.veterinarian,
        date: value.date,
        time: value.time,
        reason: value.reason,
        status: value.status,
        priority: 'Normal',
        source: value,
        queueNumber:
            QueueStore.instance.existingEntryFor(value)?.queueNumber ?? '',
      );

  final String id;
  final String pet;
  final String owner;
  final String phone;
  final String service;
  String doctor;
  DateTime date;
  String time;
  final String reason;
  String status;
  final String priority;
  String queueNumber;
  final BookedAppointment? source;
}

class StaffPayment {
  StaffPayment({
    required this.id,
    required this.owner,
    required this.pet,
    required this.amount,
    required this.status,
  });
  final String id;
  final String owner;
  final String pet;
  final int amount;
  String status;
}

class InventoryItem {
  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.reorderLevel,
    required this.unit,
    required this.expiresOn,
  });

  final String id;
  final String name;
  final String category;
  int quantity;
  final int reorderLevel;
  final String unit;
  final DateTime expiresOn;
  bool restockRequested = false;
  int restockQuantity = 0;
  String restockNote = '';
  String lastAudit = 'No stock changes recorded';

  bool get isLowStock => quantity <= reorderLevel;
  bool get isExpired => expiresOn.isBefore(DateTime.now());
}

class StaffDashboardPage extends StatelessWidget {
  const StaffDashboardPage({required this.onOpenProfile, super.key});
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        StaffOperationsStore.instance,
        AppointmentStore.instance,
        EmergencyRequestStore.instance,
        HomeVisitStore.instance,
      ]),
      builder: (context, _) {
        final items = StaffOperationsStore.instance.appointments;
        final today = items
            .where(
              (a) =>
                  DateUtils.isSameDay(a.date, DateTime.now()) &&
                  a.status != 'Cancelled',
            )
            .toList();
        final waiting = today
            .where(
              (a) =>
                  const {'Checked In', 'Waiting', 'Called'}.contains(a.status),
            )
            .length;
        final emergencies =
            today.where((a) => a.priority == 'Urgent').length +
            EmergencyRequestStore.instance.requests
                .where(
                  (r) =>
                      r.status != EmergencyStatus.completed &&
                      r.status != EmergencyStatus.declined,
                )
                .length;
        final pendingPayments = StaffOperationsStore.instance.payments
            .where((p) => p.status != 'Paid')
            .length;
        return CustomScrollView(
          key: const ValueKey('staff-dashboard'),
          slivers: [
            SliverToBoxAdapter(
              child: _DashboardHeader(onProfile: onOpenProfile),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Clinic overview', style: _sectionStyle),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.55,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _StatCard(
                          label: "Today's appointments",
                          value: '${today.length}',
                          icon: Icons.event_available_rounded,
                          color: _mint,
                          onTap: () => _push(
                            context,
                            const StaffAppointmentsPage(
                              initialFilter: 'Today',
                              standalone: true,
                            ),
                          ),
                        ),
                        _StatCard(
                          label: 'Waiting patients',
                          value: '$waiting',
                          icon: Icons.groups_rounded,
                          color: const Color(0xFFFFE3A8),
                          onTap: () =>
                              _push(context, const StaffQueueStandalonePage()),
                        ),
                        _StatCard(
                          label: 'Emergency cases',
                          value: '$emergencies',
                          icon: Icons.emergency_rounded,
                          color: const Color(0xFFFFC7C9),
                          onTap: () =>
                              _push(context, const StaffEmergencyPage()),
                        ),
                        _StatCard(
                          label: 'Pending payments',
                          value: '$pendingPayments',
                          icon: Icons.payments_outlined,
                          color: const Color(0xFFCFE0FF),
                          onTap: () =>
                              _push(context, const StaffPaymentsPage()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Quick actions', style: _sectionStyle),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 92,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _QuickAction(
                            icon: Icons.login_rounded,
                            label: 'Check in',
                            onTap: () => _push(
                              context,
                              const StaffAppointmentsPage(
                                initialFilter: 'Confirmed',
                                standalone: true,
                              ),
                            ),
                          ),
                          _QuickAction(
                            icon: Icons.add_circle_outline_rounded,
                            label: 'Walk-in',
                            onTap: () =>
                                _push(context, const StaffWalkInPage()),
                          ),
                          _QuickAction(
                            icon: Icons.format_list_numbered_rounded,
                            label: 'Queue',
                            onTap: () => _push(
                              context,
                              const StaffQueueStandalonePage(),
                            ),
                          ),
                          _QuickAction(
                            icon: Icons.home_work_outlined,
                            label: 'Home visits',
                            onTap: () =>
                                _push(context, const StaffHomeVisitsPage()),
                          ),
                          _QuickAction(
                            icon: Icons.person_search_rounded,
                            label: 'Patients',
                            onTap: () =>
                                _push(context, const StaffPatientsPage()),
                          ),
                          _QuickAction(
                            icon: Icons.bar_chart_rounded,
                            label: 'Reports',
                            onTap: () =>
                                _push(context, const StaffReportsPage()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Today's appointments",
                            style: _sectionStyle,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _push(
                            context,
                            const StaffAppointmentsPage(
                              initialFilter: 'Today',
                              standalone: true,
                            ),
                          ),
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (today.isEmpty)
                      const _EmptyCard(
                        icon: Icons.event_busy_rounded,
                        text: 'No appointments scheduled today',
                      )
                    else
                      ...today
                          .take(3)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AppointmentTile(
                                item: item,
                                onTap: () => _push(
                                  context,
                                  StaffAppointmentDetailsPage(item: item),
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),
                    const Text('Doctor availability', style: _sectionStyle),
                    const SizedBox(height: 10),
                    const _DoctorAvailability(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onProfile});
  final VoidCallback onProfile;
  @override
  Widget build(BuildContext context) => Container(
    color: _mint,
    padding: EdgeInsets.fromLTRB(
      20,
      MediaQuery.paddingOf(context).top + 18,
      14,
      24,
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(7),
          child: Image.asset('assets/photos/logoandphoto/nways_love_logo.png'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, Mya',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_fullDate(DateTime.now())} • Morning shift',
                style: const TextStyle(fontSize: 12, color: _ink),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _showInfo(
            context,
            'Notifications',
            'No new notifications. Operational alerts will appear here.',
          ),
          icon: const Badge(child: Icon(Icons.notifications_none_rounded)),
        ),
        IconButton(
          onPressed: onProfile,
          icon: const Icon(Icons.account_circle_rounded, size: 30),
        ),
      ],
    ),
  );
}

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
          if (item.status == 'Confirmed')
            _ActionButton(
              key: const ValueKey('staff-check-in'),
              label: 'Confirm Check-in',
              icon: Icons.login_rounded,
              onTap: () {
                StaffOperationsStore.instance.checkIn(item);
                _notice(
                  context,
                  '${item.pet} checked in • Queue ${item.queueNumber}',
                );
              },
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

class StaffWalkInPage extends StatefulWidget {
  const StaffWalkInPage({super.key});
  @override
  State<StaffWalkInPage> createState() => _StaffWalkInPageState();
}

class _StaffWalkInPageState extends State<StaffWalkInPage> {
  final _owner = TextEditingController();
  final _pet = TextEditingController();
  final _reason = TextEditingController();
  var _service = 'General Checkup';
  var _doctor = 'Dr. Aye Chan';
  var _urgent = false;
  @override
  void dispose() {
    _owner.dispose();
    _pet.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    appBar: _appBar('Register Walk-In'),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const _Callout(
          icon: Icons.info_outline_rounded,
          text: 'Suspected emergencies must use the emergency workflow.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _owner,
          decoration: _input('Owner name', Icons.person_outline_rounded),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pet,
          decoration: _input('Pet name', Icons.pets_outlined),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _service,
          decoration: _input('Service', Icons.medical_services_outlined),
          items: [
            'General Checkup',
            'Vaccination',
            'Follow-up',
            'Pet Care',
          ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => _service = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _doctor,
          decoration: _input('Available doctor', Icons.person_search_rounded),
          items: _doctors
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) => setState(() => _doctor = v!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reason,
          maxLines: 3,
          decoration: _input('Visit reason', Icons.notes_rounded),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          value: _urgent,
          activeThumbColor: _green,
          title: const Text('Urgent priority'),
          subtitle: const Text(
            'Provisional only; veterinarian confirms medical priority.',
          ),
          onChanged: (v) => setState(() => _urgent = v),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const ValueKey('register-walk-in'),
          onPressed: () {
            if (_owner.text.trim().isEmpty ||
                _pet.text.trim().isEmpty ||
                _reason.text.trim().isEmpty) {
              _notice(context, 'Complete the owner, pet, and visit reason.');
              return;
            }
            StaffOperationsStore.instance.addWalkIn(
              owner: _owner.text.trim(),
              pet: _pet.text.trim(),
              service: _service,
              doctor: _doctor,
              reason: _reason.text.trim(),
              urgent: _urgent,
            );
            Navigator.pop(context);
            _notice(context, 'Walk-in registered and added to the queue.');
          },
          icon: const Icon(Icons.add_circle_rounded),
          label: const Text('Register Walk-In'),
        ),
      ],
    ),
  );
}

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

class StaffHomeVisitsPage extends StatelessWidget {
  const StaffHomeVisitsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    appBar: _appBar('Home Visits'),
    body: AnimatedBuilder(
      animation: HomeVisitStore.instance,
      builder: (_, _) {
        final visits = HomeVisitStore.instance.visits;
        if (visits.isEmpty) {
          return const Center(child: Text('No home visit requests yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: visits.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final visit = visits[i];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${visit.pet.name} • ${visit.reason}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_shortDate(visit.date)} at ${visit.time}\n${visit.address}\n${visit.veterinarian}',
                    style: const TextStyle(color: _muted, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Chip(
                        label: Text(_homeLabel(visit.status)),
                        backgroundColor: const Color(0xFFE6FAF2),
                      ),
                      const Spacer(),
                      if (visit.status != HomeVisitStatus.completed)
                        OutlinedButton(
                          onPressed: () => _showInfo(
                            context,
                            'Address verified',
                            'The address is inside the clinic service area.',
                          ),
                          child: const Text('Verify address'),
                        ),
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

class StaffPaymentsPage extends StatefulWidget {
  const StaffPaymentsPage({super.key});
  @override
  State<StaffPaymentsPage> createState() => _StaffPaymentsPageState();
}

class _StaffPaymentsPageState extends State<StaffPaymentsPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    appBar: _appBar('Billing & Payments'),
    body: ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: StaffOperationsStore.instance.payments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final payment = StaffOperationsStore.instance.payments[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE6FAF2),
                    child: Icon(Icons.receipt_long_rounded, color: _green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.id,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${payment.pet} • ${payment.owner}',
                          style: const TextStyle(color: _muted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${payment.amount} MMK',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        payment.status,
                        style: TextStyle(
                          color: payment.status == 'Paid' ? _green : _red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (payment.status != 'Paid') ...[
                const Divider(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final method = await showModalBottomSheet<String>(
                        context: context,
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                [
                                      'Cash',
                                      'Card',
                                      'Bank Transfer',
                                      'Online Payment',
                                    ]
                                    .map(
                                      (m) => ListTile(
                                        title: Text(m),
                                        leading: const Icon(
                                          Icons.payments_outlined,
                                        ),
                                        onTap: () => Navigator.pop(context, m),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      );
                      if (method != null) {
                        setState(() => payment.status = 'Paid');
                        if (context.mounted) {
                          _showInfo(
                            context,
                            'Payment recorded',
                            'Receipt generated for ${payment.id} • $method. The audit entry cannot be deleted.',
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirm Payment'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}

class StaffInventoryPage extends StatefulWidget {
  const StaffInventoryPage({this.canAdjustStock = true, super.key});

  final bool canAdjustStock;

  @override
  State<StaffInventoryPage> createState() => _StaffInventoryPageState();
}

class _StaffInventoryPageState extends State<StaffInventoryPage> {
  String _query = '';
  String _filter = 'All';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    appBar: _appBar('Inventory'),
    body: AnimatedBuilder(
      animation: StaffOperationsStore.instance,
      builder: (context, _) {
        final all = StaffOperationsStore.instance.inventory;
        final lowCount = all.where((item) => item.isLowStock).length;
        final expiredCount = all.where((item) => item.isExpired).length;
        final items = all.where((item) {
          final matchesSearch = '${item.id} ${item.name} ${item.category}'
              .toLowerCase()
              .contains(_query.toLowerCase());
          final matchesFilter = switch (_filter) {
            'Low stock' => item.isLowStock,
            'Expired' => item.isExpired,
            'Medicine' || 'Supply' => item.category == _filter,
            _ => true,
          };
          return matchesSearch && matchesFilter;
        }).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _InventoryAlert(
                          label: 'Low stock',
                          value: '$lowCount',
                          icon: Icons.inventory_2_outlined,
                          color: const Color(0xFFFFE3A8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InventoryAlert(
                          label: 'Expired',
                          value: '$expiredCount',
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFFFC7C9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('staff-inventory-search'),
                    onChanged: (value) => setState(() => _query = value),
                    decoration: _input(
                      'Search medicine or supplies',
                      Icons.search_rounded,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: ['All', 'Medicine', 'Supply', 'Low stock', 'Expired']
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
              child: items.isEmpty
                  ? const Center(child: Text('No matching inventory items'))
                  : ListView.separated(
                      key: const ValueKey('staff-inventory-list'),
                      padding: const EdgeInsets.all(18),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, index) => _InventoryCard(
                        item: items[index],
                        canAdjustStock: widget.canAdjustStock,
                        onAdjust: () => _adjustInventory(context, items[index]),
                        onRestock: () => _requestRestock(context, items[index]),
                      ),
                    ),
            ),
          ],
        );
      },
    ),
  );
}

class _InventoryAlert extends StatelessWidget {
  const _InventoryAlert({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon),
        const SizedBox(width: 9),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.item,
    required this.canAdjustStock,
    required this.onAdjust,
    required this.onRestock,
  });
  final InventoryItem item;
  final bool canAdjustStock;
  final VoidCallback onAdjust;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(
      border: item.isExpired
          ? _red
          : item.isLowStock
          ? const Color(0xFFE5A000)
          : _border,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: item.category == 'Medicine'
                    ? const Color(0xFFE6FAF2)
                    : const Color(0xFFE9E5FF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                item.category == 'Medicine'
                    ? Icons.medication_rounded
                    : Icons.medical_information_outlined,
                color: _green,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${item.id} • ${item.category}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  item.unit,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 11),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            if (item.isLowStock)
              const Chip(
                avatar: Icon(Icons.inventory_2_outlined, size: 16),
                label: Text('Low stock'),
                backgroundColor: Color(0xFFFFE3A8),
              ),
            if (item.isExpired)
              const Chip(
                avatar: Icon(Icons.warning_amber_rounded, size: 16),
                label: Text('Expired'),
                backgroundColor: Color(0xFFFFC7C9),
              ),
            if (item.restockRequested)
              Chip(
                avatar: const Icon(Icons.local_shipping_outlined, size: 16),
                label: Text('Requested +${item.restockQuantity}'),
                backgroundColor: const Color(0xFFCFE0FF),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Reorder at ${item.reorderLevel} • Expires ${_shortDate(item.expiresOn)}',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        const Divider(height: 22),
        Row(
          children: [
            Expanded(
              flex: canAdjustStock ? 1 : 2,
              child: OutlinedButton.icon(
                onPressed: onRestock,
                icon: const Icon(Icons.local_shipping_outlined),
                label: Text(
                  item.restockRequested ? 'Update request' : 'Request restock',
                ),
              ),
            ),
            if (canAdjustStock) ...[
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  key: ValueKey('adjust-stock-${item.id}'),
                  onPressed: onAdjust,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Adjust stock'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Audit: ${item.lastAudit}',
          style: const TextStyle(color: _muted, fontSize: 10),
        ),
      ],
    ),
  );
}

class StaffMedicalRecordsPage extends StatefulWidget {
  const StaffMedicalRecordsPage({super.key});

  @override
  State<StaffMedicalRecordsPage> createState() =>
      _StaffMedicalRecordsPageState();
}

class _StaffMedicalRecordsPageState extends State<StaffMedicalRecordsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    appBar: _appBar('Medical Records'),
    body: AnimatedBuilder(
      animation: DoctorMedicalRecordStore.instance,
      builder: (context, _) {
        final records = DoctorMedicalRecordStore.instance.records
            .where((record) => record.finalized)
            .where(
              (record) => '${record.id} ${record.petName} ${record.ownerName}'
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
            )
            .toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const _Callout(
                    icon: Icons.lock_outline_rounded,
                    text:
                        'Finalized diagnoses, prescriptions, clinical notes, and medical records are read-only for staff.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: _input(
                      'Search pet, owner or record ID',
                      Icons.search_rounded,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: records.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Text(
                          'No finalized medical records match this search.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      itemCount: records.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final record = records[index];
                        return ListTile(
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: _border),
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE6FAF2),
                            child: Icon(
                              Icons.folder_shared_rounded,
                              color: _green,
                            ),
                          ),
                          title: Text(
                            '${record.petName} • ${record.service}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            '${record.ownerName} • ${_shortDate(record.date)}\nFinalized • Read only',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showInfo(
                            context,
                            record.id,
                            'Findings: ${record.findings}\n\nDiagnosis: ${record.diagnosis}\n\nTreatment: ${record.treatment}\n\nPrescription: ${record.prescription}',
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

class StaffHealthPostsPage extends StatelessWidget {
  const StaffHealthPostsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    appBar: _appBar('Health Posts'),
    body: AnimatedBuilder(
      animation: DoctorPostStore.instance,
      builder: (context, _) {
        final posts = DoctorPostStore.instance.posts;
        return ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: posts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 13),
          itemBuilder: (_, index) {
            final post = posts[index];
            return Container(
              decoration: _cardDecoration(),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.coverAsset.isNotEmpty)
                    Image.asset(
                      post.coverAsset,
                      width: double.infinity,
                      height: 125,
                      fit: BoxFit.cover,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          post.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, height: 1.35),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Published by veterinarian • ${_shortDate(post.createdAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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

class StaffPatientsPage extends StatelessWidget {
  const StaffPatientsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final pets = <String, StaffAppointment>{};
    for (final item in StaffOperationsStore.instance.appointments) {
      pets[item.pet] = item;
    }
    return Scaffold(
      backgroundColor: _page,
      appBar: _appBar('Patients & Owners'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: TextField(
              decoration: _input(
                'Search owner, phone, pet or pet ID',
                Icons.search_rounded,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              itemCount: pets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final item = pets.values.elementAt(i);
                return ListTile(
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
                  subtitle: Text(
                    '${item.owner} • ${item.phone}\nAllergies: none recorded',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showInfo(
                    context,
                    '${item.pet} • Patient profile',
                    'Basic profile and appointment history are available to staff. Diagnoses, prescriptions, clinical notes, and finalized medical records remain read-only.',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StaffMessagesPage extends StatefulWidget {
  const StaffMessagesPage({this.standalone = false, super.key});
  final bool standalone;
  @override
  State<StaffMessagesPage> createState() => _StaffMessagesPageState();
}

class _StaffMessagesPageState extends State<StaffMessagesPage> {
  final _reply = TextEditingController();
  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _StaffScaffold(
    title: 'Messages',
    onBack: widget.standalone ? () => Navigator.pop(context) : null,
    child: AnimatedBuilder(
      animation: ContactClinicStore.instance,
      builder: (_, _) {
        final messages = ContactClinicStore.instance.messages;
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 8, 18, 4),
              child: _Callout(
                icon: Icons.health_and_safety_outlined,
                text:
                    'Forward medical questions to a veterinarian. Escalate emergency content immediately.',
              ),
            ),
            Expanded(
              child: messages.isEmpty
                  ? const Center(child: Text('No owner conversations yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(18),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final message = messages[i];
                        return Align(
                          alignment: message.isFromStaff
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(13),
                            constraints: const BoxConstraints(maxWidth: 310),
                            decoration: BoxDecoration(
                              color: message.isFromStaff ? _mint : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.category.label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _muted,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(message.text),
                                if (!message.isFromStaff)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Wrap(
                                      spacing: 4,
                                      children: [
                                        TextButton(
                                          onPressed: () => ContactClinicStore
                                              .instance
                                              .staffUpdateStatus(
                                                message.id,
                                                ContactMessageStatus.read,
                                              ),
                                          child: const Text('Resolve'),
                                        ),
                                        TextButton(
                                          onPressed: () => _notice(
                                            context,
                                            'Forwarded to the on-duty veterinarian.',
                                          ),
                                          child: const Text('Forward'),
                                        ),
                                        if (message.category ==
                                            ContactCategory.emergency)
                                          TextButton(
                                            onPressed: () => _push(
                                              context,
                                              const StaffEmergencyPage(),
                                            ),
                                            child: const Text(
                                              'Escalate',
                                              style: TextStyle(color: _red),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _reply,
                        decoration: _input(
                          'Administrative reply',
                          Icons.reply_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () {
                        if (_reply.text.trim().isEmpty) return;
                        ContactClinicStore.instance.staffReply(
                          _reply.text.trim(),
                        );
                        _reply.clear();
                      },
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class StaffReportsPage extends StatefulWidget {
  const StaffReportsPage({super.key});
  @override
  State<StaffReportsPage> createState() => _StaffReportsPageState();
}

class _StaffReportsPageState extends State<StaffReportsPage> {
  var _type = 'Appointments';
  @override
  Widget build(BuildContext context) {
    final items = StaffOperationsStore.instance.appointments;
    final completed = items.where((a) => a.status == 'Completed').length;
    final cancelled = items.where((a) => a.status == 'Cancelled').length;
    return Scaffold(
      backgroundColor: _page,
      appBar: _appBar('Operational Reports'),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: _input('Report type', Icons.bar_chart_rounded),
            items: [
              'Appointments',
              'Queues',
              'Cancellations',
              'Payments',
              'Home Visits',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ReportMetric(
                  value: '${items.length}',
                  label: 'Total records',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReportMetric(value: '$completed', label: 'Completed'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReportMetric(value: '$cancelled', label: 'Cancelled'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 190,
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_type trend',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [45.0, 85.0, 60.0, 110.0, 76.0, 125.0, 96.0]
                      .map(
                        (h) => Container(
                          width: 22,
                          height: h,
                          decoration: BoxDecoration(
                            color: _mint,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(7),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _showInfo(
              context,
              'Report exported',
              '$_type report generated. Audit recorded for Mya Thu at ${DateTime.now().toLocal()}.',
            ),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Export Report'),
          ),
        ],
      ),
    );
  }
}

class StaffProfilePage extends StatelessWidget {
  const StaffProfilePage({super.key});
  @override
  Widget build(BuildContext context) => _StaffScaffold(
    title: 'Staff Profile',
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const CircleAvatar(
          radius: 44,
          backgroundColor: _mint,
          child: Icon(Icons.person_rounded, size: 48, color: _ink),
        ),
        const SizedBox(height: 12),
        const Text(
          'Mya Thu',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
        ),
        const Text(
          'Clinic Operations Staff',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted),
        ),
        const SizedBox(height: 20),
        const _InfoCard(
          rows: [
            ('Employee ID', 'STF-018'),
            ('Email', 'staff@nwaysclinic.com'),
            ('Phone', '09 781 220 118'),
            ('Clinic', "Nway's Love Vet Clinic"),
            ('Shift', 'Morning • 8:00 AM–4:00 PM'),
          ],
        ),
        const SizedBox(height: 14),
        _ProfileTile(
          icon: Icons.edit_outlined,
          title: 'Edit Profile',
          onTap: () => _showInfo(
            context,
            'Edit Profile',
            'Name and phone number can be updated. Role, clinic, and employee ID require administrator approval.',
          ),
        ),
        _ProfileTile(
          icon: Icons.notifications_outlined,
          title: 'Notification Settings',
          onTap: () => _showInfo(
            context,
            'Notification Settings',
            'Appointment, emergency, queue, message, and payment alerts are enabled.',
          ),
        ),
        _ProfileTile(
          icon: Icons.help_outline_rounded,
          title: 'Help & Support',
          onTap: () => _showInfo(
            context,
            'Help & Support',
            'Contact the clinic administrator for account or operational assistance.',
          ),
        ),
        _ProfileTile(
          icon: Icons.logout_rounded,
          title: 'Log Out',
          color: _red,
          onTap: () => _logout(context),
        ),
      ],
    ),
  );
}

class _StaffScaffold extends StatelessWidget {
  const _StaffScaffold({required this.title, required this.child, this.onBack});
  final String title;
  final Widget child;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        _InlineHeader(title: title, onBack: onBack),
        Expanded(child: child),
      ],
    ),
  );
}

class _InlineHeader extends StatelessWidget {
  const _InlineHeader({required this.title, this.subtitle, this.onBack});
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
    child: Row(
      children: [
        if (onBack != null) ...[
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _titleStyle),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(color: _muted)),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(color: _mint, shape: BoxShape.circle),
          child: Image.asset('assets/photos/logoandphoto/nways_love_logo.png'),
        ),
      ],
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _ink),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: _muted, height: 1.25),
            ),
          ],
        ),
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 88,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Icon(icon, color: _green),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class _DoctorAvailability extends StatelessWidget {
  const _DoctorAvailability();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: _cardDecoration(),
    child: const Column(
      children: [
        _AvailabilityRow(
          name: 'Dr. Aye Chan',
          status: 'Available',
          color: _green,
        ),
        Divider(),
        _AvailabilityRow(
          name: 'Dr. Cindy Lynn',
          status: 'Consulting',
          color: Color(0xFFE09300),
        ),
        Divider(),
        _AvailabilityRow(
          name: 'Dr. Myat Noe',
          status: 'Available',
          color: _green,
        ),
      ],
    ),
  );
}

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({
    required this.name,
    required this.status,
    required this.color,
  });
  final String name;
  final String status;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFE6FAF2),
        child: Text(name.substring(4, 5)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});
  final List<(String, String)> rows;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  rows[i].$1,
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ),
              Expanded(
                child: Text(
                  rows[i].$2,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (i < rows.length - 1) const Divider(height: 22),
        ],
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
    super.key,
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

class _Callout extends StatelessWidget {
  const _Callout({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE6FAF2),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _green),
        const SizedBox(width: 9),
        Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
      ],
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: _cardDecoration(),
    child: Row(
      children: [
        Icon(icon, color: _muted),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: _muted)),
      ],
    ),
  );
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: _muted),
        ),
      ],
    ),
  );
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = _ink,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

const _titleStyle = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.w900,
  color: _ink,
);
const _sectionStyle = TextStyle(
  fontSize: 19,
  fontWeight: FontWeight.w900,
  color: _ink,
);
const _doctors = ['Dr. Aye Chan', 'Dr. Cindy Lynn', 'Dr. Myat Noe'];

BoxDecoration _cardDecoration({Color border = _border}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(17),
  border: Border.all(color: border),
);
InputDecoration _input(String label, IconData icon) => InputDecoration(
  labelText: label,
  prefixIcon: Icon(icon),
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(color: _border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(color: _border),
  ),
);
AppBar _appBar(String title, {Color color = _mint}) => AppBar(
  title: Text(title),
  backgroundColor: color,
  surfaceTintColor: Colors.transparent,
);
void _push(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
void _notice(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
void _showInfo(BuildContext context, String title, String text) =>
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );

Future<void> _adjustInventory(BuildContext context, InventoryItem item) async {
  var quantityText = '${item.quantity}';
  var reasonText = '';
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Adjust stock quantity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Callout(
            icon: Icons.admin_panel_settings_outlined,
            text:
                'Direct stock changes are restricted to staff and administrators and always create an audit entry.',
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('inventory-quantity-field'),
            initialValue: quantityText,
            keyboardType: TextInputType.number,
            onChanged: (value) => quantityText = value,
            decoration: _input('New quantity', Icons.numbers_rounded),
          ),
          const SizedBox(height: 10),
          TextFormField(
            onChanged: (value) => reasonText = value,
            decoration: _input('Reason for adjustment', Icons.notes_rounded),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm-stock-adjustment'),
          onPressed: () {
            final value = int.tryParse(quantityText);
            if (value == null || value < 0 || reasonText.trim().isEmpty) {
              return;
            }
            StaffOperationsStore.instance.adjustStock(
              item,
              value,
              reasonText.trim(),
            );
            Navigator.pop(dialogContext, true);
          },
          child: const Text('Save adjustment'),
        ),
      ],
    ),
  );
  if (saved == true && context.mounted) {
    _notice(context, 'Stock updated and audit entry recorded.');
  }
}

Future<void> _requestRestock(BuildContext context, InventoryItem item) async {
  var quantityText =
      '${item.restockQuantity > 0 ? item.restockQuantity : item.reorderLevel * 2}';
  var noteText = item.restockNote;
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Submit restock request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: quantityText,
            keyboardType: TextInputType.number,
            onChanged: (value) => quantityText = value,
            decoration: _input('Requested quantity', Icons.add_box_outlined),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: noteText,
            maxLines: 2,
            onChanged: (value) => noteText = value,
            decoration: _input('Note (optional)', Icons.notes_rounded),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(quantityText);
            if (value == null || value <= 0) return;
            StaffOperationsStore.instance.requestRestock(
              item,
              value,
              noteText.trim(),
            );
            Navigator.pop(dialogContext, true);
          },
          child: const Text('Submit request'),
        ),
      ],
    ),
  );
  if (saved == true && context.mounted) {
    _notice(context, 'Restock request submitted for approval.');
  }
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

Future<void> _logout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('End the staff session on this device?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm-staff-logout'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Yes, Log Out'),
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

String _greeting() {
  final hour = DateTime.now().hour;
  return hour < 12
      ? 'Good Morning'
      : hour < 17
      ? 'Good Afternoon'
      : 'Good Evening';
}

String _fullDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
Color _statusColor(String value) => switch (value) {
  'Completed' => _green,
  'Cancelled' || 'Missed' => _red,
  'Waiting' || 'Called' || 'In Consultation' => const Color(0xFFB06B00),
  _ => const Color(0xFF245DA8),
};
String _emergencyLabel(EmergencyStatus value) => switch (value) {
  EmergencyStatus.submitted => 'Submitted',
  EmergencyStatus.underReview => 'Reviewing',
  EmergencyStatus.accepted => 'Accepted',
  EmergencyStatus.declined => 'Referred',
  EmergencyStatus.checkedIn => 'Arrived',
  EmergencyStatus.assessment => 'Assessing',
  EmergencyStatus.waiting => 'Waiting',
  EmergencyStatus.consultation => 'Consultation',
  EmergencyStatus.treatmentProposed => 'Treatment proposed',
  EmergencyStatus.treatmentInProgress => 'In treatment',
  EmergencyStatus.completed => 'Completed',
};
String _homeLabel(HomeVisitStatus value) => switch (value) {
  HomeVisitStatus.confirmed => 'Confirmed',
  HomeVisitStatus.onTheWay => 'On the way',
  HomeVisitStatus.arrived => 'Arrived',
  HomeVisitStatus.consultation => 'In consultation',
  HomeVisitStatus.treatmentProposed => 'Treatment proposed',
  HomeVisitStatus.completed => 'Completed',
};
