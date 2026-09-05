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
    if (handlesIdentifier(username) && password == demoPassword) {
      return const StaffLoginResult.success();
    }
    return const StaffLoginResult.failure('Invalid staff email or password.');
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
