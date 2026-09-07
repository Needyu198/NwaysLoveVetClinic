import '../data/clinic_api.dart';

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
    try {
      final role = await ClinicApi.instance.login(username, password);
      if (role == 'systemAdmin') return const SystemAdminLoginResult.success();
      await ClinicApi.instance.logout();
      return const SystemAdminLoginResult.failure(
        'This account has a different role.',
      );
    } catch (e) {
      return SystemAdminLoginResult.failure(e.toString());
    }
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
