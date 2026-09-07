part of 'system_admin_portal.dart';

/// The admin profile screen (§12). Reactive to [AdminProfileStore] and wires
/// every tile to a real, working page.
class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({required this.onLogout, super.key});

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
          child: AnimatedBuilder(
            animation: AdminProfileStore.instance,
            builder: (context, _) {
              final profile = AdminProfileStore.instance;
              return ListView(
                key: const ValueKey('system-admin-account'),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                children: [
                  Center(child: _AdminAvatar(photoPath: profile.photoPath)),
                  const SizedBox(height: 12),
                  Text(
                    profile.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    profile.role,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _adminMuted),
                  ),
                  const SizedBox(height: 20),
                  _AdminInfoCard(
                    rows: [
                      ('Admin ID', profile.adminId),
                      ('Email', profile.email),
                      ('Phone', profile.phone),
                      ('Role', profile.role),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Account', style: _adminHeroStyle),
                  const SizedBox(height: 12),
                  _AdminProfileTile(
                    icon: Icons.edit_rounded,
                    title: 'Edit profile',
                    subtitle: 'Update name, email, phone and photo',
                    keyValue: 'admin-edit-profile',
                    onTap: () => _push(context, const AdminEditProfilePage()),
                  ),
                  _AdminProfileTile(
                    icon: Icons.password_rounded,
                    title: 'Change password',
                    subtitle: 'Update your sign-in password',
                    keyValue: 'admin-change-password',
                    onTap: () =>
                        _push(context, const AdminChangePasswordPage()),
                  ),
                  _AdminProfileTile(
                    icon: Icons.shield_rounded,
                    title: 'Security',
                    subtitle: 'Two-factor and active sessions',
                    trailingText: profile.twoFactorEnabled ? 'On' : 'Off',
                    keyValue: 'admin-security',
                    onTap: () => _push(context, const AdminSecurityPage()),
                  ),
                  _AdminProfileTile(
                    icon: Icons.notifications_rounded,
                    title: 'Notification settings',
                    subtitle: 'Choose which alerts you receive',
                    keyValue: 'admin-notifications',
                    onTap: () =>
                        _push(context, const AdminNotificationSettingsPage()),
                  ),
                  _AdminProfileTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    subtitle: 'Account and system assistance',
                    onTap: () => _adminShowInfo(
                      context,
                      'Help & Support',
                      'Contact PawCare technical support for account, access, '
                          'or system configuration assistance.',
                    ),
                  ),
                  const SizedBox(height: 8),
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
              );
            },
          ),
        ),
      ],
    );
  }

  static void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar({required this.photoPath});
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    return Container(
      width: 100,
      height: 100,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: _adminMint,
        shape: BoxShape.circle,
      ),
      child: path == null
          ? const Icon(
              Icons.admin_panel_settings_rounded,
              size: 54,
              color: _adminGreen,
            )
          : (path.startsWith('assets/')
                ? Image.asset(path, fit: BoxFit.cover)
                : Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 54,
                      color: _adminGreen,
                    ),
                  )),
    );
  }
}

class _AdminProfileTile extends StatelessWidget {
  const _AdminProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingText,
    this.keyValue,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailingText;
  final String? keyValue;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      key: keyValue == null ? null : ValueKey<String>(keyValue!),
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

// ---------------------------------------------------------------------------
// Edit Profile
// ---------------------------------------------------------------------------

class AdminEditProfilePage extends StatefulWidget {
  const AdminEditProfilePage({super.key});

  @override
  State<AdminEditProfilePage> createState() => _AdminEditProfilePageState();
}

class _AdminEditProfilePageState extends State<AdminEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _profile = AdminProfileStore.instance;
  late final _name = TextEditingController(text: _profile.name);
  late final _email = TextEditingController(text: _profile.email);
  late final _phone = TextEditingController(text: _profile.phone);
  late String? _photoPath = _profile.photoPath;
  bool _dirty = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _markDirty() => _dirty = true;

  Future<void> _pickPhoto() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop('gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop('camera'),
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFB3261E),
                ),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: Color(0xFFB3261E)),
                ),
                onTap: () => Navigator.of(sheetContext).pop('remove'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'remove') {
      setState(() {
        _photoPath = null;
        _markDirty();
      });
      return;
    }
    try {
      final picked = await ImagePicker().pickImage(
        source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82,
      );
      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();
        if (bytes.length > 2 * 1024 * 1024) throw Exception('Photo too large');
        if (!mounted) return;
        setState(() {
          _photoPath = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          _markDirty();
        });
      }
    } on Exception {
      if (mounted) _adminNotice(context, 'Could not open the image picker.');
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _profile.save(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      photoPath: _photoPath,
    );
    Navigator.pop(context);
    _adminNotice(context, 'Profile updated.');
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      if (await _confirmDiscard() && context.mounted) Navigator.pop(context);
    },
    child: Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const _AdminPageHeader(
            title: 'Edit Profile',
            subtitle: 'Update your admin details',
            icon: Icons.edit_rounded,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              onChanged: _markDirty,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [
                  Center(
                    child: _AdminEditAvatar(
                      photoPath: _photoPath,
                      onTap: _pickPhoto,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const ValueKey('admin-edit-name'),
                    controller: _name,
                    decoration: _adminInput('Full name', Icons.person_outline),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('admin-edit-email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _adminInput(
                      'Email',
                      Icons.mail_outline_rounded,
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Email is required';
                      if (!RegExp(
                        r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
                      ).hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('admin-edit-phone'),
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: _adminInput('Phone', Icons.phone_outlined),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Phone is required';
                      final digits = value.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 7 || digits.length > 15) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _adminSoftMint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: _adminGreen,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Role and Admin ID (${_profile.adminId}) are fixed '
                            'and cannot be self-edited.',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    key: const ValueKey('save-admin-profile'),
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save Changes'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _adminGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AdminEditAvatar extends StatelessWidget {
  const _AdminEditAvatar({required this.photoPath, required this.onTap});
  final String? photoPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey('admin-edit-photo'),
    onTap: onTap,
    borderRadius: BorderRadius.circular(60),
    child: Stack(
      children: [
        Container(
          width: 112,
          height: 112,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: _adminMint,
            shape: BoxShape.circle,
          ),
          child: photoPath == null
              ? const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 60,
                  color: _adminGreen,
                )
              : (photoPath!.startsWith('assets/')
                    ? Image.asset(photoPath!, fit: BoxFit.cover)
                    : photoPath!.startsWith('data:image/')
                    ? Image.memory(
                        base64Decode(photoPath!.split(',').last),
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(photoPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 60,
                          color: _adminGreen,
                        ),
                      )),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: _adminGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Change Password
// ---------------------------------------------------------------------------

class AdminChangePasswordPage extends StatefulWidget {
  const AdminChangePasswordPage({super.key});

  @override
  State<AdminChangePasswordPage> createState() =>
      _AdminChangePasswordPageState();
}

class _AdminChangePasswordPageState extends State<AdminChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final ok = AdminProfileStore.instance.changePassword(
      _current.text,
      _next.text,
    );
    if (!ok) {
      _adminNotice(context, 'Current password is incorrect.');
      return;
    }
    Navigator.pop(context);
    _adminNotice(context, 'Password changed.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        _AdminPageHeader(
          title: 'Change Password',
          subtitle: 'Update your sign-in password',
          icon: Icons.password_rounded,
          trailing: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
            ),
          ),
        ),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: [
                TextFormField(
                  key: const ValueKey('admin-current-password'),
                  controller: _current,
                  obscureText: _obscure,
                  decoration: _adminInput(
                    'Current password',
                    Icons.lock_outline,
                  ),
                  validator: (v) =>
                      (v ?? '').isEmpty ? 'Enter your current password' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('admin-new-password'),
                  controller: _next,
                  obscureText: _obscure,
                  decoration: _adminInput(
                    'New password',
                    Icons.lock_reset_rounded,
                  ),
                  validator: (v) =>
                      (v ?? '').length < 6 ? 'Use at least 6 characters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('admin-confirm-password'),
                  controller: _confirm,
                  obscureText: _obscure,
                  decoration: _adminInput(
                    'Confirm new password',
                    Icons.lock_rounded,
                  ),
                  validator: (v) =>
                      v != _next.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  key: const ValueKey('submit-admin-password'),
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Update Password'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _adminGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Security (two-factor + active sessions)
// ---------------------------------------------------------------------------

class AdminSecurityPage extends StatelessWidget {
  const AdminSecurityPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const _AdminPageHeader(
          title: 'Security',
          subtitle: 'Two-factor and active sessions',
          icon: Icons.shield_rounded,
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: AdminProfileStore.instance,
            builder: (context, _) {
              final profile = AdminProfileStore.instance;
              return ListView(
                key: const ValueKey('admin-security'),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [
                  Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: _adminBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SwitchListTile(
                      key: const ValueKey('admin-2fa-switch'),
                      value: profile.twoFactorEnabled,
                      activeThumbColor: _adminGreen,
                      secondary: const Icon(
                        Icons.verified_user_rounded,
                        color: _adminGreen,
                      ),
                      title: const Text(
                        'Two-factor authentication',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        profile.twoFactorEnabled
                            ? 'A verification code is required at sign-in.'
                            : 'Add a second step to secure your account.',
                      ),
                      onChanged: profile.setTwoFactor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Active sessions', style: _adminHeroStyle),
                  const SizedBox(height: 12),
                  for (final session in profile.sessions)
                    _AdminSessionTile(session: session),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('admin-signout-all'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB3261E),
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: Color(0xFFB3261E)),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => _signOutAll(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out from all other devices'),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );

  Future<void> _signOutAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out everywhere?'),
        content: const Text('This ends every session except this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    AuditLogStore.instance.record(
      action: 'Signed out other devices',
      module: 'Admin Profile',
      record:
          '${AdminProfileStore.instance.name} '
          '(${AdminProfileStore.instance.adminId})',
      newValue: 'Other sessions ended',
      reason: 'Security action',
    );
    _adminNotice(context, 'Signed out from other devices.');
  }
}

class _AdminSessionTile extends StatelessWidget {
  const _AdminSessionTile({required this.session});

  final AdminSession session;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _adminBorder),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: _adminSoftMint,
          foregroundColor: _adminGreen,
          child: Icon(
            session.current ? Icons.verified_rounded : Icons.devices_rounded,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.device,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                '${session.location} • ${session.lastActive}',
                style: const TextStyle(color: _adminMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (session.current)
          const _AdminStatusBadge(label: 'This device', color: _adminGreen),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Notification Settings
// ---------------------------------------------------------------------------

class AdminNotificationSettingsPage extends StatelessWidget {
  const AdminNotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const _AdminPageHeader(
          title: 'Notification Settings',
          subtitle: 'Choose which alerts you receive',
          icon: Icons.notifications_rounded,
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: AdminProfileStore.instance,
            builder: (context, _) {
              final p = AdminProfileStore.instance;
              return ListView(
                key: const ValueKey('admin-notification-settings'),
                padding: const EdgeInsets.all(20),
                children: [
                  _AdminNotifSwitch(
                    icon: Icons.approval_rounded,
                    title: 'Approval alerts',
                    subtitle: 'Doctor verifications and inventory requests.',
                    value: p.approvalAlerts,
                    onChanged: (v) => p.updateNotifications(approvals: v),
                  ),
                  _AdminNotifSwitch(
                    icon: Icons.emergency_rounded,
                    title: 'Emergency alerts',
                    subtitle: 'Urgent cases across the clinic.',
                    value: p.emergencyAlerts,
                    onChanged: (v) => p.updateNotifications(emergency: v),
                  ),
                  _AdminNotifSwitch(
                    icon: Icons.settings_suggest_rounded,
                    title: 'System alerts',
                    subtitle: 'Low stock, expiry and license warnings.',
                    value: p.systemAlerts,
                    onChanged: (v) => p.updateNotifications(system: v),
                  ),
                  _AdminNotifSwitch(
                    icon: Icons.insights_rounded,
                    title: 'Report summaries',
                    subtitle: 'Periodic analytics and activity digests.',
                    value: p.reportAlerts,
                    onChanged: (v) => p.updateNotifications(report: v),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _AdminNotifSwitch extends StatelessWidget {
  const _AdminNotifSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _adminBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: _adminGreen,
        secondary: Icon(icon, color: _adminGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
      ),
    ),
  );
}
