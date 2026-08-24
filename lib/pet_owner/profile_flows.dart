import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'appointment_booking_page.dart';
import 'contact_clinic_page.dart';
import 'pet_profile_page.dart';

class OwnerProfileData {
  const OwnerProfileData({
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.phone,
    required this.email,
    required this.address,
    this.photoSource,
  });

  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String phone;
  final String email;
  final String address;
  final String? photoSource;
}

class OwnerProfileStore extends ChangeNotifier {
  OwnerProfileStore._();

  static final instance = OwnerProfileStore._();

  OwnerProfileData _profile = OwnerProfileData(
    fullName: 'Nee Yu',
    dateOfBirth: DateTime(1998, 5, 12),
    gender: 'Female',
    phone: '09965805940',
    email: 'neeyu@email.com',
    address: 'Nay Pyi Taw',
  );

  OwnerProfileData get profile => _profile;

  void update(OwnerProfileData value) {
    _profile = value;
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _profile = OwnerProfileData(
      fullName: 'Nee Yu',
      dateOfBirth: DateTime(1998, 5, 12),
      gender: 'Female',
      phone: '09965805940',
      email: 'neeyu@email.com',
      address: 'Nay Pyi Taw',
    );
    notifyListeners();
  }
}

class ProfilePet {
  const ProfilePet({
    required this.name,
    required this.type,
    required this.breed,
    required this.sex,
    required this.dateOfBirth,
    required this.weightKg,
    required this.color,
    required this.identifyingFeatures,
    required this.allergies,
    required this.conditions,
    required this.medicines,
    required this.vaccination,
    this.hasCustomPhoto = false,
  });

  final String name;
  final String type;
  final String breed;
  final String sex;
  final DateTime dateOfBirth;
  final double weightKg;
  final String color;
  final String identifyingFeatures;
  final String allergies;
  final String conditions;
  final String medicines;
  final String vaccination;
  final bool hasCustomPhoto;

  int get ageYears {
    final now = DateTime.now();
    var years = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      years--;
    }
    return years < 0 ? 0 : years;
  }

  PetProfile toPetProfile() => PetProfile(
    name: name,
    species: type,
    breed: breed,
    sex: sex,
    weight: '${weightKg.toStringAsFixed(weightKg % 1 == 0 ? 0 : 1)} kg',
    age: ageYears == 0 ? 'Under 1 year' : '$ageYears years',
    imageAsset: PetProfilePage.fallbackProfile.imageAsset,
  );
}

class ProfilePetStore extends ChangeNotifier {
  ProfilePetStore._();

  static final instance = ProfilePetStore._();
  final List<ProfilePet> _pets = [
    ProfilePet(
      name: 'Max',
      type: 'Dog',
      breed: 'Golden Retriever',
      sex: 'Male',
      dateOfBirth: DateTime(2024, 5, 10),
      weightKg: 18,
      color: 'Golden',
      identifyingFeatures: 'White mark on chest',
      allergies: 'None known',
      conditions: 'None known',
      medicines: 'None',
      vaccination: 'Rabies vaccine completed',
    ),
    ProfilePet(
      name: 'Luna',
      type: 'Cat',
      breed: 'Mixed breed',
      sex: 'Female',
      dateOfBirth: DateTime(2023, 8, 3),
      weightKg: 4,
      color: 'Grey',
      identifyingFeatures: 'White paws',
      allergies: 'None known',
      conditions: 'None known',
      medicines: 'None',
      vaccination: 'Vaccinations current',
    ),
  ];

  List<ProfilePet> get pets => List.unmodifiable(_pets);

  bool isDuplicate(ProfilePet pet) => _pets.any(
    (item) =>
        item.name.toLowerCase() == pet.name.toLowerCase() &&
        item.type == pet.type &&
        DateUtils.isSameDay(item.dateOfBirth, pet.dateOfBirth),
  );

  void add(ProfilePet pet) {
    _pets.add(pet);
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _pets.removeWhere((pet) => pet.name != 'Max' && pet.name != 'Luna');
    notifyListeners();
  }
}

class EditOwnerProfilePage extends StatefulWidget {
  const EditOwnerProfilePage({super.key});

  @override
  State<EditOwnerProfilePage> createState() => _EditOwnerProfilePageState();
}

class _EditOwnerProfilePageState extends State<EditOwnerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late DateTime _dateOfBirth;
  late String _gender;
  String? _photoSource;
  late final OwnerProfileData _original;

  bool get _dirty =>
      _name.text != _original.fullName ||
      _phone.text != _original.phone ||
      _email.text != _original.email ||
      _address.text != _original.address ||
      _gender != _original.gender ||
      !DateUtils.isSameDay(_dateOfBirth, _original.dateOfBirth) ||
      _photoSource != _original.photoSource;

  @override
  void initState() {
    super.initState();
    _original = OwnerProfileStore.instance.profile;
    _name = TextEditingController(text: _original.fullName);
    _phone = TextEditingController(text: _original.phone);
    _email = TextEditingController(text: _original.email);
    _address = TextEditingController(text: _original.address);
    _dateOfBirth = _original.dateOfBirth;
    _gender = _original.gender;
    _photoSource = _original.photoSource;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leavePage();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: const Color(0xFFA1FDD8),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: _leavePage,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFFD9FFF0),
                      child: _photoSource == null
                          ? const Icon(Icons.person_rounded, size: 58)
                          : const Icon(Icons.check_rounded, size: 48),
                    ),
                    TextButton.icon(
                      key: const ValueKey('change-owner-photo'),
                      onPressed: _choosePhoto,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(
                        _photoSource == null ? 'Change Photo' : _photoSource!,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const ValueKey('edit-owner-name'),
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Full name *',
                  border: OutlineInputBorder(),
                ),
                validator: _required,
              ),
              const SizedBox(height: 14),
              ListTile(
                key: const ValueKey('edit-owner-dob'),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFF7A7A7A)),
                  borderRadius: BorderRadius.circular(4),
                ),
                title: const Text('Date of birth'),
                subtitle: Text(_formatDate(_dateOfBirth)),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: _pickDate,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: const ValueKey('edit-owner-gender'),
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender *',
                  border: OutlineInputBorder(),
                ),
                items: const ['Female', 'Male', 'Other', 'Prefer not to say']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _gender = value!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const ValueKey('edit-owner-phone'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final normalized = value?.replaceAll(RegExp(r'[^0-9+]'), '');
                  if (normalized == null ||
                      !RegExp(r'^\+?[0-9]{7,15}$').hasMatch(normalized)) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const ValueKey('edit-owner-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  if (value.toLowerCase() == 'registered@email.com') {
                    return 'This email is already registered';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const ValueKey('edit-owner-address'),
                controller: _address,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  border: OutlineInputBorder(),
                ),
                validator: _required,
              ),
              const SizedBox(height: 22),
              FilledButton(
                key: const ValueKey('save-owner-profile'),
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (value != null) setState(() => _dateOfBirth = value);
  }

  Future<void> _choosePhoto() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Profile Photo',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                'Choose a source. Device access is used when available.',
              ),
            ),
            ListTile(
              key: const ValueKey('owner-photo-camera'),
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop('Camera photo selected'),
            ),
            ListTile(
              key: const ValueKey('owner-photo-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo Gallery'),
              onTap: () => Navigator.of(context).pop('Gallery photo selected'),
            ),
          ],
        ),
      ),
    );
    if (value != null) setState(() => _photoSource = value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final contactChanged =
        _phone.text.trim() != _original.phone ||
        _email.text.trim() != _original.email;
    if (contactChanged && !await _verifyContact()) return;
    if (!mounted) return;
    OwnerProfileStore.instance.update(
      OwnerProfileData(
        fullName: _name.text.trim(),
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        address: _address.text.trim(),
        photoSource: _photoSource,
      ),
    );
    Navigator.of(context).pop(true);
  }

  Future<bool> _verifyContact() async {
    final controller = TextEditingController();
    String? error;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Verify Contact Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the 6-digit verification code sent to your updated contact. For this prototype, use 123456.',
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('owner-verification-code'),
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Verification code',
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('verify-owner-contact'),
              onPressed: () {
                if (controller.text == '123456') {
                  Navigator.of(dialogContext).pop(true);
                } else {
                  setDialogState(() => error = 'Incorrect verification code');
                }
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _leavePage() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved profile changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }
}

class ClinicLocationPage extends StatelessWidget {
  const ClinicLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinic Location'),
        backgroundColor: const Color(0xFFA1FDD8),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            key: const ValueKey('clinic-map-placeholder'),
            height: 260,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEAE5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_pin, size: 70, color: Color(0xFFD52D2D)),
                Text(
                  "Nway's Love Vet Clinic",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Saved clinic destination available offline',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _LocationInfo(
            icon: Icons.location_on_outlined,
            title: 'Address',
            value: ContactClinicPage.address,
          ),
          const _LocationInfo(
            icon: Icons.schedule_outlined,
            title: 'Operating hours',
            value: '8:00 AM–10:00 PM',
          ),
          const _LocationInfo(
            icon: Icons.call_outlined,
            title: 'Phone',
            value:
                '${ContactClinicPage.phonePrimary} • ${ContactClinicPage.phoneSecondary}',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('get-clinic-directions'),
            onPressed: () => _chooseMap(context),
            icon: const Icon(Icons.directions_rounded),
            label: const Text('Get Directions'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey('location-call-clinic'),
            onPressed: () => _confirmLocationCall(context),
            icon: const Icon(Icons.call_outlined),
            label: const Text('Call Clinic'),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseMap(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              'Choose navigation option',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              'If location or a map app is unavailable, copy the saved address.',
            ),
          ),
          for (final name in ['Google Maps', 'Apple Maps'])
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: Text(name),
              subtitle: const Text('Open clinic destination'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$name is unavailable in this build. The clinic address remains visible for manual navigation.',
                    ),
                  ),
                );
              },
            ),
          ListTile(
            key: const ValueKey('copy-clinic-address'),
            leading: const Icon(Icons.copy_rounded),
            title: const Text('Copy clinic address'),
            onTap: () {
              Clipboard.setData(
                const ClipboardData(text: ContactClinicPage.address),
              );
              Navigator.of(sheetContext).pop();
            },
          ),
        ],
      ),
    ),
  );
}

class _LocationInfo extends StatelessWidget {
  const _LocationInfo({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: const Color(0xFF177D58)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(value),
  );
}

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _weight = TextEditingController();
  final _color = TextEditingController();
  final _features = TextEditingController();
  final _allergies = TextEditingController();
  final _conditions = TextEditingController();
  final _medicines = TextEditingController();
  final _vaccination = TextEditingController();
  String? _type;
  String? _sex;
  DateTime? _dateOfBirth;
  bool _hasPhoto = false;
  bool _showErrors = false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _breed,
      _weight,
      _color,
      _features,
      _allergies,
      _conditions,
      _medicines,
      _vaccination,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Pet'),
        backgroundColor: const Color(0xFFA1FDD8),
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 38),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFFD9FFF0),
                    child: Icon(
                      _hasPhoto ? Icons.check_rounded : Icons.pets_rounded,
                      size: 50,
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey('add-pet-photo'),
                    onPressed: _choosePetPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      _hasPhoto ? 'Pet photo selected' : 'Add Photo (optional)',
                    ),
                  ),
                ],
              ),
            ),
            _field(
              _name,
              'Pet name *',
              key: const ValueKey('add-pet-name'),
              required: true,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: const ValueKey('add-pet-type'),
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Pet type *',
                border: OutlineInputBorder(),
              ),
              items: const ['Dog', 'Cat', 'Other']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _type = value;
                _breed.clear();
              }),
              validator: (value) => value == null ? 'Select a pet type' : null,
            ),
            const SizedBox(height: 14),
            _field(
              _breed,
              _type == null ? 'Breed *' : '$_type breed *',
              required: true,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: const ValueKey('add-pet-sex'),
              initialValue: _sex,
              decoration: const InputDecoration(
                labelText: 'Sex *',
                border: OutlineInputBorder(),
              ),
              items: const ['Female', 'Male', 'Unknown']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _sex = value),
              validator: (value) => value == null ? 'Select the pet sex' : null,
            ),
            const SizedBox(height: 14),
            ListTile(
              key: const ValueKey('add-pet-dob'),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFF7A7A7A)),
                borderRadius: BorderRadius.circular(4),
              ),
              title: const Text('Date of birth *'),
              subtitle: Text(
                _dateOfBirth == null
                    ? 'Select date'
                    : '${_formatDate(_dateOfBirth!)} • Age ${_calculatedAge(_dateOfBirth!)}',
              ),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: _pickPetDate,
            ),
            if (_showErrors && _dateOfBirth == null)
              const Padding(
                padding: EdgeInsets.only(left: 14, top: 5),
                child: Text(
                  'Select the pet date of birth',
                  style: TextStyle(color: Color(0xFFB3261E), fontSize: 12),
                ),
              ),
            const SizedBox(height: 14),
            _field(
              _weight,
              'Weight in kg *',
              key: const ValueKey('add-pet-weight'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final number = double.tryParse(value?.trim() ?? '');
                return number == null || number <= 0
                    ? 'Enter a valid positive weight'
                    : null;
              },
            ),
            const SizedBox(height: 14),
            _field(_color, 'Colour'),
            const SizedBox(height: 14),
            _field(_features, 'Identifying features', maxLines: 2),
            const SizedBox(height: 20),
            const Text(
              'Medical Information',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _field(_allergies, 'Allergies', maxLines: 2),
            const SizedBox(height: 14),
            _field(_conditions, 'Existing conditions', maxLines: 2),
            const SizedBox(height: 14),
            _field(_medicines, 'Current medicines', maxLines: 2),
            const SizedBox(height: 14),
            _field(_vaccination, 'Vaccination details', maxLines: 2),
            const SizedBox(height: 22),
            FilledButton(
              key: const ValueKey('review-add-pet'),
              onPressed: _review,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Review Pet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    Key? key,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => TextFormField(
    key: key,
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator:
        validator ??
        (required
            ? (value) => value == null || value.trim().isEmpty
                  ? 'This field is required'
                  : null
            : null),
  );

  Future<void> _choosePetPhoto() async {
    final selected = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo Gallery'),
              onTap: () => Navigator.of(context).pop(true),
            ),
            ListTile(
              leading: const Icon(Icons.image_not_supported_outlined),
              title: const Text('Use default pet image'),
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _hasPhoto = selected);
  }

  Future<void> _pickPetDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (value != null) setState(() => _dateOfBirth = value);
  }

  ProfilePet _buildPet() => ProfilePet(
    name: _name.text.trim(),
    type: _type!,
    breed: _breed.text.trim(),
    sex: _sex!,
    dateOfBirth: _dateOfBirth!,
    weightKg: double.parse(_weight.text.trim()),
    color: _color.text.trim(),
    identifyingFeatures: _features.text.trim(),
    allergies: _allergies.text.trim(),
    conditions: _conditions.text.trim(),
    medicines: _medicines.text.trim(),
    vaccination: _vaccination.text.trim(),
    hasCustomPhoto: _hasPhoto,
  );

  Future<void> _review() async {
    setState(() => _showErrors = true);
    final valid = _formKey.currentState!.validate();
    if (_dateOfBirth == null) {
      setState(() {});
      return;
    }
    if (!valid) return;
    final pet = _buildPet();
    if (ProfilePetStore.instance.isDuplicate(pet)) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Possible duplicate pet'),
          content: const Text(
            'A pet with the same name, type, and date of birth already exists. Add it anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Review Again'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Pet'),
        content: Text(
          '${pet.name}\n${pet.type} • ${pet.breed}\n${pet.sex} • ${_calculatedAge(pet.dateOfBirth)}\n${pet.weightKg} kg\nVaccination: ${pet.vaccination.isEmpty ? 'Not provided' : pet.vaccination}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Edit'),
          ),
          FilledButton(
            key: const ValueKey('confirm-add-pet'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add Pet'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ProfilePetStore.instance.add(pet);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const PetProfilePage(),
        settings: RouteSettings(arguments: pet.toPetProfile()),
      ),
    );
  }
}

class RescheduleAppointmentPage extends StatefulWidget {
  const RescheduleAppointmentPage({required this.appointment, super.key});
  final BookedAppointment appointment;

  @override
  State<RescheduleAppointmentPage> createState() =>
      _RescheduleAppointmentPageState();
}

class _RescheduleAppointmentPageState extends State<RescheduleAppointmentPage> {
  DateTime? _date;
  String? _time;

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
      7,
      (index) =>
          DateUtils.dateOnly(DateTime.now()).add(Duration(days: index + 1)),
    );
    const times = [
      '9:00 AM',
      '10:00 AM',
      '11:00 AM',
      '1:00 PM',
      '2:00 PM',
      '3:00 PM',
      '4:00 PM',
      '5:00 PM',
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reschedule Appointment'),
        backgroundColor: const Color(0xFFA1FDD8),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${widget.appointment.pet.name} • ${widget.appointment.service.name}',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select a new date',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: dates
                .map(
                  (date) => ChoiceChip(
                    label: Text(_formatDate(date)),
                    selected: DateUtils.isSameDay(_date, date),
                    onSelected: (_) => setState(() {
                      _date = date;
                      _time = null;
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select a new time',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: times
                .map(
                  (time) => ChoiceChip(
                    label: Text(time),
                    selected: _time == time,
                    onSelected: _date == null
                        ? null
                        : (_) => setState(() => _time = time),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('confirm-reschedule'),
            onPressed: _date == null || _time == null
                ? null
                : () {
                    final updated = AppointmentStore.instance.reschedule(
                      widget.appointment,
                      date: _date!,
                      time: _time!,
                    );
                    if (!updated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'That slot is no longer available. Choose another time.',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
            child: const Text('Confirm Reschedule'),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _calculatedAge(DateTime date) {
  final pet = ProfilePet(
    name: '',
    type: '',
    breed: '',
    sex: '',
    dateOfBirth: date,
    weightKg: 1,
    color: '',
    identifyingFeatures: '',
    allergies: '',
    conditions: '',
    medicines: '',
    vaccination: '',
  );
  return pet.ageYears == 0 ? 'Under 1 year' : '${pet.ageYears} years';
}

Future<void> _confirmLocationCall(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Call Clinic?'),
      content: const Text('Call ${ContactClinicPage.phonePrimary}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm Call'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Call ${ContactClinicPage.phonePrimary}. If the phone app is unavailable, copy the number from this page.',
        ),
      ),
    );
  }
}
