class SystemAdminAuthApi {
  const SystemAdminAuthApi();

  static const demoEmail = 'admin@nwaysclinic.com';
  static const demoUsername = 'admin';
  static const demoPassword = 'Admin@123';

  static bool handlesIdentifier(String identifier) {
    final normalized = identifier.trim().toLowerCase();
    return normalized == demoEmail || normalized == demoUsername;
  }

  Future<SystemAdminLoginResult> login({
    required String username,
    required String password,
  }) async {
    if (handlesIdentifier(username) && password == demoPassword) {
      return const SystemAdminLoginResult.success();
    }
    return const SystemAdminLoginResult.failure(
      'Invalid system administrator username or password.',
    );
  }
}

class SystemAdminLoginResult {
  const SystemAdminLoginResult._({
    required this.isSuccess,
    required this.message,
  });

  const SystemAdminLoginResult.success() : this._(isSuccess: true, message: '');

  const SystemAdminLoginResult.failure(String message)
    : this._(isSuccess: false, message: message);

  final bool isSuccess;
  final String message;
}
