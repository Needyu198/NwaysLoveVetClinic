import 'doctor_auth_api.dart';
import 'pet_owner_auth_api.dart';
import 'system_admin_auth_api.dart';

enum AccountRole { petOwner, doctor, systemAdmin }

class AccountAuthApi {
  const AccountAuthApi({
    required this.petOwnerAuthApi,
    this.doctorAuthApi = const DoctorAuthApi(),
    this.systemAdminAuthApi = const SystemAdminAuthApi(),
  });

  final PetOwnerAuthApi petOwnerAuthApi;
  final DoctorAuthApi doctorAuthApi;
  final SystemAdminAuthApi systemAdminAuthApi;

  Future<AccountLoginResult> login({
    required String identifier,
    required String password,
  }) async {
    if (DoctorAuthApi.handlesIdentifier(identifier)) {
      final result = await doctorAuthApi.login(
        username: identifier,
        password: password,
      );
      return result.isSuccess
          ? const AccountLoginResult.success(AccountRole.doctor)
          : AccountLoginResult.failure(result.message);
    }

    if (SystemAdminAuthApi.handlesIdentifier(identifier)) {
      final result = await systemAdminAuthApi.login(
        username: identifier,
        password: password,
      );
      return result.isSuccess
          ? const AccountLoginResult.success(AccountRole.systemAdmin)
          : AccountLoginResult.failure(result.message);
    }

    final result = await petOwnerAuthApi.login(
      username: identifier,
      password: password,
    );
    return result.isSuccess
        ? const AccountLoginResult.success(AccountRole.petOwner)
        : AccountLoginResult.failure(result.message);
  }
}

class AccountLoginResult {
  const AccountLoginResult._({
    required this.isSuccess,
    required this.role,
    required this.message,
  });

  const AccountLoginResult.success(AccountRole role)
    : this._(isSuccess: true, role: role, message: '');

  const AccountLoginResult.failure(String message)
    : this._(isSuccess: false, role: null, message: message);

  final bool isSuccess;
  final AccountRole? role;
  final String message;
}
