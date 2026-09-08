part of 'staff_portal.dart';

class StaffOperationsStore extends ChangeNotifier {
  void connectDatabase() {
    DatabaseSync.instance.bind(
      'walk_in_appointments',
      this,
      () => {
        for (final item in _demo) databaseRecordKey(item, item.id): item.toDb(),
      },
      (rows) {
        _demo
          ..clear()
          ..addAll(
            rows.entries.map(
              (e) =>
                  databaseRestoreKey(StaffAppointment.fromDb(e.value), e.key),
            ),
          );
      },
    );
    DatabaseSync.instance.bind(
      'payments',
      this,
      () => {
        for (final item in payments)
          databaseRecordKey(item, item.id): item.toDb(),
      },
      (rows) {
        payments
          ..clear()
          ..addAll(
            rows.entries.map(
              (e) => databaseRestoreKey(StaffPayment.fromDb(e.value), e.key),
            ),
          );
      },
    );
    DatabaseSync.instance.bind(
      'inventory',
      this,
      () => {
        for (final item in inventory)
          databaseRecordKey(item, item.id): item.toDb(),
      },
      (rows) {
        inventory
          ..clear()
          ..addAll(
            rows.entries.map(
              (e) => databaseRestoreKey(InventoryItem.fromDb(e.value), e.key),
            ),
          );
      },
    );
  }

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
      id: 'FOOD-0010',
      name: 'Dog Food 01',
      category: 'Pet Food',
      quantity: 10,
      reorderLevel: 8,
      unit: 'bags',
      sellingPrice: 4000,
      purchasePrice: 3200,
      supplier: 'Pedigree Distributor',
      expiresOn: DateTime.now().add(const Duration(days: 300)),
    ),
    InventoryItem(
      id: 'FOOD-0011',
      name: 'Cat Food 01',
      category: 'Pet Food',
      quantity: 11,
      reorderLevel: 8,
      unit: 'bags',
      sellingPrice: 4500,
      purchasePrice: 3600,
      supplier: 'Meow Mix Supplier',
      expiresOn: DateTime.now().add(const Duration(days: 320)),
    ),
    InventoryItem(
      id: 'FOOD-0013',
      name: 'Dog Food 02',
      category: 'Pet Food',
      quantity: 13,
      reorderLevel: 8,
      unit: 'bags',
      sellingPrice: 4700,
      purchasePrice: 3800,
      supplier: 'Rabbit Food Co.',
      expiresOn: DateTime.now().add(const Duration(days: 280)),
    ),
    InventoryItem(
      id: 'MED-001',
      name: 'Amoxicillin 250 mg',
      category: 'Medicine',
      quantity: 18,
      reorderLevel: 20,
      unit: 'capsules',
      sellingPrice: 1200,
      purchasePrice: 800,
      supplier: 'PharmaVet',
      expiresOn: DateTime.now().add(const Duration(days: 180)),
    ),
    InventoryItem(
      id: 'MED-014',
      name: 'Meloxicam Oral Suspension',
      category: 'Medicine',
      quantity: 7,
      reorderLevel: 10,
      unit: 'bottles',
      sellingPrice: 6500,
      purchasePrice: 4800,
      supplier: 'PharmaVet',
      expiresOn: DateTime.now().add(const Duration(days: 75)),
    ),
    InventoryItem(
      id: 'SUP-008',
      name: 'Sterile Examination Gloves',
      category: 'Medical Supplies',
      quantity: 240,
      reorderLevel: 100,
      unit: 'pairs',
      sellingPrice: 300,
      purchasePrice: 180,
      supplier: 'ClinicPro',
      expiresOn: DateTime.now().add(const Duration(days: 700)),
    ),
    InventoryItem(
      id: 'SUP-021',
      name: 'Wound Dressing 10 cm',
      category: 'Medical Supplies',
      quantity: 0,
      reorderLevel: 25,
      unit: 'packs',
      sellingPrice: 900,
      purchasePrice: 600,
      supplier: 'ClinicPro',
      expiresOn: DateTime.now().subtract(const Duration(days: 12)),
    ),
  ];

  /// All inventory categories used by the product catalog and filters.
  static const inventoryCategories = [
    'Pet Food',
    'Medicine',
    'Vaccines',
    'Medical Supplies',
    'Cleaning Supplies',
    'Accessories',
    'Other',
  ];

  List<InventoryItem> get activeInventory =>
      inventory.where((item) => !item.archived).toList();
  List<InventoryItem> get archivedInventory =>
      inventory.where((item) => item.archived).toList();

  bool isDuplicateSku(String sku) => inventory.any(
    (item) => item.id.toLowerCase() == sku.trim().toLowerCase(),
  );

  void addItem(InventoryItem item) {
    inventory.add(item);
    _record(
      item,
      type: 'Stock In',
      quantity: item.quantity,
      previous: 0,
      next: item.quantity,
      reason: 'Initial stock',
    );
    notifyListeners();
  }

  /// Receive stock (Stock In). Adds [quantity] to the item's balance.
  void stockIn(
    InventoryItem item,
    int quantity, {
    String reason = 'Delivery received',
    String reference = '',
  }) {
    if (quantity <= 0) return;
    final previous = item.quantity;
    item.quantity = previous + quantity;
    _record(
      item,
      type: 'Stock In',
      quantity: quantity,
      previous: previous,
      next: item.quantity,
      reason: reason,
      reference: reference,
    );
    item.lastAudit =
        'Stock In +$quantity • Mya Thu • ${_shortDate(DateTime.now())}';
    if (!item.isLowStock) {
      item.restockRequested = false;
      item.restockStatus = item.restockStatus.isEmpty ? '' : 'Received';
    }
    notifyListeners();
  }

  /// Issue/use stock (Stock Out). Never allows the balance to go negative.
  /// Returns false when there is not enough stock.
  bool stockOut(
    InventoryItem item,
    int quantity, {
    required String reason,
    String reference = '',
  }) {
    if (quantity <= 0 || quantity > item.quantity) return false;
    final previous = item.quantity;
    item.quantity = previous - quantity;
    _record(
      item,
      type: 'Stock Out',
      quantity: quantity,
      previous: previous,
      next: item.quantity,
      reason: reason,
      reference: reference,
    );
    item.lastAudit =
        'Stock Out -$quantity ($reason) • Mya Thu • ${_shortDate(DateTime.now())}';
    notifyListeners();
    return true;
  }

  void adjustStock(InventoryItem item, int quantity, String reason) {
    final previous = item.quantity;
    item.quantity = quantity.clamp(0, 999999);
    _record(
      item,
      type: 'Adjustment',
      quantity: (item.quantity - previous).abs(),
      previous: previous,
      next: item.quantity,
      reason: reason,
    );
    item.lastAudit = '$reason • Mya Thu • ${_shortDate(DateTime.now())}';
    notifyListeners();
  }

  /// Notifies listeners after an in-place edit of an existing item's fields.
  void notifyChanged() => notifyListeners();

  void archiveItem(InventoryItem item, String reason) {
    item.archived = true;
    item.lastAudit =
        'Archived ($reason) • Mya Thu • ${_shortDate(DateTime.now())}';
    notifyListeners();
  }

  void requestRestock(InventoryItem item, int quantity, String note) {
    item.restockRequested = true;
    item.restockQuantity = quantity;
    item.restockNote = note;
    item.restockStatus = 'Pending Approval';
    notifyListeners();
  }

  void _record(
    InventoryItem item, {
    required String type,
    required int quantity,
    required int previous,
    required int next,
    required String reason,
    String reference = '',
  }) {
    item.movements.add(
      StockMovement(
        id: 'MOV-${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        quantity: quantity,
        previousBalance: previous,
        newBalance: next,
        reason: reason,
        staff: 'Mya Thu',
        at: DateTime.now(),
        reference: reference,
      ),
    );
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

    // Seed a pending restock request so the admin Inventory Approval flow
    // has data to review on a fresh start (the item is out of stock).
    final restockItem = inventory.firstWhere(
      (item) => item.id == 'SUP-021',
      orElse: () => inventory.first,
    );
    restockItem.restockRequested = true;
    restockItem.restockQuantity = 50;
    restockItem.restockNote =
        'Out of stock. Needed for daily wound care and surgeries.';
    restockItem.restockStatus = 'Pending Approval';
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
    if (source != null) AppointmentStore.instance.databaseChanged();
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
    final ownerId = databaseOwnerOf(item.source);
    if (ownerId == null && DatabaseSync.instance.active) return;
    if (rescheduled) {
      OwnerNotificationStore.instance.push(
        'Appointment rescheduled',
        '$pet is now booked for ${item.time}. Please review the new time.',
        ownerId: ownerId,
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
      OwnerNotificationStore.instance.push(
        'Appointment update',
        message,
        ownerId: ownerId,
      );
      return;
    }
    if (doctor != null) {
      OwnerNotificationStore.instance.push(
        'Doctor assigned',
        '$doctor has been assigned to $pet.',
        ownerId: ownerId,
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
  Map<String, dynamic> toDb() => {
    'id': id,
    'pet': pet,
    'owner': owner,
    'phone': phone,
    'service': service,
    'doctor': doctor,
    'date': date.toIso8601String(),
    'time': time,
    'reason': reason,
    'status': status,
    'priority': priority,
    'queueNumber': queueNumber,
  };
  static StaffAppointment fromDb(Map<String, dynamic> data) {
    final value = StaffAppointment(
      id: data['id'] as String,
      pet: data['pet'] as String,
      owner: data['owner'] as String,
      phone: data['phone'] as String,
      service: data['service'] as String,
      doctor: data['doctor'] as String,
      date: DateTime.parse(data['date'] as String),
      time: data['time'] as String,
      reason: data['reason'] as String,
      status: data['status'] as String,
      priority: data['priority'] as String,
      queueNumber: data['queueNumber'] as String,
    );
    return value;
  }

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
  Map<String, dynamic> toDb() => {
    'id': id,
    'owner': owner,
    'pet': pet,
    'amount': amount,
    'status': status,
  };
  static StaffPayment fromDb(Map<String, dynamic> data) {
    final value = StaffPayment(
      id: data['id'] as String,
      owner: data['owner'] as String,
      pet: data['pet'] as String,
      amount: data['amount'] as int,
      status: data['status'] as String,
    );
    return value;
  }

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

/// A single recorded stock movement (Stock In / Stock Out / adjustment) that
/// keeps the inventory auditable per the spec's Stock History requirement.
class StockMovement {
  Map<String, dynamic> toDb() => {
    'id': id,
    'type': type,
    'quantity': quantity,
    'previousBalance': previousBalance,
    'newBalance': newBalance,
    'reason': reason,
    'staff': staff,
    'at': at.toIso8601String(),
    'reference': reference,
  };
  static StockMovement fromDb(Map<String, dynamic> data) {
    final value = StockMovement(
      id: data['id'] as String,
      type: data['type'] as String,
      quantity: data['quantity'] as int,
      previousBalance: data['previousBalance'] as int,
      newBalance: data['newBalance'] as int,
      reason: data['reason'] as String,
      staff: data['staff'] as String,
      at: DateTime.parse(data['at'] as String),
      reference: data['reference'] as String,
    );
    return value;
  }

  StockMovement({
    required this.id,
    required this.type,
    required this.quantity,
    required this.previousBalance,
    required this.newBalance,
    required this.reason,
    required this.staff,
    required this.at,
    this.reference = '',
  });

  final String id;
  final String type; // 'Stock In', 'Stock Out', 'Adjustment'
  final int quantity;
  final int previousBalance;
  final int newBalance;
  final String reason;
  final String staff;
  final DateTime at;
  final String reference;
}

class InventoryItem {
  Map<String, dynamic> toDb() => {
    'id': id,
    'name': name,
    'category': category,
    'quantity': quantity,
    'reorderLevel': reorderLevel,
    'unit': unit,
    'expiresOn': expiresOn.toIso8601String(),
    'sellingPrice': sellingPrice,
    'purchasePrice': purchasePrice,
    'supplier': supplier,
    'batchNumber': batchNumber,
    'imageAsset': imageAsset,
    'description': description,
    'restockRequested': restockRequested,
    'restockQuantity': restockQuantity,
    'restockNote': restockNote,
    'restockStatus': restockStatus,
    'lastAudit': lastAudit,
    'archived': archived,
    'movements': movements.map((v) => v.toDb()).toList(),
  };
  static InventoryItem fromDb(Map<String, dynamic> data) {
    final value = InventoryItem(
      id: data['id'] as String,
      name: data['name'] as String,
      category: data['category'] as String,
      quantity: data['quantity'] as int,
      reorderLevel: data['reorderLevel'] as int,
      unit: data['unit'] as String,
      expiresOn: DateTime.parse(data['expiresOn'] as String),
      sellingPrice: data['sellingPrice'] as int,
      purchasePrice: data['purchasePrice'] as int,
      supplier: data['supplier'] as String,
      batchNumber: data['batchNumber'] as String,
      imageAsset: data['imageAsset'] == null
          ? null
          : data['imageAsset'] as String,
      // Backward-compatible: older records have no description.
      description: data['description'] as String? ?? '',
    );
    value.restockRequested = data['restockRequested'] as bool;
    value.restockQuantity = data['restockQuantity'] as int;
    value.restockNote = data['restockNote'] as String;
    value.restockStatus = data['restockStatus'] as String;
    value.lastAudit = data['lastAudit'] as String;
    value.archived = data['archived'] as bool;
    value.movements.addAll(
      (data['movements'] as List)
          .map((v) => StockMovement.fromDb(Map<String, dynamic>.from(v as Map)))
          .toList(),
    );
    return value;
  }

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.reorderLevel,
    required this.unit,
    required this.expiresOn,
    this.sellingPrice = 0,
    this.purchasePrice = 0,
    this.supplier = '',
    this.batchNumber = '',
    this.imageAsset,
    this.description = '',
  });

  final String id;
  String name;
  String category;
  int quantity;
  int reorderLevel;
  String unit;
  DateTime expiresOn;
  int sellingPrice;
  int purchasePrice;
  String supplier;
  String batchNumber;
  String? imageAsset;
  String description;

  bool restockRequested = false;
  int restockQuantity = 0;
  String restockNote = '';
  String restockStatus = '';
  String lastAudit = 'No stock changes recorded';
  bool archived = false;
  final List<StockMovement> movements = [];

  bool get isOutOfStock => quantity <= 0;
  bool get isLowStock => quantity <= reorderLevel;
  bool get isExpired => expiresOn.isBefore(DateTime.now());
  bool get isNearExpiry =>
      !isExpired &&
      expiresOn.isBefore(DateTime.now().add(const Duration(days: 90)));

  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }
}

/// Editable profile of the signed-in clinic staff member. In-memory only
/// (resets on restart) but reactive so the whole app reflects changes.
class StaffProfileStore extends ChangeNotifier {
  void connectDatabase() {
    DatabaseSync.instance.bind(
      'staff_profiles',
      this,
      () => {
        'profile': {
          'name': name,
          'phone': phone,
          'email': email,
          'shift': shift,
          'onShift': onShift,
          'photoPath': photoPath,
          'appointmentAlerts': appointmentAlerts,
          'emergencyAlerts': emergencyAlerts,
          'queueAlerts': queueAlerts,
        },
      },
      (rows) {
        final value = rows.isEmpty ? <String, dynamic>{} : rows.values.first;
        name = value['name'] as String? ?? '';
        phone = value['phone'] as String? ?? '';
        email = value['email'] as String? ?? '';
        shift = value['shift'] as String? ?? '';
        onShift = value['onShift'] as bool? ?? false;
        photoPath = value['photoPath'] as String?;
        appointmentAlerts = value['appointmentAlerts'] as bool? ?? true;
        emergencyAlerts = value['emergencyAlerts'] as bool? ?? true;
        queueAlerts = value['queueAlerts'] as bool? ?? true;
      },
    );
  }

  StaffProfileStore._();

  static final StaffProfileStore instance = StaffProfileStore._();

  // Editable by staff.
  String name = 'Mya Thu';
  String phone = '09 781 220 118';
  String email = 'staff@nwaysclinic.com';
  String shift = 'Morning • 8:00 AM–4:00 PM';
  bool onShift = true;
  String? photoPath;

  // Administrator-controlled (read-only for staff).
  final String role = 'Clinic Operations Staff';
  final String employeeId = 'STF-018';
  final String clinic = "Nway's Love Vet Clinic";

  // Notification preferences.
  bool appointmentAlerts = true;
  bool emergencyAlerts = true;
  bool queueAlerts = true;

  /// First name used for the dashboard greeting ("Good Morning, Mya").
  String get firstName => name.trim().split(' ').first;

  void save({
    required String name,
    required String phone,
    required String email,
    required String shift,
    required bool onShift,
    String? photoPath,
  }) {
    this.name = name;
    this.phone = phone;
    this.email = email;
    this.shift = shift;
    this.onShift = onShift;
    this.photoPath = photoPath;
    notifyListeners();
  }

  void setOnShift(bool value) {
    onShift = value;
    notifyListeners();
  }

  void updateNotifications({bool? appointment, bool? emergency, bool? queue}) {
    if (appointment != null) appointmentAlerts = appointment;
    if (emergency != null) emergencyAlerts = emergency;
    if (queue != null) queueAlerts = queue;
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    name = 'Mya Thu';
    phone = '09 781 220 118';
    email = 'staff@nwaysclinic.com';
    shift = 'Morning • 8:00 AM–4:00 PM';
    onShift = true;
    photoPath = null;
    appointmentAlerts = true;
    emergencyAlerts = true;
    queueAlerts = true;
    notifyListeners();
  }
}
