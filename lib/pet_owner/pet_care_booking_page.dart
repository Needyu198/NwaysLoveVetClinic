import 'dart:async';

import 'package:flutter/material.dart';

class PetCareServicesPage extends StatelessWidget {
  const PetCareServicesPage({super.key});

  static const routeName = '/pet-care-services';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CareColors.page,
      appBar: AppBar(
        title: const Text('Pet Care Services'),
        backgroundColor: _CareColors.mint,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'My Service Bookings',
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(MyServiceBookingsPage.routeName),
            icon: const Icon(Icons.assignment_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
        children: [
          const Text('Care made comfortable', style: _CareText.title),
          const SizedBox(height: 7),
          const Text(
            'Choose a service to view requirements, prices, duration, providers, and available schedules.',
            style: _CareText.body,
          ),
          const SizedBox(height: 22),
          for (final service in PetCareCatalog.services) ...[
            _ServiceCard(service: service),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class MyServiceBookingsPage extends StatelessWidget {
  const MyServiceBookingsPage({super.key});

  static const routeName = '/my-service-bookings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CareColors.page,
      appBar: AppBar(
        title: const Text('My Service Bookings'),
        backgroundColor: _CareColors.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: PetCareBookingStore.instance,
        builder: (context, _) {
          final bookings = PetCareBookingStore.instance.bookings;
          if (bookings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.content_cut_rounded,
                      size: 70,
                      color: _CareColors.muted,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No service bookings yet',
                      style: _CareText.title,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose Pet Care Services from the Clinic categories to make a booking.',
                      textAlign: TextAlign.center,
                      style: _CareText.body,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
            itemCount: bookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) =>
                _ServiceBookingCard(booking: bookings[index]),
          );
        },
      ),
    );
  }
}

class PetCareBookingStore extends ChangeNotifier {
  PetCareBookingStore._();

  static final instance = PetCareBookingStore._();

  final List<PetCareBooking> _bookings = [];

  List<PetCareBooking> get bookings => List.unmodifiable(_bookings.reversed);

  bool isSlotAvailable({
    required String provider,
    required DateTime date,
    required String time,
  }) {
    return !_bookings.any(
      (booking) =>
          booking.provider == provider &&
          DateUtils.isSameDay(booking.date, date) &&
          booking.time == time &&
          booking.status != PetCareStatus.completed,
    );
  }

  void add(PetCareBooking booking) {
    _bookings.add(booking);
    notifyListeners();
  }

  void updateStatus(PetCareBooking booking, PetCareStatus status) {
    booking.status = status;
    notifyListeners();
  }

  void saveReview(PetCareBooking booking, int rating, String review) {
    booking.rating = rating;
    booking.review = review;
    notifyListeners();
  }

  @visibleForTesting
  void clear() {
    _bookings.clear();
    notifyListeners();
  }
}

enum PetCareStatus { confirmed, checkedIn, inProgress, completed }

class PetCareBooking {
  PetCareBooking({
    required this.id,
    required this.service,
    required this.pet,
    required this.provider,
    required this.date,
    required this.time,
    required this.allergies,
    required this.behaviorNotes,
    required this.medicalConditions,
    required this.specialRequests,
    required this.location,
    this.status = PetCareStatus.confirmed,
  });

  final String id;
  final PetCareService service;
  final CarePet pet;
  final String provider;
  final DateTime date;
  final String time;
  final String allergies;
  final String behaviorNotes;
  final String medicalConditions;
  final String specialRequests;
  final String location;
  PetCareStatus status;
  int rating = 0;
  String review = '';
}

class PetCareService {
  const PetCareService({
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.availability,
    required this.requirements,
    required this.icon,
    required this.providers,
    required this.options,
    this.homeService = false,
  });

  final String name;
  final String description;
  final String price;
  final String duration;
  final String availability;
  final String requirements;
  final IconData icon;
  final List<String> providers;
  final List<ServicePriceOption> options;
  final bool homeService;
}

class ServicePriceOption {
  const ServicePriceOption(this.name, this.prices);

  final String name;
  final String prices;
}

class CarePet {
  const CarePet({
    required this.name,
    required this.breed,
    required this.age,
    required this.health,
    required this.color,
  });

  final String name;
  final String breed;
  final String age;
  final String health;
  final Color color;
}

class PetCareCatalog {
  static const services = [
    PetCareService(
      name: 'Grooming',
      description: 'A full coat, skin, ear, nail, and hygiene care session.',
      price: 'From 7,000 MMK',
      duration: '45–120 min',
      availability: 'Available today',
      requirements: 'Vaccinations current; no contagious skin condition.',
      icon: Icons.content_cut_rounded,
      providers: ['May Thazin', 'Su Hlaing', 'Ko Min Grooming Team'],
      options: [
        ServicePriceOption(
          'Shaving',
          'S 12,000 • M 15,000 • L 20,000 • XL 25,000',
        ),
        ServicePriceOption(
          'Bath Only',
          'XS 7,000 • S 10,000 • M 12,000 • L 18,000 • XL 23,000',
        ),
        ServicePriceOption('Anal Gland Cleaning', 'S–XL 1,500'),
        ServicePriceOption('Ear Cleaning', 'S–M 2,000 • L–XL 3,000'),
        ServicePriceOption('Nail Clipping', 'S 1,000 • M–XL 2,000'),
        ServicePriceOption(
          'Brushing & Hair Trimming',
          'S–M 3,000 • L–XL 3,500',
        ),
      ],
    ),
    PetCareService(
      name: 'Bathing',
      description: 'Gentle shampoo, coat conditioning, drying, and brushing.',
      price: 'From 7,000 MMK',
      duration: '30–75 min',
      availability: 'Available today',
      requirements: 'Tell us about skin sensitivities or medicated shampoo.',
      icon: Icons.bathtub_outlined,
      providers: ['Su Hlaing', 'May Thazin'],
      options: [
        ServicePriceOption('Standard Bath', 'XS 7,000 • S 10,000 • M 12,000'),
        ServicePriceOption('Large Breed Bath', 'L 18,000 • XL 23,000'),
      ],
    ),
    PetCareService(
      name: 'Nail Trimming',
      description: 'Safe nail clipping with paw inspection and finishing.',
      price: '1,000–2,000 MMK',
      duration: '15–25 min',
      availability: 'Next slot in 1 hour',
      requirements: 'Behavior notes are required for anxious pets.',
      icon: Icons.back_hand_outlined,
      providers: ['Ko Min Grooming Team', 'May Thazin'],
      options: [ServicePriceOption('Nail Clipping', 'S 1,000 • M–XL 2,000')],
    ),
    PetCareService(
      name: 'Boarding',
      description:
          'Supervised day or overnight care with feeding and activity.',
      price: 'From 18,000 MMK/day',
      duration: 'Day or overnight',
      availability: 'Advance booking required',
      requirements: 'Current vaccines and flea prevention are required.',
      icon: Icons.night_shelter_outlined,
      providers: ['Clinic Boarding Team', 'Moe Sandar'],
      options: [
        ServicePriceOption('Day Care', '18,000 per day'),
        ServicePriceOption('Overnight Stay', '28,000 per night'),
      ],
    ),
    PetCareService(
      name: 'Home Care',
      description: 'A care provider visits your home for feeding and hygiene.',
      price: 'From 25,000 MMK',
      duration: '60–90 min',
      availability: '12:00 PM–3:00 PM',
      requirements: 'Address and a safe pet-access contact are required.',
      icon: Icons.home_outlined,
      providers: ['Moe Sandar', 'Clinic Home Care Team'],
      options: [
        ServicePriceOption('Home Care Visit', '25,000 per visit'),
        ServicePriceOption('Two-pet Visit', '35,000 per visit'),
      ],
      homeService: true,
    ),
  ];

  static const pets = [
    CarePet(
      name: 'Max',
      breed: 'Golden Retriever',
      age: '2 years',
      health: 'Vaccinations current • No active conditions',
      color: Color(0xFF2F80FF),
    ),
    CarePet(
      name: 'Bella',
      breed: 'Shih Tzu',
      age: '1 year',
      health: 'Vaccinations current • Sensitive skin',
      color: Color(0xFFEF5B4E),
    ),
    CarePet(
      name: 'Luna',
      breed: 'Mixed-breed cat',
      age: '3 years',
      health: 'Vaccinations current • Indoor pet',
      color: Color(0xFF8B3DFF),
    ),
  ];
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final PetCareService service;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        key: ValueKey('pet-care-service-${service.name}'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PetCareServiceDetailsPage(service: service),
          ),
        ),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: _CareColors.mint,
                  shape: BoxShape.circle,
                ),
                child: Icon(service.icon, size: 29),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, style: _CareText.cardTitle),
                    const SizedBox(height: 5),
                    Text(service.description, style: _CareText.body),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 7,
                      children: [
                        _InfoPill(Icons.payments_outlined, service.price),
                        _InfoPill(Icons.schedule_rounded, service.duration),
                        _InfoPill(
                          Icons.event_available_outlined,
                          service.availability,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class PetCareServiceDetailsPage extends StatelessWidget {
  const PetCareServiceDetailsPage({required this.service, super.key});

  final PetCareService service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CareColors.page,
      appBar: AppBar(
        title: Text('${service.name} Services'),
        backgroundColor: _CareColors.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 118),
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: _CareColors.mint,
                  shape: BoxShape.circle,
                ),
                child: Icon(service.icon, size: 32),
              ),
              const SizedBox(width: 15),
              Expanded(child: Text(service.name, style: _CareText.title)),
            ],
          ),
          const SizedBox(height: 18),
          Text(service.description, style: _CareText.body),
          const SizedBox(height: 18),
          _DetailPanel(
            title: 'Service information',
            children: [
              _DetailRow('Price', service.price),
              _DetailRow('Duration', service.duration),
              _DetailRow('Availability', service.availability),
              _DetailRow('Requirements', service.requirements),
              _DetailRow('Providers', service.providers.join(', ')),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Service menu', style: _CareText.section),
          const SizedBox(height: 10),
          for (final option in service.options) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _CareColors.mint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.name, style: _CareText.cardTitle),
                  const SizedBox(height: 7),
                  Text(option.prices, style: _CareText.bodyDark),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton.icon(
          key: const ValueKey('start-service-booking'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PetCareBookingPage(service: service),
            ),
          ),
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Book This Service'),
          style: _CareStyles.primaryButton,
        ),
      ),
    );
  }
}

class PetCareBookingPage extends StatefulWidget {
  const PetCareBookingPage({required this.service, super.key});

  final PetCareService service;

  @override
  State<PetCareBookingPage> createState() => _PetCareBookingPageState();
}

class _PetCareBookingPageState extends State<PetCareBookingPage> {
  final _allergies = TextEditingController();
  final _behavior = TextEditingController();
  final _conditions = TextEditingController();
  final _requests = TextEditingController();
  final _address = TextEditingController();

  int _step = 0;
  CarePet? _pet;
  String? _provider;
  DateTime? _date;
  String? _time;
  int _holdSeconds = 0;
  Timer? _timer;
  String? _error;
  PetCareBooking? _created;

  List<DateTime> get _dates {
    final today = DateUtils.dateOnly(DateTime.now());
    return List.generate(7, (index) => today.add(Duration(days: index + 1)));
  }

  List<String> get _times => widget.service.homeService
      ? const ['12:00 PM', '1:00 PM', '2:00 PM', '3:00 PM']
      : const [
          '9:00 AM',
          '10:00 AM',
          '11:00 AM',
          '1:00 PM',
          '2:00 PM',
          '4:00 PM',
        ];

  @override
  void dispose() {
    _timer?.cancel();
    _allergies.dispose();
    _behavior.dispose();
    _conditions.dispose();
    _requests.dispose();
    _address.dispose();
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
    if (_date == null || _time == null || _provider == null) return;
    if (!PetCareBookingStore.instance.isSlotAvailable(
      provider: _provider!,
      date: _date!,
      time: _time!,
    )) {
      setState(
        () => _error = 'That schedule was just booked. Choose another slot.',
      );
      return;
    }
    _timer?.cancel();
    setState(() => _holdSeconds = 240);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_holdSeconds <= 1) {
        timer.cancel();
        setState(() {
          _holdSeconds = 0;
          _time = null;
          _error = 'The temporary hold expired. Select a time again.';
        });
      } else {
        setState(() => _holdSeconds -= 1);
      }
    });
    _next();
  }

  void _confirm() {
    if (_holdSeconds == 0 ||
        !PetCareBookingStore.instance.isSlotAvailable(
          provider: _provider!,
          date: _date!,
          time: _time!,
        )) {
      setState(() {
        _step = 2;
        _time = null;
        _error = 'The slot is no longer available. Please select another time.';
      });
      return;
    }

    final booking = PetCareBooking(
      id: 'CARE${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      service: widget.service,
      pet: _pet!,
      provider: _provider!,
      date: _date!,
      time: _time!,
      allergies: _allergies.text.trim(),
      behaviorNotes: _behavior.text.trim(),
      medicalConditions: _conditions.text.trim(),
      specialRequests: _requests.text.trim(),
      location: widget.service.homeService
          ? _address.text.trim()
          : "Nway's Love Vet Clinic",
    );
    _timer?.cancel();
    PetCareBookingStore.instance.add(booking);
    setState(() => _created = booking);
  }

  @override
  Widget build(BuildContext context) {
    if (_created != null) return _ServiceConfirmation(booking: _created!);

    return Scaffold(
      backgroundColor: _CareColors.page,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text('Book ${widget.service.name}'),
        backgroundColor: _CareColors.mint,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(5),
          child: LinearProgressIndicator(
            value: (_step + 1) / 5,
            backgroundColor: Colors.white54,
            color: _CareColors.green,
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
    1 => _providerStep(),
    2 => _scheduleStep(),
    3 => _instructionsStep(),
    _ => _summaryStep(),
  };

  Widget _petStep() {
    return _BookingStep(
      title: 'Select Pet',
      subtitle:
          'We will check the pet profile against the service requirements.',
      action: 'Check Eligibility',
      enabled: _pet != null,
      onAction: _next,
      child: ListView.separated(
        itemCount: PetCareCatalog.pets.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final pet = PetCareCatalog.pets[index];
          return _SelectTile(
            key: ValueKey('care-pet-${pet.name}'),
            selected: _pet == pet,
            icon: Icons.pets_rounded,
            color: pet.color,
            title: pet.name,
            subtitle: '${pet.breed} • ${pet.age}\n${pet.health}',
            onTap: () => setState(() => _pet = pet),
          );
        },
      ),
    );
  }

  Widget _providerStep() {
    return _BookingStep(
      title: 'Eligible for ${widget.service.name}',
      subtitle:
          '${_pet!.name} meets the current requirements. Select an available provider.',
      action: 'Select Schedule',
      enabled: _provider != null,
      onAction: _next,
      child: ListView.separated(
        itemCount: widget.service.providers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final provider = widget.service.providers[index];
          return _SelectTile(
            selected: _provider == provider,
            icon: Icons.badge_outlined,
            color: _CareColors.green,
            title: provider,
            subtitle: 'Pet care provider • Available this week',
            onTap: () => setState(() => _provider = provider),
          );
        },
      ),
    );
  }

  Widget _scheduleStep() {
    return _BookingStep(
      title: 'Select Schedule',
      subtitle:
          'Choose a date and time. The selected slot is held for 4 minutes.',
      action: 'Hold This Slot',
      enabled: _date != null && _time != null,
      onAction: _holdSlot,
      child: ListView(
        children: [
          const Text('Available dates', style: _CareText.section),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final date in _dates)
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
          const SizedBox(height: 24),
          const Text('Available times', style: _CareText.section),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final time in _times)
                ChoiceChip(
                  key: ValueKey('care-time-$time'),
                  label: Text(time),
                  selected: _time == time,
                  onSelected: _date == null
                      ? null
                      : (_) => setState(() => _time = time),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _instructionsStep() {
    final minutes = _holdSeconds ~/ 60;
    final seconds = (_holdSeconds % 60).toString().padLeft(2, '0');
    return _BookingStep(
      title: 'Special Instructions',
      subtitle:
          'Slot held for $minutes:$seconds. Add anything the provider should know.',
      action: 'Review Booking',
      enabled: !widget.service.homeService || _address.text.trim().isNotEmpty,
      onAction: _next,
      child: ListView(
        children: [
          _CareField(
            controller: _allergies,
            label: 'Allergies',
            hint: 'Food, shampoo, medicine, or none',
          ),
          _CareField(
            controller: _behavior,
            label: 'Behavior notes',
            hint: 'Anxious, friendly, dislikes nail care...',
          ),
          _CareField(
            controller: _conditions,
            label: 'Medical conditions',
            hint: 'Skin, mobility, or other conditions',
          ),
          _CareField(
            controller: _requests,
            label: 'Special requests',
            hint: 'Preferred style or care instructions',
          ),
          if (widget.service.homeService)
            _CareField(
              key: const ValueKey('care-address'),
              controller: _address,
              label: 'Confirmed home address *',
              hint: 'House number, street, township',
              onChanged: (_) => setState(() {}),
            ),
        ],
      ),
    );
  }

  Widget _summaryStep() {
    return _BookingStep(
      title: 'Booking Summary',
      subtitle: 'Review the details. No online payment is required.',
      action: 'Confirm Service',
      enabled: true,
      onAction: _confirm,
      child: ListView(
        children: [
          _DetailPanel(
            title: 'Service booking',
            children: [
              _DetailRow('Pet', '${_pet!.name} • ${_pet!.breed}'),
              _DetailRow('Service', widget.service.name),
              _DetailRow('Provider', _provider!),
              _DetailRow('Schedule', '${_longDate(_date!)} • $_time'),
              _DetailRow(
                'Location',
                widget.service.homeService
                    ? _address.text.trim()
                    : "Nway's Love Vet Clinic",
              ),
              _DetailRow('Price', widget.service.price),
              _DetailRow('Allergies', _valueOrNone(_allergies.text)),
              _DetailRow('Behavior', _valueOrNone(_behavior.text)),
              _DetailRow('Conditions', _valueOrNone(_conditions.text)),
              _DetailRow('Requests', _valueOrNone(_requests.text)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceConfirmation extends StatelessWidget {
  const _ServiceConfirmation({required this.booking});

  final PetCareBooking booking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CareColors.page,
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
                    color: _CareColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 68,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Service booking confirmed!',
                  textAlign: TextAlign.center,
                  style: _CareText.title,
                ),
                const SizedBox(height: 10),
                Text(
                  'Booking number: #${booking.id}',
                  style: _CareText.bodyDark,
                ),
                const SizedBox(height: 20),
                Text(
                  '${booking.service.name} for ${booking.pet.name}\n${_longDate(booking.date)} at ${booking.time}\nProvider: ${booking.provider}',
                  textAlign: TextAlign.center,
                  style: _CareText.bodyDark,
                ),
                const SizedBox(height: 18),
                const _Notice(
                  icon: Icons.notifications_active_outlined,
                  text:
                      'The pet owner and service provider have been notified.',
                ),
                const SizedBox(height: 26),
                FilledButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushReplacementNamed(MyServiceBookingsPage.routeName),
                  style: _CareStyles.primaryButton,
                  child: const Text('View Service Booking'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil(
                    (route) =>
                        route.settings.name == PetCareServicesPage.routeName,
                  ),
                  child: const Text('Back to Services'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceBookingCard extends StatelessWidget {
  const _ServiceBookingCard({required this.booking});

  final PetCareBooking booking;

  @override
  Widget build(BuildContext context) {
    final store = PetCareBookingStore.instance;
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
          Row(
            children: [
              Expanded(
                child: Text(booking.service.name, style: _CareText.cardTitle),
              ),
              _StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${booking.pet.name} • ${booking.provider}',
            style: _CareText.bodyDark,
          ),
          const SizedBox(height: 4),
          Text(
            '${_longDate(booking.date)} at ${booking.time}',
            style: _CareText.body,
          ),
          const SizedBox(height: 4),
          Text('Booking #${booking.id}', style: _CareText.body),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: switch (booking.status) {
              PetCareStatus.confirmed => FilledButton(
                onPressed: () =>
                    store.updateStatus(booking, PetCareStatus.checkedIn),
                child: const Text('Check In Pet'),
              ),
              PetCareStatus.checkedIn => FilledButton(
                onPressed: () =>
                    store.updateStatus(booking, PetCareStatus.inProgress),
                child: const Text('Start Service'),
              ),
              PetCareStatus.inProgress => FilledButton(
                onPressed: () =>
                    store.updateStatus(booking, PetCareStatus.completed),
                child: const Text('Mark Service Complete'),
              ),
              PetCareStatus.completed => OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ServiceReportPage(booking: booking),
                  ),
                ),
                child: Text(
                  booking.rating == 0
                      ? 'View Report & Review'
                      : 'View Service Report',
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class ServiceReportPage extends StatefulWidget {
  const ServiceReportPage({required this.booking, super.key});

  final PetCareBooking booking;

  @override
  State<ServiceReportPage> createState() => _ServiceReportPageState();
}

class _ServiceReportPageState extends State<ServiceReportPage> {
  late final TextEditingController _review;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.booking.rating;
    _review = TextEditingController(text: widget.booking.review);
  }

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CareColors.page,
      appBar: AppBar(
        title: const Text('Service Report'),
        backgroundColor: _CareColors.mint,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _DetailPanel(
            title: '${widget.booking.service.name} completed',
            children: [
              _DetailRow('Pet', widget.booking.pet.name),
              _DetailRow('Provider', widget.booking.provider),
              const _DetailRow(
                'Activities',
                'Service completed, hygiene check, coat and skin inspection',
              ),
              const _DetailRow(
                'Provider notes',
                'Pet was calm and cooperative. No concerns observed.',
              ),
              const _DetailRow(
                'Recommendations',
                'Continue regular home care and book the next visit in 4–6 weeks.',
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Rating and Review', style: _CareText.section),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  key: ValueKey('care-rating-$star'),
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
                    PetCareBookingStore.instance.saveReview(
                      widget.booking,
                      _rating,
                      _review.text.trim(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you. Your review was saved.'),
                      ),
                    );
                  },
            style: _CareStyles.primaryButton,
            child: const Text('Submit Review'),
          ),
        ],
      ),
    );
  }
}

class _BookingStep extends StatelessWidget {
  const _BookingStep({
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
          Text(title, style: _CareText.title),
          const SizedBox(height: 6),
          Text(subtitle, style: _CareText.body),
          const SizedBox(height: 18),
          Expanded(child: child),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: enabled ? onAction : null,
              style: _CareStyles.primaryButton,
              child: Text(action),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectTile extends StatelessWidget {
  const _SelectTile({
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
      color: selected ? _CareColors.mint : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _CareColors.green : const Color(0xFFD7E4DF),
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
                    Text(title, style: _CareText.cardTitle),
                    const SizedBox(height: 4),
                    Text(subtitle, style: _CareText.body),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? _CareColors.green : _CareColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CareField extends StatelessWidget {
  const _CareField({
    required this.controller,
    required this.label,
    required this.hint,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.title, required this.children});

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
          Text(title, style: _CareText.section),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 104, child: Text(label, style: _CareText.label)),
          Expanded(child: Text(value, style: _CareText.bodyDark)),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _CareColors.mint,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PetCareStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      PetCareStatus.confirmed => 'Confirmed',
      PetCareStatus.checkedIn => 'Checked In',
      PetCareStatus.inProgress => 'In Progress',
      PetCareStatus.completed => 'Completed',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _CareColors.mint,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _CareColors.green,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _CareColors.mint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: _CareColors.green),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: _CareText.bodyDark)),
        ],
      ),
    );
  }
}

class _CareColors {
  static const page = Color(0xFFF7FAF8);
  static const mint = Color(0xFFA1FDD8);
  static const green = Color(0xFF16855E);
  static const muted = Color(0xFF61736D);
}

class _CareText {
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
    color: _CareColors.muted,
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
    color: _CareColors.muted,
  );
}

class _CareStyles {
  static final primaryButton = FilledButton.styleFrom(
    backgroundColor: _CareColors.green,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(54),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
  );
}

String _valueOrNone(String value) =>
    value.trim().isEmpty ? 'None provided' : value.trim();

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
