part of 'doctor_portal.dart';

class DoctorHomeVisitsPage extends StatelessWidget {
  const DoctorHomeVisitsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _DoctorSubpageHeader(title: 'Home Visits'),
          Expanded(
            child: AnimatedBuilder(
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
                  key: const ValueKey('doctor-home-visits'),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  itemCount: visits.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) =>
                      _DoctorHomeVisitCard(visit: visits[index]),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _DoctorHomeVisitCard extends StatelessWidget {
  const _DoctorHomeVisitCard({required this.visit});

  final HomeVisit visit;

  @override
  Widget build(BuildContext context) => Material(
    color: DoctorStyles.mint,
    borderRadius: BorderRadius.circular(30),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('doctor-home-visit-${visit.id}'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DoctorHomeVisitDetailsPage(visit: visit),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 29,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.home_work_outlined,
                color: DoctorStyles.green,
                size: 29,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visit.pet.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_fullDate(visit.date)} • ${visit.time}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DoctorStyles.body,
                  ),
                  Text(
                    visit.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DoctorStyles.muted,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusBadge(status: _doctorHomeVisitLabel(visit.status)),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ],
        ),
      ),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _DoctorSubpageHeader(title: 'Home Visit Details'),
            Expanded(
              child: AnimatedBuilder(
                animation: HomeVisitStore.instance,
                builder: (context, _) {
                  final clinical =
                      visit.status == HomeVisitStatus.consultation ||
                      visit.status == HomeVisitStatus.treatmentProposed;
                  final nextStatus = _nextHomeVisitStatus(visit.status);
                  return ListView(
                    key: const ValueKey('doctor-home-visit-details'),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: DoctorStyles.mint,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 31,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.home_work_outlined, size: 31),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    visit.pet.name,
                                    style: DoctorStyles.title,
                                  ),
                                  Text(
                                    '${visit.pet.breed} • ${visit.pet.age}',
                                    style: DoctorStyles.body,
                                  ),
                                  Text(
                                    'Pet Owner : ${visit.contactPerson}',
                                    style: DoctorStyles.muted,
                                  ),
                                ],
                              ),
                            ),
                            _StatusBadge(
                              status: _doctorHomeVisitLabel(visit.status),
                            ),
                          ],
                        ),
                      ),
                      if (!clinical && nextStatus != null) ...[
                        const SizedBox(height: 16),
                        _homeVisitAdvanceButton(nextStatus),
                      ],
                      const SizedBox(height: 18),
                      _DoctorMintSection(
                        title: 'Visit Information',
                        icon: Icons.assignment_outlined,
                        child: _DoctorDetailsCard(
                          rows: [
                            ('Booking ID', '#${visit.id}'),
                            ('Medical history', visit.pet.medicalHistory),
                            (
                              'Date and time',
                              '${_fullDate(visit.date)} • ${visit.time}',
                            ),
                            ('Address', visit.address),
                            (
                              'Contact',
                              '${visit.contactPerson} • ${visit.phone}',
                            ),
                            ('Reason', visit.reason),
                            ('Symptoms', visit.symptoms),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const ValueKey('doctor-home-directions'),
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Opening directions to ${visit.address}',
                                ),
                              ),
                            ),
                        icon: const Icon(Icons.directions_outlined),
                        label: const Text('Open Directions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black),
                          minimumSize: const Size.fromHeight(52),
                          shape: const StadiumBorder(),
                        ),
                      ),
                      if (clinical) ...[
                        const SizedBox(height: 18),
                        _DoctorMintSection(
                          title: 'Clinical Notes',
                          icon: Icons.medical_information_outlined,
                          child: Column(
                            children: [
                              TextField(
                                key: const ValueKey('home-visit-findings'),
                                controller: _findings,
                                maxLines: 3,
                                decoration: _homeVisitFieldDecoration(
                                  'Examination findings',
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                key: const ValueKey('home-visit-treatment'),
                                controller: _treatment,
                                maxLines: 3,
                                decoration: _homeVisitFieldDecoration(
                                  'Treatment results',
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _medicines,
                                decoration: _homeVisitFieldDecoration(
                                  'Medicines',
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _recommendations,
                                maxLines: 2,
                                decoration: _homeVisitFieldDecoration(
                                  'Recommendations',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (nextStatus != null) ...[
                          const SizedBox(height: 16),
                          _homeVisitAdvanceButton(nextStatus),
                        ],
                      ] else if (nextStatus == null) ...[
                        const SizedBox(height: 16),
                        const _DoctorNotice(
                          text:
                              'This Home Visit and its clinical record are complete.',
                        ),
                      ],
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

  Widget _homeVisitAdvanceButton(HomeVisitStatus nextStatus) =>
      FilledButton.icon(
        key: const ValueKey('doctor-update-home-visit'),
        onPressed: () => _advanceVisit(nextStatus),
        icon: const Icon(Icons.update_rounded),
        label: Text(_homeVisitAction(nextStatus)),
        style: FilledButton.styleFrom(
          backgroundColor: DoctorStyles.green,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );

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

InputDecoration _homeVisitFieldDecoration(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(color: DoctorStyles.green, width: 1.6),
  ),
);
