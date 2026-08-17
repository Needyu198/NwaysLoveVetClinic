import 'dart:async';

import 'package:flutter/material.dart';

import 'pet_owner_home_page.dart';

class AppointmentBookingPage extends StatefulWidget {
  const AppointmentBookingPage({super.key});

  static const routeName = '/book-appointment';

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class MyAppointmentsPage extends StatelessWidget {
  const MyAppointmentsPage({super.key});

  static const routeName = '/my-appointments';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _BookingColors.page,
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: _BookingColors.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: AppointmentStore.instance,
        builder: (context, _) {
          final appointments = AppointmentStore.instance.appointments;
          if (appointments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_busy_rounded,
                      size: 72,
                      color: _BookingColors.muted,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No appointments yet',
                      style: _BookingText.title,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Book a clinic or home visit for one of your pets.',
                      textAlign: TextAlign.center,
                      style: _BookingText.body,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppointmentBookingPage.routeName),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Book Appointment'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
            itemCount: appointments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              return _AppointmentCard(appointment: appointments[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppointmentBookingPage.routeName),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Book'),
        backgroundColor: _BookingColors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class AppointmentStore extends ChangeNotifier {
  AppointmentStore._();

  static final instance = AppointmentStore._();

  final List<BookedAppointment> _appointments = [];

  List<BookedAppointment> get appointments =>
      List.unmodifiable(_appointments.reversed);

  bool isSlotAvailable({
    required String veterinarian,
    required DateTime date,
    required String time,
  }) {
    return !_appointments.any(
      (appointment) =>
          appointment.veterinarian == veterinarian &&
          DateUtils.isSameDay(appointment.date, date) &&
          appointment.time == time,
    );
  }

  void add(BookedAppointment appointment) {
    _appointments.add(appointment);
    notifyListeners();
  }

  @visibleForTesting
  void clear() {
    _appointments.clear();
    notifyListeners();
  }
}

class BookedAppointment {
  const BookedAppointment({
    required this.id,
    required this.pet,
    required this.service,
    required this.veterinarian,
    required this.date,
    required this.time,
    required this.symptoms,
    required this.reason,
    required this.notes,
    required this.address,
    required this.status,
  });

  final String id;
  final BookingPet pet;
  final BookingService service;
  final String veterinarian;
  final DateTime date;
  final String time;
  final String symptoms;
  final String reason;
  final String notes;
  final String address;
  final String status;
}

class BookingPet {
  const BookingPet({
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.icon,
    required this.color,
  });

  final String name;
  final String species;
  final String breed;
  final String age;
  final IconData icon;
  final Color color;
}

class BookingService {
  const BookingService({
    required this.name,
    required this.description,
    required this.icon,
    required this.homeVisit,
    required this.doctors,
  });

  final String name;
  final String description;
  final IconData icon;
  final bool homeVisit;
  final List<String> doctors;
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  static const _pets = [
    BookingPet(
      name: 'Max',
      species: 'Dog',
      breed: 'Golden Retriever',
      age: '2 years',
      icon: Icons.pets_rounded,
      color: Color(0xFF2F80FF),
    ),
    BookingPet(
      name: 'Bella',
      species: 'Dog',
      breed: 'Shih Tzu',
      age: '1 year',
      icon: Icons.pets_rounded,
      color: Color(0xFFEF5B4E),
    ),
    BookingPet(
      name: 'Luna',
      species: 'Cat',
      breed: 'Mixed breed',
      age: '3 years',
      icon: Icons.cruelty_free_rounded,
      color: Color(0xFF8B3DFF),
    ),
  ];

  static const _services = [
    BookingService(
      name: 'General Checkup',
      description: 'Routine examination and health consultation.',
      icon: Icons.health_and_safety_rounded,
      homeVisit: false,
      doctors: ['Dr. Aye Chan', 'Dr. Hnin Thiri'],
    ),
    BookingService(
      name: 'Vaccination',
      description: 'Vaccines, boosters, and vaccination advice.',
      icon: Icons.vaccines_rounded,
      homeVisit: false,
      doctors: ['Dr. Hnin Thiri', 'Dr. Su Mon'],
    ),
    BookingService(
      name: 'Emergency',
      description: 'Urgent assessment for sudden illness or injury.',
      icon: Icons.emergency_rounded,
      homeVisit: false,
      doctors: ['Dr. Aye Chan', 'Dr. Min Khant'],
    ),
    BookingService(
      name: 'Home Visit',
      description: 'A veterinarian visits your confirmed address.',
      icon: Icons.home_work_rounded,
      homeVisit: true,
      doctors: ['Dr. Min Khant', 'Dr. Aye Chan'],
    ),
  ];

  final _symptomsController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _addressController = TextEditingController();

  int _step = 0;
  BookingPet? _pet;
  BookingService? _service;
  String? _veterinarian;
  DateTime? _date;
  String? _time;
  int _holdSeconds = 0;
  Timer? _holdTimer;
  String? _error;
  BookedAppointment? _createdAppointment;

  List<DateTime> get _availableDates {
    final today = DateUtils.dateOnly(DateTime.now());
    return List.generate(7, (index) => today.add(Duration(days: index + 1)));
  }

  List<String> get _availableTimes {
    if (_service?.homeVisit ?? false) {
      return const ['12:00 PM', '1:00 PM', '2:00 PM'];
    }
    return const [
      '9:00 AM',
      '10:00 AM',
      '11:00 AM',
      '4:00 PM',
      '5:00 PM',
      '6:00 PM',
    ];
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _symptomsController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_createdAppointment != null) {
      return _BookingConfirmation(appointment: _createdAppointment!);
    }

    return Scaffold(
      backgroundColor: _BookingColors.page,
      body: SafeArea(
        child: Column(
          children: [
            _BookingHeader(
              step: _step,
              onBack: _step == 0 ? () => Navigator.of(context).pop() : _back,
            ),
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
                  style: const TextStyle(
                    color: Color(0xFFB3261E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _currentStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currentStep() {
    return switch (_step) {
      0 => _selectPetStep(),
      1 => _selectServiceStep(),
      2 => _selectVeterinarianStep(),
      3 => _selectDateStep(),
      4 => _selectTimeStep(),
      5 => _appointmentDetailsStep(),
      _ => _summaryStep(),
    };
  }

  Widget _selectPetStep() {
    return _StepLayout(
      title: 'Choose Pet',
      subtitle: 'Select the pet that needs care.',
      actionLabel: 'Continue',
      actionEnabled: _pet != null,
      onAction: _next,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _pets.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final pet = _pets[index];
          return _SelectionCard(
            selected: _pet == pet,
            onTap: () => setState(() => _pet = pet),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: pet.color.withValues(alpha: 0.14),
                  child: Icon(pet.icon, color: pet.color, size: 38),
                ),
                const SizedBox(height: 12),
                Text(pet.name, style: _BookingText.cardTitle),
                const SizedBox(height: 5),
                Text(
                  '${pet.species} • ${pet.breed}\n${pet.age}',
                  textAlign: TextAlign.center,
                  style: _BookingText.caption,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _selectServiceStep() {
    return _StepLayout(
      title: 'Select Service',
      subtitle: 'Choose the type of appointment.',
      actionLabel: 'Find Veterinarians',
      actionEnabled: _service != null,
      onAction: _next,
      child: Column(
        children: [
          _SelectedPetStrip(pet: _pet!),
          const SizedBox(height: 16),
          for (final service in _services) ...[
            _SelectionCard(
              selected: _service == service,
              onTap: () => setState(() {
                _service = service;
                _veterinarian = null;
                _date = null;
                _clearHeldTime();
              }),
              child: Row(
                children: [
                  _IconBubble(icon: service.icon),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service.name, style: _BookingText.cardTitle),
                        const SizedBox(height: 4),
                        Text(service.description, style: _BookingText.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _selectVeterinarianStep() {
    return _StepLayout(
      title: 'Select Veterinarian',
      subtitle: 'Available for ${_service!.name}.',
      actionLabel: 'Choose Date',
      actionEnabled: _veterinarian != null,
      onAction: _next,
      child: Column(
        children: [
          for (final doctor in _service!.doctors) ...[
            _SelectionCard(
              selected: _veterinarian == doctor,
              onTap: () => setState(() {
                _veterinarian = doctor;
                _date = null;
                _clearHeldTime();
              }),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 31,
                    backgroundColor: Color(0xFFE7F8F1),
                    child: Icon(
                      Icons.person_rounded,
                      size: 38,
                      color: _BookingColors.green,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctor, style: _BookingText.cardTitle),
                        const SizedBox(height: 4),
                        Text(
                          _doctorSpecialty(doctor),
                          style: _BookingText.caption,
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: _BookingColors.green,
                              size: 17,
                            ),
                            SizedBox(width: 5),
                            Text('Available', style: _BookingText.success),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _selectDateStep() {
    return _StepLayout(
      title: 'Select Date',
      subtitle: 'Appointments can be booked from tomorrow.',
      actionLabel: 'View Time Slots',
      actionEnabled: _date != null,
      onAction: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BookingContextCard(
            pet: _pet!,
            service: _service!,
            veterinarian: _veterinarian!,
          ),
          const SizedBox(height: 20),
          const Text('Available dates', style: _BookingText.section),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final date in _availableDates)
                ChoiceChip(
                  key: ValueKey('appointment-date-${date.day}'),
                  selected: DateUtils.isSameDay(_date, date),
                  onSelected: (_) => setState(() {
                    _date = date;
                    _clearHeldTime();
                  }),
                  selectedColor: _BookingColors.green,
                  labelStyle: TextStyle(
                    color: DateUtils.isSameDay(_date, date)
                        ? Colors.white
                        : _BookingColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                  label: Text(_shortDate(date)),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _NoticeBox(
            icon: Icons.schedule_rounded,
            text: _service!.homeVisit
                ? 'Home visits are available only from 12:00 PM to 3:00 PM.'
                : 'Clinic hours: 9:00 AM–12:00 PM and 4:00 PM–7:00 PM.',
          ),
        ],
      ),
    );
  }

  Widget _selectTimeStep() {
    return _StepLayout(
      title: 'Select Time Slot',
      subtitle: _date == null ? '' : _longDate(_date!),
      actionLabel: 'Enter Appointment Details',
      actionEnabled: _time != null && _holdSeconds > 0,
      onAction: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_time != null)
            _NoticeBox(
              icon: Icons.timer_outlined,
              text:
                  '$_time is held for ${_formatCountdown(_holdSeconds)}. Complete the booking before the hold expires.',
            ),
          if (_time != null) const SizedBox(height: 18),
          const Text('Available one-hour slots', style: _BookingText.section),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _availableTimes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final time = _availableTimes[index];
              final available = AppointmentStore.instance.isSlotAvailable(
                veterinarian: _veterinarian!,
                date: _date!,
                time: time,
              );
              return FilledButton(
                key: ValueKey('appointment-time-$time'),
                onPressed: available ? () => _holdTime(time) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _time == time
                      ? _BookingColors.green
                      : Colors.white,
                  foregroundColor: _time == time
                      ? Colors.white
                      : _BookingColors.ink,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: _time == time
                          ? _BookingColors.green
                          : const Color(0xFFD8E7E1),
                    ),
                  ),
                  elevation: _time == time ? 2 : 0,
                ),
                child: Text(time),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _appointmentDetailsStep() {
    return _StepLayout(
      title: 'Appointment Details',
      subtitle: 'Tell the clinic how they can help.',
      actionLabel: 'Review Booking',
      actionEnabled: true,
      onAction: _validateDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BookingTextField(
            key: const ValueKey('appointment-symptoms'),
            controller: _symptomsController,
            label: 'Symptoms *',
            hint: 'Describe the symptoms you noticed',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _BookingTextField(
            key: const ValueKey('appointment-reason'),
            controller: _reasonController,
            label: 'Appointment reason *',
            hint: 'What is the main reason for this visit?',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _BookingTextField(
            controller: _notesController,
            label: 'Optional notes',
            hint: 'Medication, behavior, or other information',
            maxLines: 3,
          ),
          if (_service!.homeVisit) ...[
            const SizedBox(height: 16),
            _BookingTextField(
              key: const ValueKey('appointment-address'),
              controller: _addressController,
              label: 'Confirmed home address *',
              hint: 'House, street, township, and contact details',
              maxLines: 3,
              prefixIcon: Icons.location_on_rounded,
            ),
            const SizedBox(height: 12),
            const _NoticeBox(
              icon: Icons.verified_user_rounded,
              text:
                  'The address is required for a Home Visit. Your selected slot is within 12:00 PM–3:00 PM.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryStep() {
    return _StepLayout(
      title: 'Booking Summary',
      subtitle: 'Review everything before confirming.',
      actionLabel: 'Confirm Appointment',
      actionEnabled: _holdSeconds > 0,
      onAction: _confirmBooking,
      child: Column(
        children: [
          _SummaryCard(
            rows: [
              ('Pet', '${_pet!.name} • ${_pet!.species}'),
              ('Service', _service!.name),
              ('Veterinarian', _veterinarian!),
              ('Date', _longDate(_date!)),
              ('Time', '$_time (1 hour)'),
              ('Symptoms', _symptomsController.text.trim()),
              ('Reason', _reasonController.text.trim()),
              if (_notesController.text.trim().isNotEmpty)
                ('Notes', _notesController.text.trim()),
              if (_service!.homeVisit)
                ('Address', _addressController.text.trim()),
            ],
          ),
          const SizedBox(height: 16),
          _NoticeBox(
            icon: Icons.timer_outlined,
            text:
                'Final slot check in ${_formatCountdown(_holdSeconds)}. Confirmation prevents double booking.',
          ),
        ],
      ),
    );
  }

  void _next() {
    if (_step >= 6) return;
    setState(() {
      _error = null;
      _step++;
    });
  }

  void _back() {
    if (_step == 0) return;
    setState(() {
      _error = null;
      _step--;
    });
  }

  void _holdTime(String time) {
    _holdTimer?.cancel();
    setState(() {
      _time = time;
      _holdSeconds = 4 * 60;
      _error = null;
    });
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_holdSeconds <= 1) {
        timer.cancel();
        setState(() {
          _time = null;
          _holdSeconds = 0;
          _error = 'The temporary slot hold expired. Select a time again.';
        });
        return;
      }
      setState(() => _holdSeconds--);
    });
  }

  void _clearHeldTime() {
    _holdTimer?.cancel();
    _time = null;
    _holdSeconds = 0;
  }

  void _validateDetails() {
    if (_holdSeconds == 0 || _time == null) {
      setState(
        () => _error = 'Your time-slot hold expired. Select a time again.',
      );
      _goToStep(4);
      return;
    }
    if (_symptomsController.text.trim().isEmpty ||
        _reasonController.text.trim().isEmpty) {
      setState(() => _error = 'Symptoms and appointment reason are required.');
      return;
    }
    if (_service!.homeVisit && _addressController.text.trim().isEmpty) {
      setState(() => _error = 'Confirm the address for the Home Visit.');
      return;
    }
    _next();
  }

  void _confirmBooking() {
    if (_holdSeconds == 0 || _time == null) {
      setState(
        () => _error = 'The slot hold expired. Please select a time again.',
      );
      _goToStep(4);
      return;
    }

    final slotAvailable = AppointmentStore.instance.isSlotAvailable(
      veterinarian: _veterinarian!,
      date: _date!,
      time: _time!,
    );
    if (!slotAvailable) {
      setState(
        () => _error = 'That slot was just booked. Choose another time.',
      );
      _goToStep(4);
      return;
    }

    final suffix = DateTime.now().millisecondsSinceEpoch.toString();
    final appointment = BookedAppointment(
      id: 'NWAY${suffix.substring(suffix.length - 7)}',
      pet: _pet!,
      service: _service!,
      veterinarian: _veterinarian!,
      date: _date!,
      time: _time!,
      symptoms: _symptomsController.text.trim(),
      reason: _reasonController.text.trim(),
      notes: _notesController.text.trim(),
      address: _addressController.text.trim(),
      status: 'Confirmed',
    );
    AppointmentStore.instance.add(appointment);
    _holdTimer?.cancel();
    setState(() => _createdAppointment = appointment);
  }

  void _goToStep(int step) {
    setState(() => _step = step);
  }

  String _doctorSpecialty(String doctor) {
    return switch (doctor) {
      'Dr. Hnin Thiri' => 'Vaccination and preventive care',
      'Dr. Min Khant' => 'Emergency and mobile veterinary care',
      'Dr. Su Mon' => 'Vaccination and consultation',
      _ => 'General veterinary medicine',
    };
  }
}

class _BookingHeader extends StatelessWidget {
  const _BookingHeader({required this.step, required this.onBack});

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 18),
      decoration: const BoxDecoration(
        color: _BookingColors.mint,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                tooltip: 'Back',
              ),
              const Expanded(
                child: Text(
                  'Book Appointment',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
              Image.asset(
                PetOwnerHomePage.logoAsset,
                width: 52,
                height: 52,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var index = 0; index < 7; index++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 5,
                    decoration: BoxDecoration(
                      color: index <= step
                          ? _BookingColors.green
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (index < 6) const SizedBox(width: 5),
              ],
            ],
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Step ${step + 1} of 7',
              style: const TextStyle(
                color: _BookingColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLayout extends StatelessWidget {
  const _StepLayout({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.actionLabel,
    required this.actionEnabled,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String actionLabel;
  final bool actionEnabled;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _BookingText.title),
                const SizedBox(height: 6),
                Text(subtitle, style: _BookingText.body),
                const SizedBox(height: 22),
                child,
              ],
            ),
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: actionEnabled ? onAction : null,
              style: FilledButton.styleFrom(
                backgroundColor: _BookingColors.green,
                disabledBackgroundColor: const Color(0xFFB7C9C2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE8FFF5) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? _BookingColors.green : const Color(0xFFDDE9E4),
              width: selected ? 2.3 : 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C0B2F25),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SelectedPetStrip extends StatelessWidget {
  const _SelectedPetStrip({required this.pet});

  final BookingPet pet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _BookingColors.mint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(pet.icon, color: pet.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${pet.name} • ${pet.species} • ${pet.breed}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFFDDF8EC),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: _BookingColors.green, size: 28),
    );
  }
}

class _BookingContextCard extends StatelessWidget {
  const _BookingContextCard({
    required this.pet,
    required this.service,
    required this.veterinarian,
  });

  final BookingPet pet;
  final BookingService service;
  final String veterinarian;

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      rows: [
        ('Pet', '${pet.name} • ${pet.species}'),
        ('Service', service.name),
        ('Veterinarian', veterinarian),
      ],
    );
  }
}

class _BookingTextField extends StatelessWidget {
  const _BookingTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLines,
    this.prefixIcon,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _BookingText.section),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: Color(0xFFD8E7E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: Color(0xFFD8E7E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(
                color: _BookingColors.green,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8E7E1)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 105,
                  child: Text(rows[index].$1, style: _BookingText.caption),
                ),
                Expanded(
                  child: Text(
                    rows[index].$2,
                    style: const TextStyle(
                      color: _BookingColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (index < rows.length - 1) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  const _NoticeBox({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FFF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC6EEDD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _BookingColors.green, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: _BookingText.caption)),
        ],
      ),
    );
  }
}

class _BookingConfirmation extends StatelessWidget {
  const _BookingConfirmation({required this.appointment});

  final BookedAppointment appointment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _BookingColors.page,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 44, 24, 28),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 54,
                backgroundColor: _BookingColors.green,
                child: Icon(Icons.check_rounded, color: Colors.white, size: 68),
              ),
              const SizedBox(height: 26),
              const Text(
                'Your booking is confirmed!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _BookingColors.ink,
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text('Booking ID: #${appointment.id}', style: _BookingText.body),
              const SizedBox(height: 24),
              _SummaryCard(
                rows: [
                  ('Pet', appointment.pet.name),
                  ('Service', appointment.service.name),
                  ('Veterinarian', appointment.veterinarian),
                  ('Date', _longDate(appointment.date)),
                  ('Time', appointment.time),
                  ('Status', appointment.status),
                ],
              ),
              const SizedBox(height: 16),
              const _NoticeBox(
                icon: Icons.notifications_active_rounded,
                text:
                    'Notifications have been prepared for the pet owner, veterinarian, and clinic staff.',
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushReplacementNamed(MyAppointmentsPage.routeName),
                  style: FilledButton.styleFrom(
                    backgroundColor: _BookingColors.green,
                  ),
                  child: const Text('View My Appointments'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _BookingColors.green,
                    side: const BorderSide(
                      color: _BookingColors.green,
                      width: 2,
                    ),
                  ),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final BookedAppointment appointment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8E7E1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBubble(icon: appointment.service.icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appointment.service.name,
                        style: _BookingText.cardTitle,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F8EF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        appointment.status,
                        style: _BookingText.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${appointment.pet.name} • ${appointment.veterinarian}',
                  style: _BookingText.body,
                ),
                const SizedBox(height: 5),
                Text(
                  '${_longDate(appointment.date)} • ${appointment.time}',
                  style: _BookingText.caption,
                ),
                const SizedBox(height: 5),
                Text('Booking #${appointment.id}', style: _BookingText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingColors {
  const _BookingColors._();

  static const page = Color(0xFFF7FAF8);
  static const mint = Color(0xFFC5F7E3);
  static const green = Color(0xFF20B978);
  static const ink = Color(0xFF17211E);
  static const muted = Color(0xFF60756E);
}

class _BookingText {
  const _BookingText._();

  static const title = TextStyle(
    color: _BookingColors.ink,
    fontSize: 28,
    fontWeight: FontWeight.w900,
  );
  static const section = TextStyle(
    color: _BookingColors.ink,
    fontSize: 17,
    fontWeight: FontWeight.w900,
  );
  static const cardTitle = TextStyle(
    color: _BookingColors.ink,
    fontSize: 18,
    fontWeight: FontWeight.w900,
  );
  static const body = TextStyle(
    color: _BookingColors.muted,
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w600,
  );
  static const caption = TextStyle(
    color: _BookingColors.muted,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const success = TextStyle(
    color: Color(0xFF087F50),
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );
}

String _shortDate(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${weekdays[date.weekday - 1]} ${date.day}';
}

String _longDate(DateTime date) {
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

String _formatCountdown(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$remainder';
}
