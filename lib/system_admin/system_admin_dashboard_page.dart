part of 'system_admin_portal.dart';

/// The real admin dashboard: system totals, pending approvals, alerts, and a
/// recent-activity timeline. Cards navigate to the related management page.
class _AdminDashboardTab extends StatelessWidget {
  const _AdminDashboardTab();

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppointmentStore.instance,
        QueueStore.instance,
        EmergencyRequestStore.instance,
        UserAccountStore.instance,
        DoctorVerificationStore.instance,
        StaffOperationsStore.instance,
        AuditLogStore.instance,
      ]),
      builder: (context, _) {
        final users = UserAccountStore.instance;
        final appointments = AppointmentStore.instance.appointments;
        final todayAppointments = appointments
            .where(
              (a) =>
                  DateUtils.isSameDay(a.date, DateTime.now()) &&
                  a.status != 'Cancelled',
            )
            .length;
        final queueCount = QueueStore.instance.active.length;
        final emergencies = EmergencyRequestStore.instance.requests
            .where(
              (r) => !const {
                EmergencyStatus.completed,
                EmergencyStatus.declined,
              }.contains(r.status),
            )
            .length;

        final pendingDoctors = DoctorVerificationStore.instance.pendingCount;
        final pendingRequests = StaffOperationsStore.instance.inventory
            .where((item) => item.restockRequested)
            .length;

        final lowStock = StaffOperationsStore.instance.inventory
            .where((item) => item.isLowStock && !item.archived)
            .length;
        final expired = StaffOperationsStore.instance.inventory
            .where((item) => item.isExpired && !item.archived)
            .length;

        return ListView(
          key: const ValueKey('system-admin-dashboard'),
          padding: EdgeInsets.zero,
          children: [
            SafeArea(bottom: false, child: _AdminDashboardHeader()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('System Overview', style: _adminHeroStyle),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    children: [
                      _AdminSummaryCard(
                        icon: Icons.groups_rounded,
                        label: 'Total Users',
                        value: '${users.users.length}',
                        onTap: () => _open(context, const AdminUsersPage()),
                      ),
                      _AdminSummaryCard(
                        icon: Icons.medical_services_rounded,
                        label: 'Doctors',
                        value: '${users.countByRole(AdminUserRole.doctor)}',
                        onTap: () => _open(context, const AdminUsersPage()),
                      ),
                      _AdminSummaryCard(
                        icon: Icons.badge_rounded,
                        label: 'Staff',
                        value: '${users.countByRole(AdminUserRole.staff)}',
                        onTap: () => _open(context, const AdminUsersPage()),
                      ),
                      _AdminSummaryCard(
                        icon: Icons.pets_rounded,
                        label: 'Pet Owners',
                        value: '${users.countByRole(AdminUserRole.owner)}',
                        onTap: () => _open(context, const AdminUsersPage()),
                      ),
                      _AdminSummaryCard(
                        icon: Icons.event_available_rounded,
                        label: 'Today Appts',
                        value: '$todayAppointments',
                      ),
                      _AdminSummaryCard(
                        icon: Icons.groups_2_rounded,
                        label: 'In Queue',
                        value: '$queueCount',
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text('Pending Approvals', style: _adminHeroStyle),
                  const SizedBox(height: 14),
                  _AdminApprovalCard(
                    icon: Icons.verified_user_rounded,
                    title: 'Doctor Verifications',
                    count: pendingDoctors,
                    onTap: () => _open(context, const AdminVerificationPage()),
                  ),
                  const SizedBox(height: 12),
                  _AdminApprovalCard(
                    icon: Icons.inventory_2_rounded,
                    title: 'Inventory Requests',
                    count: pendingRequests,
                    onTap: () => _open(context, const AdminInventoryPage()),
                  ),
                  const SizedBox(height: 12),
                  _AdminApprovalCard(
                    icon: Icons.person_add_alt_1_rounded,
                    title: 'Pending Accounts',
                    count: users.pendingCount,
                    onTap: () => _open(
                      context,
                      const AdminUsersPage(
                        initialStatus: AdminAccountStatus.pending,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text('Alerts', style: _adminHeroStyle),
                  const SizedBox(height: 14),
                  if (emergencies == 0 && lowStock == 0 && expired == 0)
                    const _AdminAlertTile(
                      icon: Icons.check_circle_rounded,
                      color: _adminGreen,
                      title: 'All clear',
                      message: 'No active emergencies or stock alerts.',
                    )
                  else ...[
                    if (emergencies > 0) ...[
                      _AdminAlertTile(
                        icon: Icons.emergency_rounded,
                        color: const Color(0xFFB3261E),
                        title: 'Active emergencies',
                        message: '$emergencies case(s) need attention.',
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (lowStock > 0) ...[
                      _AdminAlertTile(
                        icon: Icons.trending_down_rounded,
                        color: const Color(0xFF9A5B00),
                        title: 'Low stock',
                        message: '$lowStock item(s) at or below reorder level.',
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (expired > 0)
                      _AdminAlertTile(
                        icon: Icons.event_busy_rounded,
                        color: const Color(0xFFB3261E),
                        title: 'Expired items',
                        message: '$expired item(s) past expiry date.',
                      ),
                  ],
                  const SizedBox(height: 26),
                  const Text('Recent Activity', style: _adminHeroStyle),
                  const SizedBox(height: 14),
                  ...AuditLogStore.instance.entries
                      .take(4)
                      .map((entry) => _AdminActivityRow(entry: entry)),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      onPressed: () => _open(context, const AdminAuditPage()),
                      child: const Text('View all activity'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminDashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      boxShadow: [
        BoxShadow(
          color: Color(0x30000000),
          blurRadius: 10,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Image.asset(
          'assets/photos/logoandphoto/nways_love_logo.png',
          width: 60,
          height: 60,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_greeting()}, Mr.Admin',
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _dashboardDate(DateTime.now()),
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AdminSummaryCard extends StatelessWidget {
  const _AdminSummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: _adminSoftMint,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _adminGreen, size: 26),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: _adminMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AdminApprovalCard extends StatelessWidget {
  const _AdminApprovalCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _adminBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _adminSoftMint,
              foregroundColor: _adminGreen,
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: count > 0 ? const Color(0xFFB3261E) : _adminMint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: count > 0 ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: _adminMuted),
          ],
        ),
      ),
    ),
  );
}

class _AdminActivityRow extends StatelessWidget {
  const _AdminActivityRow({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: _adminGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.action} • ${entry.record}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              Text(
                '${entry.module} • ${_auditTime(entry.timestamp)}',
                style: const TextStyle(color: _adminMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
