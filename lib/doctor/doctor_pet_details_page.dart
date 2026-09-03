part of 'doctor_portal.dart';

class DoctorPetDetailsPage extends StatelessWidget {
  const DoctorPetDetailsPage({required this.record, super.key});

  final DoctorAppointmentRecord record;

  @override
  Widget build(BuildContext context) {
    final profile = _matchingProfile;
    final speciesAndBreed = record.petDetails.split(' • ');
    final species = profile?.type ?? speciesAndBreed.first;
    final breed =
        profile?.breed ??
        (speciesAndBreed.length > 1 ? speciesAndBreed.last : 'Not recorded');
    final allergies = profile?.allergies ?? record.allergies;
    final history = DoctorMedicalRecordStore.instance.recordsFor(
      record.petName,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 14, 20, 12),
              child: InkWell(
                key: const ValueKey('doctor-pet-details-back'),
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(18),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left_rounded, size: 30),
                      SizedBox(width: 10),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('doctor-pet-details'),
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 34),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 28, 14, 20),
                  decoration: BoxDecoration(
                    color: DoctorStyles.mint,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipOval(
                              child: SizedBox(
                                width: 96,
                                height: 96,
                                child: Image.asset(
                                  'assets/photos/logoandphoto/nways_photo.png',
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topRight,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Name : ${record.petName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pet Owner : ${record.ownerName}',
                                    style: _DoctorPetDetailStyles.summary,
                                  ),
                                  Text(
                                    'Pet Owner ID : ${record.id}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _DoctorPetDetailStyles.summary,
                                  ),
                                  Wrap(
                                    spacing: 24,
                                    children: [
                                      Text(
                                        'Age : ${profile == null ? record.source?.pet.age ?? 'Not recorded' : _compactAge(profile.dateOfBirth)}',
                                        style: _DoctorPetDetailStyles.summary,
                                      ),
                                      Text(
                                        'Weight : ${profile == null ? 'Not recorded' : '${profile.weightKg.toStringAsFixed(profile.weightKg % 1 == 0 ? 0 : 1)} kg'}',
                                        style: _DoctorPetDetailStyles.summary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          'Allergies',
                          style: _DoctorPetDetailStyles.sectionTitle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DoctorPetWhitePanel(
                        minHeight: 102,
                        child: Text(
                          allergies,
                          style: _DoctorPetDetailStyles.body,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: const ValueKey('doctor-open-clinic-history'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DoctorPetHistoryPage(
                                petName: record.petName,
                                currentRecord: record,
                              ),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 13),
                            child: Center(
                              child: Text(
                                'Clinic History',
                                style: _DoctorPetDetailStyles.sectionTitle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DoctorPetWhitePanel(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
                        ),
                        child: history.isEmpty
                            ? const Center(
                                child: Text(
                                  'NA',
                                  style: _DoctorPetDetailStyles.sectionTitle,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final item in history)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 5,
                                      ),
                                      child: Text(
                                        '${_fullDate(item.date)} • ${item.service}\n'
                                        '${_orNotRecorded(item.diagnosis)}',
                                        style: _DoctorPetDetailStyles.body,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 38),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          'Additional Information',
                          style: _DoctorPetDetailStyles.sectionTitle,
                        ),
                      ),
                      const SizedBox(height: 9),
                      _DoctorPetWhitePanel(
                        padding: const EdgeInsets.fromLTRB(28, 22, 22, 24),
                        child: Text(
                          _additionalInformation(
                            profile: profile,
                            species: species,
                            breed: breed,
                          ),
                          style: _DoctorPetDetailStyles.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ProfilePet? get _matchingProfile {
    for (final profile in ProfilePetStore.instance.pets) {
      if (profile.name.toLowerCase() == record.petName.toLowerCase()) {
        return profile;
      }
    }
    return null;
  }

  String _additionalInformation({
    required ProfilePet? profile,
    required String species,
    required String breed,
  }) {
    return [
      'Pet Name: ${record.petName}',
      'Species: $species',
      'Breed: $breed',
      'Sex: ${profile?.sex ?? 'Not recorded'}',
      'Date of Birth: ${profile == null ? 'Not recorded' : _shortDate(profile.dateOfBirth)}',
      'Weight: ${profile == null ? 'Not recorded' : '${profile.weightKg.toStringAsFixed(profile.weightKg % 1 == 0 ? 0 : 1)} kg'}',
      'Blood Type: Not recorded',
      'Allergies: ${profile?.allergies ?? record.allergies}',
      'Chronic Diseases: ${profile?.conditions ?? record.existingConditions}',
      'Current Medications: ${profile?.medicines ?? 'Not recorded'}',
      'Microchip ID: Not recorded',
      'Spayed/Neutered: Not recorded',
      'Vaccination: ${profile?.vaccination ?? 'Not recorded'}',
      'Last Deworming: Not recorded',
      'Last Flea & Tick Prevention: Not recorded',
      'Next Annual Check-up: Not recorded',
    ].join('\n');
  }
}

class _DoctorPetWhitePanel extends StatelessWidget {
  const _DoctorPetWhitePanel({
    required this.child,
    this.minHeight,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final double? minHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: BoxConstraints(minHeight: minHeight ?? 0),
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
    ),
    child: child,
  );
}

class _DoctorPetDetailStyles {
  const _DoctorPetDetailStyles._();

  static const summary = TextStyle(
    color: Colors.black,
    fontSize: 15,
    height: 1.35,
  );
  static const sectionTitle = TextStyle(
    color: Colors.black,
    fontSize: 23,
    fontWeight: FontWeight.w900,
  );
  static const body = TextStyle(
    color: Colors.black,
    fontSize: 16,
    height: 1.34,
  );
}

String _compactAge(DateTime birthDate) {
  final now = DateTime.now();
  var months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
  if (now.day < birthDate.day) months--;
  if (months < 0) months = 0;
  final years = months ~/ 12;
  final remainingMonths = months % 12;
  if (years == 0) return '$remainingMonths mo';
  if (remainingMonths == 0) return '$years yr';
  return '$years yr $remainingMonths mo';
}

String _shortDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
