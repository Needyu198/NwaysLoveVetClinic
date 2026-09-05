part of 'system_admin_portal.dart';

class _AdminAccountTab extends StatelessWidget {
  const _AdminAccountTab({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminSimpleHeader(
          title: 'Account',
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
              const _AdminInfoCard(
                rows: [
                  ('Role', 'System Administrator'),
                  ('Account', 'admin@nwaysclinic.com'),
                  ('Access', 'Clinic configuration and oversight'),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _adminSoftMint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security_rounded, color: _adminGreen),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This page is available only after a registered system administrator account is authenticated.',
                      ),
                    ),
                  ],
                ),
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
}
