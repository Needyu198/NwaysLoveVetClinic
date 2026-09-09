part of 'system_admin_portal.dart';

/// Roles an account can hold in the clinic system.
enum AdminUserRole { owner, doctor, staff, admin }

extension AdminUserRoleLabel on AdminUserRole {
  String get label => switch (this) {
    AdminUserRole.owner => 'Pet Owner',
    AdminUserRole.doctor => 'Doctor',
    AdminUserRole.staff => 'Staff',
    AdminUserRole.admin => 'Administrator',
  };

  IconData get icon => switch (this) {
    AdminUserRole.owner => Icons.pets_rounded,
    AdminUserRole.doctor => Icons.medical_services_rounded,
    AdminUserRole.staff => Icons.badge_rounded,
    AdminUserRole.admin => Icons.admin_panel_settings_rounded,
  };
}

/// Account lifecycle: Pending -> Active -> Suspended -> Reactivated (Active).
enum AdminAccountStatus { pending, active, suspended }

extension AdminAccountStatusLabel on AdminAccountStatus {
  String get label => switch (this) {
    AdminAccountStatus.pending => 'Pending',
    AdminAccountStatus.active => 'Active',
    AdminAccountStatus.suspended => 'Suspended',
  };

  Color get color => switch (this) {
    AdminAccountStatus.pending => const Color(0xFF9A5B00),
    AdminAccountStatus.active => _adminGreen,
    AdminAccountStatus.suspended => const Color(0xFFB3261E),
  };
}

/// A single system user account managed by the administrator.
class AdminUser {
  Map<String, dynamic> toDb() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.name,
    'status': status.name,
    'lastActive': lastActive,
    'createdOn': createdOn.toIso8601String(),
    // Sent once, only when provisioning a brand-new login. The backend uses it
    // to create the account's password and strips it before storing, so it is
    // never persisted or read back.
    if (password.isNotEmpty) 'password': password,
  };
  static AdminUser fromDb(Map<String, dynamic> data) {
    final value = AdminUser(
      id: data['id'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      phone: data['phone'] as String,
      role: AdminUserRole.values.byName(data['role'] as String),
      status: AdminAccountStatus.values.byName(data['status'] as String),
      lastActive: data['lastActive'] as String,
      createdOn: DateTime.parse(data['createdOn'] as String),
    );
    return value;
  }

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.status = AdminAccountStatus.active,
    this.lastActive = 'Today',
    this.password = '',
    DateTime? createdOn,
  }) : createdOn = createdOn ?? DateTime.now();

  final String id;
  String name;
  String email;
  String phone;
  AdminUserRole role;
  AdminAccountStatus status;
  String lastActive;
  final DateTime createdOn;

  /// Transient plaintext password, populated only when an admin creates a new
  /// account. Included in [toDb] once so the backend can provision the login,
  /// never restored by [fromDb].
  String password;
}

/// In-memory directory of every account in the system. Drives the Users and
/// Roles management screen and the dashboard user counts.
class UserAccountStore extends ChangeNotifier {
  void connectDatabase() {
    DatabaseSync.instance.bind(
      'user_directory',
      this,
      () => {
        for (final item in _users)
          databaseRecordKey(item, item.id): item.toDb(),
      },
      (rows) {
        _users
          ..clear()
          ..addAll(
            rows.entries.map(
              (e) => databaseRestoreKey(AdminUser.fromDb(e.value), e.key),
            ),
          );
      },
    );
  }

  UserAccountStore._() {
    _seed();
  }

  static final UserAccountStore instance = UserAccountStore._();

  final List<AdminUser> _users = [];

  List<AdminUser> get users => List.unmodifiable(_users);

  int countByRole(AdminUserRole role) =>
      _users.where((u) => u.role == role).length;

  int get pendingCount =>
      _users.where((u) => u.status == AdminAccountStatus.pending).length;

  void _seed() {
    _users.addAll([
      AdminUser(
        id: 'USR-1001',
        name: 'Lynn Htet',
        email: 'lynn.htet@email.com',
        phone: '09 421 555 018',
        role: AdminUserRole.owner,
        lastActive: 'Today',
      ),
      AdminUser(
        id: 'USR-1002',
        name: 'May Zin',
        email: 'may.zin@email.com',
        phone: '09 450 920 111',
        role: AdminUserRole.owner,
        lastActive: 'Yesterday',
      ),
      AdminUser(
        id: 'USR-1003',
        name: 'Nandar Moe',
        email: 'nandar.moe@email.com',
        phone: '09 770 123 882',
        role: AdminUserRole.owner,
        status: AdminAccountStatus.pending,
        lastActive: 'Never',
      ),
      AdminUser(
        id: 'DOC-2001',
        name: 'Dr. Aye Chan',
        email: 'aye.chan@nwaysclinic.com',
        phone: '09 771 004 220',
        role: AdminUserRole.doctor,
        lastActive: 'Today',
      ),
      AdminUser(
        id: 'DOC-2002',
        name: 'Dr. Cindy Lynn',
        email: 'cindy.lynn@nwaysclinic.com',
        phone: '09 655 200 143',
        role: AdminUserRole.doctor,
        lastActive: '2 hours ago',
      ),
      AdminUser(
        id: 'DOC-2003',
        name: 'Dr. Myat Noe',
        email: 'myat.noe@nwaysclinic.com',
        phone: '09 512 887 664',
        role: AdminUserRole.doctor,
        status: AdminAccountStatus.pending,
        lastActive: 'Never',
      ),
      AdminUser(
        id: 'STF-3001',
        name: 'Mya Thu',
        email: 'mya.thu@nwaysclinic.com',
        phone: '09 781 220 118',
        role: AdminUserRole.staff,
        lastActive: 'Today',
      ),
      AdminUser(
        id: 'STF-3002',
        name: 'Kaung Set',
        email: 'kaung.set@nwaysclinic.com',
        phone: '09 940 771 355',
        role: AdminUserRole.staff,
        status: AdminAccountStatus.suspended,
        lastActive: '1 week ago',
      ),
      AdminUser(
        id: 'ADM-9001',
        name: 'Mr. Admin',
        email: 'admin@nwaysclinic.com',
        phone: '09 400 000 001',
        role: AdminUserRole.admin,
        lastActive: 'Now',
      ),
    ]);
  }

  void addUser({
    required String name,
    required String email,
    required String phone,
    required AdminUserRole role,
    String password = '',
  }) {
    final prefix = switch (role) {
      AdminUserRole.owner => 'USR',
      AdminUserRole.doctor => 'DOC',
      AdminUserRole.staff => 'STF',
      AdminUserRole.admin => 'ADM',
    };
    final user = AdminUser(
      id: '$prefix-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      role: role,
      status: AdminAccountStatus.pending,
      lastActive: 'Never',
      password: password,
    );
    _users.insert(0, user);
    AuditLogStore.instance.record(
      action: 'Created account',
      module: 'Users and Roles',
      record: '${user.name} (${user.id})',
      newValue: '${role.label} • Pending',
      reason: 'New account provisioned',
    );
    notifyListeners();
  }

  void activate(AdminUser user) {
    final previous = user.status.label;
    user.status = AdminAccountStatus.active;
    user.lastActive = 'Today';
    AuditLogStore.instance.record(
      action: 'Activated account',
      module: 'Users and Roles',
      record: '${user.name} (${user.id})',
      previousValue: previous,
      newValue: 'Active',
      reason: 'Account approved for sign-in',
    );
    notifyListeners();
  }

  void suspend(AdminUser user, String reason) {
    final previous = user.status.label;
    user.status = AdminAccountStatus.suspended;
    AuditLogStore.instance.record(
      action: 'Suspended account',
      module: 'Users and Roles',
      record: '${user.name} (${user.id})',
      previousValue: previous,
      newValue: 'Suspended',
      reason: reason,
    );
    notifyListeners();
  }

  void changeRole(AdminUser user, AdminUserRole role, String reason) {
    final previous = user.role.label;
    user.role = role;
    AuditLogStore.instance.record(
      action: 'Changed role',
      module: 'Users and Roles',
      record: '${user.name} (${user.id})',
      previousValue: previous,
      newValue: role.label,
      reason: reason,
    );
    notifyListeners();
  }

  /// Permanently removes an account. Dropping it from the list makes
  /// DatabaseSync send a deletion, which the backend uses to delete the
  /// directory record and the underlying login.
  void deleteUser(AdminUser user, String reason) {
    _users.removeWhere((u) => u.id == user.id);
    AuditLogStore.instance.record(
      action: 'Deleted account',
      module: 'Users and Roles',
      record: '${user.name} (${user.id})',
      previousValue: user.status.label,
      newValue: 'Deleted',
      reason: reason,
    );
    notifyListeners();
  }
}

/// Doctor verification lifecycle per the spec:
/// Submitted -> Under Review -> Approved -> Active (or Rejected).
enum VerificationStatus { submitted, underReview, approved, rejected }

extension VerificationStatusLabel on VerificationStatus {
  String get label => switch (this) {
    VerificationStatus.submitted => 'Submitted',
    VerificationStatus.underReview => 'Under Review',
    VerificationStatus.approved => 'Approved',
    VerificationStatus.rejected => 'Rejected',
  };

  Color get color => switch (this) {
    VerificationStatus.submitted => const Color(0xFF2358A5),
    VerificationStatus.underReview => const Color(0xFF9A5B00),
    VerificationStatus.approved => _adminGreen,
    VerificationStatus.rejected => const Color(0xFFB3261E),
  };

  bool get isPending =>
      this == VerificationStatus.submitted ||
      this == VerificationStatus.underReview;
}

/// A doctor's professional verification application.
class DoctorApplication {
  Map<String, dynamic> toDb() => {
    'id': id,
    'name': name,
    'specialty': specialty,
    'email': email,
    'phone': phone,
    'licenseNumber': licenseNumber,
    'licenseExpiry': licenseExpiry.toIso8601String(),
    'qualifications': qualifications,
    'documents': documents.map((v) => v).toList(),
    'status': status.name,
    'decisionReason': decisionReason,
  };
  static DoctorApplication fromDb(Map<String, dynamic> data) {
    final value = DoctorApplication(
      id: data['id'] as String,
      name: data['name'] as String,
      specialty: data['specialty'] as String,
      email: data['email'] as String,
      phone: data['phone'] as String,
      licenseNumber: data['licenseNumber'] as String,
      licenseExpiry: DateTime.parse(data['licenseExpiry'] as String),
      qualifications: data['qualifications'] as String,
      documents: (data['documents'] as List).map((v) => v as String).toList(),
      status: VerificationStatus.values.byName(data['status'] as String),
      decisionReason: data['decisionReason'] as String,
    );
    return value;
  }

  DoctorApplication({
    required this.id,
    required this.name,
    required this.specialty,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.qualifications,
    required this.documents,
    this.status = VerificationStatus.submitted,
    this.decisionReason = '',
  });

  final String id;
  final String name;
  final String specialty;
  final String email;
  final String phone;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String qualifications;
  final List<String> documents;
  VerificationStatus status;
  String decisionReason;
}

/// In-memory store of doctor verification applications.
class DoctorVerificationStore extends ChangeNotifier {
  void connectDatabase() {
    DatabaseSync.instance.bind(
      'doctor_verifications',
      this,
      () => {
        for (final item in _applications)
          databaseRecordKey(item, item.id): item.toDb(),
      },
      (rows) {
        _applications
          ..clear()
          ..addAll(
            rows.entries.map(
              (e) =>
                  databaseRestoreKey(DoctorApplication.fromDb(e.value), e.key),
            ),
          );
      },
    );
  }

  DoctorVerificationStore._() {
    _seed();
  }

  static final DoctorVerificationStore instance = DoctorVerificationStore._();

  final List<DoctorApplication> _applications = [];

  List<DoctorApplication> get applications => List.unmodifiable(_applications);

  List<DoctorApplication> get pending =>
      _applications.where((a) => a.status.isPending).toList();

  int get pendingCount => pending.length;

  void _seed() {
    _applications.addAll([
      DoctorApplication(
        id: 'VER-5001',
        name: 'Dr. Myat Noe',
        specialty: 'Emergency & Critical Care',
        email: 'myat.noe@nwaysclinic.com',
        phone: '09 512 887 664',
        licenseNumber: 'VET-MM-2024-0091',
        licenseExpiry: DateTime.now().add(const Duration(days: 540)),
        qualifications: 'DVM, University of Veterinary Science, Yezin',
        documents: ['Veterinary License.pdf', 'DVM Certificate.pdf', 'CV.pdf'],
      ),
      DoctorApplication(
        id: 'VER-5002',
        name: 'Dr. Su Latt',
        specialty: 'Dermatology',
        email: 'su.latt@nwaysclinic.com',
        phone: '09 660 220 411',
        licenseNumber: 'VET-MM-2023-0450',
        licenseExpiry: DateTime.now().add(const Duration(days: 40)),
        qualifications: 'DVM, MSc Dermatology',
        documents: ['Veterinary License.pdf', 'Dermatology Certificate.pdf'],
        status: VerificationStatus.underReview,
      ),
    ]);
  }

  void approve(DoctorApplication application, String reason) {
    application.status = VerificationStatus.approved;
    application.decisionReason = reason;
    AuditLogStore.instance.record(
      action: 'Approved doctor',
      module: 'Doctor Verification',
      record: '${application.name} (${application.id})',
      previousValue: 'Pending',
      newValue: 'Approved • Active',
      reason: reason,
    );
    notifyListeners();
  }

  void reject(DoctorApplication application, String reason) {
    application.status = VerificationStatus.rejected;
    application.decisionReason = reason;
    AuditLogStore.instance.record(
      action: 'Rejected doctor',
      module: 'Doctor Verification',
      record: '${application.name} (${application.id})',
      previousValue: 'Pending',
      newValue: 'Rejected',
      reason: reason,
    );
    notifyListeners();
  }
}

/// A single immutable audit entry recording a sensitive admin action.
class AuditEntry {
  Map<String, dynamic> toDb() => {
    'id': id,
    'action': action,
    'module': module,
    'record': record,
    'actor': actor,
    'timestamp': timestamp.toIso8601String(),
    'previousValue': previousValue,
    'newValue': newValue,
    'reason': reason,
  };
  static AuditEntry fromDb(Map<String, dynamic> data) {
    final value = AuditEntry(
      id: data['id'] as String,
      action: data['action'] as String,
      module: data['module'] as String,
      record: data['record'] as String,
      actor: data['actor'] as String,
      timestamp: DateTime.parse(data['timestamp'] as String),
      previousValue: data['previousValue'] as String,
      newValue: data['newValue'] as String,
      reason: data['reason'] as String,
    );
    return value;
  }

  AuditEntry({
    required this.id,
    required this.action,
    required this.module,
    required this.record,
    required this.actor,
    required this.timestamp,
    this.previousValue = '',
    this.newValue = '',
    this.reason = '',
  });

  final String id;
  final String action;
  final String module;
  final String record;
  final String actor;
  final DateTime timestamp;
  final String previousValue;
  final String newValue;
  final String reason;
}

/// Central, append-only audit trail. Every admin action writes here so the
/// Audit Logs screen can display who did what, when, and why.
class AuditLogStore extends ChangeNotifier {
  void connectDatabase() {
    DatabaseSync.instance.bind(
      'audit_logs',
      this,
      () => {
        for (final item in _entries)
          databaseRecordKey(item, item.id): item.toDb(),
      },
      (rows) {
        _entries
          ..clear()
          ..addAll(
            rows.entries.map(
              (e) => databaseRestoreKey(AuditEntry.fromDb(e.value), e.key),
            ),
          );
      },
    );
  }

  AuditLogStore._() {
    _seed();
  }

  static final AuditLogStore instance = AuditLogStore._();

  final List<AuditEntry> _entries = [];

  List<AuditEntry> get entries => List.unmodifiable(_entries);

  void _seed() {
    final now = DateTime.now();
    _entries.addAll([
      AuditEntry(
        id: 'LOG-0001',
        action: 'Signed in',
        module: 'Authentication',
        record: 'Mr. Admin (ADM-9001)',
        actor: 'Mr. Admin',
        timestamp: now.subtract(const Duration(minutes: 8)),
        newValue: 'Session created',
      ),
      AuditEntry(
        id: 'LOG-0002',
        action: 'Suspended account',
        module: 'Users and Roles',
        record: 'Kaung Set (STF-3002)',
        actor: 'Mr. Admin',
        timestamp: now.subtract(const Duration(days: 7)),
        previousValue: 'Active',
        newValue: 'Suspended',
        reason: 'Extended leave of absence',
      ),
    ]);
  }

  void record({
    required String action,
    required String module,
    required String record,
    String actor = 'Mr. Admin',
    String previousValue = '',
    String newValue = '',
    String reason = '',
  }) {
    _entries.insert(
      0,
      AuditEntry(
        id: 'LOG-${DateTime.now().microsecondsSinceEpoch}',
        action: action,
        module: module,
        record: record,
        actor: actor,
        timestamp: DateTime.now(),
        previousValue: previousValue,
        newValue: newValue,
        reason: reason,
      ),
    );
    notifyListeners();
  }
}

/// A signed-in device/session shown under the admin Security screen.
class AdminSession {
  const AdminSession({
    required this.device,
    required this.location,
    required this.lastActive,
    this.current = false,
  });

  final String device;
  final String location;
  final String lastActive;
  final bool current;
}

/// Editable profile of the signed-in administrator. In-memory only (resets on
/// restart) but reactive so the whole profile UI reflects changes.
class AdminProfileStore extends ChangeNotifier {
  void connectDatabase() {
    DatabaseSync.instance.bind(
      'admin_profiles',
      this,
      () => {
        'profile': {
          'name': name,
          'phone': phone,
          'email': email,
          'photoPath': photoPath,
          'twoFactorEnabled': twoFactorEnabled,
          'approvalAlerts': approvalAlerts,
          'emergencyAlerts': emergencyAlerts,
          'systemAlerts': systemAlerts,
          'reportAlerts': reportAlerts,
        },
      },
      (rows) {
        final value = rows.isEmpty ? <String, dynamic>{} : rows.values.first;
        name = value['name'] as String? ?? '';
        phone = value['phone'] as String? ?? '';
        email = value['email'] as String? ?? '';
        photoPath = value['photoPath'] as String?;
        twoFactorEnabled = value['twoFactorEnabled'] as bool? ?? false;
        approvalAlerts = value['approvalAlerts'] as bool? ?? true;
        emergencyAlerts = value['emergencyAlerts'] as bool? ?? true;
        systemAlerts = value['systemAlerts'] as bool? ?? true;
        reportAlerts = value['reportAlerts'] as bool? ?? false;
      },
    );
  }

  AdminProfileStore._();

  static final AdminProfileStore instance = AdminProfileStore._();

  // Editable by the admin.
  String name = 'Mr. Admin';
  String email = 'admin@nwaysclinic.com';
  String phone = '09 400 000 001';
  String? photoPath;

  // Fixed / managed identity.
  final String role = 'System Administrator';
  final String adminId = 'ADM-9001';

  // Security.
  bool twoFactorEnabled = false;
  String _password = 'admin1234';

  // Notification preferences.
  bool approvalAlerts = true;
  bool emergencyAlerts = true;
  bool systemAlerts = true;
  bool reportAlerts = false;

  final List<AdminSession> sessions = const [
    AdminSession(
      device: 'This device • Web',
      location: 'Yangon, MM',
      lastActive: 'Active now',
      current: true,
    ),
    AdminSession(
      device: 'iPhone 14 • PawCare app',
      location: 'Yangon, MM',
      lastActive: '2 days ago',
    ),
    AdminSession(
      device: 'Windows PC • Chrome',
      location: 'Mandalay, MM',
      lastActive: '1 week ago',
    ),
  ];

  bool get passwordIsSet => _password.isNotEmpty;

  void save({
    required String name,
    required String email,
    required String phone,
    required String? photoPath,
  }) {
    this.name = name;
    this.email = email;
    this.phone = phone;
    this.photoPath = photoPath;
    AuditLogStore.instance.record(
      action: 'Updated profile',
      module: 'Admin Profile',
      record: '$name ($adminId)',
      newValue: '$email • $phone',
      reason: 'Self-service profile edit',
    );
    notifyListeners();
  }

  void setTwoFactor(bool enabled) {
    twoFactorEnabled = enabled;
    AuditLogStore.instance.record(
      action: enabled ? 'Enabled two-factor auth' : 'Disabled two-factor auth',
      module: 'Admin Profile',
      record: '$name ($adminId)',
      newValue: enabled ? 'Two-factor ON' : 'Two-factor OFF',
      reason: 'Security preference change',
    );
    notifyListeners();
  }

  bool changePassword(String current, String next) {
    if (current != _password) return false;
    _password = next;
    AuditLogStore.instance.record(
      action: 'Changed password',
      module: 'Admin Profile',
      record: '$name ($adminId)',
      newValue: 'Password updated',
      reason: 'Self-service password change',
    );
    notifyListeners();
    return true;
  }

  void updateNotifications({
    bool? approvals,
    bool? emergency,
    bool? system,
    bool? report,
  }) {
    if (approvals != null) approvalAlerts = approvals;
    if (emergency != null) emergencyAlerts = emergency;
    if (system != null) systemAlerts = system;
    if (report != null) reportAlerts = report;
    notifyListeners();
  }
}
