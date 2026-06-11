import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class PetOwnerAuthApi {
  const PetOwnerAuthApi({FirebaseAuth? firebaseAuth}) : this._(firebaseAuth);

  const PetOwnerAuthApi._(this._firebaseAuth);

  static const String usernameEmailDomain = 'nway.local';

  final FirebaseAuth? _firebaseAuth;

  Future<PetOwnerLoginResult> login({
    required String username,
    required String password,
  }) async {
    try {
      await _ensureFirebaseInitialized();

      await (_firebaseAuth ?? FirebaseAuth.instance).signInWithEmailAndPassword(
        email: _emailForUsername(username),
        password: password,
      );

      return const PetOwnerLoginResult.success();
    } on FirebaseAuthException catch (error) {
      return PetOwnerLoginResult.failure(_messageForFirebaseError(error));
    } on FirebaseException catch (error) {
      if (error.code == 'no-app') {
        return const PetOwnerLoginResult.failure(
          'Firebase is not configured yet. Run FlutterFire configuration first.',
        );
      }

      return PetOwnerLoginResult.failure(error.message ?? 'Firebase error.');
    } on UnsupportedError catch (error) {
      return PetOwnerLoginResult.failure(error.message ?? 'Firebase error.');
    }
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (_firebaseAuth != null || Firebase.apps.isNotEmpty) {
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static String _emailForUsername(String username) {
    final trimmedUsername = username.trim();
    if (trimmedUsername.contains('@')) {
      return trimmedUsername;
    }

    return '$trimmedUsername@$usernameEmailDomain';
  }

  static String _messageForFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid username or password.';
      case 'network-request-failed':
        return 'Cannot reach Firebase. Check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return error.message ?? 'Firebase login failed.';
    }
  }
}

class PetOwnerLoginResult {
  const PetOwnerLoginResult._({required this.isSuccess, required this.message});

  const PetOwnerLoginResult.success() : this._(isSuccess: true, message: '');

  const PetOwnerLoginResult.failure(String message)
    : this._(isSuccess: false, message: message);

  final bool isSuccess;
  final String message;
}
