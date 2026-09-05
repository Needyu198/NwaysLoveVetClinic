import 'dart:async';

import 'package:flutter/material.dart';

class HomeVisitBookingPage extends StatefulWidget {
  const HomeVisitBookingPage({super.key});

  static const routeName = '/book-home-visit';

  @override
  State<HomeVisitBookingPage> createState() => _HomeVisitBookingPageState();
}

class MyHomeVisitsPage extends StatelessWidget {
  const MyHomeVisitsPage({super.key});

  static const routeName = '/my-home-visits';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _VisitColors.page,
      appBar: AppBar(
        title: const Text('My Home Visits'),
        backgroundColor: _VisitColors.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: HomeVisitStore.instance,
        builder: (context, _) {
          final visits = HomeVisitStore.instance.visits;
          if (visits.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.home_work_outlined,
                      size: 72,
                      color: _VisitColors.muted,
                    ),
                    const SizedBox(height: 18),
                    const Text('No home visits yet', style: _VisitText.title),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose Home Visit from the Clinic categories to make a booking.',
                      textAlign: TextAlign.center,
                      style: _VisitText.body,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
            itemCount: visits.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final visit = visits[index];
              return _VisitCard(
                visit: visit,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => HomeVisitTrackingPage(visit: visit),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(HomeVisitBookingPage.routeName),
        backgroundColor: _VisitColors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_home_outlined),
        label: const Text('Book Visit'),
      ),
    );
  }
}

class HomeVisitStore extends ChangeNotifier {
  HomeVisitStore._();

  static final instance = HomeVisitStore._();

  final List<HomeVisit> _visits = [];

  List<HomeVisit> get visits => List.unmodifiable(_visits.reversed);

  bool isSlotAvailable({
    required String veterinarian,
    required DateTime date,
    required String time,
  }) {
    return !_visits.any(
      (visit) =>
          visit.veterinarian == veterinarian &&
          DateUtils.isSameDay(visit.date, date) &&
          visit.time == time &&
          visit.status != HomeVisitStatus.completed,
    );
  }

  void add(HomeVisit visit) {
    _visits.add(visit);
    notifyListeners();
  }

  void updateStatus(HomeVisit visit, HomeVisitStatus status) {
    visit.status = status;
    notifyListeners();
  }

  void assignDoctor(HomeVisit visit, String veterinarian) {
    visit.veterinarian = veterinarian;
    notifyListeners();
  }

  void completeVisit(HomeVisit visit) {
    visit.status = HomeVisitStatus.completed;
    visit.findings =
        'General examination completed. Temperature, breathing, and hydration are stable.';
    visit.treatmentNotes =
        'Supportive home care provided and symptoms discussed with the pet owner.';
    visit.medicines =
        'Prescribed medicines: follow the veterinarian’s dosage instructions.';
    visit.recommendations =
        'Monitor appetite and activity. Contact the clinic if symptoms worsen.';
    notifyListeners();
  }

  void saveReview(HomeVisit visit, int rating, String review) {
    visit.rating = rating;
    visit.review = review;
    notifyListeners();
  }

  @visibleForTesting
  void clear() {
    _visits.clear();
    notifyListeners();
  }
}

enum HomeVisitStatus {
  confirmed,
  onTheWay,
  arrived,
  consultation,
  treatmentProposed,
  completed,
}

class HomeVisit {
  HomeVisit({
    required this.id,
    required this.pet,
    required this.veterinarian,
    required this.date,
    required this.time,
    required this.reason,
    required this.symptoms,
    required this.address,
    required this.contactPerson,
    required this.phone,
    this.status = HomeVisitStatus.confirmed,
  });

  final String id;
  final HomeVisitPet pet;
  String veterinarian;
  final DateTime date;
  final String time;
  final String reason;
  final String symptoms;
  final String address;
  final String contactPerson;
  final String phone;
  HomeVisitStatus status;
  String findings = '';
  String treatmentNotes = '';
  String medicines = '';
  String recommendations = '';
  int rating = 0;
  String review = '';
}

class HomeVisitPet {
  const HomeVisitPet({
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

class _HomeVisitBookingPageState extends State<HomeVisitBookingPage> {
  static const _pets = [
    HomeVisitPet(
      name: 'Max',
      breed: 'Golden Retriever',
      age: '2 years',
      medicalHistory: 'Vaccinations current • Previous annual checkup normal',
      color: Color(0xFF2F80FF),
    ),
    HomeVisitPet(
      name: 'Bella',
      breed: 'Shih Tzu',
      age: '1 year',
      medicalHistory: 'Sensitive skin • No medication allergies recorded',
      color: Color(0xFFEF5B4E),
    ),
    HomeVisitPet(
      name: 'Luna',
      breed: 'Mixed-breed cat',
      age: '3 years',
      medicalHistory: 'Indoor pet • Vaccinations current',
      color: Color(0xFF8B3DFF),
    ),
  ];

  static const _veterinarians = [
    'Dr. Hnin Thiri Aung',
    'Dr. Cindy Lynn',
    'Dr. Myat Noe',
  ];

  static const _reasons = [
    'General Checkup',
    'Follow-up Consultation',
    'Vaccination',
    'Mobility Concern',
    'Other',
  ];

  static const _savedAddress =
      'No. 18, Chindwin Street, Popba Thiri Township, Nay Pyi Taw';

  final _symptoms = TextEditingController();
  final _customReason = TextEditingController();
  final _address = TextEditingController(text: _savedAddress);
  final _contactPerson = TextEditingController(text: 'Nee Yu');
  final _phone = TextEditingController(text: '09-5312717');

  int _step = 0;
  HomeVisitPet? _pet;
  String? _veterinarian;
  DateTime? _date;
  String? _time;
  String? _reason;
  bool _useSavedAddress = true;
  int _holdSeconds = 0;
  Timer? _holdTimer;
  String? _error;
  HomeVisit? _created;

  List<DateTime> get _availableDates {
    final today = DateUtils.dateOnly(DateTime.now());
    return List.generate(7, (index) => today.add(Duration(days: index + 1)));
  }

  static const _availableTimes = ['12:00 PM', '1:00 PM', '2:00 PM'];

  @override
  void dispose() {
    _holdTimer?.cancel();
    _symptoms.dispose();
    _customReason.dispose();
    _address.dispose();
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

  void _holdSlot() {
    if (!HomeVisitStore.instance.isSlotAvailable(
      veterinarian: _veterinarian!,
      date: _date!,
      time: _time!,
    )) {
      setState(
        () => _error = 'That slot was just booked. Select another time.',
      );
      return;
    }

    _holdTimer?.cancel();
    setState(() => _holdSeconds = 240);
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_holdSeconds <= 1) {
        timer.cancel();
        setState(() {
          _holdSeconds = 0;
          _time = null;
          _step = 3;
          _error = 'The temporary hold expired. Please select a time again.';
        });
      } else {
        setState(() => _holdSeconds -= 1);
      }
    });
    _next();
  }

  bool _validateReason() {
    if (_reason == null) {
      setState(() => _error = 'Select a reason for the Home Visit.');
      return false;
    }
    if (_reason == 'Other' && _customReason.text.trim().isEmpty) {
      setState(() => _error = 'Enter the reason for the visit.');
      return false;
    }
    if (_symptoms.text.trim().isEmpty) {
      setState(() => _error = 'Describe the pet’s symptoms.');
      return false;
    }
    return true;
  }

  bool _validateAddress() {
    final address = _address.text.trim().toLowerCase();
    if (address.length < 12) {
      setState(() => _error = 'Enter a complete service address.');
      return false;
    }
    if (!address.contains('nay pyi taw') && !address.contains('naypyidaw')) {
      setState(
        () => _error =
            'The Home Visit address must be inside the Nay Pyi Taw service area.',
      );
      return false;
    }
    return true;
  }

  bool _validateContact() {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (_contactPerson.text.trim().isEmpty) {
      setState(() => _error = 'Enter the contact person’s name.');
      return false;
    }
    if (digits.length < 7) {
      setState(() => _error = 'Enter a valid contact phone number.');
      return false;
    }
    return true;
  }

  void _confirm() {
    if (_holdSeconds == 0 ||
        !HomeVisitStore.instance.isSlotAvailable(
          veterinarian: _veterinarian!,
          date: _date!,
          time: _time!,
        )) {
      setState(() {
        _step = 3;
        _time = null;
        _error = 'The slot is no longer available. Select another time.';
      });
      return;
    }

    final visit = HomeVisit(
      id: 'HOME${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      pet: _pet!,
      veterinarian: _veterinarian!,
      date: _date!,
      time: _time!,
      reason: _reason == 'Other' ? _customReason.text.trim() : _reason!,
      symptoms: _symptoms.text.trim(),
      address: _address.text.trim(),
      contactPerson: _contactPerson.text.trim(),
      phone: _phone.text.trim(),
    );
    _holdTimer?.cancel();
    HomeVisitStore.instance.add(visit);
    setState(() => _created = visit);
  }

  @override
  Widget build(BuildContext context) {
    if (_created != null) return _HomeVisitConfirmation(visit: _created!);

    return Scaffold(
      backgroundColor: _VisitColors.page,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Book a Home Visit'),
        backgroundColor: _VisitColors.mint,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'My Home Visits',
            onPressed: () =>
                Navigator.of(context).pushNamed(MyHomeVisitsPage.routeName),
            icon: const Icon(Icons.assignment_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(5),
          child: LinearProgressIndicator(
            value: (_step + 1) / 8,
            color: _VisitColors.green,
            backgroundColor: Colors.white54,
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
                color: const Color(0xFFFFE8E5),
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
    0 => _petStep(),
    1 => _veterinarianStep(),
    2 => _dateStep(),
    3 => _timeStep(),
    4 => _reasonStep(),
    5 => _addressStep(),
    6 => _contactStep(),
    _ => _summaryStep(),
  };

  Widget _petStep() {
    return _VisitStep(
      title: 'Select Pet',
      subtitle: 'Choose the pet that needs a veterinarian at home.',
      action: 'Select Veterinarian',
      enabled: _pet != null,
      onAction: _next,
      child: ListView.separated(
        itemCount: _pets.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final pet = _pets[index];
          return _VisitSelectTile(
            key: ValueKey('home-visit-pet-${pet.name}'),
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

  Widget _veterinarianStep() {
    return _VisitStep(
      title: 'Select Veterinarian',
      subtitle: 'Choose an available veterinarian for ${_pet!.name}.',
      action: 'View Available Dates',
      enabled: _veterinarian != null,
      onAction: _next,
      child: ListView.separated(
        itemCount: _veterinarians.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final veterinarian = _veterinarians[index];
          return _VisitSelectTile(
            selected: _veterinarian == veterinarian,
            icon: Icons.medical_services_outlined,
            color: _VisitColors.green,
            title: veterinarian,
            subtitle: 'Home consultation veterinarian • Available this week',
            onTap: () => setState(() => _veterinarian = veterinarian),
          );
        },
      ),
    );
  }

  Widget _dateStep() {
    return _VisitStep(
      title: 'Select Date',
      subtitle: 'Available dates for $_veterinarian.',
      action: 'View Home Visit Times',
      enabled: _date != null,
      onAction: _next,
      child: ListView(
        children: [
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final date in _availableDates)
                ChoiceChip(
                  label: Text(_shortDate(date)),
                  selected: _date == date,
                  onSelected: (_) => setState(() {
                    _date = date;
                    _time = null;
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeStep() {
    return _VisitStep(
      title: 'Select Time',
      subtitle:
          'Home Visits are available in one-hour slots between 12:00 PM and 3:00 PM.',
      action: 'Hold This Slot',
      enabled: _time != null,
      onAction: _holdSlot,
      child: ListView(
        children: [
          for (final time in _availableTimes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _VisitSelectTile(
                key: ValueKey('home-visit-time-$time'),
                selected: _time == time,
                icon: Icons.schedule_rounded,
                color: _VisitColors.green,
                title: time,
                subtitle: 'One-hour Home Visit slot',
                onTap: () => setState(() => _time = time),
              ),
            ),
        ],
      ),
    );
  }

  Widget _reasonStep() {
    final minutes = _holdSeconds ~/ 60;
    final seconds = (_holdSeconds % 60).toString().padLeft(2, '0');
    return _VisitStep(
      title: 'Visit Reason',
      subtitle: 'Your slot is held for $minutes:$seconds.',
      action: 'Confirm Visit Address',
      enabled: true,
      onAction: () {
        if (_validateReason()) _next();
      },
      child: ListView(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reason in _reasons)
                ChoiceChip(
                  label: Text(reason),
                  selected: _reason == reason,
                  onSelected: (_) => setState(() => _reason = reason),
                ),
            ],
          ),
          if (_reason == 'Other') ...[
            const SizedBox(height: 14),
            _VisitField(
              controller: _customReason,
              label: 'Visit reason *',
              hint: 'Enter the required service',
            ),
          ],
          const SizedBox(height: 14),
          _VisitField(
            key: const ValueKey('home-visit-symptoms'),
            controller: _symptoms,
            label: 'Symptoms *',
            hint: 'Describe the symptoms and when they started',
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _addressStep() {
    return _VisitStep(
      title: 'Visit Address',
      subtitle: 'Home Visits are currently available within Nay Pyi Taw.',
      action: 'Validate Address',
      enabled: true,
      onAction: () {
        if (_validateAddress()) _next();
      },
      child: ListView(
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Saved Address')),
              ButtonSegment(value: false, label: Text('New Address')),
            ],
            selected: {_useSavedAddress},
            onSelectionChanged: (selection) {
              setState(() {
                _useSavedAddress = selection.first;
                _address.text = _useSavedAddress ? _savedAddress : '';
              });
            },
          ),
          const SizedBox(height: 18),
          _VisitField(
            key: const ValueKey('home-visit-address'),
            controller: _address,
            label: 'Complete address *',
            hint: 'House number, street, township, Nay Pyi Taw',
            maxLines: 4,
          ),
          const SizedBox(height: 10),
          const _VisitNotice(
            icon: Icons.location_on_outlined,
            text:
                'The address will be checked against the clinic’s Home Visit service area.',
          ),
        ],
      ),
    );
  }

  Widget _contactStep() {
    return _VisitStep(
      title: 'Contact Details',
      subtitle: 'Confirm who the veterinarian should contact on arrival.',
      action: 'Review Home Visit',
      enabled: true,
      onAction: () {
        if (_validateContact()) _next();
      },
      child: ListView(
        children: [
          _VisitField(
            key: const ValueKey('home-visit-contact'),
            controller: _contactPerson,
            label: 'Contact person *',
            hint: 'Full name',
          ),
          const SizedBox(height: 14),
          _VisitField(
            key: const ValueKey('home-visit-phone'),
            controller: _phone,
            label: 'Phone number *',
            hint: '09-xxxxxxxxx',
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _summaryStep() {
    return _VisitStep(
      title: 'Home Visit Summary',
      subtitle: 'Review the booking. No online payment is required.',
      action: 'Confirm Home Visit',
      enabled: true,
      onAction: _confirm,
      child: ListView(
        children: [
          _VisitDetailPanel(
            title: 'Complete booking information',
            children: [
              _VisitDetailRow('Pet', '${_pet!.name} • ${_pet!.breed}'),
              _VisitDetailRow('Veterinarian', _veterinarian!),
              _VisitDetailRow('Schedule', '${_longDate(_date!)} • $_time'),
              _VisitDetailRow(
                'Reason',
                _reason == 'Other' ? _customReason.text.trim() : _reason!,
              ),
              _VisitDetailRow('Symptoms', _symptoms.text.trim()),
              _VisitDetailRow('Address', _address.text.trim()),
              _VisitDetailRow('Contact', _contactPerson.text.trim()),
              _VisitDetailRow('Phone', _phone.text.trim()),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeVisitConfirmation extends StatelessWidget {
  const _HomeVisitConfirmation({required this.visit});

  final HomeVisit visit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _VisitColors.page,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Container(
                  width: 108,
                  height: 108,
                  decoration: const BoxDecoration(
                    color: _VisitColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 58,
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Home Visit confirmed!',
                  textAlign: TextAlign.center,
                  style: _VisitText.title,
                ),
                const SizedBox(height: 10),
                Text('Booking ID: #${visit.id}', style: _VisitText.bodyDark),
                const SizedBox(height: 18),
                Text(
                  '${visit.pet.name} • ${visit.veterinarian}\n${_longDate(visit.date)} at ${visit.time}\n${visit.address}',
                  textAlign: TextAlign.center,
                  style: _VisitText.bodyDark,
                ),
                const SizedBox(height: 18),
                const _VisitNotice(
                  icon: Icons.notifications_active_outlined,
                  text:
                      'The pet owner, veterinarian, and clinic staff have been notified.',
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => HomeVisitTrackingPage(visit: visit),
                    ),
                  ),
                  style: _VisitStyles.primaryButton,
                  child: const Text('Open Visit Reminder'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil(
                    (route) =>
                        route.settings.name == HomeVisitBookingPage.routeName,
                  ),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeVisitTrackingPage extends StatelessWidget {
  const HomeVisitTrackingPage({required this.visit, super.key});

  final HomeVisit visit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _VisitColors.page,
      appBar: AppBar(
        title: const Text('Home Visit Status'),
        backgroundColor: _VisitColors.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: HomeVisitStore.instance,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _VisitStatusHeader(status: visit.status),
              const SizedBox(height: 18),
              _VisitDetailPanel(
                title: 'Upcoming Home Visit',
                children: [
                  _VisitDetailRow('Booking ID', '#${visit.id}'),
                  _VisitDetailRow('Pet', visit.pet.name),
                  _VisitDetailRow('Veterinarian', visit.veterinarian),
                  _VisitDetailRow(
                    'Date and time',
                    '${_longDate(visit.date)} • ${visit.time}',
                  ),
                  _VisitDetailRow('Address', visit.address),
                  _VisitDetailRow(
                    'Contact',
                    '${visit.contactPerson} • ${visit.phone}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _VisitNotice(
                icon: Icons.info_outline,
                text: _statusMessage(visit.status),
              ),
              const SizedBox(height: 20),
              _statusAction(context),
            ],
          );
        },
      ),
    );
  }

  Widget _statusAction(BuildContext context) {
    final store = HomeVisitStore.instance;
    return switch (visit.status) {
      HomeVisitStatus.confirmed => FilledButton.icon(
        onPressed: () => store.updateStatus(visit, HomeVisitStatus.onTheWay),
        icon: const Icon(Icons.directions_car_outlined),
        label: const Text('Veterinarian On the Way'),
        style: _VisitStyles.primaryButton,
      ),
      HomeVisitStatus.onTheWay => FilledButton.icon(
        onPressed: () => store.updateStatus(visit, HomeVisitStatus.arrived),
        icon: const Icon(Icons.location_on_outlined),
        label: const Text('Confirm Veterinarian Arrived'),
        style: _VisitStyles.primaryButton,
      ),
      HomeVisitStatus.arrived => FilledButton.icon(
        onPressed: () =>
            store.updateStatus(visit, HomeVisitStatus.consultation),
        icon: const Icon(Icons.health_and_safety_outlined),
        label: const Text('Begin Home Consultation'),
        style: _VisitStyles.primaryButton,
      ),
      HomeVisitStatus.consultation => FilledButton.icon(
        onPressed: () =>
            store.updateStatus(visit, HomeVisitStatus.treatmentProposed),
        icon: const Icon(Icons.medication_outlined),
        label: const Text('Record Findings'),
        style: _VisitStyles.primaryButton,
      ),
      HomeVisitStatus.treatmentProposed => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _VisitDetailPanel(
            title: 'Proposed treatment',
            children: [
              _VisitDetailRow(
                'Plan',
                'Supportive care, prescribed medicine, and symptom monitoring',
              ),
              _VisitDetailRow(
                'Consent',
                'Review the plan before approving treatment.',
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => store.completeVisit(visit),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Approve Treatment'),
            style: _VisitStyles.primaryButton,
          ),
        ],
      ),
      HomeVisitStatus.completed => FilledButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => HomeVisitMedicalRecordPage(visit: visit),
          ),
        ),
        icon: const Icon(Icons.description_outlined),
        label: const Text('Open Medical Record'),
        style: _VisitStyles.primaryButton,
      ),
    };
  }
}

class HomeVisitMedicalRecordPage extends StatefulWidget {
  const HomeVisitMedicalRecordPage({required this.visit, super.key});

  final HomeVisit visit;

  @override
  State<HomeVisitMedicalRecordPage> createState() =>
      _HomeVisitMedicalRecordPageState();
}

class _HomeVisitMedicalRecordPageState
    extends State<HomeVisitMedicalRecordPage> {
  late final TextEditingController _review;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.visit.rating;
    _review = TextEditingController(text: widget.visit.review);
  }

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _VisitColors.page,
      appBar: AppBar(
        title: const Text('Home Visit Medical Record'),
        backgroundColor: _VisitColors.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _VisitDetailPanel(
            title: '${widget.visit.pet.name} • Completed Home Visit',
            children: [
              _VisitDetailRow('Veterinarian', widget.visit.veterinarian),
              _VisitDetailRow('Visit reason', widget.visit.reason),
              _VisitDetailRow('Findings', widget.visit.findings),
              _VisitDetailRow('Treatment notes', widget.visit.treatmentNotes),
              _VisitDetailRow('Medicines', widget.visit.medicines),
              _VisitDetailRow('Recommendations', widget.visit.recommendations),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Rating and Review', style: _VisitText.section),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  key: ValueKey('home-visit-rating-$star'),
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: const Color(0xFFFFB000),
                    size: 34,
                  ),
                ),
            ],
          ),
          TextField(
            controller: _review,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Write a review',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _rating == 0
                ? null
                : () {
                    HomeVisitStore.instance.saveReview(
                      widget.visit,
                      _rating,
                      _review.text.trim(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Thank you. Your Home Visit review was saved.',
                        ),
                      ),
                    );
                  },
            style: _VisitStyles.primaryButton,
            child: const Text('Submit Review'),
          ),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit, required this.onTap});

  final HomeVisit visit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: _VisitColors.mint,
                    foregroundColor: _VisitColors.green,
                    child: Icon(Icons.home_work_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${visit.pet.name} Home Visit',
                      style: _VisitText.cardTitle,
                    ),
                  ),
                  _VisitStatusBadge(status: visit.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(visit.veterinarian, style: _VisitText.bodyDark),
              Text(
                '${_longDate(visit.date)} at ${visit.time}',
                style: _VisitText.body,
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('View status', style: _VisitText.link),
                  Icon(Icons.chevron_right_rounded, color: _VisitColors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitStep extends StatelessWidget {
  const _VisitStep({
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
          Text(title, style: _VisitText.title),
          const SizedBox(height: 6),
          Text(subtitle, style: _VisitText.body),
          const SizedBox(height: 18),
          Expanded(child: child),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: enabled ? onAction : null,
              style: _VisitStyles.primaryButton,
              child: Text(action),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitSelectTile extends StatelessWidget {
  const _VisitSelectTile({
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
      color: selected ? _VisitColors.mint : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _VisitColors.green : const Color(0xFFD7E4DF),
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
                    Text(title, style: _VisitText.cardTitle),
                    const SizedBox(height: 4),
                    Text(subtitle, style: _VisitText.body),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? _VisitColors.green : _VisitColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitField extends StatelessWidget {
  const _VisitField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _VisitDetailPanel extends StatelessWidget {
  const _VisitDetailPanel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD6EEE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _VisitText.section),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _VisitDetailRow extends StatelessWidget {
  const _VisitDetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 106, child: Text(label, style: _VisitText.label)),
          Expanded(child: Text(value, style: _VisitText.bodyDark)),
        ],
      ),
    );
  }
}

class _VisitNotice extends StatelessWidget {
  const _VisitNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _VisitColors.mint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: _VisitColors.green),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: _VisitText.bodyDark)),
        ],
      ),
    );
  }
}

class _VisitStatusHeader extends StatelessWidget {
  const _VisitStatusHeader({required this.status});

  final HomeVisitStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _VisitColors.mint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.home_work_rounded,
            size: 40,
            color: _VisitColors.green,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current status', style: _VisitText.label),
                const SizedBox(height: 3),
                Text(_statusLabel(status), style: _VisitText.cardTitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitStatusBadge extends StatelessWidget {
  const _VisitStatusBadge({required this.status});

  final HomeVisitStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _VisitColors.mint,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(_statusLabel(status), style: _VisitText.badge),
    );
  }
}

class _VisitColors {
  static const page = Color(0xFFF7FAF8);
  static const mint = Color(0xFFA1FDD8);
  static const green = Color(0xFF16855E);
  static const muted = Color(0xFF61736D);
}

class _VisitText {
  static const title = TextStyle(
    fontSize: 27,
    fontWeight: FontWeight.w900,
    color: Color(0xFF101814),
  );
  static const section = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w900,
    color: Color(0xFF101814),
  );
  static const cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: Color(0xFF101814),
  );
  static const body = TextStyle(
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: _VisitColors.muted,
  );
  static const bodyDark = TextStyle(
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w700,
    color: Color(0xFF25312D),
  );
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: _VisitColors.muted,
  );
  static const link = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w900,
    color: _VisitColors.green,
  );
  static const badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w900,
    color: _VisitColors.green,
  );
}

class _VisitStyles {
  static final primaryButton = FilledButton.styleFrom(
    backgroundColor: _VisitColors.green,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(54),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
  );
}

String _statusLabel(HomeVisitStatus status) => switch (status) {
  HomeVisitStatus.confirmed => 'Confirmed',
  HomeVisitStatus.onTheWay => 'On the Way',
  HomeVisitStatus.arrived => 'Arrived',
  HomeVisitStatus.consultation => 'Consultation',
  HomeVisitStatus.treatmentProposed => 'Treatment Proposed',
  HomeVisitStatus.completed => 'Completed',
};

String _statusMessage(HomeVisitStatus status) => switch (status) {
  HomeVisitStatus.confirmed =>
    'Reminder: your Home Visit is scheduled for the date and time shown above.',
  HomeVisitStatus.onTheWay =>
    'The veterinarian is travelling to your confirmed address.',
  HomeVisitStatus.arrived =>
    'The veterinarian has arrived. Please provide the pet for examination.',
  HomeVisitStatus.consultation =>
    'The veterinarian is examining the pet and recording findings.',
  HomeVisitStatus.treatmentProposed =>
    'Review and approve the proposed care before treatment continues.',
  HomeVisitStatus.completed =>
    'The visit is complete. Treatment notes and recommendations are ready.',
};

String _shortDate(DateTime date) {
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
  return '${months[date.month - 1]} ${date.day}';
}

String _longDate(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${weekdays[date.weekday - 1]}, ${_shortDate(date)} ${date.year}';
}
