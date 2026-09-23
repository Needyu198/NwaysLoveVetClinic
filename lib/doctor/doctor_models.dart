part of 'doctor_portal.dart';

class DoctorAppointmentRecord {
  Map<String, dynamic> toDb() => {
    'id': id,
    'petName': petName,
    'petDetails': petDetails,
    'ownerName': ownerName,
    'service': service,
    'date': date.toIso8601String(),
    'time': time,
    'reason': reason,
    'symptoms': symptoms,
    '_status': _status,
    'consultationNotes': consultationNotes,
    'diagnosis': diagnosis,
    'treatment': treatment,
    'allergies': allergies,
    'existingConditions': existingConditions,
    'prescription': prescription,
    'vaccination': vaccination,
    'nextDoseDate': nextDoseDate,
    'followUp': followUp,
    'rescheduleNote': rescheduleNote,
  };
  static DoctorAppointmentRecord fromDb(Map<String, dynamic> data) {
    final value = DoctorAppointmentRecord(
      id: data['id'] as String,
      petName: data['petName'] as String,
      petDetails: data['petDetails'] as String,
      ownerName: data['ownerName'] as String,
      service: data['service'] as String,
      date: DateTime.parse(data['date'] as String),
      time: data['time'] as String,
      reason: data['reason'] as String,
      symptoms: data['symptoms'] as String,
      initialStatus: data['_status'] as String,
    );
    value.consultationNotes = data['consultationNotes'] as String;
    value.diagnosis = data['diagnosis'] as String;
    value.treatment = data['treatment'] as String;
    value.allergies = data['allergies'] as String;
    value.existingConditions = data['existingConditions'] as String;
    value.prescription = data['prescription'] as String;
    value.vaccination = data['vaccination'] as String;
    value.nextDoseDate = data['nextDoseDate'] as String;
    value.followUp = data['followUp'] as String;
    value.rescheduleNote = data['rescheduleNote'] as String;
    return value;
  }

  DoctorAppointmentRecord({
    required this.id,
    required this.petName,
    required this.petDetails,
    required this.ownerName,
    required this.service,
    required this.date,
    required this.time,
    required this.reason,
    required this.symptoms,
    required String initialStatus,
    this.source,
  }) : _status = initialStatus;

  factory DoctorAppointmentRecord.fromBooking(BookedAppointment booking) {
    return DoctorAppointmentRecord(
      id: booking.id,
      petName: booking.pet.name,
      petDetails: '${booking.pet.species} • ${booking.pet.breed}',
      ownerName: 'Pet Owner',
      service: booking.service.name,
      date: booking.date,
      time: booking.time,
      reason: booking.reason,
      symptoms: booking.symptoms,
      initialStatus: booking.status,
      source: booking,
    );
  }

  final String id;
  final String petName;
  final String petDetails;
  final String ownerName;
  final String service;
  final DateTime date;
  final String time;
  final String reason;
  final String symptoms;
  final BookedAppointment? source;
  String _status;
  String consultationNotes = '';
  String diagnosis = '';
  String treatment = '';
  String allergies = 'No known allergies recorded';
  String existingConditions = 'No existing medical conditions recorded';
  String prescription = '';
  String vaccination = '';
  String nextDoseDate = '';
  String followUp = '';
  String rescheduleNote = '';

  String get status => source?.status ?? _status;
  set status(String value) => _status = value;
}

class DoctorPost {
  Map<String, dynamic> toDb() => {
    'id': id,
    'title': title,
    'content': content,
    'coverAsset': coverAsset,
    'attachmentAssets': attachmentAssets.map((v) => v).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'authorId': authorId,
    'authorName': authorName,
    'authorSpecialty': authorSpecialty,
    'authorPhoto': authorPhoto,
    'category': category,
    'audience': audience,
    'status': status,
    if (scheduledFor != null) 'scheduledFor': scheduledFor!.toIso8601String(),
  };
  static DoctorPost fromDb(Map<String, dynamic> data) {
    final createdAt =
        DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now();
    final value = DoctorPost(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? 'Untitled post',
      content: data['content'] as String? ?? '',
      coverAsset: data['coverAsset'] as String? ?? '',
      attachmentAssets: (data['attachmentAssets'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(data['updatedAt'] as String? ?? '') ?? createdAt,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Clinic Veterinarian',
      authorSpecialty: data['authorSpecialty'] as String? ?? '',
      authorPhoto: data['authorPhoto'] as String?,
      category: data['category'] as String? ?? 'Pet Health',
      audience: data['audience'] as String? ?? 'All Pets',
      status: data['status'] as String? ?? 'published',
      scheduledFor: DateTime.tryParse(data['scheduledFor'] as String? ?? ''),
    );
    return value;
  }

  const DoctorPost({
    required this.id,
    required this.title,
    required this.content,
    required this.coverAsset,
    required this.attachmentAssets,
    required this.createdAt,
    DateTime? updatedAt,
    this.authorId = '',
    this.authorName = 'Clinic Veterinarian',
    this.authorSpecialty = '',
    this.authorPhoto,
    this.category = 'Pet Health',
    this.audience = 'All Pets',
    this.status = 'published',
    this.scheduledFor,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  final String title;
  final String content;
  final String coverAsset;
  final List<String> attachmentAssets;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String authorId;
  final String authorName;
  final String authorSpecialty;
  final String? authorPhoto;
  final String category;
  final String audience;
  final String status;
  final DateTime? scheduledFor;

  bool get isPublished =>
      (status == 'published' || status == 'scheduled') &&
      (scheduledFor == null || !scheduledFor!.isAfter(DateTime.now()));

  DoctorPost copyWith({
    String? title,
    String? content,
    String? coverAsset,
    List<String>? attachmentAssets,
    String? category,
    String? audience,
    String? status,
    DateTime? scheduledFor,
    bool clearSchedule = false,
  }) => DoctorPost(
    id: id,
    title: title ?? this.title,
    content: content ?? this.content,
    coverAsset: coverAsset ?? this.coverAsset,
    attachmentAssets: attachmentAssets ?? this.attachmentAssets,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    authorId: authorId,
    authorName: authorName,
    authorSpecialty: authorSpecialty,
    authorPhoto: authorPhoto,
    category: category ?? this.category,
    audience: audience ?? this.audience,
    status: status ?? this.status,
    scheduledFor: clearSchedule ? null : scheduledFor ?? this.scheduledFor,
  );
}

class DoctorPostDraft {
  Map<String, dynamic> toDb() => {
    'id': id,
    'title': title,
    'content': content,
    'coverAsset': coverAsset,
    'attachmentAssets': attachmentAssets.map((v) => v).toList(),
    'category': category,
    'audience': audience,
    'updatedAt': updatedAt.toIso8601String(),
  };
  static DoctorPostDraft fromDb(Map<String, dynamic> data) {
    final value = DoctorPostDraft(
      id: data['id'] as String? ?? 'draft',
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      coverAsset: data['coverAsset'] as String? ?? '',
      attachmentAssets: (data['attachmentAssets'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      category: data['category'] as String? ?? 'Pet Health',
      audience: data['audience'] as String? ?? 'All Pets',
      updatedAt:
          DateTime.tryParse(data['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
    return value;
  }

  DoctorPostDraft({
    this.id = 'draft',
    required this.title,
    required this.content,
    required this.coverAsset,
    required this.attachmentAssets,
    this.category = 'Pet Health',
    this.audience = 'All Pets',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String title;
  final String content;
  final String coverAsset;
  final List<String> attachmentAssets;
  final String category;
  final String audience;
  final DateTime updatedAt;

  DoctorPost asPost() => DoctorPost(
    id: 'draft',
    title: title.isEmpty ? 'Untitled draft' : title,
    content: content.isEmpty ? 'No post content yet.' : content,
    coverAsset: coverAsset,
    attachmentAssets: attachmentAssets,
    createdAt: DateTime.now(),
    updatedAt: updatedAt,
    category: category,
    audience: audience,
    status: 'draft',
  );
}

class DoctorPostStore extends ChangeNotifier {
  void connectDatabase() {
    DatabaseSync.instance.bind(
      'health_post_drafts',
      this,
      () => {
        for (final draft in _drafts)
          databaseRecordKey(draft, draft.id): draft.toDb(),
      },
      (rows) {
        _drafts
          ..clear()
          ..addAll(
            rows.entries.map(
              (entry) => databaseRestoreKey(
                DoctorPostDraft.fromDb(entry.value),
                entry.key,
              ),
            ),
          );
      },
    );
    DatabaseSync.instance.bind(
      'health_posts',
      this,
      () => {
        for (final item in _posts)
          databaseRecordKey(item, item.id): item.toDb(),
      },
      (rows) {
        _posts
          ..clear()
          ..addAll(
            rows.entries.map(
              (e) => databaseRestoreKey(DoctorPost.fromDb(e.value), e.key),
            ),
          )
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      },
    );
  }

  DoctorPostStore._();

  static final instance = DoctorPostStore._();

  static const defaultCover = 'assets/photos/logoandphoto/pets_transparent.png';
  static const gallery = [
    'assets/photos/logoandphoto/nways_photo.png',
    'assets/photos/logoandphoto/pets_row.png',
    'assets/photos/logoandphoto/nways_pets.png',
  ];

  final List<DoctorPost> _posts = [
    DoctorPost(
      id: 'welcome-post',
      title: '🐶 A Dog’s Love Is Forever',
      content:
          'Dogs are more than just pets—they’re family. ❤️\n'
          'From the excited tail wags when you come home to the quiet moments by your side, they have a special way of making every day better.\n'
          'Give your furry friend the love, care, and attention they deserve. 🐾\n'
          'Because to your dog, you are their whole world. 🐕💛\n'
          '#DogLove #DogsOfInstagram\n'
          '#PetLove #DogLife #FurryFriend\n'
          '#DogsAreFamily',
      coverAsset: defaultCover,
      attachmentAssets: gallery,
      createdAt: DateTime(2026, 6, 12),
    ),
  ];
  final List<DoctorPostDraft> _drafts = [];

  List<DoctorPost> get posts =>
      List.unmodifiable(_posts.where((post) => post.isPublished));
  List<DoctorPost> get allPosts => List.unmodifiable(_posts);
  List<DoctorPostDraft> get drafts => List.unmodifiable(
    [..._drafts]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
  );
  DoctorPostDraft? get draft => drafts.firstOrNull;

  void saveDraft(DoctorPostDraft draft) {
    final index = _drafts.indexWhere((item) => item.id == draft.id);
    if (index < 0) {
      _drafts.add(draft);
    } else {
      final key = databaseKeyOf(_drafts[index]);
      _drafts[index] = key == null ? draft : databaseRestoreKey(draft, key);
    }
    notifyListeners();
  }

  void deleteDraft(String id) {
    _drafts.removeWhere((draft) => draft.id == id);
    notifyListeners();
  }

  DoctorPost publish({
    required String title,
    required String content,
    required String coverAsset,
    required List<String> attachmentAssets,
    required String category,
    required String audience,
    String? draftId,
    DoctorPost? replacing,
    DateTime? scheduledFor,
  }) {
    final now = DateTime.now();
    final profile = DoctorProfileStore.instance.data;
    var post = DoctorPost(
      id: replacing?.id ?? 'POST-${now.microsecondsSinceEpoch}',
      title: title,
      content: content,
      coverAsset: coverAsset,
      attachmentAssets: List.unmodifiable(attachmentAssets),
      createdAt: replacing?.createdAt ?? now,
      updatedAt: now,
      authorId: replacing?.authorId.isNotEmpty == true
          ? replacing!.authorId
          : ClinicApi.instance.accountId,
      authorName: replacing?.authorName.isNotEmpty == true
          ? replacing!.authorName
          : (profile.name.isEmpty ? 'Clinic Veterinarian' : profile.name),
      authorSpecialty: replacing?.authorSpecialty.isNotEmpty == true
          ? replacing!.authorSpecialty
          : profile.specialty,
      authorPhoto: replacing?.authorPhoto ?? profile.photoUrl,
      category: category,
      audience: audience,
      status: scheduledFor != null && scheduledFor.isAfter(now)
          ? 'scheduled'
          : 'published',
      scheduledFor: scheduledFor,
    );
    if (replacing == null) {
      _posts.insert(0, post);
    } else {
      final index = _posts.indexOf(replacing);
      final key = databaseKeyOf(replacing);
      if (key != null) post = databaseRestoreKey(post, key);
      if (index >= 0) _posts[index] = post;
    }
    if (draftId != null) _drafts.removeWhere((draft) => draft.id == draftId);
    notifyListeners();
    return post;
  }

  void archive(DoctorPost post) =>
      _replace(post, post.copyWith(status: 'archived'));

  void restore(DoctorPost post) =>
      _replace(post, post.copyWith(status: 'published'));

  void deletePost(DoctorPost post) {
    _posts.remove(post);
    notifyListeners();
  }

  void restorePostSnapshot(DoctorPost post) {
    final index = _posts.indexWhere((item) => item.id == post.id);
    if (index < 0) {
      _posts.insert(0, post);
    } else {
      final key = databaseKeyOf(_posts[index]);
      _posts[index] = key == null ? post : databaseRestoreKey(post, key);
    }
    notifyListeners();
  }

  void _replace(DoctorPost old, DoctorPost next) {
    final index = _posts.indexOf(old);
    if (index < 0) return;
    final key = databaseKeyOf(old);
    _posts[index] = key == null ? next : databaseRestoreKey(next, key);
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    if (_posts.length > 1) _posts.removeRange(0, _posts.length - 1);
    _drafts.clear();
    notifyListeners();
  }
}

class DoctorAppointmentStore extends ChangeNotifier {
  DoctorAppointmentStore._();

  static final instance = DoctorAppointmentStore._();
  void connectDatabase() {
    DatabaseSync.instance.bind(
      'doctor_appointment_state',
      this,
      () => {for (final e in _persisted.entries) e.key: e.value.toMap()},
      (rows) {
        _demoRecords.clear();
        _persisted
          ..clear()
          ..addAll(
            rows.map((k, v) => MapEntry(k, DoctorAppointmentState.fromMap(v))),
          );
        _loaded = true;
        _loading = false;
      },
    );
  }

  static String get doctorName => ClinicApi.instance.token == null
      ? 'Dr. Aye Chan'
      : ClinicApi.instance.account?['fullName'] as String? ?? '';

  final List<DoctorAppointmentRecord> _demoRecords = [];

  final _repository = DoctorAppointmentRepository.instance;

  /// Persisted doctor-side state loaded from Database, keyed by appointment id.
  final Map<String, DoctorAppointmentState> _persisted = {};
  bool _loaded = false;
  bool _loading = false;

  bool get isSyncedWithDatabase => _loaded;

  /// Loads persisted appointment state from Database and applies it to the
  /// current records. Safe to call repeatedly; only fetches once per session
  /// unless [force] is set.
  Future<void> loadPersistedState({bool force = false}) async {
    if (_loading || (_loaded && !force)) return;
    _loading = true;
    final loaded = await _repository.loadAll();
    _persisted
      ..clear()
      ..addAll(loaded);
    _loaded = true;
    _loading = false;
    if (loaded.isNotEmpty) {
      _applyPersistedState();
      notifyListeners();
    }
  }

  /// Applies any persisted state onto the live records (demo records get their
  /// status restored; every record gets its saved clinical notes back).
  void _applyPersistedState() {
    for (final record in _demoRecords) {
      final state = _persisted[record.id];
      if (state == null) continue;
      _restore(record, state);
      if (state.status != null) record.status = state.status!;
    }
  }

  void _restore(DoctorAppointmentRecord record, DoctorAppointmentState state) {
    record
      ..consultationNotes = state.consultationNotes
      ..diagnosis = state.diagnosis
      ..treatment = state.treatment
      ..prescription = state.prescription
      ..vaccination = state.vaccination
      ..nextDoseDate = state.nextDoseDate
      ..followUp = state.followUp
      ..rescheduleNote = state.rescheduleNote;
  }

  void ensureDemoSchedule() {
    if (ClinicApi.instance.token != null || _demoRecords.isNotEmpty) return;
    final today = DateTime.now();
    _demoRecords.addAll([
      DoctorAppointmentRecord(
        id: 'DOC-${today.year}${today.month}${today.day}-01',
        petName: 'Bruno',
        petDetails: 'Dog • Pug',
        ownerName: 'Lynn Kyaw',
        service: 'General Checkup',
        date: today,
        time: '9:00 AM',
        reason: 'Routine health assessment',
        symptoms: 'Reduced appetite',
        initialStatus: 'Confirmed',
      ),
      DoctorAppointmentRecord(
        id: 'DOC-${today.year}${today.month}${today.day}-02',
        petName: 'Mimi',
        petDetails: 'Cat • Ragdoll',
        ownerName: 'May Zin',
        service: 'Vaccination',
        date: today,
        time: '11:00 AM',
        reason: 'Annual vaccination',
        symptoms: 'No current symptoms',
        initialStatus: 'Pending',
      ),
      DoctorAppointmentRecord(
        id: 'DOC-${today.year}${today.month}${today.day}-03',
        petName: 'Sugar',
        petDetails: 'Dog • Pomeranian',
        ownerName: 'Thiri Win',
        service: 'Follow-up',
        date: today.add(const Duration(days: 1)),
        time: '2:00 PM',
        reason: 'Treatment follow-up',
        symptoms: 'Skin irritation improving',
        initialStatus: 'Confirmed',
      ),
    ]);
  }

  List<DoctorAppointmentRecord> get appointments {
    ensureDemoSchedule();
    final ownerRecords = AppointmentStore.instance.appointments
        .where((appointment) => appointment.veterinarian == doctorName)
        .where(
          (appointment) =>
              !_demoRecords.any((record) => record.id == appointment.id),
        )
        .map((booking) {
          final record = DoctorAppointmentRecord.fromBooking(booking);
          // Reattach any saved clinical notes to freshly-mapped bookings so a
          // completed consultation survives a restart. Status stays owned by
          // AppointmentStore for real bookings.
          final state = _persisted[record.id];
          if (state != null) _restore(record, state);
          return record;
        });
    final result = [..._demoRecords, ...ownerRecords];
    result.sort((a, b) {
      final dateComparison = a.date.compareTo(b.date);
      return dateComparison != 0
          ? dateComparison
          : _timeMinutes(a.time).compareTo(_timeMinutes(b.time));
    });
    return result;
  }

  void updateStatus(DoctorAppointmentRecord record, String status) {
    if (record.source case final source?) {
      AppointmentStore.instance.staffSetStatus(source, status);
    } else {
      record.status = status;
    }
    notifyListeners();
    persist(record);
  }

  /// Persists a record's doctor-side state to PostgreSQL (fire-and-forget). Also
  /// updates the local cache so it survives list rebuilds within the session.
  Future<void> persist(DoctorAppointmentRecord record) async {
    final state = DoctorAppointmentState.fromRecord(record);
    _persisted[record.id] = state;
    notifyListeners();
    await _repository.save(record.id, state);
  }

  @visibleForTesting
  void clearDemoSchedule() {
    _demoRecords.clear();
    notifyListeners();
  }
}

class DoctorMedicalRecord {
  Map<String, dynamic> toDb() => {
    'id': id,
    'appointmentId': appointmentId,
    'petName': petName,
    'ownerName': ownerName,
    'service': service,
    'date': date.toIso8601String(),
    'symptoms': symptoms,
    'findings': findings,
    'diagnosis': diagnosis,
    'treatment': treatment,
    'prescription': prescription,
    'vaccination': vaccination,
    'nextDoseDate': nextDoseDate,
    'followUp': followUp,
    'testResult': testResult,
    'finalized': finalized,
  };
  static DoctorMedicalRecord fromDb(Map<String, dynamic> data) {
    final value = DoctorMedicalRecord(
      id: data['id'] as String,
      appointmentId: data['appointmentId'] as String,
      petName: data['petName'] as String,
      ownerName: data['ownerName'] as String,
      service: data['service'] as String,
      date: DateTime.parse(data['date'] as String),
      symptoms: data['symptoms'] as String,
      findings: data['findings'] as String,
      diagnosis: data['diagnosis'] as String,
      treatment: data['treatment'] as String,
      prescription: data['prescription'] as String,
      vaccination: data['vaccination'] as String,
      nextDoseDate: data['nextDoseDate'] as String,
      followUp: data['followUp'] as String,
      testResult: data['testResult'] as String,
      finalized: data['finalized'] as bool,
    );
    return value;
  }

  DoctorMedicalRecord({
    required this.id,
    required this.appointmentId,
    required this.petName,
    required this.ownerName,
    required this.service,
    required this.date,
    required this.symptoms,
    required this.findings,
    required this.diagnosis,
    required this.treatment,
    required this.prescription,
    required this.vaccination,
    required this.nextDoseDate,
    required this.followUp,
    required this.testResult,
    required this.finalized,
  });

  final String id;
  final String appointmentId;
  final String petName;
  final String ownerName;
  final String service;
  final DateTime date;
  final String symptoms;
  String findings;
  String diagnosis;
  String treatment;
  String prescription;
  String vaccination;
  String nextDoseDate;
  String followUp;
  String testResult;
  bool finalized;
}

class DoctorMedicalRecordStore extends ChangeNotifier {
  void connectDatabase() {
    DatabaseSync.instance.bind(
      'medical_records',
      this,
      () => {
        for (final item in _records)
          databaseRecordKey(item, item.id): item.toDb(),
      },
      (rows) {
        _records
          ..clear()
          ..addAll(
            rows.entries.map(
              (e) => databaseRestoreKey(
                DoctorMedicalRecord.fromDb(e.value),
                e.key,
              ),
            ),
          );
      },
    );
  }

  DoctorMedicalRecordStore._();

  static final instance = DoctorMedicalRecordStore._();
  final List<DoctorMedicalRecord> _records = [];

  List<DoctorMedicalRecord> get records => List.unmodifiable(_records.reversed);

  List<DoctorMedicalRecord> recordsFor(String petName) => _records
      .where(
        (record) =>
            record.petName.toLowerCase() == petName.toLowerCase() &&
            record.finalized,
      )
      .toList();

  void saveFromConsultation(
    DoctorAppointmentRecord appointment, {
    required bool finalized,
    required String testResult,
  }) {
    final existing = _records.cast<DoctorMedicalRecord?>().firstWhere(
      (record) => record?.appointmentId == appointment.id,
      orElse: () => null,
    );
    if (existing == null) {
      _records.add(
        DoctorMedicalRecord(
          id: 'MED-${appointment.id}',
          appointmentId: appointment.id,
          petName: appointment.petName,
          ownerName: appointment.ownerName,
          service: appointment.service,
          date: DateTime.now(),
          symptoms: appointment.symptoms,
          findings: appointment.consultationNotes,
          diagnosis: appointment.diagnosis,
          treatment: appointment.treatment,
          prescription: appointment.prescription,
          vaccination: appointment.vaccination,
          nextDoseDate: appointment.nextDoseDate,
          followUp: appointment.followUp,
          testResult: testResult,
          finalized: finalized,
        ),
      );
    } else {
      existing
        ..findings = appointment.consultationNotes
        ..diagnosis = appointment.diagnosis
        ..treatment = appointment.treatment
        ..prescription = appointment.prescription
        ..vaccination = appointment.vaccination
        ..nextDoseDate = appointment.nextDoseDate
        ..followUp = appointment.followUp
        ..testResult = testResult
        ..finalized = finalized;
    }
    notifyListeners();
  }

  @visibleForTesting
  void clear() {
    _records.clear();
    notifyListeners();
  }
}

class DoctorNotification {
  Map<String, dynamic> toDb() => {
    'title': title,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
  };
  static DoctorNotification fromDb(Map<String, dynamic> data) {
    final value = DoctorNotification(
      title: data['title'] as String,
      message: data['message'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
      read: data['read'] as bool,
    );
    return value;
  }

  DoctorNotification({
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
  });

  final String title;
  final String message;
  final DateTime createdAt;
  bool read;
}

class DoctorNotificationStore extends ChangeNotifier {
  void connectDatabase() {
    DatabaseSync.instance.bind(
      'doctor_notifications',
      this,
      () => {
        for (final item in _notifications)
          databaseRecordKey(item, item.createdAt.toIso8601String()): item
              .toDb(),
      },
      (rows) {
        _notifications
          ..clear()
          ..addAll(
            rows.entries.map(
              (e) =>
                  databaseRestoreKey(DoctorNotification.fromDb(e.value), e.key),
            ),
          );
      },
    );
  }

  DoctorNotificationStore._();

  static final instance = DoctorNotificationStore._();
  final List<DoctorNotification> _notifications = [];

  List<DoctorNotification> get notifications =>
      List.unmodifiable(_notifications.reversed);
  int get unreadCount => _notifications.where((item) => !item.read).length;

  void add(String title, String message) {
    _notifications.add(
      DoctorNotification(
        title: title,
        message: message,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void markAllRead() {
    for (final item in _notifications) {
      item.read = true;
    }
    notifyListeners();
  }
}
