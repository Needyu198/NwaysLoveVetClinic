import 'package:flutter/material.dart';

import 'pet_add_reminder_page.dart' show ReminderType;
export 'pet_add_reminder_page.dart' show ReminderType;

/// A pet-care reminder, created either by the pet owner or by clinic staff.
class PetReminder {
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
  ReminderStore._() {
    _seed();
  }

  static final ReminderStore instance = ReminderStore._();

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
    add(reminder);
    return reminder;
  }

  void toggleCompleted(PetReminder reminder) {
    reminder.completed = !reminder.completed;
    notifyListeners();
  }

  void _seed() {
    _reminders.addAll([
      PetReminder(
        id: 'REM-SEED-1',
        title: 'Annual Rabies Vaccination',
        type: ReminderType.vaccine,
        dateTime: DateTime(2026, 4, 4, 10, 0),
        note: 'Bring previous vaccination records',
        petName: 'Max',
      ),
      PetReminder(
        id: 'REM-SEED-2',
        title: 'General Health Checkup',
        type: ReminderType.checkup,
        dateTime: DateTime(2026, 4, 15, 14, 30),
        note: 'Follow-up for grain-free diet assessment',
        petName: 'Max',
      ),
      PetReminder(
        id: 'REM-SEED-3',
        title: 'Bordetella Vaccine',
        type: ReminderType.vaccine,
        dateTime: DateTime(2026, 3, 2, 9, 0),
        note: 'Completed successfully',
        petName: 'Max',
        completed: true,
      ),
    ]);
  }

  @visibleForTesting
  void reset() {
    _reminders.clear();
    _seed();
    notifyListeners();
  }
}

/// A notification shown to the pet owner, typically raised by staff actions
/// (appointment confirmed/rescheduled/cancelled, doctor assigned, queue call).
class OwnerNotification {
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
  OwnerNotificationStore._();

  static final OwnerNotificationStore instance = OwnerNotificationStore._();

  final List<OwnerNotification> _items = [];

  List<OwnerNotification> get notifications =>
      List.unmodifiable(_items.reversed);
  int get unreadCount => _items.where((n) => !n.read).length;

  void push(String title, String message) {
    _items.add(
      OwnerNotification(
        id: 'NOTIF-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        message: message,
        createdAt: DateTime.now(),
      ),
    );
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
