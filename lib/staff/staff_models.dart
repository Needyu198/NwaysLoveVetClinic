part of 'staff_portal.dart';

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
    _notifyOwner(
      item,
      status: status,
      doctor: doctor,
      rescheduled: date != null,
    );
  }

  /// Sends the pet owner a notification reflecting a staff change so the owner
  /// sees clinic-side updates to their booking.
  void _notifyOwner(
    StaffAppointment item, {
    String? status,
    String? doctor,
    bool rescheduled = false,
  }) {
    final pet = item.pet;
    if (rescheduled) {
      OwnerNotificationStore.instance.push(
        'Appointment rescheduled',
        '$pet is now booked for ${item.time}. Please review the new time.',
      );
      return;
    }
    if (status != null) {
      final message = switch (status) {
        'Confirmed' => 'Your appointment for $pet has been confirmed.',
        'Cancelled' => 'Your appointment for $pet was cancelled.',
        'Checked In' => '$pet has been checked in at the clinic.',
        'Called' => 'It is $pet\u2019s turn. Please proceed to the room.',
        'In Consultation' => '$pet\u2019s consultation has started.',
        'Completed' => '$pet\u2019s visit is complete.',
        _ => '$pet\u2019s appointment is now "$status".',
      };
      OwnerNotificationStore.instance.push('Appointment update', message);
      return;
    }
    if (doctor != null) {
      OwnerNotificationStore.instance.push(
        'Doctor assigned',
        '$doctor has been assigned to $pet.',
      );
    }
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
