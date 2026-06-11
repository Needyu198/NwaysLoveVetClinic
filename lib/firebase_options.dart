import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase is not configured yet. Run `flutterfire configure` and create '
      'the Firebase Auth user Lynn198@nway.local.',
    );
  }
}
