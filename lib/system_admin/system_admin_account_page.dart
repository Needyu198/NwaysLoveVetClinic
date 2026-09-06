part of 'system_admin_portal.dart';

class _AdminAccountTab extends StatelessWidget {
  const _AdminAccountTab({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminSimpleHeader(
          title: 'Profile',
          trailing: IconButton(
            key: const ValueKey('system-admin-logout'),
            tooltip: 'Log Out',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ),
        Expanded(
          child: ListView(
            key: const ValueKey('system-admin-account'),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            children: [
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: _adminSoftMint,
                      foregroundColor: _adminGreen,
                      child: Icon(Icons.admin_panel_settings_rounded, size: 44),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mr. Admin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'System Administrator',
                      style: TextStyle(color: _adminMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _AdminInfoCard(
                rows: [
                  ('Name', 'Mr. Admin'),
                  ('Email', 'admin@nwaysclinic.com'),
                  ('Phone', '09 400 000 001'),
                  ('Role', 'System Administrator'),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Account', style: _adminHeroStyle),
              const SizedBox(height: 12),
              _AdminProfileTile(
                icon: Icons.edit_rounded,
                title: 'Edit profile',
                subtitle: 'Update name, email and phone',
                onTap: () => _comingSoon(context, 'Edit profile'),
              ),
              _AdminProfileTile(
                icon: Icons.password_rounded,
                title: 'Change password',
                subtitle: 'Update your sign-in password',
                onTap: () => _comingSoon(context, 'Change password'),
              ),
              _AdminProfileTile(
                icon: Icons.shield_rounded,
                title: 'Security',
                subtitle: 'Two-factor authentication',
                trailingText: 'Off',
                onTap: () => _comingSoon(context, 'Two-factor authentication'),
              ),
              _AdminProfileTile(
                icon: Icons.devices_rounded,
                title: 'Active sessions',
                subtitle: 'This device • signed in now',
                onTap: () => _comingSoon(context, 'Active sessions'),
              ),
              _AdminProfileTile(
                icon: Icons.notifications_rounded,
                title: 'Notification settings',
                subtitle: 'Alert preferences',
                onTap: () => _comingSoon(context, 'Notification settings'),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const ValueKey('system-admin-account-logout'),
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log Out'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF1017),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _comingSoon(BuildContext context, String label) =>
      _adminNotice(context, '$label is coming soon.');
}

class _AdminProfileTile extends StatelessWidget {
  const _AdminProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _adminBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _adminSoftMint,
                foregroundColor: _adminGreen,
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _adminMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: const TextStyle(
                    color: _adminMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: _adminMuted),
            ],
          ),
        ),
      ),
    ),
  );
}
