part of 'system_admin_portal.dart';

/// Users and Roles management. Lists every account with search + role/status
/// filters, and opens a detail page with activate/suspend/role-change actions.
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({this.initialStatus, super.key});

  /// When opened from a dashboard card, pre-filter by this status.
  final AdminAccountStatus? initialStatus;

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _search = TextEditingController();
  AdminUserRole? _roleFilter;
  AdminAccountStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatus;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AdminUser> _filtered() {
    final query = _search.text.trim().toLowerCase();
    return UserAccountStore.instance.users.where((user) {
      if (_roleFilter != null && user.role != _roleFilter) return false;
      if (_statusFilter != null && user.status != _statusFilter) return false;
      if (query.isEmpty) return true;
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.phone.toLowerCase().contains(query) ||
          user.id.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _AdminPageHeader(
            title: 'Users and Roles',
            subtitle: 'Manage every account in the system',
            icon: Icons.groups_rounded,
            trailing: IconButton(
              key: const ValueKey('admin-add-user'),
              tooltip: 'Add user',
              onPressed: _openAddUser,
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: UserAccountStore.instance,
              builder: (context, _) {
                final users = _filtered();
                return ListView(
                  key: const ValueKey('admin-users-list'),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                  children: [
                    TextField(
                      key: const ValueKey('admin-users-search'),
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search name, email, phone or ID',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: _adminSoftMint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _rolesRow(),
                    const SizedBox(height: 10),
                    _statusRow(),
                    const SizedBox(height: 18),
                    if (users.isEmpty)
                      const _AdminEmptyState(
                        icon: Icons.person_search_rounded,
                        title: 'No matching users',
                        message: 'Adjust your search or filters.',
                      )
                    else
                      for (final user in users) ...[
                        _AdminUserCard(
                          user: user,
                          onTap: () => _openDetail(user),
                        ),
                        const SizedBox(height: 12),
                      ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _rolesRow() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _AdminFilterChip(
          label: 'All roles',
          selected: _roleFilter == null,
          onTap: () => setState(() => _roleFilter = null),
        ),
        for (final role in AdminUserRole.values) ...[
          const SizedBox(width: 8),
          _AdminFilterChip(
            label: role.label,
            selected: _roleFilter == role,
            onTap: () => setState(() => _roleFilter = role),
          ),
        ],
      ],
    ),
  );

  Widget _statusRow() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _AdminFilterChip(
          label: 'Any status',
          selected: _statusFilter == null,
          onTap: () => setState(() => _statusFilter = null),
        ),
        for (final status in AdminAccountStatus.values) ...[
          const SizedBox(width: 8),
          _AdminFilterChip(
            label: status.label,
            selected: _statusFilter == status,
            onTap: () => setState(() => _statusFilter = status),
          ),
        ],
      ],
    ),
  );

  void _openDetail(AdminUser user) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => AdminUserDetailPage(user: user)));

  void _openAddUser() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AdminAddUserPage()));
}

class _AdminUserCard extends StatelessWidget {
  const _AdminUserCard({required this.user, required this.onTap});

  final AdminUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
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
              child: Icon(user.role.icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${user.role.label} • ${user.id}',
                    style: const TextStyle(color: _adminMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _AdminStatusBadge(
              label: user.status.label,
              color: user.status.color,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Detail page for a single account with lifecycle actions.
class AdminUserDetailPage extends StatelessWidget {
  const AdminUserDetailPage({required this.user, super.key});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: UserAccountStore.instance,
        builder: (context, _) {
          return Column(
            children: [
              _AdminPageHeader(
                title: user.name,
                subtitle: user.role.label,
                icon: user.role.icon,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                  children: [
                    Center(
                      child: _AdminStatusBadge(
                        label: 'Account ${user.status.label}',
                        color: user.status.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AdminInfoCard(
                      rows: [
                        ('User ID', user.id),
                        ('Email', user.email),
                        ('Phone', user.phone),
                        ('Role', user.role.label),
                        ('Last active', user.lastActive),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text('Account actions', style: _adminHeroStyle),
                    const SizedBox(height: 12),
                    if (user.status != AdminAccountStatus.active)
                      _AdminActionButton(
                        icon: Icons.check_circle_rounded,
                        label: user.status == AdminAccountStatus.pending
                            ? 'Activate account'
                            : 'Reactivate account',
                        color: _adminGreen,
                        onTap: () {
                          UserAccountStore.instance.activate(user);
                          _adminNotice(context, '${user.name} is now active.');
                        },
                      ),
                    if (user.status != AdminAccountStatus.suspended)
                      _AdminActionButton(
                        icon: Icons.block_rounded,
                        label: 'Suspend account',
                        color: const Color(0xFFB3261E),
                        onTap: () async {
                          final reason = await _adminReasonDialog(
                            context,
                            title: 'Suspend ${user.name}?',
                            actionLabel: 'Suspend',
                            actionColor: const Color(0xFFB3261E),
                          );
                          if (reason == null || !context.mounted) return;
                          UserAccountStore.instance.suspend(user, reason);
                          _adminNotice(context, '${user.name} suspended.');
                        },
                      ),
                    _AdminActionButton(
                      icon: Icons.delete_forever_rounded,
                      label: 'Delete account',
                      color: const Color(0xFFB3261E),
                      onTap: () => _deleteAccount(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final reason = await _adminReasonDialog(
      context,
      title: 'Delete ${user.name}?',
      actionLabel: 'Delete account',
      actionColor: const Color(0xFFB3261E),
    );
    if (reason == null || !context.mounted) return;
    final navigator = Navigator.of(context);
    UserAccountStore.instance.deleteUser(user, reason);
    _adminNotice(context, '${user.name} deleted.');
    // The account no longer exists; return to the users list.
    navigator.maybePop();
  }
}

/// Form to create a new account.
class AdminAddUserPage extends StatefulWidget {
  const AdminAddUserPage({super.key});

  @override
  State<AdminAddUserPage> createState() => _AdminAddUserPageState();
}

class _AdminAddUserPageState extends State<AdminAddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  AdminUserRole _role = AdminUserRole.owner;

  // Admins provision Pet Owner, Doctor, and Staff accounts here. Administrator
  // accounts are intentionally not creatable from this screen.
  static const _assignableRoles = [
    AdminUserRole.owner,
    AdminUserRole.doctor,
    AdminUserRole.staff,
  ];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const _AdminPageHeader(
            title: 'Add User',
            subtitle: 'Create a new account',
            icon: Icons.person_add_alt_1_rounded,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                children: [
                  _field(
                    controller: _name,
                    label: 'Full name',
                    icon: Icons.person_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _email,
                    label: 'Email',
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Email is required';
                      final ok = RegExp(
                        r'^[\w.\-]+@[\w\-]+\.[\w.\-]+$',
                      ).hasMatch(value);
                      return ok ? null : 'Enter a valid email';
                    },
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _phone,
                    label: 'Phone',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().length < 6)
                        ? 'Enter a valid phone number'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _password,
                    label: 'Password',
                    icon: Icons.lock_rounded,
                    obscureText: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Password must be at least 8 characters'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _confirmPassword,
                    label: 'Confirm password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureConfirm,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) =>
                        (v != _password.text) ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Role',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AdminUserRole>(
                    initialValue: _role,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _adminSoftMint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      for (final role in _assignableRoles)
                        DropdownMenuItem(value: role, child: Text(role.label)),
                    ],
                    onChanged: (value) =>
                        setState(() => _role = value ?? _role),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _adminSoftMint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: _adminGreen),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'New accounts start as Pending. Activate the '
                            'account to allow sign-in.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    key: const ValueKey('admin-save-user'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _adminGreen,
                      minimumSize: const Size.fromHeight(52),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _save,
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    validator: validator,
    obscureText: obscureText,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: _adminSoftMint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    UserAccountStore.instance.addUser(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      role: _role,
      password: _password.text,
    );
    _adminNotice(
      context,
      'Account created as Pending. Activate it to allow sign-in with the '
      'email and password.',
    );
    Navigator.of(context).pop();
  }
}

class _AdminActionButton extends StatelessWidget {
  const _AdminActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    ),
  );
}
