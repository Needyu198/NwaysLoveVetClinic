part of 'doctor_portal.dart';

/// Reactive store around [DoctorProfileData] that loads from and persists to
/// Firebase via [DoctorProfileRepository]. Falls back to in-memory defaults
/// when Firebase is unavailable so the UI keeps working.
class DoctorProfileStore extends ChangeNotifier {
  DoctorProfileStore._() {
    _load();
  }

  static final instance = DoctorProfileStore._();

  final _repository = DoctorProfileRepository.instance;

  DoctorProfileData _data = const DoctorProfileData();
  bool _loading = true;
  bool _syncedWithFirebase = false;

  DoctorProfileData get data => _data;
  bool get isLoading => _loading;
  bool get isSyncedWithFirebase => _syncedWithFirebase;

  Future<void> _load() async {
    final loaded = await _repository.load();
    if (loaded != null) {
      _data = loaded;
      _syncedWithFirebase = true;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> reload() async {
    _loading = true;
    notifyListeners();
    await _load();
  }

  /// Applies a change locally (immediately) then persists in the background.
  Future<bool> _apply(DoctorProfileData next) async {
    _data = next;
    notifyListeners();
    final saved = await _repository.save(next);
    _syncedWithFirebase = saved;
    notifyListeners();
    return saved;
  }

  Future<bool> saveProfile({
    required String name,
    required String specialty,
    required String biography,
    required String phone,
    required String email,
    required String experience,
  }) => _apply(
    _data.copyWith(
      name: name,
      specialty: specialty,
      biography: biography,
      phone: phone,
      email: email,
      experience: experience,
    ),
  );

  Future<bool> saveCredentials({
    required List<String> qualifications,
    required List<String> certifications,
    required List<String> expertise,
    required List<String> languages,
    required String license,
    DateTime? licenseExpiry,
  }) => _apply(
    _data.copyWith(
      qualifications: qualifications,
      certifications: certifications,
      expertise: expertise,
      languages: languages,
      license: license,
      licenseExpiry: licenseExpiry,
      clearLicenseExpiry: licenseExpiry == null,
    ),
  );

  Future<bool> saveSchedule({
    required Map<DoctorWeekday, DaySchedule> schedule,
    required List<DateTime> leaveDates,
    required bool acceptingAppointments,
  }) => _apply(
    _data.copyWith(
      schedule: schedule,
      leaveDates: leaveDates,
      acceptingAppointments: acceptingAppointments,
    ),
  );

  Future<bool> setPhotoUrl(String? url) =>
      _apply(_data.copyWith(photoUrl: url, clearPhoto: url == null));

  Future<bool> setAvailability(bool value) =>
      _apply(_data.copyWith(acceptingAppointments: value));

  Future<bool> setNotifications(bool value) =>
      _apply(_data.copyWith(notificationsEnabled: value));

  Future<bool> updateNotificationSettings({
    bool? notificationsEnabled,
    bool? appointmentReminders,
    bool? emergencyAlerts,
    bool? marketingEmails,
  }) => _apply(
    _data.copyWith(
      notificationsEnabled: notificationsEnabled,
      appointmentReminders: appointmentReminders,
      emergencyAlerts: emergencyAlerts,
      marketingEmails: marketingEmails,
    ),
  );

  Future<bool> setTwoFactor(bool value) =>
      _apply(_data.copyWith(twoFactorEnabled: value));
}

class DoctorProfilePage extends StatelessWidget {
  const DoctorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DoctorProfileStore.instance,
      builder: (context, _) {
        final store = DoctorProfileStore.instance;
        final profile = store.data;
        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _DoctorProfileHeader(),
              Expanded(
                child: ListView(
                  key: const ValueKey('doctor-profile'),
                  padding: const EdgeInsets.fromLTRB(28, 14, 28, 30),
                  children: [
                    if (store.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 14),
                        child: LinearProgressIndicator(minHeight: 3),
                      ),
                    _DoctorProfileHero(profile: profile),
                    const SizedBox(height: 18),
                    _ProfileCompletenessCard(profile: profile),
                    const SizedBox(height: 18),
                    _DoctorCredentialsCard(profile: profile),
                    const SizedBox(height: 18),
                    _DoctorAvailabilitySummaryCard(profile: profile),
                    const SizedBox(height: 22),
                    _DoctorAccountSettingsCard(
                      profile: profile,
                      onLogout: () => _logout(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will return to the clinic login page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-doctor-logout'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log Out'),
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
}

class _DoctorProfileHeader extends StatelessWidget {
  const _DoctorProfileHeader();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: 116,
    padding: const EdgeInsets.fromLTRB(34, 8, 20, 12),
    alignment: Alignment.centerLeft,
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      boxShadow: [
        BoxShadow(
          color: Color(0x38000000),
          blurRadius: 6,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Image.asset(
      'assets/photos/logoandphoto/nways_love_logo.png',
      width: 92,
      height: 92,
      fit: BoxFit.contain,
    ),
  );
}

class _DoctorProfileHero extends StatelessWidget {
  const _DoctorProfileHero({required this.profile});

  final DoctorProfileData profile;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
    decoration: BoxDecoration(
      color: DoctorStyles.mint,
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 7,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            _DoctorAvatar(
              key: const ValueKey('doctor-profile-photo'),
              photoUrl: profile.photoUrl,
              onTap: () => _handlePhotoTap(context),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    profile.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.phone,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _DoctorProfilePill(label: profile.specialty),
        const SizedBox(height: 12),
        _DoctorProfilePill(label: 'VET License : ${profile.license}'),
        const SizedBox(height: 12),
        _AvailabilityStatusPill(accepting: profile.acceptingAppointments),
      ],
    ),
  );

  Future<void> _handlePhotoTap(BuildContext context) async {
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(_PhotoAction.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(_PhotoAction.camera),
            ),
            if (profile.photoUrl != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFB3261E),
                ),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: Color(0xFFB3261E)),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_PhotoAction.remove),
              ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    final store = DoctorProfileStore.instance;
    if (action == _PhotoAction.remove) {
      await store.setPhotoUrl(null);
      return;
    }

    final source = action == _PhotoAction.gallery
        ? ImageSource.gallery
        : ImageSource.camera;
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82,
      );
    } on Exception {
      picked = null;
    }
    if (picked == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Uploading photo...')));
    final url = await store._repository.uploadPhoto(picked.path);
    if (url == null) {
      // Firebase unreachable: keep the local file path so the user still sees
      // their selection this session.
      await store.setPhotoUrl(picked.path);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Photo set locally. Will sync when online.'),
        ),
      );
      return;
    }
    await store.setPhotoUrl(url);
    messenger.showSnackBar(
      const SnackBar(content: Text('Profile photo updated.')),
    );
  }
}

enum _PhotoAction { gallery, camera, remove }

class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({required this.photoUrl, required this.onTap, super.key});

  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(58),
      child: Stack(
        children: [
          Container(
            width: 112,
            height: 112,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: _buildImage(),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: DoctorStyles.green,
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

  Widget _buildImage() {
    final url = photoUrl;
    if (url == null) return _fallback();
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _fallback(),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _fallback(),
      );
    }
    return Image.file(
      File(url),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => _fallback(),
    );
  }

  Widget _fallback() =>
      const Icon(Icons.person_rounded, size: 68, color: Color(0xFF789A93));
}

class _DoctorProfilePill extends StatelessWidget {
  const _DoctorProfilePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 46),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _AvailabilityStatusPill extends StatelessWidget {
  const _AvailabilityStatusPill({required this.accepting});

  final bool accepting;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 46),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            accepting ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
            size: 20,
            color: accepting ? DoctorStyles.green : const Color(0xFF9A5B00),
          ),
          const SizedBox(width: 8),
          Text(
            accepting ? 'Accepting bookings' : 'Not accepting bookings',
            style: TextStyle(
              color: accepting ? DoctorStyles.green : const Color(0xFF9A5B00),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfileCompletenessCard extends StatelessWidget {
  const _ProfileCompletenessCard({required this.profile});

  final DoctorProfileData profile;

  @override
  Widget build(BuildContext context) {
    final percent = (profile.completeness * 100).round();
    final complete = percent >= 100;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DoctorStyles.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                complete ? Icons.verified_rounded : Icons.donut_large_rounded,
                color: DoctorStyles.green,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Profile completeness',
                  style: DoctorStyles.cardTitle,
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: DoctorStyles.green,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: profile.completeness,
              minHeight: 9,
              backgroundColor: const Color(0xFFE3EEE9),
              color: DoctorStyles.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            complete
                ? 'Your profile is complete and ready for pet owners.'
                : 'Add a photo, credentials, and availability to reach 100%.',
            style: DoctorStyles.muted,
          ),
        ],
      ),
    );
  }
}

class _DoctorCredentialsCard extends StatelessWidget {
  const _DoctorCredentialsCard({required this.profile});

  final DoctorProfileData profile;

  @override
  Widget build(BuildContext context) {
    return _DoctorProfileSection(
      title: 'Professional Credentials',
      icon: Icons.workspace_premium_outlined,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VerificationBadge(status: profile.verification),
            const SizedBox(height: 14),
            _CredentialGroup(
              icon: Icons.school_outlined,
              label: 'Qualifications',
              values: profile.qualifications,
            ),
            _CredentialGroup(
              icon: Icons.badge_outlined,
              label: 'Certifications',
              values: profile.certifications,
            ),
            _CredentialGroup(
              icon: Icons.star_outline_rounded,
              label: 'Areas of expertise',
              values: profile.expertise,
            ),
            _CredentialGroup(
              icon: Icons.translate_rounded,
              label: 'Languages',
              values: profile.languages,
            ),
            _CredentialRow(
              icon: Icons.event_busy_outlined,
              label: 'License expiry',
              value: profile.licenseExpiry == null
                  ? 'Not set'
                  : _fullDate(profile.licenseExpiry!),
              warning: _expiringSoon(profile.licenseExpiry),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('edit-doctor-credentials'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EditDoctorCredentialsPage(),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit credentials'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DoctorStyles.green,
                  side: const BorderSide(color: DoctorStyles.green),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _expiringSoon(DateTime? date) {
    if (date == null) return false;
    return date.isBefore(DateTime.now().add(const Duration(days: 60)));
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.status});

  final CredentialVerification status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      CredentialVerification.verified => (
        DoctorStyles.green,
        Icons.verified_rounded,
      ),
      CredentialVerification.pending => (
        const Color(0xFF9A5B00),
        Icons.hourglass_bottom_rounded,
      ),
      CredentialVerification.unverified => (
        const Color(0xFFB3261E),
        Icons.error_outline_rounded,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            status.label,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CredentialGroup extends StatelessWidget {
  const _CredentialGroup({
    required this.icon,
    required this.label,
    required this.values,
  });

  final IconData icon;
  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: DoctorStyles.green),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: DoctorStyles.muted),
              const SizedBox(height: 4),
              if (values.isEmpty)
                const Text('Not added', style: DoctorStyles.cardValue)
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final value in values)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: DoctorStyles.softMint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(value, style: DoctorStyles.cardValue),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.icon,
    required this.label,
    required this.value,
    this.warning = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        icon,
        size: 20,
        color: warning ? const Color(0xFFB3261E) : DoctorStyles.green,
      ),
      const SizedBox(width: 10),
      Text('$label: ', style: DoctorStyles.muted),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            color: warning ? const Color(0xFFB3261E) : DoctorStyles.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _DoctorAvailabilitySummaryCard extends StatelessWidget {
  const _DoctorAvailabilitySummaryCard({required this.profile});

  final DoctorProfileData profile;

  @override
  Widget build(BuildContext context) {
    return _DoctorProfileSection(
      title: 'Availability & Shifts',
      icon: Icons.calendar_month_outlined,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final day in profile.orderedSchedule) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 46,
                    child: Text(
                      day.day.shortLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      day.summary,
                      style: TextStyle(
                        color: day.isWorking
                            ? DoctorStyles.ink
                            : const Color(0xFF9AA8A2),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontStyle: day.isWorking
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            if (profile.leaveDates.isNotEmpty) ...[
              const Divider(height: 20),
              const Text('Upcoming leave', style: DoctorStyles.muted),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final date in profile.leaveDates)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _leaveChipDate(date),
                        style: const TextStyle(
                          color: Color(0xFFB3261E),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('edit-doctor-availability'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EditDoctorAvailabilityPage(),
                  ),
                ),
                icon: const Icon(Icons.schedule_rounded, size: 18),
                label: const Text('Edit availability'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DoctorStyles.green,
                  side: const BorderSide(color: DoctorStyles.green),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _leaveChipDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

class _DoctorAccountSettingsCard extends StatelessWidget {
  const _DoctorAccountSettingsCard({
    required this.profile,
    required this.onLogout,
  });

  final DoctorProfileData profile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
    decoration: BoxDecoration(
      color: DoctorStyles.mint,
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 7,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Setting',
          style: TextStyle(
            color: Colors.black,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        _DoctorSettingsButton(
          key: const ValueKey('edit-doctor-profile'),
          icon: Icons.person_outline_rounded,
          label: 'Account',
          statusText: profile.name,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const EditDoctorProfilePage(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _DoctorSettingsButton(
          key: const ValueKey('doctor-security-setting'),
          icon: Icons.shield_outlined,
          label: 'Security',
          statusText: profile.twoFactorEnabled ? '2FA on' : '2FA off',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const DoctorSecurityPage()),
          ),
        ),
        const SizedBox(height: 14),
        _DoctorSettingsButton(
          key: const ValueKey('doctor-notification-setting'),
          icon: Icons.notifications_none_rounded,
          label: 'Notifications',
          statusText: profile.notificationsEnabled ? 'Enabled' : 'Disabled',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const DoctorNotificationsSettingsPage(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _DoctorSettingsButton(
          key: const ValueKey('doctor-availability-setting'),
          icon: Icons.tune_rounded,
          label: 'Preferences',
          statusText: profile.acceptingAppointments
              ? 'Accepting bookings'
              : 'Bookings paused',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const DoctorPreferencesPage(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _DoctorSettingsButton(
          icon: Icons.info_outline_rounded,
          label: 'About',
          onTap: () => showAboutDialog(
            context: context,
            applicationName: "Nway's Love Vet Clinic",
            applicationVersion: '1.0.0',
          ),
        ),
        const SizedBox(height: 14),
        _DoctorSettingsButton(
          key: const ValueKey('doctor-logout'),
          icon: Icons.logout_rounded,
          label: 'Log Out',
          color: const Color(0xFFFF1017),
          foreground: Colors.white,
          onTap: onLogout,
        ),
      ],
    ),
  );
}

class _DoctorSettingsButton extends StatelessWidget {
  const _DoctorSettingsButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.statusText,
    this.color = Colors.white,
    this.foreground = Colors.black,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final String? statusText;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: foreground),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (statusText != null && statusText!.isNotEmpty)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    statusText!,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: foreground.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DoctorProfileSection extends StatelessWidget {
  const _DoctorProfileSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
    decoration: BoxDecoration(
      color: DoctorStyles.mint,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(icon, size: 25),
              const SizedBox(width: 9),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        child,
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Edit profile
// ---------------------------------------------------------------------------

class EditDoctorProfilePage extends StatefulWidget {
  const EditDoctorProfilePage({super.key});

  @override
  State<EditDoctorProfilePage> createState() => _EditDoctorProfilePageState();
}

class _EditDoctorProfilePageState extends State<EditDoctorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final _data = DoctorProfileStore.instance.data;
  late final _name = TextEditingController(text: _data.name);
  late final _specialty = TextEditingController(text: _data.specialty);
  late final _experience = TextEditingController(text: _data.experience);
  late final _biography = TextEditingController(text: _data.biography);
  late final _phone = TextEditingController(text: _data.phone);
  late final _email = TextEditingController(text: _data.email);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _specialty.dispose();
    _experience.dispose();
    _biography.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final saved = await DoctorProfileStore.instance.saveProfile(
      name: _name.text.trim(),
      specialty: _specialty.text.trim(),
      experience: _experience.text.trim(),
      biography: _biography.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Profile saved to Firebase.'
              : 'Saved locally. Will sync when back online.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _EditDoctorProfileHeader(title: 'Edit Doctor Profile'),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                children: [
                  _DoctorProfileSection(
                    title: 'Profile Information',
                    icon: Icons.edit_note_rounded,
                    child: Column(
                      children: [
                        _DoctorTextField(
                          controller: _name,
                          label: 'Full name *',
                          validator: _requiredValidator('Full name'),
                        ),
                        _DoctorTextField(
                          controller: _specialty,
                          label: 'Specialty *',
                          validator: _requiredValidator('Specialty'),
                        ),
                        _DoctorTextField(
                          controller: _experience,
                          label: 'Experience (e.g. 8 years)',
                        ),
                        _DoctorTextField(
                          controller: _biography,
                          label: 'Biography',
                          maxLines: 4,
                        ),
                        _DoctorTextField(
                          controller: _phone,
                          label: 'Phone number *',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            if (!_isValidPhone(value!)) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        _DoctorTextField(
                          controller: _email,
                          label: 'Email *',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!_isValidEmail(value!)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SaveButton(
                    keyValue: 'save-doctor-profile',
                    saving: _saving,
                    onPressed: _save,
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

String? Function(String?) _requiredValidator(String field) =>
    (value) => (value ?? '').trim().isEmpty ? '$field is required' : null;

// ---------------------------------------------------------------------------
// Edit credentials
// ---------------------------------------------------------------------------

class EditDoctorCredentialsPage extends StatefulWidget {
  const EditDoctorCredentialsPage({super.key});

  @override
  State<EditDoctorCredentialsPage> createState() =>
      _EditDoctorCredentialsPageState();
}

class _EditDoctorCredentialsPageState extends State<EditDoctorCredentialsPage> {
  late final _data = DoctorProfileStore.instance.data;
  late final _license = TextEditingController(text: _data.license);
  late final List<String> _qualifications = [..._data.qualifications];
  late final List<String> _certifications = [..._data.certifications];
  late final List<String> _expertise = [..._data.expertise];
  late final List<String> _languages = [..._data.languages];
  late DateTime? _licenseExpiry = _data.licenseExpiry;
  bool _saving = false;

  @override
  void dispose() {
    _license.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _licenseExpiry ?? now.add(const Duration(days: 365)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) setState(() => _licenseExpiry = picked);
  }

  Future<void> _save() async {
    if (_license.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('License number is required.')),
      );
      return;
    }
    setState(() => _saving = true);
    final saved = await DoctorProfileStore.instance.saveCredentials(
      qualifications: _qualifications,
      certifications: _certifications,
      expertise: _expertise,
      languages: _languages,
      license: _license.text.trim(),
      licenseExpiry: _licenseExpiry,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? 'Credentials saved.' : 'Saved locally.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _EditDoctorProfileHeader(title: 'Credentials'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              children: [
                _DoctorProfileSection(
                  title: 'License',
                  icon: Icons.badge_outlined,
                  child: Column(
                    children: [
                      _DoctorTextField(
                        controller: _license,
                        label: 'License number *',
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          leading: const Icon(Icons.event_busy_outlined),
                          title: const Text('License expiry date'),
                          subtitle: Text(
                            _licenseExpiry == null
                                ? 'Not set'
                                : _fullDate(_licenseExpiry!),
                          ),
                          trailing: TextButton(
                            onPressed: _pickExpiry,
                            child: const Text('Pick'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ChipListEditor(
                  title: 'Qualifications',
                  icon: Icons.school_outlined,
                  values: _qualifications,
                  hint: 'e.g. DVM - University of Veterinary Science',
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 16),
                _ChipListEditor(
                  title: 'Certifications',
                  icon: Icons.workspace_premium_outlined,
                  values: _certifications,
                  hint: 'e.g. Certified in Small Animal Surgery',
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 16),
                _ChipListEditor(
                  title: 'Areas of expertise',
                  icon: Icons.star_outline_rounded,
                  values: _expertise,
                  hint: 'e.g. Dermatology',
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 16),
                _ChipListEditor(
                  title: 'Languages',
                  icon: Icons.translate_rounded,
                  values: _languages,
                  hint: 'e.g. English',
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 20),
                _SaveButton(
                  keyValue: 'save-doctor-credentials',
                  saving: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ChipListEditor extends StatefulWidget {
  const _ChipListEditor({
    required this.title,
    required this.icon,
    required this.values,
    required this.hint,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final List<String> values;
  final String hint;
  final VoidCallback onChanged;

  @override
  State<_ChipListEditor> createState() => _ChipListEditorState();
}

class _ChipListEditorState extends State<_ChipListEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    setState(() {
      widget.values.add(value);
      _controller.clear();
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) => _DoctorProfileSection(
    title: widget.title,
    icon: widget.icon,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.values.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('Nothing added yet.', style: DoctorStyles.muted),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < widget.values.length; i++)
                  InputChip(
                    label: Text(widget.values[i]),
                    backgroundColor: DoctorStyles.softMint,
                    onDeleted: () {
                      setState(() => widget.values.removeAt(i));
                      widget.onChanged();
                    },
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.hint,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _add,
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: DoctorStyles.green,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Edit availability
// ---------------------------------------------------------------------------

class EditDoctorAvailabilityPage extends StatefulWidget {
  const EditDoctorAvailabilityPage({super.key});

  @override
  State<EditDoctorAvailabilityPage> createState() =>
      _EditDoctorAvailabilityPageState();
}

class _EditDoctorAvailabilityPageState
    extends State<EditDoctorAvailabilityPage> {
  late final Map<DoctorWeekday, DaySchedule> _schedule = {
    for (final day in DoctorWeekday.values)
      day: DoctorProfileStore.instance.data.dayFor(day),
  };
  late final List<DateTime> _leaveDates = [
    ...DoctorProfileStore.instance.data.leaveDates,
  ];
  late bool _accepting = DoctorProfileStore.instance.data.acceptingAppointments;
  bool _saving = false;

  Future<TimeOfDay?> _pickTime(int minutes) => showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
  );

  Future<void> _addLeave() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        if (!_leaveDates.any((d) => _sameDay(d, picked))) {
          _leaveDates.add(picked);
          _leaveDates.sort();
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final saved = await DoctorProfileStore.instance.saveSchedule(
      schedule: _schedule,
      leaveDates: _leaveDates,
      acceptingAppointments: _accepting,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? 'Availability saved.' : 'Saved locally.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _EditDoctorProfileHeader(title: 'Availability & Shifts'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: DoctorStyles.softMint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SwitchListTile(
                    key: const ValueKey('accepting-appointments-switch'),
                    value: _accepting,
                    activeThumbColor: DoctorStyles.green,
                    title: const Text(
                      'Accepting appointments',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      _accepting
                          ? 'Pet owners can book with you.'
                          : 'New bookings are paused.',
                    ),
                    onChanged: (value) => setState(() => _accepting = value),
                  ),
                ),
                const SizedBox(height: 16),
                for (final day in DoctorWeekday.values) ...[
                  _DayScheduleEditor(
                    schedule: _schedule[day]!,
                    onToggle: (working) => setState(
                      () => _schedule[day] = _schedule[day]!.copyWith(
                        isWorking: working,
                      ),
                    ),
                    onPickStart: () async {
                      final t = await _pickTime(_schedule[day]!.startMinutes);
                      if (t != null) {
                        setState(
                          () => _schedule[day] = _schedule[day]!.copyWith(
                            startMinutes: t.hour * 60 + t.minute,
                          ),
                        );
                      }
                    },
                    onPickEnd: () async {
                      final t = await _pickTime(_schedule[day]!.endMinutes);
                      if (t != null) {
                        setState(
                          () => _schedule[day] = _schedule[day]!.copyWith(
                            endMinutes: t.hour * 60 + t.minute,
                          ),
                        );
                      }
                    },
                    onPickBreakStart: () async {
                      final current =
                          _schedule[day]!.breakStartMinutes ?? 12 * 60;
                      final t = await _pickTime(current);
                      if (t != null) {
                        setState(
                          () => _schedule[day] = _schedule[day]!.copyWith(
                            breakStartMinutes: t.hour * 60 + t.minute,
                            breakEndMinutes:
                                _schedule[day]!.breakEndMinutes ?? 13 * 60,
                          ),
                        );
                      }
                    },
                    onPickBreakEnd: () async {
                      final current =
                          _schedule[day]!.breakEndMinutes ?? 13 * 60;
                      final t = await _pickTime(current);
                      if (t != null) {
                        setState(
                          () => _schedule[day] = _schedule[day]!.copyWith(
                            breakStartMinutes:
                                _schedule[day]!.breakStartMinutes ?? 12 * 60,
                            breakEndMinutes: t.hour * 60 + t.minute,
                          ),
                        );
                      }
                    },
                    onClearBreak: () => setState(
                      () => _schedule[day] = _schedule[day]!.copyWith(
                        clearBreak: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _DoctorProfileSection(
                  title: 'Leave dates',
                  icon: Icons.beach_access_outlined,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_leaveDates.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Text(
                              'No leave scheduled.',
                              style: DoctorStyles.muted,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (var i = 0; i < _leaveDates.length; i++)
                                InputChip(
                                  label: Text(_fullDate(_leaveDates[i])),
                                  backgroundColor: const Color(0xFFFFE8E9),
                                  onDeleted: () =>
                                      setState(() => _leaveDates.removeAt(i)),
                                ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _addLeave,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add leave date'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _SaveButton(
                  keyValue: 'save-doctor-availability',
                  saving: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _DayScheduleEditor extends StatelessWidget {
  const _DayScheduleEditor({
    required this.schedule,
    required this.onToggle,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onPickBreakStart,
    required this.onPickBreakEnd,
    required this.onClearBreak,
  });

  final DaySchedule schedule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onPickBreakStart;
  final VoidCallback onPickBreakEnd;
  final VoidCallback onClearBreak;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 6, 12, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: DoctorStyles.border),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                schedule.day.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              schedule.isWorking ? 'Working' : 'Off duty',
              style: TextStyle(
                color: schedule.isWorking
                    ? DoctorStyles.green
                    : const Color(0xFF9AA8A2),
                fontWeight: FontWeight.w700,
              ),
            ),
            Switch(
              value: schedule.isWorking,
              activeThumbColor: DoctorStyles.green,
              onChanged: onToggle,
            ),
          ],
        ),
        if (schedule.isWorking) ...[
          Row(
            children: [
              Expanded(
                child: _TimeButton(
                  label: 'Start',
                  value: _formatMinutes(schedule.startMinutes),
                  onTap: onPickStart,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeButton(
                  label: 'End',
                  value: _formatMinutes(schedule.endMinutes),
                  onTap: onPickEnd,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (schedule.hasBreak)
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'Break start',
                    value: _formatMinutes(schedule.breakStartMinutes!),
                    onTap: onPickBreakStart,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeButton(
                    label: 'Break end',
                    value: _formatMinutes(schedule.breakEndMinutes!),
                    onTap: onPickBreakEnd,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove break',
                  onPressed: onClearBreak,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onPickBreakStart,
                icon: const Icon(Icons.free_breakfast_outlined, size: 18),
                label: const Text('Add break'),
              ),
            ),
        ],
      ],
    ),
  );
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 10),
      side: const BorderSide(color: DoctorStyles.border),
    ),
    child: Column(
      children: [
        Text(label, style: DoctorStyles.muted),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: DoctorStyles.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Notifications settings
// ---------------------------------------------------------------------------

class DoctorNotificationsSettingsPage extends StatelessWidget {
  const DoctorNotificationsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: DoctorProfileStore.instance,
          builder: (context, _) {
            final store = DoctorProfileStore.instance;
            final profile = store.data;
            final enabled = profile.notificationsEnabled;
            return Column(
              children: [
                const _EditDoctorProfileHeader(title: 'Notifications'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                    children: [
                      _SettingSwitchTile(
                        keyValue: 'notif-master-switch',
                        icon: Icons.notifications_active_outlined,
                        title: 'Push notifications',
                        subtitle:
                            'Master switch for all app notifications on this '
                            'device.',
                        value: enabled,
                        onChanged: (value) => store.updateNotificationSettings(
                          notificationsEnabled: value,
                        ),
                      ),
                      _SettingSwitchTile(
                        icon: Icons.event_available_outlined,
                        title: 'Appointment reminders',
                        subtitle:
                            'Reminders before each scheduled appointment.',
                        value: enabled && profile.appointmentReminders,
                        onChanged: enabled
                            ? (value) => store.updateNotificationSettings(
                                appointmentReminders: value,
                              )
                            : null,
                      ),
                      _SettingSwitchTile(
                        icon: Icons.emergency_outlined,
                        title: 'Emergency alerts',
                        subtitle: 'Immediate alerts for new emergency cases.',
                        value: enabled && profile.emergencyAlerts,
                        onChanged: enabled
                            ? (value) => store.updateNotificationSettings(
                                emergencyAlerts: value,
                              )
                            : null,
                      ),
                      _SettingSwitchTile(
                        icon: Icons.mail_outline_rounded,
                        title: 'Marketing emails',
                        subtitle:
                            'Clinic news, tips, and product updates by email.',
                        value: profile.marketingEmails,
                        onChanged: (value) => store.updateNotificationSettings(
                          marketingEmails: value,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preferences
// ---------------------------------------------------------------------------

class DoctorPreferencesPage extends StatelessWidget {
  const DoctorPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: DoctorProfileStore.instance,
          builder: (context, _) {
            final store = DoctorProfileStore.instance;
            final profile = store.data;
            return Column(
              children: [
                const _EditDoctorProfileHeader(title: 'Preferences'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                    children: [
                      _SettingSwitchTile(
                        keyValue: 'accepting-bookings-switch',
                        icon: Icons.event_seat_outlined,
                        title: 'Accepting appointments',
                        subtitle: profile.acceptingAppointments
                            ? 'Accepting bookings — pet owners can book you.'
                            : 'Paused — no new bookings will be accepted.',
                        value: profile.acceptingAppointments,
                        onChanged: store.setAvailability,
                      ),
                      const SizedBox(height: 4),
                      ListTile(
                        leading: const Icon(Icons.schedule_rounded),
                        title: const Text('Working hours & shifts'),
                        subtitle: const Text(
                          'Set which days and hours you work.',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const EditDoctorAvailabilityPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Security
// ---------------------------------------------------------------------------

class DoctorSecurityPage extends StatelessWidget {
  const DoctorSecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: DoctorProfileStore.instance,
          builder: (context, _) {
            final store = DoctorProfileStore.instance;
            final profile = store.data;
            return Column(
              children: [
                const _EditDoctorProfileHeader(title: 'Account Security'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                    children: [
                      ListTile(
                        key: const ValueKey('change-password-tile'),
                        leading: const Icon(Icons.password_rounded),
                        title: const Text('Change password'),
                        subtitle: const Text('Update your login password.'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showChangePassword(context),
                      ),
                      const Divider(),
                      _SettingSwitchTile(
                        keyValue: 'two-factor-switch',
                        icon: Icons.security_rounded,
                        title: 'Two-factor authentication',
                        subtitle: profile.twoFactorEnabled
                            ? 'Enabled — extra code required at sign in.'
                            : 'Disabled — add a second step for safety.',
                        value: profile.twoFactorEnabled,
                        onChanged: (value) async {
                          await store.setTwoFactor(value);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? 'Two-factor authentication enabled.'
                                    : 'Two-factor authentication disabled.',
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          'Active sessions',
                          style: DoctorStyles.section,
                        ),
                      ),
                      const _SessionTile(
                        device: 'iPhone 15 — this device',
                        detail: 'Yangon, MM • Active now',
                        current: true,
                      ),
                      const _SessionTile(
                        device: 'Clinic iPad',
                        detail: 'Yangon, MM • 2 hours ago',
                      ),
                      const _SessionTile(
                        device: 'Chrome on Windows',
                        detail: 'Mandalay, MM • Yesterday',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const ValueKey('sign-out-all-devices'),
                          onPressed: () => _confirmSignOutAll(context),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Sign Out From All Devices'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB3261E),
                            side: const BorderSide(color: Color(0xFFB3261E)),
                            minimumSize: const Size.fromHeight(52),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showChangePassword(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Enter your current password' : null,
              ),
              TextFormField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: (v) =>
                    (v ?? '').length < 8 ? 'Use at least 8 characters' : null,
              ),
              TextFormField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
                validator: (v) =>
                    v != next.text ? 'Passwords do not match' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-change-password'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
    current.dispose();
    next.dispose();
    confirm.dispose();
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated.')));
    }
  }

  Future<void> _confirmSignOutAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out everywhere?'),
        content: const Text(
          'This ends every active session, including other devices. '
          'You will need to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign Out All'),
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
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.device,
    required this.detail,
    this.current = false,
  });

  final String device;
  final String detail;
  final bool current;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(
      current ? Icons.phone_iphone_rounded : Icons.devices_other_rounded,
      color: current ? DoctorStyles.green : const Color(0xFF61716B),
    ),
    title: Text(device),
    subtitle: Text(detail),
    trailing: current
        ? const Text(
            'Current',
            style: TextStyle(
              color: DoctorStyles.green,
              fontWeight: FontWeight.w700,
            ),
          )
        : null,
  );
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.keyValue,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? keyValue;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: DoctorStyles.softMint,
      borderRadius: BorderRadius.circular(18),
    ),
    child: SwitchListTile(
      key: keyValue == null ? null : ValueKey(keyValue),
      value: value,
      onChanged: onChanged,
      activeThumbColor: DoctorStyles.green,
      secondary: Icon(icon, color: DoctorStyles.green),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
    ),
  );
}

class _DoctorTextField extends StatelessWidget {
  const _DoctorTextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _doctorProfileFieldDecoration(label),
    ),
  );
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.keyValue,
    required this.saving,
    required this.onPressed,
  });

  final String keyValue;
  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    key: ValueKey(keyValue),
    onPressed: saving ? null : onPressed,
    icon: saving
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.check_rounded),
    label: Text(saving ? 'Saving...' : 'Save Changes'),
    style: FilledButton.styleFrom(
      backgroundColor: DoctorStyles.green,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(56),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
  );
}

class _EditDoctorProfileHeader extends StatelessWidget {
  const _EditDoctorProfileHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 16, 24, 18),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      boxShadow: [
        BoxShadow(
          color: Color(0x28000000),
          blurRadius: 7,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(22),
          child: const Padding(
            padding: EdgeInsets.all(7),
            child: Icon(Icons.chevron_left_rounded, size: 30),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    ),
  );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

InputDecoration _doctorProfileFieldDecoration(String label) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(22)),
    borderSide: BorderSide(color: Colors.transparent),
  );
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: border,
    enabledBorder: border,
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(22)),
      borderSide: BorderSide(color: DoctorStyles.green, width: 1.8),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  );
}
