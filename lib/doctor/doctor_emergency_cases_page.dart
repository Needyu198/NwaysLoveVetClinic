part of 'doctor_portal.dart';

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
