import '../data/clinic_api.dart';

class StaffAuthApi {
  const StaffAuthApi();

  static const demoEmail = 'staff@nwaysclinic.com';
  static const demoUsername = 'staff';
  static const demoPassword = 'Staff@123';

  static bool handlesIdentifier(String identifier) {
    final normalized = identifier.trim().toLowerCase();
    return normalized == demoEmail || normalized == demoUsername;
  }

  Future<StaffLoginResult> login({
    required String username,
    required String password,
  }) async {
    try {
      final role = await ClinicApi.instance.login(username, password);
      if (role == 'staff') return const StaffLoginResult.success();
      await ClinicApi.instance.logout();
      return const StaffLoginResult.failure(
        'This account has a different role.',
      );
    } catch (e) {
      return StaffLoginResult.failure(e.toString());
    }
  }
}

class StaffLoginResult {
  const StaffLoginResult._({required this.isSuccess, required this.message});

  const StaffLoginResult.success() : this._(isSuccess: true, message: '');

  const StaffLoginResult.failure(String message)
    : this._(isSuccess: false, message: message);

  final bool isSuccess;
  final String message;
}
