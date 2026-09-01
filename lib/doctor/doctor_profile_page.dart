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
        return ListView(
          key: const ValueKey('doctor-profile'),
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 36),
          children: [
            const CircleAvatar(
              radius: 52,
              backgroundColor: DoctorStyles.mint,
              child: Icon(Icons.medical_services_rounded, size: 52),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile photo picker opened.')),
              ),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Change Photo'),
            ),
            Text(
              profile.name,
              textAlign: TextAlign.center,
              style: DoctorStyles.title,
            ),
            Text(
              profile.specialty,
              textAlign: TextAlign.center,
              style: DoctorStyles.muted,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('edit-doctor-profile'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EditDoctorProfilePage(),
                ),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile'),
            ),
            const SizedBox(height: 14),
            _DoctorDetailsCard(
              rows: [
                ('License', profile.license),
                ('Clinic', "Nway's Love Vet Clinic"),
                ('Email', profile.email),
                ('Phone', profile.phone),
                ('Experience', profile.experience),
                ('Biography', profile.biography),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Clinic Schedule', style: DoctorStyles.section),
            const SizedBox(height: 10),
            const _DoctorDetailsCard(
              rows: [
                ('Monday–Friday', '9:00 AM – 5:00 PM'),
                ('Saturday', '9:00 AM – 1:00 PM'),
                ('Sunday', 'Off duty'),
              ],
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              key: const ValueKey('doctor-availability-setting'),
              value: profile.acceptingAppointments,
              onChanged: profile.setAvailability,
              title: const Text('Accepting appointments'),
              subtitle: const Text('Allow new bookings in available slots'),
            ),
            SwitchListTile(
              key: const ValueKey('doctor-notification-setting'),
              value: profile.notificationsEnabled,
              onChanged: profile.setNotifications,
              title: const Text('Doctor notifications'),
              subtitle: const Text('Appointments, emergencies and Home Visits'),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded),
              title: const Text('Help and Support'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clinic support: 09-5312717')),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: const ValueKey('doctor-logout'),
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB3261E),
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
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
    backgroundColor: DoctorStyles.page,
    appBar: AppBar(
      title: const Text('Edit Doctor Profile'),
      backgroundColor: DoctorStyles.mint,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final field in <(String, TextEditingController, int)>[
          ('Full name', _name, 1),
          ('Specialty', _specialty, 1),
          ('Biography', _biography, 4),
          ('Phone number', _phone, 1),
          ('Email', _email, 1),
        ]) ...[
          TextField(
            controller: field.$2,
            maxLines: field.$3,
            decoration: InputDecoration(
              labelText: field.$1,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton(
          key: const ValueKey('save-doctor-profile'),
          onPressed: () {
            if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) return;
            DoctorProfileStore.instance.save(
              name: _name.text.trim(),
              specialty: _specialty.text.trim(),
              biography: _biography.text.trim(),
              phone: _phone.text.trim(),
              email: _email.text.trim(),
            );
            Navigator.of(context).pop();
          },
          child: const Text('Save Changes'),
        ),
      ],
    ),
  );
}
