part of 'doctor_portal.dart';

/// Identifier for a working day slot in the weekly schedule.
enum DoctorWeekday {
  monday('Monday', 'Mon'),
  tuesday('Tuesday', 'Tue'),
  wednesday('Wednesday', 'Wed'),
  thursday('Thursday', 'Thu'),
  friday('Friday', 'Fri'),
  saturday('Saturday', 'Sat'),
  sunday('Sunday', 'Sun');

  const DoctorWeekday(this.label, this.shortLabel);

  final String label;
  final String shortLabel;
}

/// Verification status for professional credentials.
enum CredentialVerification {
  verified('Verified'),
  pending('Pending Review'),
  unverified('Not Submitted');

  const CredentialVerification(this.label);

  final String label;

  static CredentialVerification fromName(String? value) =>
      CredentialVerification.values.firstWhere(
        (status) => status.name == value,
        orElse: () => CredentialVerification.unverified,
      );
}

/// A single day's working hours. When [isWorking] is false the day is "Off duty".
class DaySchedule {
  const DaySchedule({
    required this.day,
    this.isWorking = false,
    this.startMinutes = 9 * 60,
    this.endMinutes = 16 * 60,
    this.breakStartMinutes,
    this.breakEndMinutes,
  });

  final DoctorWeekday day;
  final bool isWorking;

  /// Minutes since midnight for the shift start/end and optional break window.
  final int startMinutes;
  final int endMinutes;
  final int? breakStartMinutes;
  final int? breakEndMinutes;

  bool get hasBreak => breakStartMinutes != null && breakEndMinutes != null;

  DaySchedule copyWith({
    bool? isWorking,
    int? startMinutes,
    int? endMinutes,
    int? breakStartMinutes,
    int? breakEndMinutes,
    bool clearBreak = false,
  }) => DaySchedule(
    day: day,
    isWorking: isWorking ?? this.isWorking,
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
    breakStartMinutes: clearBreak
        ? null
        : (breakStartMinutes ?? this.breakStartMinutes),
    breakEndMinutes: clearBreak
        ? null
        : (breakEndMinutes ?? this.breakEndMinutes),
  );

  String get summary {
    if (!isWorking) return 'Off duty';
    final buffer = StringBuffer(
      '${_formatMinutes(startMinutes)} - ${_formatMinutes(endMinutes)}',
    );
    if (hasBreak) {
      buffer.write(
        '  (Break ${_formatMinutes(breakStartMinutes!)} - '
        '${_formatMinutes(breakEndMinutes!)})',
      );
    }
    return buffer.toString();
  }

  Map<String, dynamic> toMap() => {
    'isWorking': isWorking,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
    'breakStartMinutes': breakStartMinutes,
    'breakEndMinutes': breakEndMinutes,
  };

  static DaySchedule fromMap(DoctorWeekday day, Map<String, dynamic>? map) {
    if (map == null) return DaySchedule(day: day);
    return DaySchedule(
      day: day,
      isWorking: map['isWorking'] as bool? ?? false,
      startMinutes: (map['startMinutes'] as num?)?.toInt() ?? 9 * 60,
      endMinutes: (map['endMinutes'] as num?)?.toInt() ?? 16 * 60,
      breakStartMinutes: (map['breakStartMinutes'] as num?)?.toInt(),
      breakEndMinutes: (map['breakEndMinutes'] as num?)?.toInt(),
    );
  }
}

String _formatMinutes(int minutes) {
  final normalized = minutes % (24 * 60);
  final hour = normalized ~/ 60;
  final minute = normalized % 60;
  final period = hour < 12 ? 'AM' : 'PM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  final minuteText = minute.toString().padLeft(2, '0');
  return '$displayHour:$minuteText $period';
}

/// Immutable snapshot of all persisted doctor profile data.
class DoctorProfileData {
  const DoctorProfileData({
    this.name = 'Dr. Aye Chan',
    this.specialty = 'General Veterinarian',
    this.license = 'VET-MM-1042',
    this.experience = '8 years',
    this.biography =
        'Compassionate veterinarian focused on preventive care and clear '
        'communication with pet owners.',
    this.phone = '09-5312717',
    this.email = 'doctor@nwaysclinic.com',
    this.photoUrl,
    this.acceptingAppointments = true,
    this.notificationsEnabled = true,
    this.appointmentReminders = true,
    this.emergencyAlerts = true,
    this.marketingEmails = false,
    this.twoFactorEnabled = false,
    this.qualifications = const ['DVM - University of Veterinary Science'],
    this.certifications = const ['Certified in Small Animal Surgery'],
    this.expertise = const ['Preventive Care', 'Dermatology'],
    this.languages = const ['English', 'Burmese'],
    this.licenseExpiry,
    this.verification = CredentialVerification.pending,
    this.schedule = const {},
    this.leaveDates = const [],
  });

  final String name;
  final String specialty;
  final String license;
  final String experience;
  final String biography;
  final String phone;
  final String email;
  final String? photoUrl;

  final bool acceptingAppointments;
  final bool notificationsEnabled;
  final bool appointmentReminders;
  final bool emergencyAlerts;
  final bool marketingEmails;
  final bool twoFactorEnabled;

  final List<String> qualifications;
  final List<String> certifications;
  final List<String> expertise;
  final List<String> languages;
  final DateTime? licenseExpiry;
  final CredentialVerification verification;

  /// Weekday -> schedule. Missing days default to off duty.
  final Map<DoctorWeekday, DaySchedule> schedule;
  final List<DateTime> leaveDates;

  DaySchedule dayFor(DoctorWeekday day) =>
      schedule[day] ?? DaySchedule(day: day);

  List<DaySchedule> get orderedSchedule =>
      DoctorWeekday.values.map(dayFor).toList();

  DoctorProfileData copyWith({
    String? name,
    String? specialty,
    String? license,
    String? experience,
    String? biography,
    String? phone,
    String? email,
    String? photoUrl,
    bool clearPhoto = false,
    bool? acceptingAppointments,
    bool? notificationsEnabled,
    bool? appointmentReminders,
    bool? emergencyAlerts,
    bool? marketingEmails,
    bool? twoFactorEnabled,
    List<String>? qualifications,
    List<String>? certifications,
    List<String>? expertise,
    List<String>? languages,
    DateTime? licenseExpiry,
    bool clearLicenseExpiry = false,
    CredentialVerification? verification,
    Map<DoctorWeekday, DaySchedule>? schedule,
    List<DateTime>? leaveDates,
  }) => DoctorProfileData(
    name: name ?? this.name,
    specialty: specialty ?? this.specialty,
    license: license ?? this.license,
    experience: experience ?? this.experience,
    biography: biography ?? this.biography,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
    acceptingAppointments: acceptingAppointments ?? this.acceptingAppointments,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    appointmentReminders: appointmentReminders ?? this.appointmentReminders,
    emergencyAlerts: emergencyAlerts ?? this.emergencyAlerts,
    marketingEmails: marketingEmails ?? this.marketingEmails,
    twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    qualifications: qualifications ?? this.qualifications,
    certifications: certifications ?? this.certifications,
    expertise: expertise ?? this.expertise,
    languages: languages ?? this.languages,
    licenseExpiry: clearLicenseExpiry
        ? null
        : (licenseExpiry ?? this.licenseExpiry),
    verification: verification ?? this.verification,
    schedule: schedule ?? this.schedule,
    leaveDates: leaveDates ?? this.leaveDates,
  );

  /// Fields that count toward the profile completeness indicator.
  double get completeness {
    final checks = <bool>[
      name.trim().isNotEmpty,
      specialty.trim().isNotEmpty,
      _isValidEmail(email),
      _isValidPhone(phone),
      biography.trim().length >= 20,
      photoUrl != null,
      license.trim().isNotEmpty,
      licenseExpiry != null,
      qualifications.isNotEmpty,
      expertise.isNotEmpty,
      languages.isNotEmpty,
      orderedSchedule.any((day) => day.isWorking),
    ];
    final done = checks.where((value) => value).length;
    return done / checks.length;
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'specialty': specialty,
    'license': license,
    'experience': experience,
    'biography': biography,
    'phone': phone,
    'email': email,
    'photoUrl': photoUrl,
    'acceptingAppointments': acceptingAppointments,
    'notificationsEnabled': notificationsEnabled,
    'appointmentReminders': appointmentReminders,
    'emergencyAlerts': emergencyAlerts,
    'marketingEmails': marketingEmails,
    'twoFactorEnabled': twoFactorEnabled,
    'qualifications': qualifications,
    'certifications': certifications,
    'expertise': expertise,
    'languages': languages,
    'licenseExpiry': licenseExpiry?.toIso8601String(),
    'verification': verification.name,
    'schedule': {
      for (final entry in schedule.entries) entry.key.name: entry.value.toMap(),
    },
    'leaveDates': leaveDates.map((date) => date.toIso8601String()).toList(),
  };

  static DoctorProfileData fromMap(Map<String, dynamic> map) {
    const fallback = DoctorProfileData();
    return DoctorProfileData(
      name: map['name'] as String? ?? fallback.name,
      specialty: map['specialty'] as String? ?? fallback.specialty,
      license: map['license'] as String? ?? fallback.license,
      experience: map['experience'] as String? ?? fallback.experience,
      biography: map['biography'] as String? ?? fallback.biography,
      phone: map['phone'] as String? ?? fallback.phone,
      email: map['email'] as String? ?? fallback.email,
      photoUrl: map['photoUrl'] as String?,
      acceptingAppointments:
          map['acceptingAppointments'] as bool? ??
          fallback.acceptingAppointments,
      notificationsEnabled:
          map['notificationsEnabled'] as bool? ?? fallback.notificationsEnabled,
      appointmentReminders:
          map['appointmentReminders'] as bool? ?? fallback.appointmentReminders,
      emergencyAlerts:
          map['emergencyAlerts'] as bool? ?? fallback.emergencyAlerts,
      marketingEmails:
          map['marketingEmails'] as bool? ?? fallback.marketingEmails,
      twoFactorEnabled:
          map['twoFactorEnabled'] as bool? ?? fallback.twoFactorEnabled,
      qualifications:
          _stringList(map['qualifications']) ?? fallback.qualifications,
      certifications:
          _stringList(map['certifications']) ?? fallback.certifications,
      expertise: _stringList(map['expertise']) ?? fallback.expertise,
      languages: _stringList(map['languages']) ?? fallback.languages,
      licenseExpiry: _parseDate(map['licenseExpiry']),
      verification: CredentialVerification.fromName(
        map['verification'] as String?,
      ),
      schedule: _parseSchedule(map['schedule']),
      leaveDates: _parseDateList(map['leaveDates']),
    );
  }

  static List<String>? _stringList(Object? value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return null;
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static List<DateTime> _parseDateList(Object? value) {
    if (value is List) {
      return value
          .map((item) => DateTime.tryParse(item.toString()))
          .whereType<DateTime>()
          .toList();
    }
    return const [];
  }

  static Map<DoctorWeekday, DaySchedule> _parseSchedule(Object? value) {
    if (value is! Map) return const {};
    final result = <DoctorWeekday, DaySchedule>{};
    for (final day in DoctorWeekday.values) {
      final raw = value[day.name];
      if (raw is Map) {
        result[day] = DaySchedule.fromMap(day, raw.cast<String, dynamic>());
      }
    }
    return result;
  }
}

bool _isValidEmail(String value) {
  final email = value.trim();
  if (email.isEmpty) return false;
  return RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email);
}

bool _isValidPhone(String value) {
  final phone = value.trim();
  if (phone.isEmpty) return false;
  // Accept digits, spaces, dashes, parentheses and a leading +; need 7-15 digits.
  if (!RegExp(r'^\+?[\d\s\-()]{7,20}$').hasMatch(phone)) return false;
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 7 && digits.length <= 15;
}

/// PostgreSQL-backed doctor profile access. Persistence is coordinated with
/// the other stores by DatabaseSync.
class DoctorProfileRepository {
  DoctorProfileRepository._();
  static final instance = DoctorProfileRepository._();
  Future<void> ensureInitialized() async {}
  Future<DoctorProfileData?> load() async => DoctorProfileStore.instance.data;
  Future<bool> save(DoctorProfileData data) async {
    await DatabaseSync.instance.flush();
    return DatabaseSync.instance.active && DatabaseSync.instance.error == null;
  }

  Future<String?> uploadPhoto(String filePath) async {
    final bytes = await XFile(filePath).readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      throw ClinicApiException('Please choose a photo smaller than 2 MB.');
    }
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }
}
