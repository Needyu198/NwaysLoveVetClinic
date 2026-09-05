import 'package:flutter/material.dart';

import 'owner_shared_stores.dart';
import 'pet_add_reminder_page.dart';
import 'pet_reminder_styles.dart';

class PetReminderPage extends StatelessWidget {
  const PetReminderPage({super.key});

  static const String routeName = '/pet-reminder';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: ReminderStore.instance,
          builder: (context, _) {
            final upcoming = ReminderStore.instance.upcoming;
            final completed = ReminderStore.instance.completed;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _ReminderHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 36),
                  sliver: SliverList.list(
                    key: const ValueKey('owner-reminder-list'),
                    children: [
                      _ReminderSummary(
                        upcomingCount: upcoming.length,
                        completedCount: completed.length,
                      ),
                      const SizedBox(height: 20),
                      const _ReminderSectionLabel(title: 'Upcoming'),
                      const SizedBox(height: 12),
                      if (upcoming.isEmpty)
                        const _ReminderEmpty(text: 'No upcoming reminders')
                      else
                        for (final reminder in upcoming) ...[
                          _ReminderCard.fromModel(reminder),
                          const SizedBox(height: 16),
                        ],
                      const SizedBox(height: 8),
                      const _ReminderSectionLabel(title: 'Completed'),
                      const SizedBox(height: 12),
                      if (completed.isEmpty)
                        const _ReminderEmpty(text: 'No completed reminders')
                      else
                        for (final reminder in completed) ...[
                          _ReminderCard.fromModel(reminder),
                          const SizedBox(height: 16),
                        ],
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReminderEmpty extends StatelessWidget {
  const _ReminderEmpty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2F4EC)),
    ),
    child: Row(
      children: [
        const Icon(Icons.event_note_rounded, color: Color(0xFF69717F)),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Color(0xFF69717F))),
      ],
    ),
  );
}

String _reminderDate(DateTime value) {
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
  final day = value.day.toString().padLeft(2, '0');
  return '${months[value.month - 1]} $day, ${value.year}';
}

String _reminderTime(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

class _ReminderHeader extends StatelessWidget {
  const _ReminderHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reminder', style: ReminderStyles.pageTitle),
                SizedBox(height: 2),
                Text(
                  'Pet care tasks and visits',
                  style: ReminderStyles.pageSubtitle,
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(PetAddReminderPage.routeName);
            },
            icon: const Icon(Icons.add_rounded, size: 22),
            label: const Text('Add'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF69717F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderSummary extends StatelessWidget {
  const _ReminderSummary({
    required this.upcomingCount,
    required this.completedCount,
  });

  final int upcomingCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2F4EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100B2F25),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          _SummaryTile(
            icon: Icons.notifications_active_rounded,
            label: 'Upcoming',
            value: '$upcomingCount',
            color: const Color(0xFF16785B),
          ),
          const SizedBox(width: 12),
          _SummaryTile(
            icon: Icons.check_circle_rounded,
            label: 'Completed',
            value: '$completedCount',
            color: const Color(0xFF69717F),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: ReminderStyles.summaryLabel),
                  const SizedBox(height: 2),
                  Text(value, style: ReminderStyles.summaryValue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderSectionLabel extends StatelessWidget {
  const _ReminderSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: ReminderStyles.sectionLabel);
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.date,
    required this.time,
    required this.category,
    required this.categoryIcon,
    required this.note,
    this.isCompleted = false,
    this.reminder,
  });

  factory _ReminderCard.fromModel(PetReminder reminder) {
    final (iconColor, category, categoryIcon) = switch (reminder.type) {
      ReminderType.vaccine => (
        const Color(0xFF1F63FF),
        'Vaccine',
        Icons.vaccines_rounded,
      ),
      ReminderType.medicine => (
        const Color(0xFF6B7280),
        'Medicine',
        Icons.medication_rounded,
      ),
      ReminderType.checkup => (
        const Color(0xFFB23CFF),
        'Check-up',
        Icons.local_hospital_rounded,
      ),
    };
    return _ReminderCard(
      icon: reminder.type.icon,
      iconColor: reminder.completed
          ? iconColor.withValues(alpha: 0.6)
          : iconColor,
      title: reminder.title,
      date: _reminderDate(reminder.dateTime),
      time: _reminderTime(reminder.dateTime),
      category: category,
      categoryIcon: categoryIcon,
      note: reminder.note.isEmpty
          ? (reminder.createdByStaff
                ? 'Scheduled by clinic staff'
                : 'No additional notes')
          : reminder.note,
      isCompleted: reminder.completed,
      reminder: reminder,
    );
  }

  final IconData icon;
  final Color iconColor;
  final String title;
  final String date;
  final String time;
  final String category;
  final IconData categoryIcon;
  final String note;
  final bool isCompleted;
  final PetReminder? reminder;

  @override
  Widget build(BuildContext context) {
    final foreground = isCompleted
        ? const Color(0xFF667B75)
        : const Color(0xFF1D2736);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFC2FBE3),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C0B2F25),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? iconColor.withValues(alpha: 0.72)
                      : iconColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: ReminderStyles.cardTitle.copyWith(
                              color: foreground,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationThickness: 2,
                            ),
                          ),
                        ),
                        if (isCompleted) ...[
                          const SizedBox(width: 8),
                          const _DoneBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    _CategoryPill(icon: categoryIcon, label: category),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetaPill(
                  icon: Icons.calendar_month_rounded,
                  label: date,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetaPill(icon: Icons.schedule_rounded, label: time),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _NoteBox(note: note, isCompleted: isCompleted),
          const SizedBox(height: 16),
          _CompleteButton(isCompleted: isCompleted, reminder: reminder),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF667085), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ReminderStyles.meta,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isCheckup = label.toLowerCase().contains('check');
    final color = isCheckup ? const Color(0xFF8700E8) : const Color(0xFF0D55FF);
    final background = isCheckup
        ? const Color(0xFFF0D9FF)
        : const Color(0xFFDDEBFF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Text(label, style: ReminderStyles.category.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({required this.note, required this.isCompleted});

  final String note;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.white.withValues(alpha: 0.72)
            : const Color(0xFFF3F7FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC9DBFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.edit_note_rounded,
            color: Color(0xFF667085),
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(note, style: ReminderStyles.note)),
        ],
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({required this.isCompleted, this.reminder});

  final bool isCompleted;
  final PetReminder? reminder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: reminder == null
            ? null
            : () => ReminderStore.instance.toggleCompleted(reminder!),
        icon: const Icon(Icons.check_circle_outline_rounded, size: 22),
        label: Text(isCompleted ? 'Mark Incomplete' : 'Complete'),
        style: FilledButton.styleFrom(
          backgroundColor: isCompleted
              ? const Color(0xFFF6F7F9)
              : const Color(0xFF06C957),
          foregroundColor: isCompleted ? const Color(0xFF344054) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Colors.black, size: 22),
        ),
      ),
    );
  }
}

class _DoneBadge extends StatelessWidget {
  const _DoneBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text('Done', style: ReminderStyles.done),
    );
  }
}
