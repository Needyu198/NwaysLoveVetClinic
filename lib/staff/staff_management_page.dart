part of 'staff_portal.dart';

class StaffManagementPage extends StatelessWidget {
  const StaffManagementPage({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        const _InlineHeader(
          title: 'Management',
          subtitle: 'Clinic operations and patient services',
        ),
        Expanded(
          child: GridView.count(
            key: const ValueKey('staff-management-menu'),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            crossAxisCount: 2,
            childAspectRatio: 1.08,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _ManagementCard(
                title: 'Appointments',
                subtitle: 'Confirm, assign and reschedule',
                icon: Icons.event_note_rounded,
                color: _mint,
                onTap: () => _push(
                  context,
                  const StaffAppointmentsPage(standalone: true),
                ),
              ),
              _ManagementCard(
                title: 'Queue',
                subtitle: 'Manage the live clinic queue',
                icon: Icons.format_list_numbered_rounded,
                color: const Color(0xFFFFE3A8),
                onTap: () => _push(context, const StaffQueueStandalonePage()),
              ),
              _ManagementCard(
                key: const ValueKey('staff-inventory-card'),
                title: 'Inventory',
                subtitle: 'Stock, alerts and restock requests',
                icon: Icons.inventory_2_rounded,
                color: const Color(0xFFE2D4FF),
                onTap: () => _push(context, const StaffInventoryPage()),
              ),
              _ManagementCard(
                title: 'Medical Records',
                subtitle: 'View finalized clinical records',
                icon: Icons.folder_shared_rounded,
                color: const Color(0xFFD8F3ED),
                onTap: () => _push(context, const StaffMedicalRecordsPage()),
              ),
              _ManagementCard(
                title: 'Emergency Cases',
                subtitle: 'Review and coordinate urgent care',
                icon: Icons.emergency_rounded,
                color: const Color(0xFFFFC7C9),
                onTap: () => _push(context, const StaffEmergencyPage()),
              ),
              _ManagementCard(
                title: 'Home Visits',
                subtitle: 'Verify and coordinate visits',
                icon: Icons.home_work_rounded,
                color: const Color(0xFFFFE8C7),
                onTap: () => _push(context, const StaffHomeVisitsPage()),
              ),
              _ManagementCard(
                title: 'Health Posts',
                subtitle: 'Review clinic education posts',
                icon: Icons.article_rounded,
                color: const Color(0xFFD6E8FF),
                onTap: () => _push(context, const StaffHealthPostsPage()),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _ink),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: _muted, height: 1.25),
            ),
          ],
        ),
      ),
    ),
  );
}
