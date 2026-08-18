import 'package:flutter/material.dart';

import 'appointment_booking_page.dart';

class EmergencyServicePage extends StatefulWidget {
  const EmergencyServicePage({super.key});

  static const routeName = '/emergency-service';

  @override
  State<EmergencyServicePage> createState() => _EmergencyServicePageState();
}

class MyEmergencyRequestsPage extends StatelessWidget {
  const MyEmergencyRequestsPage({super.key});

  static const routeName = '/my-emergency-requests';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _EmergencyColors.page,
      appBar: AppBar(
        title: const Text('Emergency Requests'),
        backgroundColor: _EmergencyColors.lightRed,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: EmergencyRequestStore.instance,
        builder: (context, _) {
          final requests = EmergencyRequestStore.instance.requests;
          if (requests.isEmpty) {
            return const _EmergencyEmpty();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) => _EmergencyRequestCard(
              request: requests[index],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EmergencyStatusPage(request: requests[index]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class EmergencyRequestStore extends ChangeNotifier {
  EmergencyRequestStore._();

  static final instance = EmergencyRequestStore._();

  final List<EmergencyRequest> _requests = [];

  List<EmergencyRequest> get requests => List.unmodifiable(_requests.reversed);

  void add(EmergencyRequest request) {
    _requests.add(request);
    notifyListeners();
  }

  void recordOwnerConsent(EmergencyRequest request) {
    request.ownerConsent = true;
    notifyListeners();
  }

  void staffUpdate(
    EmergencyRequest request,
    EmergencyStatus status, {
    String? priority,
    String? response,
  }) {
    request.status = status;
    if (priority != null) request.priority = priority;
    if (response != null) request.clinicResponse = response;

    switch (status) {
      case EmergencyStatus.submitted:
        break;
      case EmergencyStatus.underReview:
        request.priority = priority ?? 'High';
        break;
      case EmergencyStatus.accepted:
        request.clinicResponse =
            response ?? 'The clinic can accept this emergency case.';
        break;
      case EmergencyStatus.declined:
        request.clinicResponse =
            response ??
            'The clinic cannot safely accept this case. Please contact the nearest emergency hospital.';
        break;
      case EmergencyStatus.checkedIn:
        request.clinicResponse = 'Request verified and pet checked in.';
        break;
      case EmergencyStatus.assessment:
        request.findings =
            'Initial emergency assessment is in progress. Vital signs are being monitored.';
        break;
      case EmergencyStatus.waiting:
        request.priority = priority ?? request.priority;
        break;
      case EmergencyStatus.consultation:
        request.findings =
            'Emergency examination completed and clinical findings recorded.';
        break;
      case EmergencyStatus.treatmentProposed:
        request.diagnosis =
            'Emergency diagnosis recorded after examination and diagnostic review.';
        request.proposedTreatment =
            'Stabilization, prescribed medication, and condition-specific emergency care.';
        break;
      case EmergencyStatus.treatmentInProgress:
        request.treatmentResult =
            'Emergency treatment is currently in progress.';
        break;
      case EmergencyStatus.completed:
        request.treatmentResult =
            'Emergency treatment completed and the pet’s condition stabilized.';
        request.recommendations =
            'Monitor the pet closely, follow all medicine instructions, and book the recommended follow-up.';
        break;
    }
    notifyListeners();
  }

  @visibleForTesting
  void clear() {
    _requests.clear();
    notifyListeners();
  }
}

enum EmergencyStatus {
  submitted,
  underReview,
  accepted,
  declined,
  checkedIn,
  assessment,
  waiting,
  consultation,
  treatmentProposed,
  treatmentInProgress,
  completed,
}

class EmergencyRequest {
  EmergencyRequest({
    required this.id,
    required this.createdAt,
    required this.pet,
    required this.symptoms,
    required this.description,
    required this.contactPerson,
    required this.phone,
    this.status = EmergencyStatus.submitted,
  });

  final String id;
  final DateTime createdAt;
  final EmergencyPet pet;
  final List<String> symptoms;
  final String description;
  final String contactPerson;
  final String phone;
  EmergencyStatus status;
  String priority = 'Pending staff review';
  String clinicResponse = 'Waiting for the clinic to review the request.';
  String findings = '';
  String diagnosis = '';
  String proposedTreatment = '';
  String treatmentResult = '';
  String recommendations = '';
  bool ownerConsent = false;
}

class EmergencyPet {
  const EmergencyPet({
    required this.name,
    required this.breed,
    required this.age,
    required this.medicalHistory,
    required this.color,
  });

  final String name;
  final String breed;
  final String age;
  final String medicalHistory;
  final Color color;
}

class _EmergencyServicePageState extends State<EmergencyServicePage> {
  static const _pets = [
    EmergencyPet(
      name: 'Max',
      breed: 'Golden Retriever',
      age: '2 years',
      medicalHistory: 'Vaccinations current • No medication allergies',
      color: Color(0xFF2F80FF),
    ),
    EmergencyPet(
      name: 'Bella',
      breed: 'Shih Tzu',
      age: '1 year',
      medicalHistory: 'Sensitive skin • Previous checkup normal',
      color: Color(0xFFEF5B4E),
    ),
    EmergencyPet(
      name: 'Luna',
      breed: 'Mixed-breed cat',
      age: '3 years',
      medicalHistory: 'Indoor pet • Vaccinations current',
      color: Color(0xFF8B3DFF),
    ),
  ];

  static const _symptomOptions = [
    'Breathing Difficulty',
    'Severe Bleeding',
    'Seizure',
    'Suspected Poisoning',
    'Collapse or Unresponsive',
    'Severe Pain',
    'Trauma or Accident',
    'Repeated Vomiting',
  ];

  final _description = TextEditingController();
  final _contactPerson = TextEditingController(text: 'Nee Yu');
  final _phone = TextEditingController(text: '09-5312717');

  int _step = 0;
  EmergencyPet? _pet;
  final Set<String> _symptoms = {};
  String? _error;
  EmergencyRequest? _created;

  @override
  void dispose() {
    _description.dispose();
    _contactPerson.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _next() {
    setState(() {
      _error = null;
      _step += 1;
    });
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _error = null;
      _step -= 1;
    });
  }

  bool _validateDescription() {
    if (_description.text.trim().length < 8) {
      setState(() => _error = 'Enter a short description of the emergency.');
      return false;
    }
    return true;
  }

  bool _validateContact() {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (_contactPerson.text.trim().isEmpty || digits.length < 7) {
      setState(
        () => _error = 'Confirm a valid contact person and phone number.',
      );
      return false;
    }
    return true;
  }

  void _submit() {
    final value = DateTime.now().microsecondsSinceEpoch.toString();
    final request = EmergencyRequest(
      id: 'ER${value.substring(value.length - 8)}',
      createdAt: DateTime.now(),
      pet: _pet!,
      symptoms: _symptoms.toList(),
      description: _description.text.trim(),
      contactPerson: _contactPerson.text.trim(),
      phone: _phone.text.trim(),
    );
    EmergencyRequestStore.instance.add(request);
    setState(() => _created = request);
  }

  @override
  Widget build(BuildContext context) {
    if (_created != null) return _EmergencyConfirmation(request: _created!);
    return Scaffold(
      backgroundColor: _EmergencyColors.page,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Emergency Service'),
        backgroundColor: _EmergencyColors.lightRed,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Emergency Requests',
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(MyEmergencyRequestsPage.routeName),
            icon: const Icon(Icons.assignment_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(5),
          child: LinearProgressIndicator(
            value: (_step + 1) / 6,
            backgroundColor: Colors.white54,
            color: _EmergencyColors.red,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE1E1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFB3261E)),
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: KeyedSubtree(key: ValueKey(_step), child: _stepBody()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBody() => switch (_step) {
    0 => _noticeStep(),
    1 => _petStep(),
    2 => _symptomsStep(),
    3 => _descriptionStep(),
    4 => _contactStep(),
    _ => _summaryStep(),
  };

  Widget _noticeStep() {
    return _EmergencyStep(
      title: 'Emergency Notice',
      subtitle: 'Review this information before submitting a request.',
      action: 'Continue Emergency Request',
      enabled: true,
      onAction: _next,
      child: ListView(
        children: const [
          _EmergencyNotice(
            icon: Icons.warning_amber_rounded,
            text:
                'For breathing difficulty, uncontrolled bleeding, collapse, poisoning, or seizures, call the clinic immediately and bring the pet without delay.',
          ),
          SizedBox(height: 14),
          _EmergencyInfoCard(
            title: 'Clinic Hours',
            value: '9:00 AM–12:00 PM\n4:00 PM–7:00 PM',
            icon: Icons.schedule_rounded,
          ),
          SizedBox(height: 12),
          _EmergencyInfoCard(
            title: 'Emergency Contact',
            value: '09-5312717 • 09-965805940',
            icon: Icons.call_outlined,
          ),
          SizedBox(height: 12),
          _EmergencyInfoCard(
            title: 'Clinic Address',
            value: 'Chindwin Street, Popba Thiri Township, Nay Pyi Taw',
            icon: Icons.location_on_outlined,
          ),
        ],
      ),
    );
  }

  Widget _petStep() {
    return _EmergencyStep(
      title: 'Select Pet',
      subtitle: 'Choose the pet that needs emergency care.',
      action: 'Select Emergency Symptoms',
      enabled: _pet != null,
      onAction: _next,
      child: ListView.separated(
        itemCount: _pets.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final pet = _pets[index];
          return _EmergencySelectTile(
            key: ValueKey('emergency-pet-${pet.name}'),
            selected: _pet == pet,
            icon: Icons.pets_rounded,
            color: pet.color,
            title: pet.name,
            subtitle:
                '${pet.breed} • ${pet.age}\nMedical history: ${pet.medicalHistory}',
            onTap: () => setState(() => _pet = pet),
          );
        },
      ),
    );
  }

  Widget _symptomsStep() {
    return _EmergencyStep(
      title: 'Emergency Symptoms',
      subtitle: 'Select every symptom affecting ${_pet!.name}.',
      action: 'Describe the Emergency',
      enabled: _symptoms.isNotEmpty,
      onAction: _next,
      child: ListView(
        children: [
          for (final symptom in _symptomOptions)
            CheckboxListTile(
              key: ValueKey('emergency-symptom-$symptom'),
              value: _symptoms.contains(symptom),
              onChanged: (selected) => setState(() {
                if (selected ?? false) {
                  _symptoms.add(symptom);
                } else {
                  _symptoms.remove(symptom);
                }
              }),
              title: Text(symptom),
              activeColor: _EmergencyColors.red,
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _descriptionStep() {
    return _EmergencyStep(
      title: 'Emergency Description',
      subtitle: 'Briefly describe the pet’s current condition.',
      action: 'Confirm Contact Details',
      enabled: true,
      onAction: () {
        if (_validateDescription()) _next();
      },
      child: ListView(
        children: [
          TextField(
            key: const ValueKey('emergency-description'),
            controller: _description,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Condition description *',
              hintText: 'What happened and when did the symptoms begin?',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactStep() {
    return _EmergencyStep(
      title: 'Contact Details',
      subtitle: 'Confirm who clinic staff should contact immediately.',
      action: 'Review Emergency Request',
      enabled: true,
      onAction: () {
        if (_validateContact()) _next();
      },
      child: ListView(
        children: [
          TextField(
            key: const ValueKey('emergency-contact'),
            controller: _contactPerson,
            decoration: const InputDecoration(
              labelText: 'Contact person *',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('emergency-phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number *',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStep() {
    return _EmergencyStep(
      title: 'Emergency Summary',
      subtitle: 'Confirm all details before alerting clinic staff.',
      action: 'Submit Emergency Request',
      enabled: true,
      onAction: _submit,
      child: ListView(
        children: [
          _EmergencyDetailsPanel(
            details: {
              'Pet': '${_pet!.name} • ${_pet!.breed}',
              'Symptoms': _symptoms.join(', '),
              'Description': _description.text.trim(),
              'Contact person': _contactPerson.text.trim(),
              'Phone': _phone.text.trim(),
            },
          ),
        ],
      ),
    );
  }
}

class _EmergencyConfirmation extends StatelessWidget {
  const _EmergencyConfirmation({required this.request});

  final EmergencyRequest request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _EmergencyColors.page,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 54,
                  backgroundColor: _EmergencyColors.red,
                  child: Icon(
                    Icons.emergency_rounded,
                    color: Colors.white,
                    size: 62,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Emergency request submitted',
                  textAlign: TextAlign.center,
                  style: _EmergencyText.title,
                ),
                const SizedBox(height: 10),
                Text(
                  'Request ID: #${request.id}',
                  style: _EmergencyText.bodyDark,
                ),
                const SizedBox(height: 18),
                const _EmergencyNotice(
                  icon: Icons.directions_car_outlined,
                  text:
                      'Bring your pet to the clinic immediately. Call the clinic while travelling if the condition worsens.',
                ),
                const SizedBox(height: 14),
                const _EmergencyNotice(
                  icon: Icons.notifications_active_outlined,
                  text: 'Clinic staff have been notified immediately.',
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => EmergencyStatusPage(request: request),
                    ),
                  ),
                  style: _EmergencyStyles.primaryButton,
                  child: const Text('Open Emergency Status'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmergencyStatusPage extends StatelessWidget {
  const EmergencyStatusPage({required this.request, super.key});

  final EmergencyRequest request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _EmergencyColors.page,
      appBar: AppBar(
        title: const Text('Emergency Status'),
        backgroundColor: _EmergencyColors.lightRed,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: EmergencyRequestStore.instance,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _EmergencyStatusPanel(request: request),
            const SizedBox(height: 16),
            _EmergencyDetailsPanel(
              details: {
                'Request ID': '#${request.id}',
                'Pet': request.pet.name,
                'Symptoms': request.symptoms.join(', '),
                'Description': request.description,
                'Priority': request.priority,
                'Clinic response': request.clinicResponse,
                if (request.findings.isNotEmpty) 'Findings': request.findings,
                if (request.diagnosis.isNotEmpty)
                  'Diagnosis': request.diagnosis,
                if (request.proposedTreatment.isNotEmpty)
                  'Proposed treatment': request.proposedTreatment,
                if (request.treatmentResult.isNotEmpty)
                  'Treatment result': request.treatmentResult,
                if (request.recommendations.isNotEmpty)
                  'Recommendations': request.recommendations,
              },
            ),
            const SizedBox(height: 16),
            const _EmergencyNotice(
              icon: Icons.lock_outline_rounded,
              text:
                  'Emergency priority and status are updated by clinic staff. Pet owners cannot change them manually.',
            ),
            if (request.status == EmergencyStatus.treatmentProposed) ...[
              const SizedBox(height: 16),
              if (request.ownerConsent)
                const _EmergencyNotice(
                  icon: Icons.check_circle_outline,
                  text: 'Owner treatment consent has been recorded.',
                )
              else
                FilledButton.icon(
                  key: const ValueKey('approve-emergency-treatment'),
                  onPressed: () => EmergencyRequestStore.instance
                      .recordOwnerConsent(request),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Approve Emergency Treatment'),
                  style: _EmergencyStyles.primaryButton,
                ),
            ],
            if (request.status == EmergencyStatus.completed) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        EmergencyMedicalRecordPage(request: request),
                  ),
                ),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Open Medical Record'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AppointmentBookingPage(
                      initialPetName: request.pet.name,
                    ),
                  ),
                ),
                icon: const Icon(Icons.event_repeat_outlined),
                label: const Text('Book Follow-up'),
                style: _EmergencyStyles.primaryButton,
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/history'),
                icon: const Icon(Icons.history_rounded),
                label: const Text('Open Emergency History'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmergencyMedicalRecordPage extends StatelessWidget {
  const EmergencyMedicalRecordPage({required this.request, super.key});

  final EmergencyRequest request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _EmergencyColors.page,
      appBar: AppBar(
        title: const Text('Emergency Medical Record'),
        backgroundColor: _EmergencyColors.lightRed,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _EmergencyDetailsPanel(
            details: {
              'Request ID': '#${request.id}',
              'Pet': request.pet.name,
              'Symptoms': request.symptoms.join(', '),
              'Findings': request.findings,
              'Diagnosis': request.diagnosis,
              'Treatment': request.treatmentResult,
              'Recommendations': request.recommendations,
            },
          ),
        ],
      ),
    );
  }
}

class _EmergencyRequestCard extends StatelessWidget {
  const _EmergencyRequestCard({required this.request, required this.onTap});

  final EmergencyRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: _EmergencyColors.lightRed,
                foregroundColor: _EmergencyColors.red,
                child: Icon(Icons.emergency_outlined),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.pet.name, style: _EmergencyText.cardTitle),
                    Text('#${request.id}', style: _EmergencyText.body),
                  ],
                ),
              ),
              Text(
                _emergencyStatusLabel(request.status),
                style: _EmergencyText.badge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyStep extends StatelessWidget {
  const _EmergencyStep({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.enabled,
    required this.onAction,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String action;
  final bool enabled;
  final VoidCallback onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _EmergencyText.title),
          const SizedBox(height: 6),
          Text(subtitle, style: _EmergencyText.body),
          const SizedBox(height: 18),
          Expanded(child: child),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: enabled ? onAction : null,
            style: _EmergencyStyles.primaryButton,
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class _EmergencySelectTile extends StatelessWidget {
  const _EmergencySelectTile({
    required this.selected,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final bool selected;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _EmergencyColors.lightRed : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _EmergencyColors.red : const Color(0xFFE3D7D7),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.14),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _EmergencyText.cardTitle),
                    const SizedBox(height: 4),
                    Text(subtitle, style: _EmergencyText.body),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? _EmergencyColors.red : _EmergencyColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyDetailsPanel extends StatelessWidget {
  const _EmergencyDetailsPanel({required this.details});

  final Map<String, String> details;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0D2D2)),
      ),
      child: Column(
        children: [
          for (final entry in details.entries) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 112,
                  child: Text(entry.key, style: _EmergencyText.label),
                ),
                Expanded(
                  child: Text(entry.value, style: _EmergencyText.bodyDark),
                ),
              ],
            ),
            if (entry.key != details.keys.last) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

class _EmergencyNotice extends StatelessWidget {
  const _EmergencyNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _EmergencyColors.lightRed,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: _EmergencyColors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: _EmergencyText.bodyDark)),
        ],
      ),
    );
  }
}

class _EmergencyInfoCard extends StatelessWidget {
  const _EmergencyInfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: _EmergencyColors.red, size: 30),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _EmergencyText.cardTitle),
                const SizedBox(height: 3),
                Text(value, style: _EmergencyText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyStatusPanel extends StatelessWidget {
  const _EmergencyStatusPanel({required this.request});

  final EmergencyRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _EmergencyColors.lightRed,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emergency_rounded,
            color: _EmergencyColors.red,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            _emergencyStatusLabel(request.status),
            style: _EmergencyText.title,
          ),
          const SizedBox(height: 4),
          Text('Priority: ${request.priority}', style: _EmergencyText.bodyDark),
        ],
      ),
    );
  }
}

class _EmergencyEmpty extends StatelessWidget {
  const _EmergencyEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emergency_outlined,
              size: 70,
              color: _EmergencyColors.muted,
            ),
            SizedBox(height: 16),
            Text('No emergency requests', style: _EmergencyText.title),
          ],
        ),
      ),
    );
  }
}

class _EmergencyColors {
  static const page = Color(0xFFFFF8F8);
  static const lightRed = Color(0xFFFFE4E4);
  static const red = Color(0xFFD73535);
  static const muted = Color(0xFF756161);
}

class _EmergencyText {
  static const title = TextStyle(
    color: Color(0xFF241717),
    fontSize: 27,
    fontWeight: FontWeight.w900,
  );
  static const cardTitle = TextStyle(
    color: Color(0xFF241717),
    fontSize: 18,
    fontWeight: FontWeight.w900,
  );
  static const body = TextStyle(
    color: _EmergencyColors.muted,
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w600,
  );
  static const bodyDark = TextStyle(
    color: Color(0xFF3C2929),
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w700,
  );
  static const label = TextStyle(
    color: _EmergencyColors.muted,
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );
  static const badge = TextStyle(
    color: _EmergencyColors.red,
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );
}

class _EmergencyStyles {
  static final primaryButton = FilledButton.styleFrom(
    backgroundColor: _EmergencyColors.red,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(54),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
  );
}

String _emergencyStatusLabel(EmergencyStatus status) => switch (status) {
  EmergencyStatus.submitted => 'Submitted',
  EmergencyStatus.underReview => 'Under Staff Review',
  EmergencyStatus.accepted => 'Accepted by Clinic',
  EmergencyStatus.declined => 'Unable to Accept',
  EmergencyStatus.checkedIn => 'Checked In',
  EmergencyStatus.assessment => 'Emergency Assessment',
  EmergencyStatus.waiting => 'Emergency Queue',
  EmergencyStatus.consultation => 'Emergency Consultation',
  EmergencyStatus.treatmentProposed => 'Treatment Approval Required',
  EmergencyStatus.treatmentInProgress => 'Emergency Treatment',
  EmergencyStatus.completed => 'Completed',
};
