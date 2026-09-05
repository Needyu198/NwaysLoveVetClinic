part of 'staff_portal.dart';

/// A selectable clinic doctor shown in the assignment picker.
class _StaffDoctor {
  const _StaffDoctor(this.name, this.specialty);
  final String name;
  final String specialty;
}

const _staffDoctors = [
  _StaffDoctor('Dr. Aye Chan', 'Heart Specialist'),
  _StaffDoctor('Dr. Cindy Lynn', 'Attending Physician'),
  _StaffDoctor('Dr. Myat Noe', 'Operation Lead'),
];

class StaffHomeVisitsPage extends StatefulWidget {
  const StaffHomeVisitsPage({super.key});

  @override
  State<StaffHomeVisitsPage> createState() => _StaffHomeVisitsPageState();
}

class _StaffHomeVisitsPageState extends State<StaffHomeVisitsPage> {
  String _filter = 'All';

  static const _filters = ['All', 'On Going', 'In Queue'];

  bool _matches(HomeVisit visit, String filter) => switch (filter) {
    'On Going' => const {
      HomeVisitStatus.onTheWay,
      HomeVisitStatus.arrived,
      HomeVisitStatus.consultation,
      HomeVisitStatus.treatmentProposed,
    }.contains(visit.status),
    'In Queue' => visit.status == HomeVisitStatus.confirmed,
    _ => true,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const _HomeVisitHeader(title: 'Home visit'),
        Expanded(
          child: AnimatedBuilder(
            animation: HomeVisitStore.instance,
            builder: (context, _) {
              final all = HomeVisitStore.instance.visits;
              final visits = all
                  .where((visit) => _matches(visit, _filter))
                  .toList();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                    child: SizedBox(
                      height: 42,
                      child: ListView.separated(
                        key: const ValueKey('staff-home-visit-filters'),
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final value = _filters[index];
                          return _AppointmentFilterChip(
                            label: value,
                            count: all.where((v) => _matches(v, value)).length,
                            selected: _filter == value,
                            onTap: () => setState(() => _filter = value),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        key: const ValueKey('staff-home-visit-records'),
                        onPressed: () =>
                            _push(context, const StaffMedicalRecordsPage()),
                        icon: const Icon(
                          Icons.folder_shared_outlined,
                          size: 18,
                        ),
                        label: const Text('Records'),
                        style: TextButton.styleFrom(
                          foregroundColor: _green,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, 8),
                    child: _HomeVisitWindowNotice(),
                  ),
                  Expanded(
                    child: visits.isEmpty
                        ? const _HomeVisitEmpty()
                        : ListView.separated(
                            key: const ValueKey('staff-home-visits'),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                            itemCount: visits.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) =>
                                _HomeVisitCard(visit: visits[index]),
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

class _HomeVisitWindowNotice extends StatelessWidget {
  const _HomeVisitWindowNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: _muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Home visit can be assigned between 12:00 - 14:00',
            style: const TextStyle(color: _muted, height: 1.3),
          ),
        ),
      ],
    ),
  );
}

class _HomeVisitEmpty extends StatelessWidget {
  const _HomeVisitEmpty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_work_outlined, size: 52, color: _muted),
          SizedBox(height: 12),
          Text(
            'No home visit requests',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Requests will appear here once owners book a home visit.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
          ),
        ],
      ),
    ),
  );
}

class _HomeVisitCard extends StatelessWidget {
  const _HomeVisitCard({required this.visit});
  final HomeVisit visit;

  @override
  Widget build(BuildContext context) => Material(
    color: _mint,
    borderRadius: BorderRadius.circular(34),
    clipBehavior: Clip.antiAlias,
    elevation: 2,
    shadowColor: const Color(0x33000000),
    child: InkWell(
      onTap: () => _push(context, StaffHomeVisitDetailPage(visit: visit)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(
                'assets/photos/logoandphoto/nways_pets.png',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visit.pet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pet Owner : ${visit.contactPerson}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 104),
              height: 42,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                visit.status == HomeVisitStatus.confirmed
                    ? 'Assign'
                    : _homeLabel(visit.status),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Detail page
// ---------------------------------------------------------------------------

class StaffHomeVisitDetailPage extends StatefulWidget {
  const StaffHomeVisitDetailPage({required this.visit, super.key});
  final HomeVisit visit;

  @override
  State<StaffHomeVisitDetailPage> createState() =>
      _StaffHomeVisitDetailPageState();
}

class _StaffHomeVisitDetailPageState extends State<StaffHomeVisitDetailPage> {
  late final TextEditingController _location = TextEditingController(
    text: widget.visit.address,
  );
  late String _doctor = _resolveDoctor(widget.visit.veterinarian);

  static String _resolveDoctor(String current) {
    final match = _staffDoctors.any((d) => d.name == current);
    return match ? current : _staffDoctors.first.name;
  }

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  /// Opens the doctor picker. When [assignOnPick] is true (the primary
  /// "Assign Doctor" action), choosing a doctor also commits the assignment;
  /// otherwise it just updates the selected doctor shown on the field.
  Future<void> _pickDoctor({required bool assignOnPick}) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _mint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _DoctorPickerSheet(selected: _doctor),
    );
    if (choice == null) return;
    setState(() => _doctor = choice);
    if (assignOnPick) _assign();
  }

  void _assign() {
    HomeVisitStore.instance.assignDoctor(widget.visit, _doctor);
    if (widget.visit.status == HomeVisitStatus.confirmed) {
      HomeVisitStore.instance.updateStatus(
        widget.visit,
        HomeVisitStatus.onTheWay,
      );
    }
    OwnerNotificationStore.instance.push(
      'Home visit doctor assigned',
      '$_doctor is assigned to ${widget.visit.pet.name}\u2019s home visit and is on the way.',
    );
    Navigator.pop(context);
    _notice(context, '$_doctor assigned to ${widget.visit.pet.name}.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const _HomeVisitHeader(title: 'Detail'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              _HomeVisitSummaryCard(visit: widget.visit),
              const SizedBox(height: 18),
              _HomeVisitLabeledField(
                label: 'Available Doctor',
                icon: Icons.person_search_rounded,
                child: InkWell(
                  key: const ValueKey('home-visit-doctor-field'),
                  onTap: () => _pickDoctor(assignOnPick: false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _doctor,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _ink,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _LocationField(controller: _location),
              const SizedBox(height: 26),
              SizedBox(
                height: 58,
                child: FilledButton(
                  key: const ValueKey('assign-home-visit-doctor'),
                  onPressed: () => _pickDoctor(assignOnPick: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: _mint,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Assign Doctor'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HomeVisitSummaryCard extends StatelessWidget {
  const _HomeVisitSummaryCard({required this.visit});
  final HomeVisit visit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _mint,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(
                'assets/photos/logoandphoto/nways_pets.png',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visit.pet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pet Owner : ${visit.contactPerson}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Visit Reason : ${_orDash(visit.reason)}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'Symptoms : ${_orDash(visit.symptoms)}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  static String _orDash(String value) => value.trim().isEmpty ? '—' : value;
}

class _HomeVisitLabeledField extends StatelessWidget {
  const _HomeVisitLabeledField({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: _green, size: 24),
            const SizedBox(width: 14),
            Expanded(child: child),
          ],
        ),
      ),
      Positioned(
        left: 18,
        top: -8,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            label,
            style: const TextStyle(
              color: _green,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );
}

class _LocationField extends StatelessWidget {
  const _LocationField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
    ),
    padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Icon(Icons.notes_rounded, color: _ink, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(fontSize: 16, color: _ink),
                decoration: const InputDecoration(
                  hintText: 'Location',
                  hintStyle: TextStyle(color: _muted, fontSize: 16),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          key: const ValueKey('home-visit-open-map'),
          onPressed: () {
            final query = controller.text.trim();
            _showInfo(
              context,
              'Open in Map',
              query.isEmpty
                  ? 'Add a location first to open it in the map.'
                  : 'Opening “$query” in the map app.',
            );
          },
          icon: const Icon(Icons.map_outlined, size: 18),
          label: const Text('Open in Map'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _ink,
            side: const BorderSide(color: _border),
            shape: const StadiumBorder(),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Doctor picker sheet
// ---------------------------------------------------------------------------

class _DoctorPickerSheet extends StatelessWidget {
  const _DoctorPickerSheet({required this.selected});
  final String selected;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Assign Doctor',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          for (final doctor in _staffDoctors) ...[
            _DoctorPickerTile(
              doctor: doctor,
              selected: doctor.name == selected,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    ),
  );
}

class _DoctorPickerTile extends StatelessWidget {
  const _DoctorPickerTile({required this.doctor, required this.selected});
  final _StaffDoctor doctor;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: selected ? _green : Colors.transparent),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFE6FAF2),
          child: Icon(Icons.person_rounded, color: _green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                doctor.specialty,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        FilledButton(
          key: ValueKey('pick-doctor-${doctor.name}'),
          onPressed: () => Navigator.pop(context, doctor.name),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00C566),
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          ),
          child: const Text('Assign'),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Shared header
// ---------------------------------------------------------------------------

class _HomeVisitHeader extends StatelessWidget {
  const _HomeVisitHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      color: _mint,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 18, 22),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.chevron_left_rounded, size: 30),
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: _ink,
                ),
              ),
            ),
            Image.asset(
              'assets/photos/logoandphoto/nways_love_logo.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    ),
  );
}
