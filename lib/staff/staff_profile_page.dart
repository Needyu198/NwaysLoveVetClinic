part of 'staff_portal.dart';

class StaffProfilePage extends StatelessWidget {
  const StaffProfilePage({super.key});
  @override
  Widget build(BuildContext context) => _StaffScaffold(
    title: 'Staff Profile',
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const CircleAvatar(
          radius: 44,
          backgroundColor: _mint,
          child: Icon(Icons.person_rounded, size: 48, color: _ink),
        ),
        const SizedBox(height: 12),
        const Text(
          'Mya Thu',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
        ),
        const Text(
          'Clinic Operations Staff',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted),
        ),
        const SizedBox(height: 20),
        const _InfoCard(
          rows: [
            ('Employee ID', 'STF-018'),
            ('Email', 'staff@nwaysclinic.com'),
            ('Phone', '09 781 220 118'),
            ('Clinic', "Nway's Love Vet Clinic"),
            ('Shift', 'Morning • 8:00 AM–4:00 PM'),
          ],
        ),
        const SizedBox(height: 14),
        _ProfileTile(
          icon: Icons.edit_outlined,
          title: 'Edit Profile',
          onTap: () => _showInfo(
            context,
            'Edit Profile',
            'Name and phone number can be updated. Role, clinic, and employee ID require administrator approval.',
          ),
        ),
        _ProfileTile(
          icon: Icons.notifications_outlined,
          title: 'Notification Settings',
          onTap: () => _showInfo(
            context,
            'Notification Settings',
            'Appointment, emergency, queue, and payment alerts are enabled.',
          ),
        ),
        _ProfileTile(
          icon: Icons.help_outline_rounded,
          title: 'Help & Support',
          onTap: () => _showInfo(
            context,
            'Help & Support',
            'Contact the clinic administrator for account or operational assistance.',
          ),
        ),
        _ProfileTile(
          icon: Icons.logout_rounded,
          title: 'Log Out',
          color: _red,
          onTap: () => _logout(context),
        ),
      ],
    ),
  );
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = _ink,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

Future<void> _logout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('End the staff session on this device?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm-staff-logout'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Yes, Log Out'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginPage.routeName, (_) => false);
  }
}
