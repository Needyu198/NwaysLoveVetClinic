import 'package:flutter/material.dart';

import '../login/login_page.dart';
import 'appointment_booking_page.dart';
import 'home_visit_booking_page.dart';
import 'profile_flows.dart';

const _profileMint = Color(0xFFA1FDD8);
const _profileGreen = Color(0xFF177D58);

enum MedicalRecordCategory {
  all('All'),
  consultation('Consultation'),
  vaccination('Vaccination'),
  treatment('Treatment'),
  prescription('Prescription'),
  emergency('Emergency');

  const MedicalRecordCategory(this.label);
  final String label;
}

class ProfileMedicalEntry {
  const ProfileMedicalEntry({
    required this.id,
    required this.petName,
    required this.category,
    required this.title,
    required this.date,
    required this.veterinarian,
    required this.status,
    required this.details,
    this.documentTitle,
    this.followUp,
  });

  final String id;
  final String petName;
  final MedicalRecordCategory category;
  final String title;
  final DateTime date;
  final String veterinarian;
  final String status;
  final Map<String, String> details;
  final String? documentTitle;
  final String? followUp;
}

List<ProfileMedicalEntry> _medicalEntries() {
  final now = DateUtils.dateOnly(DateTime.now());
  final entries = <ProfileMedicalEntry>[];
  for (final pet in ProfilePetStore.instance.pets) {
    entries.addAll([
      ProfileMedicalEntry(
        id: 'VAC-${pet.name}-1',
        petName: pet.name,
        category: MedicalRecordCategory.vaccination,
        title: 'Rabies Vaccination',
        date: now.subtract(const Duration(days: 90)),
        veterinarian: 'Dr. Hnin Thiri',
        status: 'Completed',
        details: const {
          'Dose': 'Annual booster • 1 dose',
          'Given by': 'Dr. Hnin Thiri',
          'Clinic': "Nway's Love Vet Clinic",
          'Notes': 'Administered and recorded by clinic staff.',
        },
        documentTitle: 'Vaccination Certificate',
      ),
      ProfileMedicalEntry(
        id: 'VAC-${pet.name}-2',
        petName: pet.name,
        category: MedicalRecordCategory.vaccination,
        title: 'Annual Booster',
        date: now.add(const Duration(days: 14)),
        veterinarian: 'Clinic vaccination team',
        status: 'Upcoming',
        details: const {
          'Dose': 'Booster dose',
          'Reminder': 'Not enabled',
          'Notes': 'Book a vaccination appointment before the due date.',
        },
      ),
      ProfileMedicalEntry(
        id: 'VAC-${pet.name}-3',
        petName: pet.name,
        category: MedicalRecordCategory.vaccination,
        title: 'Core Vaccine Review',
        date: now.subtract(const Duration(days: 20)),
        veterinarian: 'Clinic vaccination team',
        status: 'Overdue',
        details: const {
          'Dose': 'Eligibility review required',
          'Notes': 'Contact the clinic to confirm the appropriate vaccine.',
        },
      ),
      ProfileMedicalEntry(
        id: 'TRT-${pet.name}-1',
        petName: pet.name,
        category: MedicalRecordCategory.treatment,
        title: 'Skin Irritation Treatment',
        date: now.subtract(const Duration(days: 35)),
        veterinarian: 'Dr. Aye Chan',
        status: 'Follow-up Required',
        details: const {
          'Diagnosis': 'Mild allergic dermatitis',
          'Procedure': 'Skin examination and cleaning',
          'Medicines': 'Veterinary antihistamine',
          'Recommendations': 'Prevent licking and monitor the affected area.',
        },
        documentTitle: 'Prescription',
        followUp: 'Follow up within 2 weeks or sooner if symptoms worsen.',
      ),
      ProfileMedicalEntry(
        id: 'TRT-${pet.name}-2',
        petName: pet.name,
        category: MedicalRecordCategory.treatment,
        title: 'Routine Dental Care',
        date: now.subtract(const Duration(days: 70)),
        veterinarian: 'Dr. Nway',
        status: 'Completed',
        details: const {
          'Diagnosis': 'Routine plaque buildup',
          'Procedure': 'Dental cleaning',
          'Medicines': 'None prescribed',
          'Recommendations': 'Continue regular dental care.',
        },
      ),
      ProfileMedicalEntry(
        id: 'CON-${pet.name}-1',
        petName: pet.name,
        category: MedicalRecordCategory.consultation,
        title: 'General Consultation',
        date: now.subtract(const Duration(days: 50)),
        veterinarian: 'Dr. Nway',
        status: 'Completed',
        details: const {
          'Symptoms': 'Routine wellness visit',
          'Diagnosis': 'General condition stable',
          'Treatment': 'Clinical examination',
          'Recommendations': 'Continue preventive care.',
        },
        documentTitle: 'Consultation Report',
      ),
      ProfileMedicalEntry(
        id: 'PRE-${pet.name}-1',
        petName: pet.name,
        category: MedicalRecordCategory.prescription,
        title: 'Dermatitis Prescription',
        date: now.subtract(const Duration(days: 35)),
        veterinarian: 'Dr. Aye Chan',
        status: 'Completed',
        details: const {
          'Medicine': 'Veterinary antihistamine',
          'Dosage': 'Use exactly as prescribed by the veterinarian',
          'Frequency': 'See prescription label',
          'Duration': 'Complete the prescribed course',
        },
        documentTitle: 'Prescription Document',
      ),
      ProfileMedicalEntry(
        id: 'EMR-${pet.name}-1',
        petName: pet.name,
        category: MedicalRecordCategory.emergency,
        title: 'Emergency Consultation',
        date: now.subtract(const Duration(days: 120)),
        veterinarian: 'Dr. Aye Chan',
        status: 'Completed',
        details: const {
          'Symptoms': 'Sudden weakness and vomiting',
          'Diagnosis': 'Acute stomach irritation',
          'Treatment': 'Emergency assessment and supportive care',
          'Recommendations': 'Monitor appetite and hydration closely.',
        },
        documentTitle: 'Emergency Treatment Report',
      ),
    ]);
  }
  return entries;
}

class VaccinationSummaryPage extends StatefulWidget {
  const VaccinationSummaryPage({super.key});

  @override
  State<VaccinationSummaryPage> createState() => _VaccinationSummaryPageState();
}

class _VaccinationSummaryPageState extends State<VaccinationSummaryPage> {
  late String _petName = ProfilePetStore.instance.pets.first.name;
  final Set<String> _reminders = {};

  @override
  Widget build(BuildContext context) {
    final records = _medicalEntries()
        .where(
          (record) =>
              record.petName == _petName &&
              record.category == MedicalRecordCategory.vaccination,
        )
        .toList();
    return _MedicalScaffold(
      title: 'Vaccination Summary',
      child: ListView(
        key: const ValueKey('vaccination-summary-list'),
        padding: const EdgeInsets.all(20),
        children: [
          _PetSelector(
            value: _petName,
            onChanged: (value) => setState(() => _petName = value),
          ),
          const SizedBox(height: 18),
          const _ReadOnlyNotice(
            text:
                'Vaccination records are read-only and updated only by veterinarians or authorized clinic staff.',
          ),
          const SizedBox(height: 14),
          for (final record in records) ...[
            _MedicalEntryCard(
              record: record,
              onTap: () => _openMedicalDetails(context, record),
              footer: record.status == 'Upcoming'
                  ? SwitchListTile(
                      key: ValueKey('vaccine-reminder-${record.id}'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Vaccination reminder'),
                      subtitle: Text(
                        _reminders.contains(record.id)
                            ? 'Reminder scheduled before the due date'
                            : 'Reminder is off',
                      ),
                      value: _reminders.contains(record.id),
                      onChanged: (value) => setState(
                        () => value
                            ? _reminders.add(record.id)
                            : _reminders.remove(record.id),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            key: const ValueKey('book-vaccination'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AppointmentBookingPage(
                  initialPetName: _petName,
                  initialServiceName: 'Vaccination',
                ),
              ),
            ),
            icon: const Icon(Icons.calendar_month_rounded),
            label: const Text('Book Vaccination'),
          ),
        ],
      ),
    );
  }
}

class TreatmentHistoryPage extends StatefulWidget {
  const TreatmentHistoryPage({super.key});

  @override
  State<TreatmentHistoryPage> createState() => _TreatmentHistoryPageState();
}

class _TreatmentHistoryPageState extends State<TreatmentHistoryPage> {
  late String _petName = ProfilePetStore.instance.pets.first.name;

  @override
  Widget build(BuildContext context) {
    final records = _medicalEntries()
        .where(
          (record) =>
              record.petName == _petName &&
              record.category == MedicalRecordCategory.treatment,
        )
        .toList();
    return _MedicalScaffold(
      title: 'Treatment History',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _PetSelector(
            value: _petName,
            onChanged: (value) => setState(() => _petName = value),
          ),
          const SizedBox(height: 18),
          const _ReadOnlyNotice(
            text:
                'Treatment information is read-only and can only be updated by veterinarians or authorized staff.',
          ),
          const SizedBox(height: 14),
          for (final record in records) ...[
            _MedicalEntryCard(
              record: record,
              onTap: () => _openMedicalDetails(context, record),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            key: const ValueKey('book-treatment-follow-up'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    AppointmentBookingPage(initialPetName: _petName),
              ),
            ),
            icon: const Icon(Icons.event_repeat_rounded),
            label: const Text('Book Follow-up'),
          ),
        ],
      ),
    );
  }
}

class ProfileMedicalRecordsPage extends StatefulWidget {
  const ProfileMedicalRecordsPage({super.key});

  @override
  State<ProfileMedicalRecordsPage> createState() =>
      _ProfileMedicalRecordsPageState();
}

class _ProfileMedicalRecordsPageState extends State<ProfileMedicalRecordsPage> {
  late String _petName = ProfilePetStore.instance.pets.first.name;
  MedicalRecordCategory _category = MedicalRecordCategory.all;
  String _query = '';
  String _dateFilter = 'All dates';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final records = _medicalEntries().where((record) {
      if (record.petName != _petName) return false;
      if (_category != MedicalRecordCategory.all &&
          record.category != _category) {
        return false;
      }
      if (_query.isNotEmpty &&
          !'${record.title} ${record.veterinarian} ${record.status}'
              .toLowerCase()
              .contains(_query.toLowerCase())) {
        return false;
      }
      if (_dateFilter == 'Last 30 days' &&
          now.difference(record.date).inDays > 30) {
        return false;
      }
      return true;
    }).toList();
    return _MedicalScaffold(
      title: 'Medical Records',
      child: ListView(
        key: const ValueKey('profile-medical-records-list'),
        padding: const EdgeInsets.all(20),
        children: [
          _PetSelector(
            value: _petName,
            onChanged: (value) => setState(() => _petName = value),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('medical-record-search'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              labelText: 'Search records',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _dateFilter,
            decoration: const InputDecoration(
              labelText: 'Date range',
              border: OutlineInputBorder(),
            ),
            items: const ['All dates', 'Last 30 days']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => _dateFilter = value!),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: MedicalRecordCategory.values
                  .map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        key: ValueKey('medical-category-${category.name}'),
                        label: Text(category.label),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          const _ReadOnlyNotice(
            text:
                'Pet owners can view medical records but cannot edit or delete them.',
          ),
          const SizedBox(height: 14),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('No matching medical records')),
            ),
          for (final record in records) ...[
            _MedicalEntryCard(
              record: record,
              onTap: () => _openMedicalDetails(context, record),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class MedicalEntryDetailsPage extends StatelessWidget {
  const MedicalEntryDetailsPage({required this.record, super.key});
  final ProfileMedicalEntry record;

  @override
  Widget build(BuildContext context) => _MedicalScaffold(
    title: 'Record Details',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          record.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text('${record.petName} • ${_date(record.date)} • ${record.status}'),
        const SizedBox(height: 18),
        _DetailsCard(
          rows: {'Veterinarian': record.veterinarian, ...record.details},
        ),
        if (record.followUp != null) ...[
          const SizedBox(height: 14),
          _ReadOnlyNotice(text: record.followUp!),
        ],
        if (record.documentTitle != null) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const ValueKey('view-medical-document'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MedicalDocumentPage(record: record),
              ),
            ),
            icon: const Icon(Icons.description_outlined),
            label: Text(
              record.category == MedicalRecordCategory.treatment
                  ? 'View Prescription'
                  : 'View Document',
            ),
          ),
        ],
        if (record.category == MedicalRecordCategory.treatment &&
            record.followUp != null) ...[
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    AppointmentBookingPage(initialPetName: record.petName),
              ),
            ),
            icon: const Icon(Icons.event_repeat_rounded),
            label: const Text('Book Follow-up'),
          ),
        ],
      ],
    ),
  );
}

class MedicalDocumentPage extends StatelessWidget {
  const MedicalDocumentPage({required this.record, super.key});
  final ProfileMedicalEntry record;

  @override
  Widget build(BuildContext context) => _MedicalScaffold(
    title: record.documentTitle ?? 'Medical Document',
    child: Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFBACBC4)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 56, color: _profileGreen),
            const SizedBox(height: 12),
            Text(
              record.documentTitle ?? 'Document',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              '${record.petName}\n${record.title}\n${_date(record.date)}\n${record.veterinarian}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Clinic-issued read-only document',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}

class SavedAddress {
  SavedAddress({
    required this.id,
    required this.label,
    required this.recipient,
    required this.phone,
    required this.house,
    required this.street,
    required this.district,
    required this.province,
    required this.postalCode,
    required this.landmark,
    this.isDefault = false,
  });
  final String id;
  String label;
  String recipient;
  String phone;
  String house;
  String street;
  String district;
  String province;
  String postalCode;
  String landmark;
  bool isDefault;
  String get fullAddress =>
      '$house, $street, $district, $province ${postalCode.isEmpty ? '' : postalCode}'
          .trim();
}

class SavedAddressStore extends ChangeNotifier {
  SavedAddressStore._();
  static final instance = SavedAddressStore._();
  final List<SavedAddress> _addresses = [
    SavedAddress(
      id: 'ADDR-1',
      label: 'Home',
      recipient: 'Nee Yu',
      phone: '09965805940',
      house: 'No. 12',
      street: 'Chindwin Street',
      district: 'Popba Thiri Township',
      province: 'Nay Pyi Taw',
      postalCode: '15011',
      landmark: 'Near the market',
      isDefault: true,
    ),
  ];
  List<SavedAddress> get addresses => List.unmodifiable(_addresses);

  void save(SavedAddress address) {
    final index = _addresses.indexWhere((item) => item.id == address.id);
    if (address.isDefault) {
      for (final item in _addresses) {
        item.isDefault = false;
      }
    }
    index < 0 ? _addresses.add(address) : _addresses[index] = address;
    notifyListeners();
  }

  bool isUsedByActiveBooking(SavedAddress address) =>
      HomeVisitStore.instance.visits.any(
        (visit) =>
            visit.status != HomeVisitStatus.completed &&
            visit.address.contains(address.street),
      );
  void delete(SavedAddress address) {
    _addresses.remove(address);
    if (_addresses.isNotEmpty && !_addresses.any((item) => item.isDefault)) {
      _addresses.first.isDefault = true;
    }
    notifyListeners();
  }
}

class SavedAddressesPage extends StatelessWidget {
  const SavedAddressesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Saved Addresses'),
      backgroundColor: _profileMint,
    ),
    body: AnimatedBuilder(
      animation: SavedAddressStore.instance,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final address in SavedAddressStore.instance.addresses)
            Card(
              child: ListTile(
                title: Row(
                  children: [
                    Text(
                      address.label,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (address.isDefault)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Chip(label: Text('Default')),
                      ),
                  ],
                ),
                subtitle: Text(
                  '${address.recipient} • ${address.phone}\n${address.fullAddress}\nLandmark: ${address.landmark}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => value == 'edit'
                      ? _openAddressForm(context, address)
                      : _deleteAddress(context, address),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('add-saved-address'),
            onPressed: () => _openAddressForm(context, null),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Add New Address'),
          ),
        ],
      ),
    ),
  );
}

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({this.address, super.key});
  final SavedAddress? address;

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _key = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers;
  late String _label;
  late bool _defaultAddress;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _controllers = [
      a?.recipient,
      a?.phone,
      a?.house,
      a?.street,
      a?.district,
      a?.province,
      a?.postalCode,
      a?.landmark,
    ].map((value) => TextEditingController(text: value ?? '')).toList();
    _label = a?.label ?? 'Home';
    _defaultAddress = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Recipient name *',
      'Phone number *',
      'House number *',
      'Street *',
      'District *',
      'Province *',
      'Postal code',
      'Landmark',
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address'),
        backgroundColor: _profileMint,
      ),
      body: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              TextFormField(
                key: i == 0 ? const ValueKey('address-recipient') : null,
                controller: _controllers[i],
                keyboardType: i == 1 ? TextInputType.phone : TextInputType.text,
                decoration: InputDecoration(
                  labelText: labels[i],
                  border: const OutlineInputBorder(),
                ),
                validator: i < 6
                    ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'This field is required';
                        }
                        if (i == 1 &&
                            !RegExp(r'^\+?[0-9]{7,15}$').hasMatch(
                              value.replaceAll(RegExp(r'[^0-9+]'), ''),
                            )) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      }
                    : null,
              ),
              const SizedBox(height: 12),
            ],
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Home', label: Text('Home')),
                ButtonSegment(value: 'Work', label: Text('Work')),
                ButtonSegment(value: 'Other', label: Text('Other')),
              ],
              selected: {_label},
              onSelectionChanged: (value) =>
                  setState(() => _label = value.first),
            ),
            SwitchListTile(
              title: const Text('Set as Default'),
              value: _defaultAddress,
              onChanged: (value) => setState(() => _defaultAddress = value),
            ),
            FilledButton(
              key: const ValueKey('save-address'),
              onPressed: () {
                if (!_key.currentState!.validate()) return;
                SavedAddressStore.instance.save(
                  SavedAddress(
                    id:
                        widget.address?.id ??
                        'ADDR-${DateTime.now().microsecondsSinceEpoch}',
                    label: _label,
                    recipient: _controllers[0].text.trim(),
                    phone: _controllers[1].text.trim(),
                    house: _controllers[2].text.trim(),
                    street: _controllers[3].text.trim(),
                    district: _controllers[4].text.trim(),
                    province: _controllers[5].text.trim(),
                    postalCode: _controllers[6].text.trim(),
                    landmark: _controllers[7].text.trim(),
                    isDefault: _defaultAddress,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: Text(
                widget.address == null ? 'Save Address' : 'Save Changes',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationPreferences {
  NotificationPreferences();

  NotificationPreferences.copy(NotificationPreferences other)
    : enabled = other.enabled,
      appointments = other.appointments,
      queue = other.queue,
      medical = other.medical,
      services = other.services,
      messages = other.messages,
      promotions = other.promotions;

  bool enabled = true;
  bool appointments = true;
  bool queue = true;
  bool medical = true;
  bool services = true;
  bool messages = true;
  bool promotions = false;
}

class NotificationSettingsStore extends ChangeNotifier {
  NotificationSettingsStore._();

  static final instance = NotificationSettingsStore._();
  NotificationPreferences preferences = NotificationPreferences();

  void save(NotificationPreferences value) {
    preferences = NotificationPreferences.copy(value);
    notifyListeners();
  }
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});
  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late final NotificationPreferences settings = NotificationPreferences.copy(
    NotificationSettingsStore.instance.preferences,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notification Settings'),
      backgroundColor: _profileMint,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SwitchListTile(
          key: const ValueKey('notifications-enabled'),
          title: const Text('Enable Notifications'),
          subtitle: const Text(
            'Device permission is requested when notifications are enabled.',
          ),
          value: settings.enabled,
          onChanged: (value) => setState(() => settings.enabled = value),
        ),
        const Divider(),
        _notificationSwitch(
          'Appointment confirmations and reminders',
          settings.appointments,
          (v) => settings.appointments = v,
        ),
        _notificationSwitch(
          'Queue updates',
          settings.queue,
          (v) => settings.queue = v,
        ),
        _notificationSwitch(
          'Vaccination and follow-up reminders',
          settings.medical,
          (v) => settings.medical = v,
        ),
        _notificationSwitch(
          'Pet Care and Home Visit status',
          settings.services,
          (v) => settings.services = v,
        ),
        _notificationSwitch(
          'Clinic chat messages',
          settings.messages,
          (v) => settings.messages = v,
        ),
        _notificationSwitch(
          'Clinic news and promotions',
          settings.promotions,
          (v) => settings.promotions = v,
        ),
        const ListTile(
          leading: Icon(Icons.lock_rounded, color: _profileGreen),
          title: Text('Emergency and account-security alerts'),
          subtitle: Text('Always enabled and cannot be disabled.'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('save-notification-settings'),
          onPressed: () {
            NotificationSettingsStore.instance.save(settings);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification settings updated')),
            );
            Navigator.of(context).pop();
          },
          child: const Text('Save Settings'),
        ),
      ],
    ),
  );

  Widget _notificationSwitch(
    String title,
    bool value,
    ValueChanged<bool> save,
  ) => SwitchListTile(
    title: Text(title),
    value: value,
    onChanged: settings.enabled
        ? (changed) => setState(() => save(changed))
        : null,
  );
}

enum SupportStatus { submitted, reviewing, inProgress, resolved, closed }

class SupportTicket {
  SupportTicket({
    required this.id,
    required this.category,
    required this.subject,
    required this.description,
    this.hasAttachment = false,
    this.status = SupportStatus.submitted,
  });
  final String id;
  final String category;
  final String subject;
  final String description;
  final bool hasAttachment;
  SupportStatus status;
  String staffReply = 'Waiting for clinic support to review this request.';
}

class SupportTicketStore extends ChangeNotifier {
  SupportTicketStore._();
  static final instance = SupportTicketStore._();
  final List<SupportTicket> tickets = [];
  void add(SupportTicket ticket) {
    tickets.add(ticket);
    notifyListeners();
  }

  void resolve(SupportTicket ticket) {
    ticket.status = SupportStatus.resolved;
    notifyListeners();
  }

  void staffUpdate(SupportTicket ticket, SupportStatus status, String reply) {
    ticket.status = status;
    ticket.staffReply = reply;
    notifyListeners();
  }
}

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});
  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  String _query = '';
  static const articles = <String, String>{
    'Account':
        'Update personal and contact information from Profile → Edit Profile.',
    'Booking':
        'Open Clinic, choose a booking category, then select the pet, service, veterinarian, date, and time.',
    'Medical Records':
        'Medical records are read-only and are updated by clinic staff or veterinarians.',
    'Pet Care':
        'Pet Care bookings and their staff-managed status are available from the Clinic page.',
    'Technical Support':
        'Restart the app and check connectivity. If the issue remains, submit a support request.',
  };

  @override
  Widget build(BuildContext context) {
    final filtered = articles.entries
        .where(
          (entry) => '${entry.key} ${entry.value}'.toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: _profileMint,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            key: const ValueKey('help-search'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              labelText: 'Search help',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          for (final article in filtered)
            Card(
              child: ExpansionTile(
                title: Text(article.key),
                childrenPadding: const EdgeInsets.all(16),
                children: [Text(article.value)],
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('contact-support'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SupportRequestPage(),
              ),
            ),
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('Contact Support'),
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: SupportTicketStore.instance,
            builder: (context, _) => Column(
              children: SupportTicketStore.instance.tickets
                  .map(
                    (ticket) => ListTile(
                      title: Text('#${ticket.id} • ${ticket.subject}'),
                      subtitle: Text(
                        '${_supportStatus(ticket.status)}\n${ticket.staffReply}',
                      ),
                      isThreeLine: true,
                      trailing: ticket.status == SupportStatus.resolved
                          ? TextButton(
                              onPressed: () =>
                                  SupportTicketStore.instance.resolve(ticket),
                              child: const Text('Resolved'),
                            )
                          : null,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class SupportRequestPage extends StatefulWidget {
  const SupportRequestPage({super.key});
  @override
  State<SupportRequestPage> createState() => _SupportRequestPageState();
}

class _SupportRequestPageState extends State<SupportRequestPage> {
  final _key = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  String _category = 'Account';
  bool _attachment = false;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Support Request'),
      backgroundColor: _profileMint,
    ),
    body: Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Issue category',
              border: OutlineInputBorder(),
            ),
            items:
                const [
                      'Account',
                      'Booking',
                      'Medical Records',
                      'Pet Care',
                      'Technical Support',
                    ]
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _category = value!),
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('support-subject'),
            controller: _subject,
            decoration: const InputDecoration(
              labelText: 'Subject *',
              border: OutlineInputBorder(),
            ),
            validator: _required,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('support-description'),
            controller: _description,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Description *',
              border: OutlineInputBorder(),
            ),
            validator: _required,
          ),
          CheckboxListTile(
            title: const Text('Attach screenshot'),
            subtitle: const Text(
              'A placeholder attachment will be added in this build.',
            ),
            value: _attachment,
            onChanged: (value) => setState(() => _attachment = value ?? false),
          ),
          FilledButton(
            key: const ValueKey('submit-support-request'),
            onPressed: () {
              if (!_key.currentState!.validate()) return;
              final ticket = SupportTicket(
                id: 'SUP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                category: _category,
                subject: _subject.text.trim(),
                description: _description.text.trim(),
                hasAttachment: _attachment,
              );
              SupportTicketStore.instance.add(ticket);
              showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Support request submitted'),
                  content: Text(
                    'Reference number: #${ticket.id}\nStatus: Submitted',
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('View Requests'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    ),
  );
}

Future<void> confirmProfileLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log Out?'),
      content: const Text(
        'This ends the current session. Your pets, appointments, and saved information will not be deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm-profile-logout'),
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

class _MedicalScaffold extends StatelessWidget {
  const _MedicalScaffold({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      backgroundColor: _profileMint,
      surfaceTintColor: Colors.transparent,
    ),
    backgroundColor: const Color(0xFFF7FAF9),
    body: child,
  );
}

class _PetSelector extends StatelessWidget {
  const _PetSelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: const ValueKey('medical-pet-selector'),
    initialValue: value,
    decoration: const InputDecoration(
      labelText: 'Select Pet',
      border: OutlineInputBorder(),
    ),
    items: ProfilePetStore.instance.pets
        .map(
          (pet) => DropdownMenuItem(
            value: pet.name,
            child: Text('${pet.name} • ${pet.type}'),
          ),
        )
        .toList(),
    onChanged: (selected) {
      if (selected != null) onChanged(selected);
    },
  );
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFE5FFF5),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline_rounded, color: _profileGreen),
        const SizedBox(width: 9),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _MedicalEntryCard extends StatelessWidget {
  const _MedicalEntryCard({
    required this.record,
    required this.onTap,
    this.footer,
  });
  final ProfileMedicalEntry record;
  final VoidCallback onTap;
  final Widget? footer;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              record.title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              '${_date(record.date)} • ${record.veterinarian}\n${record.category.label}',
            ),
            trailing: Chip(label: Text(record.status)),
            onTap: onTap,
          ),
          ?footer,
        ],
      ),
    ),
  );
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.rows});
  final Map<String, String> rows;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: rows.entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 105,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ),
  );
}

void _openMedicalDetails(BuildContext context, ProfileMedicalEntry record) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MedicalEntryDetailsPage(record: record),
      ),
    );

Future<void> _openAddressForm(BuildContext context, SavedAddress? address) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddressFormPage(address: address),
      ),
    );

Future<void> _deleteAddress(BuildContext context, SavedAddress address) async {
  if (SavedAddressStore.instance.isUsedByActiveBooking(address)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This address is attached to an active Home Visit and cannot be deleted.',
        ),
      ),
    );
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete Address?'),
      content: Text('Remove ${address.label} from saved addresses?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true) SavedAddressStore.instance.delete(address);
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;
String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
String _supportStatus(SupportStatus status) => switch (status) {
  SupportStatus.submitted => 'Submitted',
  SupportStatus.reviewing => 'Reviewing',
  SupportStatus.inProgress => 'In Progress',
  SupportStatus.resolved => 'Resolved',
  SupportStatus.closed => 'Closed',
};
