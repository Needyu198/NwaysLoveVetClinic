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
    if (handlesIdentifier(username) && password == demoPassword) {
      return const DoctorLoginResult.success();
    }
    return const DoctorLoginResult.failure(
      'Invalid doctor username or password.',
    );
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
