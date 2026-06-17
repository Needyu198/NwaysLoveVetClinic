import 'package:flutter/material.dart';

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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _ReminderHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 36),
              sliver: SliverList.list(
                children: const [
                  _ReminderSummary(),
                  SizedBox(height: 20),
                  _ReminderSectionLabel(title: 'Upcoming'),
                  SizedBox(height: 12),
                  _ReminderCard(
                    icon: Icons.vaccines_rounded,
                    iconColor: Color(0xFF1F63FF),
                    title: 'Annual Rabies Vaccination',
                    date: 'Apr 04, 2026',
                    time: '10:00 AM',
                    category: 'Vaccine',
                    categoryIcon: Icons.vaccines_rounded,
                    note: 'Bring previous vaccination records',
                  ),
                  SizedBox(height: 16),
                  _ReminderCard(
                    icon: Icons.medical_services_rounded,
                    iconColor: Color(0xFFB23CFF),
                    title: 'General Health Checkup',
                    date: 'Apr 15, 2026',
                    time: '2:30 PM',
                    category: 'Check-up',
                    categoryIcon: Icons.local_hospital_rounded,
                    note: 'Follow-up for grain-free diet assessment',
                  ),
                  SizedBox(height: 22),
                  _ReminderSectionLabel(title: 'Completed'),
                  SizedBox(height: 12),
                  _ReminderCard(
                    icon: Icons.vaccines_rounded,
                    iconColor: Color(0xFF69AEF4),
                    title: 'Bordetella Vaccine',
                    date: 'Mar 02, 2026',
                    time: '9:00 AM',
                    category: 'Vaccine',
                    categoryIcon: Icons.vaccines_rounded,
                    note: 'Completed successfully',
                    isCompleted: true,
                  ),
                  SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
  const _ReminderSummary();

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
      child: const Row(
        children: [
          _SummaryTile(
            icon: Icons.notifications_active_rounded,
            label: 'Upcoming',
            value: '2',
            color: Color(0xFF16785B),
          ),
          SizedBox(width: 12),
          _SummaryTile(
            icon: Icons.check_circle_rounded,
            label: 'Completed',
            value: '1',
            color: Color(0xFF69717F),
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
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String date;
  final String time;
  final String category;
  final IconData categoryIcon;
  final String note;
  final bool isCompleted;

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
          _CompleteButton(isCompleted: isCompleted),
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
  const _CompleteButton({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: () {},
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
