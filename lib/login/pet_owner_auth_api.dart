import '../data/clinic_api.dart';

class PetOwnerAuthApi {
  const PetOwnerAuthApi();
  Future<PetOwnerLoginResult> login({
    required String username,
    required String password,
  }) async {
    try {
      return PetOwnerLoginResult.success(
        await ClinicApi.instance.login(username, password),
      );
    } catch (e) {
      return PetOwnerLoginResult.failure(e.toString());
    }
  }
}

class PetOwnerLoginResult {
  const PetOwnerLoginResult._({
    required this.isSuccess,
    required this.message,
    this.role = 'petOwner',
  });

  const PetOwnerLoginResult.success([String role = 'petOwner'])
    : this._(isSuccess: true, message: '', role: role);

  const PetOwnerLoginResult.failure(String message)
    : this._(isSuccess: false, message: message);

  final String role;
  final bool isSuccess;
  final String message;
}
