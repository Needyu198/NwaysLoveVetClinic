import '../data/clinic_api.dart';

class DoctorAuthApi {
  const DoctorAuthApi();

  static const demoEmail = 'doctor@nwaysclinic.com';
  static const demoUsername = 'doctor';
  static const demoPassword = 'Doctor@123';

  static bool handlesIdentifier(String identifier) {
    final normalized = identifier.trim().toLowerCase();
    return normalized == demoEmail || normalized == demoUsername;
  }

  Future<DoctorLoginResult> login({
    required String username,
    required String password,
  }) async {
    try {
      final role = await ClinicApi.instance.login(username, password);
      if (role == 'doctor') return const DoctorLoginResult.success();
      await ClinicApi.instance.logout();
      return const DoctorLoginResult.failure(
        'This account has a different role.',
      );
    } catch (e) {
      return DoctorLoginResult.failure(e.toString());
    }
  }
}

class DoctorLoginResult {
  const DoctorLoginResult._({required this.isSuccess, required this.message});

  const DoctorLoginResult.success() : this._(isSuccess: true, message: '');

  const DoctorLoginResult.failure(String message)
    : this._(isSuccess: false, message: message);

  final bool isSuccess;
  final String message;
}
