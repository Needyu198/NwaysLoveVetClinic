import '../data/database_sync.dart';
import 'package:flutter/material.dart';

import 'pet_add_reminder_page.dart' show ReminderType;
export 'pet_add_reminder_page.dart' show ReminderType;

/// A pet-care reminder, created either by the pet owner or by clinic staff.
class PetReminder {
  Map<String, dynamic> toDb() => {
    'id': id,
    'title': title,
    'type': type.name,
    'dateTime': dateTime.toIso8601String(),
    'note': note,
    'petName': petName,
    'createdByStaff': createdByStaff,
    'completed': completed,
  };
  static PetReminder fromDb(Map<String, dynamic> data) {
    final value = PetReminder(
      id: data['id'] as String,
      title: data['title'] as String,
      type: ReminderType.values.byName(data['type'] as String),
      dateTime: DateTime.parse(data['dateTime'] as String),
      note: data['note'] as String,
      petName: data['petName'] == null ? null : data['petName'] as String,
      createdByStaff: data['createdByStaff'] as bool,
      completed: data['completed'] as bool,
    );
    return value;
  }

  PetReminder({
    required this.id,
    required this.title,
    required this.type,
    required this.dateTime,
    this.note = '',
    this.petName,
    this.createdByStaff = false,
    this.completed = false,
  });

  final String id;
  final String title;
  final ReminderType type;
  final DateTime dateTime;
  final String note;
  final String? petName;
  final bool createdByStaff;
  bool completed;
}

/// Shared reminder store used by both the pet-owner reminder screens and the
/// staff side (staff can schedule follow-up reminders for an owner).
class ReminderStore extends ChangeNotifier {
  void connectDatabase() {
    DatabaseSync.instance.bind(
      'reminders',
      this,
      () => {
        for (final item in _reminders)
          databaseRecordKey(item, item.id): item.toDb(),
      },
      (rows) {
        _reminders
          ..clear()
          ..addAll(
            rows.entries.map(
              (e) => databaseRestoreKey(PetReminder.fromDb(e.value), e.key),
            ),
          );
      },
    );
  }

  ReminderStore._();

  static final ReminderStore instance = ReminderStore._();

  // Reminders come entirely from the database (what the owner or staff adds).
  // No seeded/demo reminders.
  final List<PetReminder> _reminders = [];

  List<PetReminder> get reminders => List.unmodifiable(_reminders);
  List<PetReminder> get upcoming =>
      _reminders.where((r) => !r.completed).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  List<PetReminder> get completed =>
      _reminders.where((r) => r.completed).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  void add(PetReminder reminder) {
    _reminders.add(reminder);
    notifyListeners();
  }

  PetReminder addNew({
    required String title,
    required ReminderType type,
    required DateTime dateTime,
    String note = '',
    String? petName,
    bool createdByStaff = false,
    String? ownerId,
  }) {
    final reminder = PetReminder(
      id: 'REM-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      type: type,
      dateTime: dateTime,
      note: note,
      petName: petName,
      createdByStaff: createdByStaff,
    );
    databaseAssignOwner(reminder, reminder.id, ownerId);
    add(reminder);
    return reminder;
  }

  void toggleCompleted(PetReminder reminder) {
    reminder.completed = !reminder.completed;
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _reminders.clear();
    notifyListeners();
  }
}

/// A notification shown to the pet owner, typically raised by staff actions
/// (appointment confirmed/rescheduled/cancelled, doctor assigned, queue call).
class OwnerNotification {
  Map<String, dynamic> toDb() => {
    'id': id,
    'title': title,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
  };
  static OwnerNotification fromDb(Map<String, dynamic> data) {
    final value = OwnerNotification(
      id: data['id'] as String,
      title: data['title'] as String,
      message: data['message'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      read: data['read'] as bool,
    );
    return value;
  }

  OwnerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  bool read;
}

/// Shared owner-facing notification feed. Staff actions push into it; the pet
/// owner reads it from their notifications screen.
class OwnerNotificationStore extends ChangeNotifier {
  void connectDatabase() {
    DatabaseSync.instance.bind(
      'owner_notifications',
      this,
      () => {
        for (final item in _items)
          databaseRecordKey(item, item.id): item.toDb(),
      },
      (rows) {
        _items
          ..clear()
          ..addAll(
            rows.entries.map(
              (e) =>
                  databaseRestoreKey(OwnerNotification.fromDb(e.value), e.key),
            ),
          );
      },
    );
  }

  OwnerNotificationStore._();

  static final OwnerNotificationStore instance = OwnerNotificationStore._();

  final List<OwnerNotification> _items = [];

  List<OwnerNotification> get notifications =>
      List.unmodifiable(_items.reversed);
  int get unreadCount => _items.where((n) => !n.read).length;

  void push(String title, String message, {String? ownerId}) {
    final notification = OwnerNotification(
      id: 'NOTIF-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      message: message,
      createdAt: DateTime.now(),
    );
    _items.add(databaseAssignOwner(notification, notification.id, ownerId));
    notifyListeners();
  }

  void markAllRead() {
    var changed = false;
    for (final item in _items) {
      if (!item.read) {
        item.read = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  @visibleForTesting
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
