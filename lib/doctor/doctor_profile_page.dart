part of 'doctor_portal.dart';

class DoctorProfileStore extends ChangeNotifier {
  DoctorProfileStore._();

  static final instance = DoctorProfileStore._();
  String name = 'Dr. Aye Chan';
  String specialty = 'General Veterinarian';
  String license = 'VET-MM-1042';
  String experience = '8 years';
  String biography =
      'Compassionate veterinarian focused on preventive care and clear communication with pet owners.';
  String phone = '09-5312717';
  String email = 'doctor@nwaysclinic.com';
  bool acceptingAppointments = true;
  bool notificationsEnabled = true;

  void save({
    required String name,
    required String specialty,
    required String biography,
    required String phone,
    required String email,
  }) {
    this.name = name;
    this.specialty = specialty;
    this.biography = biography;
    this.phone = phone;
    this.email = email;
    notifyListeners();
  }

  void setAvailability(bool value) {
    acceptingAppointments = value;
    notifyListeners();
  }

  void setNotifications(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }
}

class DoctorProfilePage extends StatelessWidget {
  const DoctorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DoctorProfileStore.instance,
      builder: (context, _) {
        final profile = DoctorProfileStore.instance;
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
                    _DoctorProfileHero(profile: profile),
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

  final DoctorProfileStore profile;

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
            InkWell(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile photo picker opened.')),
              ),
              borderRadius: BorderRadius.circular(58),
              child: Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 68,
                  color: Color(0xFF789A93),
                ),
              ),
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
        const _DoctorShiftPanel(),
      ],
    ),
  );
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

class _DoctorShiftPanel extends StatelessWidget {
  const _DoctorShiftPanel();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(38, 16, 20, 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shift',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 5),
        Text(
          'Mon - (9:00 - 12:00) (13:00 - 16:00)\n'
          'Tue - (9:00 - 12:00) (13:00 - 16:00)\n'
          'Wed - (9:00 - 12:00) (13:00 - 16:00)\n'
          'Fri  - (9:00 - 12:00) (13:00 - 16:00)',
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _DoctorAccountSettingsCard extends StatelessWidget {
  const _DoctorAccountSettingsCard({
    required this.profile,
    required this.onLogout,
  });

  final DoctorProfileStore profile;
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
          label: 'Account',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const EditDoctorProfilePage(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _DoctorSettingsButton(
          key: const ValueKey('doctor-notification-setting'),
          label: 'Notifications',
          onTap: () {
            profile.setNotifications(!profile.notificationsEnabled);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  profile.notificationsEnabled
                      ? 'Doctor notifications enabled.'
                      : 'Doctor notifications disabled.',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        _DoctorSettingsButton(
          key: const ValueKey('doctor-availability-setting'),
          label: 'Preferences',
          onTap: () {
            profile.setAvailability(!profile.acceptingAppointments);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  profile.acceptingAppointments
                      ? 'New appointments are enabled.'
                      : 'New appointments are paused.',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        _DoctorSettingsButton(
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
          label: 'Log Out',
          color: const Color(0xFFFF1017),
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
    this.color = Colors.white,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 19,
              fontWeight: FontWeight.w500,
            ),
          ),
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

class EditDoctorProfilePage extends StatefulWidget {
  const EditDoctorProfilePage({super.key});

  @override
  State<EditDoctorProfilePage> createState() => _EditDoctorProfilePageState();
}

class _EditDoctorProfilePageState extends State<EditDoctorProfilePage> {
  late final _name = TextEditingController(
    text: DoctorProfileStore.instance.name,
  );
  late final _specialty = TextEditingController(
    text: DoctorProfileStore.instance.specialty,
  );
  late final _biography = TextEditingController(
    text: DoctorProfileStore.instance.biography,
  );
  late final _phone = TextEditingController(
    text: DoctorProfileStore.instance.phone,
  );
  late final _email = TextEditingController(
    text: DoctorProfileStore.instance.email,
  );

  @override
  void dispose() {
    _name.dispose();
    _specialty.dispose();
    _biography.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _EditDoctorProfileHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              children: [
                _DoctorProfileSection(
                  title: 'Profile Information',
                  icon: Icons.edit_note_rounded,
                  child: Column(
                    children: [
                      for (final field
                          in <(String, TextEditingController, int)>[
                            ('Full name', _name, 1),
                            ('Specialty', _specialty, 1),
                            ('Biography', _biography, 4),
                            ('Phone number', _phone, 1),
                            ('Email', _email, 1),
                          ]) ...[
                        TextField(
                          controller: field.$2,
                          maxLines: field.$3,
                          decoration: _doctorProfileFieldDecoration(field.$1),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const ValueKey('save-doctor-profile'),
                  onPressed: () {
                    if (_name.text.trim().isEmpty ||
                        _email.text.trim().isEmpty) {
                      return;
                    }
                    DoctorProfileStore.instance.save(
                      name: _name.text.trim(),
                      specialty: _specialty.text.trim(),
                      biography: _biography.text.trim(),
                      phone: _phone.text.trim(),
                      email: _email.text.trim(),
                    );
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save Changes'),
                  style: FilledButton.styleFrom(
                    backgroundColor: DoctorStyles.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
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
      ),
    ),
  );
}

class _EditDoctorProfileHeader extends StatelessWidget {
  const _EditDoctorProfileHeader();

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
        const Expanded(
          child: Text(
            'Edit Doctor Profile',
            style: TextStyle(
              color: Colors.black,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    ),
  );
}

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
