part of 'staff_portal.dart';

class StaffProfilePage extends StatelessWidget {
  const StaffProfilePage({super.key});

  @override
  Widget build(BuildContext context) => _StaffScaffold(
    title: 'Staff Profile',
    child: AnimatedBuilder(
      animation: StaffProfileStore.instance,
      builder: (context, _) {
        final profile = StaffProfileStore.instance;
        return ListView(
          key: const ValueKey('staff-profile'),
          padding: const EdgeInsets.all(18),
          children: [
            Center(child: _StaffAvatar(photoPath: profile.photoPath)),
            const SizedBox(height: 12),
            Text(
              profile.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            Text(
              profile.role,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted),
            ),
            const SizedBox(height: 10),
            Center(child: _ShiftBadge(onShift: profile.onShift)),
            const SizedBox(height: 20),
            _InfoCard(
              rows: [
                ('Employee ID', profile.employeeId),
                ('Email', profile.email),
                ('Phone', profile.phone),
                ('Clinic', profile.clinic),
                ('Shift', profile.shift),
              ],
            ),
            const SizedBox(height: 14),
            _ProfileTile(
              icon: Icons.edit_outlined,
              title: 'Edit Profile',
              onTap: () => _push(context, const StaffEditProfilePage()),
            ),
            _ProfileTile(
              icon: Icons.notifications_outlined,
              title: 'Notification Settings',
              onTap: () =>
                  _push(context, const StaffNotificationSettingsPage()),
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
        );
      },
    ),
  );
}

class _StaffAvatar extends StatelessWidget {
  const _StaffAvatar({required this.photoPath});
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    return Container(
      width: 96,
      height: 96,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: _mint, shape: BoxShape.circle),
      child: path == null
          ? const Icon(Icons.person_rounded, size: 52, color: _ink)
          : (path.startsWith('assets/')
                ? Image.asset(path, fit: BoxFit.cover)
                : Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.person_rounded, size: 52, color: _ink),
                  )),
    );
  }
}

class _ShiftBadge extends StatelessWidget {
  const _ShiftBadge({required this.onShift});
  final bool onShift;

  @override
  Widget build(BuildContext context) {
    final color = onShift ? _green : _muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            onShift ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            onShift ? 'On shift' : 'Off shift',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
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

// ---------------------------------------------------------------------------
// Edit Profile
// ---------------------------------------------------------------------------

class StaffEditProfilePage extends StatefulWidget {
  const StaffEditProfilePage({super.key});

  @override
  State<StaffEditProfilePage> createState() => _StaffEditProfilePageState();
}

class _StaffEditProfilePageState extends State<StaffEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _profile = StaffProfileStore.instance;
  late final _name = TextEditingController(text: _profile.name);
  late final _phone = TextEditingController(text: _profile.phone);
  late final _email = TextEditingController(text: _profile.email);
  late String _shift = _shiftOptions.contains(_profile.shift)
      ? _profile.shift
      : _shiftOptions.first;
  late bool _onShift = _profile.onShift;
  late String? _photoPath = _profile.photoPath;
  bool _dirty = false;

  static const _shiftOptions = [
    'Morning • 8:00 AM–4:00 PM',
    'Afternoon • 12:00 PM–8:00 PM',
    'Night • 8:00 PM–4:00 AM',
  ];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
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
                leading: const Icon(Icons.delete_outline_rounded, color: _red),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: _red),
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
      if (mounted) _notice(context, 'Could not open the image picker.');
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _profile.save(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      shift: _shift,
      onShift: _onShift,
      photoPath: _photoPath,
    );
    Navigator.pop(context);
    _notice(context, 'Profile updated.');
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
            style: FilledButton.styleFrom(backgroundColor: _red),
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
      backgroundColor: _page,
      body: Column(
        children: [
          const _StaffMintHeader(
            title: 'Edit Profile',
            subtitle: 'Update your staff details',
            icon: Icons.badge_outlined,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              onChanged: _markDirty,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                children: [
                  Center(
                    child: _EditAvatar(
                      photoPath: _photoPath,
                      onTap: _pickPhoto,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _EditSectionLabel('Editable details'),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const ValueKey('staff-edit-name'),
                    controller: _name,
                    decoration: _input('Full name', Icons.person_outline),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('staff-edit-phone'),
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: _input('Phone number', Icons.phone_outlined),
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
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('staff-edit-email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _input('Email', Icons.mail_outline_rounded),
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
                  DropdownButtonFormField<String>(
                    initialValue: _shift,
                    isExpanded: true,
                    decoration: _input('Shift', Icons.schedule_rounded),
                    items: _shiftOptions
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _shift = v ?? _shift;
                      _markDirty();
                    }),
                  ),
                  const SizedBox(height: 6),
                  Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: const BorderSide(color: _border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SwitchListTile(
                      value: _onShift,
                      activeThumbColor: _green,
                      title: const Text('Currently on shift'),
                      subtitle: Text(
                        _onShift
                            ? 'You appear available to the clinic.'
                            : 'You appear off duty.',
                      ),
                      onChanged: (v) => setState(() {
                        _onShift = v;
                        _markDirty();
                      }),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _EditSectionLabel('Managed by administrator'),
                  const SizedBox(height: 10),
                  _InfoCard(
                    rows: [
                      ('Employee ID', _profile.employeeId),
                      ('Role', _profile.role),
                      ('Clinic', _profile.clinic),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Role, clinic, and employee ID require administrator approval to change.',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const ValueKey('save-staff-profile'),
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save Changes'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
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

class _EditSectionLabel extends StatelessWidget {
  const _EditSectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w900,
      color: _ink,
    ),
  );
}

class _EditAvatar extends StatelessWidget {
  const _EditAvatar({required this.photoPath, required this.onTap});
  final String? photoPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey('staff-edit-photo'),
    onTap: onTap,
    borderRadius: BorderRadius.circular(60),
    child: Stack(
      children: [
        Container(
          width: 112,
          height: 112,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(color: _mint, shape: BoxShape.circle),
          child: photoPath == null
              ? const Icon(Icons.person_rounded, size: 60, color: _ink)
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
                          Icons.person_rounded,
                          size: 60,
                          color: _ink,
                        ),
                      )),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: _green,
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
// Notification Settings
// ---------------------------------------------------------------------------

class StaffNotificationSettingsPage extends StatelessWidget {
  const StaffNotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _page,
    body: Column(
      children: [
        const _StaffMintHeader(
          title: 'Notification Settings',
          subtitle: 'Choose which alerts you receive',
          icon: Icons.notifications_outlined,
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: StaffProfileStore.instance,
            builder: (context, _) {
              final p = StaffProfileStore.instance;
              return ListView(
                key: const ValueKey('staff-notification-settings'),
                padding: const EdgeInsets.all(18),
                children: [
                  _NotifSwitch(
                    icon: Icons.event_available_outlined,
                    title: 'Appointment alerts',
                    subtitle: 'New, confirmed, and rescheduled bookings.',
                    value: p.appointmentAlerts,
                    onChanged: (v) => p.updateNotifications(appointment: v),
                  ),
                  _NotifSwitch(
                    icon: Icons.emergency_outlined,
                    title: 'Emergency alerts',
                    subtitle: 'Urgent cases that need immediate action.',
                    value: p.emergencyAlerts,
                    onChanged: (v) => p.updateNotifications(emergency: v),
                  ),
                  _NotifSwitch(
                    icon: Icons.groups_rounded,
                    title: 'Queue alerts',
                    subtitle: 'Live queue and walk-in updates.',
                    value: p.queueAlerts,
                    onChanged: (v) => p.updateNotifications(queue: v),
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

class _NotifSwitch extends StatelessWidget {
  const _NotifSwitch({
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
        side: const BorderSide(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: _green,
        secondary: Icon(icon, color: _green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
      ),
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
    try {
      await DatabaseSync.instance.stop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginPage.routeName, (_) => false);
  }
}
