import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Thin wrapper around Firebase initialization and Firebase Authentication.
///
/// Firebase is treated as an optional layer: the app's authoritative auth and
/// authorization still come from the custom backend session ([ClinicApi]).
/// Firebase Auth is used to also register/sign in the user with the clinic's
/// Firebase project so features that depend on it (e.g. Cloud Messaging token
/// association, future Firestore usage) have an authenticated Firebase user.
///
/// Every method degrades gracefully: if Firebase is unavailable, the methods
/// return quietly so the backend login flow is never blocked.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _available = false;

  /// True when Firebase initialized successfully on this platform.
  bool get isAvailable => _available;

  FirebaseAuth? get _auth => _available ? FirebaseAuth.instance : null;

  /// Current Firebase user, or null when not signed in / unavailable.
  User? get currentUser => _auth?.currentUser;

  /// Initialize Firebase. Safe to call multiple times. Never throws.
  Future<void> ensureInitialized() async {
    if (_available) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _available = true;
    } catch (e) {
      _available = false;
      debugPrint('Firebase unavailable, continuing without it: $e');
    }
  }

  /// Sign in (or transparently register) a Firebase user with the given email
  /// and password. Returns true on success. Never throws; failures are logged
  /// and reported as false so the caller can continue on backend auth alone.
  ///
  /// The clinic backend uses usernames, not emails, so callers pass a synthetic
  /// email derived from the account (see [emailForIdentifier]).
  Future<bool> signInOrRegister({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) return false;
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        try {
          await auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          return true;
        } catch (e2) {
          debugPrint('Firebase register failed: $e2');
          return false;
        }
      }
      // Wrong password against an existing Firebase user, or other issues:
      // do not block the backend login, just report failure.
      debugPrint('Firebase sign-in failed: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('Firebase sign-in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Firebase sign-out error: $e');
    }
  }

  /// Backend accounts use usernames; Firebase requires an email. Map a username
  /// to a stable synthetic email in the clinic's domain when the identifier is
  /// not already an email address.
  static String emailForIdentifier(String identifier) {
    final id = identifier.trim().toLowerCase();
    if (id.contains('@')) return id;
    return '$id@users.nwayslovevetclinic.app';
  }
}
