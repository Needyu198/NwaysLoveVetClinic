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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                  children: [
                    _DoctorProfileHero(profile: profile),
                    const SizedBox(height: 18),
                    _DoctorProfileSection(
                      title: 'Professional Information',
                      icon: Icons.badge_outlined,
                      child: _DoctorDetailsCard(
                        rows: [
                          ('License', profile.license),
                          ('Clinic', "Nway's Love Vet Clinic"),
                          ('Email', profile.email),
                          ('Phone', profile.phone),
                          ('Experience', profile.experience),
                          ('Biography', profile.biography),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _DoctorProfileSection(
                      title: 'Clinic Schedule',
                      icon: Icons.calendar_month_rounded,
                      child: _DoctorDetailsCard(
                        rows: [
                          ('Monday–Friday', '9:00 AM – 5:00 PM'),
                          ('Saturday', '9:00 AM – 1:00 PM'),
                          ('Sunday', 'Off duty'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DoctorProfileSection(
                      title: 'Preferences',
                      icon: Icons.tune_rounded,
                      child: Column(
                        children: [
                          _DoctorProfileSettingTile(
                            child: SwitchListTile(
                              key: const ValueKey(
                                'doctor-availability-setting',
                              ),
                              value: profile.acceptingAppointments,
                              onChanged: profile.setAvailability,
                              activeThumbColor: DoctorStyles.green,
                              title: const Text('Accepting appointments'),
                              subtitle: const Text(
                                'Allow new bookings in available slots',
                              ),
                              secondary: const Icon(
                                Icons.event_available_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _DoctorProfileSettingTile(
                            child: SwitchListTile(
                              key: const ValueKey(
                                'doctor-notification-setting',
                              ),
                              value: profile.notificationsEnabled,
                              onChanged: profile.setNotifications,
                              activeThumbColor: DoctorStyles.green,
                              title: const Text('Doctor notifications'),
                              subtitle: const Text(
                                'Appointments, emergencies and Home Visits',
                              ),
                              secondary: const Icon(
                                Icons.notifications_none_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _DoctorProfileSettingTile(
                            child: ListTile(
                              leading: const Icon(Icons.help_outline_rounded),
                              title: const Text('Help and Support'),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Clinic support: 09-5312717',
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      key: const ValueKey('doctor-logout'),
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Log Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB3261E),
                        side: const BorderSide(
                          color: Color(0xFFB3261E),
                          width: 1.5,
                        ),
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
    padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
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
    child: const Text(
      'Doctor Profile',
      style: TextStyle(
        color: Colors.black,
        fontSize: 29,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
    ),
  );
}

class _DoctorProfileHero extends StatelessWidget {
  const _DoctorProfileHero({required this.profile});

  final DoctorProfileStore profile;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
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
        Container(
          width: 106,
          height: 106,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            size: 54,
            color: DoctorStyles.green,
          ),
        ),
        TextButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo picker opened.')),
          ),
          style: TextButton.styleFrom(foregroundColor: Colors.black),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Change Photo'),
        ),
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 27,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          profile.specialty,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black, fontSize: 15),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const ValueKey('edit-doctor-profile'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const EditDoctorProfilePage(),
            ),
          ),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Profile'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(50),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
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

class _DoctorProfileSettingTile extends StatelessWidget {
  const _DoctorProfileSettingTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: child,
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
