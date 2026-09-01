part of 'doctor_portal.dart';

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
