part of 'staff_portal.dart';

class StaffOperationsStore extends ChangeNotifier {
  void databaseChanged() => notifyListeners();

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
      category: 'Food',
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
      category: 'Food',
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
      category: 'Food',
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
      category: 'Accessories',
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
      category: 'Accessories',
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
  static const inventoryCategories = ['Food', 'Medicine', 'Accessories'];

  List<InventoryItem> get activeInventory =>
      inventory.where((item) => !item.archived).toList();
  List<InventoryItem> get archivedInventory =>
      inventory.where((item) => item.archived).toList();

  bool isDuplicateSku(String sku) => inventory.any(
    (item) => item.id.toLowerCase() == sku.trim().toLowerCase(),
  );

  InventoryItem? findByBarcode(String barcode) {
    final normalized = barcode.trim();
    if (normalized.isEmpty) return null;
    for (final item in activeInventory) {
      if (item.barcode == normalized) return item;
    }
    return null;
  }

  bool isDuplicateBarcode(String barcode, {InventoryItem? except}) {
    final normalized = barcode.trim();
    return normalized.isNotEmpty &&
        inventory.any((item) => item != except && item.barcode == normalized);
  }

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
    String batchNumber = '',
    DateTime? expiresOn,
  }) {
    if (quantity <= 0) return;
    final previous = item.quantity;
    item.quantity = previous + quantity;
    if (batchNumber.trim().isNotEmpty && expiresOn != null) {
      if (item.batches.isEmpty && previous > 0) {
        item.batches.add(
          InventoryBatch(
            batchNumber: item.batchNumber.isEmpty
                ? 'LEGACY-${item.id}'
                : item.batchNumber,
            quantity: previous,
            expiresOn: item.expiresOn,
          ),
        );
      }
      final normalizedBatch = batchNumber.trim();
      final existing = item.batches.where(
        (batch) =>
            batch.batchNumber.toLowerCase() == normalizedBatch.toLowerCase(),
      );
      if (existing.isEmpty) {
        item.batches.add(
          InventoryBatch(
            batchNumber: normalizedBatch,
            quantity: quantity,
            expiresOn: expiresOn,
            receivedOn: DateTime.now(),
          ),
        );
      } else {
        existing.first.quantity += quantity;
      }
      item.batchNumber = normalizedBatch;
      item.expiresOn = expiresOn;
    }
    _record(
      item,
      type: 'Stock In',
      quantity: quantity,
      previous: previous,
      next: item.quantity,
      reason: reason,
      reference: reference,
      batchNumber: batchNumber.trim(),
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
    if (item.batches.isNotEmpty && quantity > item.availableUnexpiredQuantity) {
      return false;
    }
    final previous = item.quantity;
    final usedBatches = <String>[];
    var remaining = quantity;
    final eligible =
        item.batches
            .where((batch) => !batch.isExpired && batch.quantity > 0)
            .toList()
          ..sort((a, b) => a.expiresOn.compareTo(b.expiresOn));
    for (final batch in eligible) {
      if (remaining == 0) break;
      final used = remaining < batch.quantity ? remaining : batch.quantity;
      batch.quantity -= used;
      remaining -= used;
      usedBatches.add('${batch.batchNumber}:$used');
    }
    item.quantity = previous - quantity;
    _record(
      item,
      type: 'Stock Out',
      quantity: quantity,
      previous: previous,
      next: item.quantity,
      reason: reason,
      reference: reference,
      batchNumber: usedBatches.join(', '),
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

  void deleteItem(InventoryItem item) {
    inventory.remove(item);
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
    String batchNumber = '',
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
        batchNumber: batchNumber,
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
    if (source != null &&
        (status == null ||
            !const {
              'Checked In',
              'Called',
              'Arrived',
              'In Consultation',
              'Completed',
              'Missed',
              'Cancelled',
            }.contains(status))) {
      AppointmentStore.instance.databaseChanged();
    }
    notifyListeners();
    _notifyOwner(
      item,
      status: status,
      doctor: doctor,
      rescheduled: date != null,
    );
  }

  void recordConfirmationCall(
    StaffAppointment item,
    AppointmentConfirmationCall call,
  ) {
    item.confirmationCalls.add(call);
    if (item.source != null) AppointmentStore.instance.databaseChanged();
    notifyListeners();
  }

  /// Sends the pet owner a notification reflecting a staff change so the owner
  /// sees clinic-side updates to their booking.
  void _notifyOwner(
    StaffAppointment item, {
    String? status,
    String? doctor,
    bool rescheduled = false,
  }) {
    if (DatabaseSync.instance.active &&
        status != null &&
        const {
          'Checked In',
          'Called',
          'Arrived',
          'In Consultation',
          'Completed',
          'Missed',
          'Cancelled',
        }.contains(status)) {
      return;
    }
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
    final dailyWalkInCount = _demo
        .where(
          (item) =>
              item.id.startsWith('WALK-') &&
              DateUtils.isSameDay(item.date, timestamp),
        )
        .length;
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
        queueNumber: 'W${(dailyWalkInCount + 1).toString().padLeft(3, '0')}',
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
    'confirmationCalls': confirmationCalls
        .map((value) => value.toDb())
        .toList(),
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
      confirmationCalls: (data['confirmationCalls'] as List? ?? const [])
          .map(
            (value) => AppointmentConfirmationCall.fromDb(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(),
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
    List<AppointmentConfirmationCall>? confirmationCalls,
  }) : confirmationCalls = confirmationCalls ?? [];

  factory StaffAppointment.fromBooking(BookedAppointment value) {
    final queue = QueueStore.instance.existingEntryFor(value);
    final queueStatus = queue == null
        ? value.status
        : switch (queue.status) {
            QueueStatus.waiting => 'Waiting',
            QueueStatus.called => 'Called',
            QueueStatus.arrived => 'Arrived',
            QueueStatus.inConsultation => 'In Consultation',
            QueueStatus.completed => 'Completed',
            QueueStatus.missed => 'Missed',
            QueueStatus.cancelled => 'Cancelled',
          };
    return StaffAppointment(
      id: value.id,
      pet: value.pet.name,
      owner: value.ownerName,
      phone: value.ownerPhone,
      service: value.service.name,
      doctor: value.veterinarian,
      date: value.date,
      time: value.time,
      reason: value.reason,
      status: queueStatus,
      priority: queue?.priority == 'urgent' ? 'Urgent' : 'Normal',
      source: value,
      queueNumber: queue?.queueNumber ?? '',
      confirmationCalls: value.confirmationCalls,
    );
  }

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
  final List<AppointmentConfirmationCall> confirmationCalls;

  DateTime? get startsAt {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
    ).firstMatch(time.trim().toUpperCase());
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    hour = hour % 12 + (match.group(3) == 'PM' ? 12 : 0);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool confirmationCallDue({DateTime? now}) {
    final current = now ?? DateTime.now();
    final start = startsAt;
    if (start == null ||
        !DateUtils.isSameDay(start, current) ||
        !const {'Pending', 'Confirmed'}.contains(status)) {
      return false;
    }
    final resolved = confirmationCalls.any(
      (call) => const {
        AppointmentCallOutcome.confirmed,
        AppointmentCallOutcome.runningLate,
        AppointmentCallOutcome.cannotCome,
      }.contains(call.outcome),
    );
    if (resolved) return false;
    if (confirmationCalls.isNotEmpty) {
      final latest = confirmationCalls.last;
      if (latest.retryAt case final retryAt? when retryAt.isAfter(current)) {
        return false;
      }
    }
    final untilStart = start.difference(current);
    return untilStart <= const Duration(minutes: 30) &&
        untilStart > const Duration(hours: -2);
  }

  bool confirmationCallOverdue({DateTime? now}) =>
      confirmationCallDue(now: now) &&
      startsAt!.isBefore(now ?? DateTime.now());

  QueueServiceGroup get queueServiceGroup =>
      queueServiceGroupForName(service, walkIn: id.startsWith('WALK-'));
}

class PaymentAuditEvent {
  const PaymentAuditEvent({
    required this.id,
    required this.at,
    required this.actorId,
    required this.actorRole,
    required this.action,
    required this.fromStatus,
    required this.toStatus,
    required this.details,
  });

  factory PaymentAuditEvent.fromDb(Map<String, dynamic> data) =>
      PaymentAuditEvent(
        id: data['id'] as String? ?? '',
        at: DateTime.tryParse(data['at'] as String? ?? '') ?? DateTime(1970),
        actorId: data['actorId'] as String? ?? 'unknown',
        actorRole: data['actorRole'] as String? ?? 'unknown',
        action: data['action'] as String? ?? 'payment.updated',
        fromStatus: data['fromStatus'] as String? ?? '',
        toStatus: data['toStatus'] as String? ?? '',
        details: Map<String, dynamic>.from(
          data['details'] as Map? ?? const <String, dynamic>{},
        ),
      );

  Map<String, dynamic> toDb() => {
    'id': id,
    'at': at.toIso8601String(),
    'actorId': actorId,
    'actorRole': actorRole,
    'action': action,
    'fromStatus': fromStatus,
    'toStatus': toStatus,
    'details': details,
  };

  final String id;
  final DateTime at;
  final String actorId;
  final String actorRole;
  final String action;
  final String fromStatus;
  final String toStatus;
  final Map<String, dynamic> details;
}

class MmqrPaymentDetails {
  const MmqrPaymentDetails({
    required this.reference,
    required this.amount,
    required this.currency,
    required this.status,
    required this.qrPayload,
    required this.createdAt,
    required this.expiresAt,
    this.settledAt,
    this.providerTransactionId = '',
  });

  factory MmqrPaymentDetails.fromDb(
    Map<String, dynamic> data,
  ) => MmqrPaymentDetails(
    reference: data['reference'] as String? ?? '',
    amount: (data['amount'] as num?)?.toInt() ?? 0,
    currency: data['currency'] as String? ?? 'MMK',
    status: data['status'] as String? ?? 'Pending',
    qrPayload: data['qrPayload'] as String? ?? '',
    createdAt:
        DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime(1970),
    expiresAt:
        DateTime.tryParse(data['expiresAt'] as String? ?? '') ?? DateTime(1970),
    settledAt: DateTime.tryParse(data['settledAt'] as String? ?? ''),
    providerTransactionId: data['providerTransactionId'] as String? ?? '',
  );

  Map<String, dynamic> toDb() => {
    'reference': reference,
    'amount': amount,
    'currency': currency,
    'status': status,
    'qrPayload': qrPayload,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    if (settledAt != null) 'settledAt': settledAt!.toIso8601String(),
    if (providerTransactionId.isNotEmpty)
      'providerTransactionId': providerTransactionId,
  };

  final String reference;
  final int amount;
  final String currency;
  final String status;
  final String qrPayload;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? settledAt;
  final String providerTransactionId;
}

class StaffPayment {
  Map<String, dynamic> toDb() => {
    'id': id,
    'owner': owner,
    'pet': pet,
    'amount': amount,
    'status': status,
    if (paymentMethod.isNotEmpty) 'paymentMethod': paymentMethod,
    if (paidAt != null) 'paidAt': paidAt!.toIso8601String(),
    if (mmqr != null) 'mmqr': mmqr!.toDb(),
    'auditTrail': auditTrail.map((event) => event.toDb()).toList(),
    if (settlement.isNotEmpty) 'settlement': settlement,
  };
  static StaffPayment fromDb(Map<String, dynamic> data) {
    final value = StaffPayment(
      id: data['id'] as String,
      owner: data['owner'] as String,
      pet: data['pet'] as String,
      amount: (data['amount'] as num).toInt(),
      status: data['status'] as String,
      paymentMethod: data['paymentMethod'] as String? ?? '',
      paidAt: DateTime.tryParse(data['paidAt'] as String? ?? ''),
      mmqr: data['mmqr'] is Map
          ? MmqrPaymentDetails.fromDb(
              Map<String, dynamic>.from(data['mmqr'] as Map),
            )
          : null,
      auditTrail: (data['auditTrail'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (event) =>
                PaymentAuditEvent.fromDb(Map<String, dynamic>.from(event)),
          )
          .toList(),
      settlement: Map<String, dynamic>.from(
        data['settlement'] as Map? ?? const <String, dynamic>{},
      ),
    );
    return value;
  }

  StaffPayment({
    required this.id,
    required this.owner,
    required this.pet,
    required this.amount,
    required this.status,
    this.paymentMethod = '',
    this.paidAt,
    this.mmqr,
    List<PaymentAuditEvent>? auditTrail,
    Map<String, dynamic>? settlement,
  }) : auditTrail = auditTrail ?? [],
       settlement = settlement ?? {};
  final String id;
  final String owner;
  final String pet;
  final int amount;
  String status;
  final String paymentMethod;
  final DateTime? paidAt;
  final MmqrPaymentDetails? mmqr;
  final List<PaymentAuditEvent> auditTrail;
  final Map<String, dynamic> settlement;

  bool get hasPendingMmqr => status == 'Pending' && mmqr?.status == 'Pending';
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
    'batchNumber': batchNumber,
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
      reference: data['reference'] as String? ?? '',
      batchNumber: data['batchNumber'] as String? ?? '',
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
    this.batchNumber = '',
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
  final String batchNumber;
}

class InventoryBatch {
  InventoryBatch({
    required this.batchNumber,
    required this.quantity,
    required this.expiresOn,
    this.receivedOn,
  });

  factory InventoryBatch.fromDb(Map<String, dynamic> data) => InventoryBatch(
    batchNumber: data['batchNumber'] as String? ?? '',
    quantity: data['quantity'] as int? ?? 0,
    expiresOn: DateTime.parse(data['expiresOn'] as String),
    receivedOn: data['receivedOn'] == null
        ? null
        : DateTime.parse(data['receivedOn'] as String),
  );

  Map<String, dynamic> toDb() => {
    'batchNumber': batchNumber,
    'quantity': quantity,
    'expiresOn': expiresOn.toIso8601String(),
    'receivedOn': receivedOn?.toIso8601String(),
  };

  final String batchNumber;
  int quantity;
  final DateTime expiresOn;
  final DateTime? receivedOn;

  bool get isExpired => expiresOn.isBefore(DateTime.now());
  bool get isNearExpiry =>
      !isExpired &&
      expiresOn.isBefore(DateTime.now().add(const Duration(days: 90)));
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
    'barcode': barcode,
    'batches': batches.map((batch) => batch.toDb()).toList(),
    'imageAsset': imageAsset,
    'productImages': productImages,
    'subcategory': subcategory,
    'petType': petType,
    'brand': brand,
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
      category: _normalizeInventoryCategory(data['category'] as String),
      quantity: data['quantity'] as int,
      reorderLevel: data['reorderLevel'] as int,
      unit: data['unit'] as String,
      expiresOn: DateTime.parse(data['expiresOn'] as String),
      sellingPrice: data['sellingPrice'] as int,
      purchasePrice: data['purchasePrice'] as int,
      supplier: data['supplier'] as String,
      batchNumber: data['batchNumber'] as String,
      barcode: data['barcode'] as String? ?? '',
      batches:
          (data['batches'] as List?)
              ?.map(
                (value) => InventoryBatch.fromDb(
                  Map<String, dynamic>.from(value as Map),
                ),
              )
              .toList() ??
          const [],
      imageAsset: data['imageAsset'] == null
          ? null
          : data['imageAsset'] as String,
      productImages:
          (data['productImages'] as List?)
              ?.whereType<String>()
              .where((value) => value.isNotEmpty)
              .toList() ??
          const [],
      subcategory: data['subcategory'] as String? ?? '',
      petType: data['petType'] as String? ?? 'All Pets',
      brand: data['brand'] as String? ?? data['supplier'] as String? ?? '',
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
    this.barcode = '',
    List<InventoryBatch> batches = const [],
    this.imageAsset,
    this.productImages = const [],
    this.subcategory = '',
    this.petType = 'All Pets',
    this.brand = '',
    this.description = '',
  }) : batches = List<InventoryBatch>.of(batches);

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
  String barcode;
  List<InventoryBatch> batches;
  String? imageAsset;
  List<String> productImages;
  String subcategory;
  String petType;
  String brand;
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
  bool get isExpired => batches.isNotEmpty
      ? batches
            .where((batch) => batch.quantity > 0)
            .every((batch) => batch.isExpired)
      : expiresOn.isBefore(DateTime.now());
  bool get isNearExpiry => batches.isNotEmpty
      ? batches.any((batch) => batch.quantity > 0 && batch.isNearExpiry)
      : !isExpired &&
            expiresOn.isBefore(DateTime.now().add(const Duration(days: 90)));

  int get availableUnexpiredQuantity => batches.isEmpty
      ? (isExpired ? 0 : quantity)
      : batches
            .where((batch) => !batch.isExpired)
            .fold(0, (total, batch) => total + batch.quantity);

  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }
}

String _normalizeInventoryCategory(String category) {
  switch (category) {
    case 'Food':
    case 'Pet Food':
    case 'Treats':
      return 'Food';
    case 'Medicine':
    case 'Vaccines':
    case 'Medical Supplies':
      return 'Medicine';
    case 'Accessories':
    case 'Grooming':
    case 'Toys':
    case 'Cleaning Supplies':
    case 'Other':
      return 'Accessories';
    default:
      return 'Accessories';
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
