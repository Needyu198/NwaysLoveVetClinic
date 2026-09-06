part of 'system_admin_portal.dart';

/// The Management tab is a menu that routes into each admin capability.
class _AdminManagementTab extends StatelessWidget {
  const _AdminManagementTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _AdminSimpleHeader(title: 'Management'),
        Expanded(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              UserAccountStore.instance,
              DoctorVerificationStore.instance,
              StaffOperationsStore.instance,
            ]),
            builder: (context, _) {
              final pendingUsers = UserAccountStore.instance.pendingCount;
              final pendingDoctors =
                  DoctorVerificationStore.instance.pendingCount;
              final pendingRequests = StaffOperationsStore.instance.inventory
                  .where((item) => item.restockRequested)
                  .length;
              return ListView(
                key: const ValueKey('system-admin-management'),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                children: [
                  _AdminMenuTile(
                    icon: Icons.groups_rounded,
                    title: 'Users and Roles',
                    subtitle: 'Accounts, roles and status',
                    badge: pendingUsers,
                    keyValue: 'admin-menu-users',
                    onTap: () => _open(context, const AdminUsersPage()),
                  ),
                  _AdminMenuTile(
                    icon: Icons.verified_user_rounded,
                    title: 'Doctor Verification',
                    subtitle: 'Review applications and licenses',
                    badge: pendingDoctors,
                    keyValue: 'admin-menu-verification',
                    onTap: () => _open(context, const AdminVerificationPage()),
                  ),
                  _AdminMenuTile(
                    icon: Icons.inventory_2_rounded,
                    title: 'Inventory Approval',
                    subtitle: 'Restock and adjustment requests',
                    badge: pendingRequests,
                    keyValue: 'admin-menu-inventory',
                    onTap: () => _open(context, const AdminInventoryPage()),
                  ),
                  _AdminMenuTile(
                    icon: Icons.receipt_long_rounded,
                    title: 'Audit Logs',
                    subtitle: 'Sensitive actions and changes',
                    keyValue: 'admin-menu-audit',
                    onTap: () => _open(context, const AdminAuditPage()),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class _AdminMenuTile extends StatelessWidget {
  const _AdminMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.keyValue,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String keyValue;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Material(
      key: ValueKey(keyValue),
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _adminBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _adminSoftMint,
                foregroundColor: _adminGreen,
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _adminMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (badge > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB3261E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right_rounded, color: _adminMuted),
            ],
          ),
        ),
      ),
    ),
  );
}
