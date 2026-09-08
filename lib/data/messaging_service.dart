import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'clinic_api.dart';
import 'firebase_service.dart';

/// Firebase Cloud Messaging (push notifications).
///
/// After login, [registerForPush] requests notification permission, obtains the
/// device's FCM token, and registers it with the backend (`/devices/register`)
/// so the server can push notifications to this device. All steps degrade
/// gracefully: if Firebase/messaging is unavailable or permission is denied,
/// the app keeps working with in-app notifications only.
class MessagingService {
  MessagingService._();
  static final MessagingService instance = MessagingService._();

  String? _token;
  bool _wired = false;

  FirebaseMessaging? get _messaging =>
      FirebaseService.instance.isAvailable ? FirebaseMessaging.instance : null;

  /// Request permission, fetch the token, register it, and set up listeners.
  Future<void> registerForPush() async {
    final messaging = _messaging;
    if (messaging == null) return;
    try {
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Push permission denied; skipping FCM registration.');
        return;
      }

      // On iOS the APNs token must be available before the FCM token.
      final token = await messaging.getToken();
      if (token == null) return;
      _token = token;
      await _register(token);

      if (!_wired) {
        _wired = true;
        messaging.onTokenRefresh.listen((t) {
          _token = t;
          _register(t);
        });
        FirebaseMessaging.onMessage.listen((message) {
          debugPrint(
            'Push received in foreground: ${message.notification?.title}',
          );
        });
      }
    } catch (e) {
      debugPrint('FCM registration error: $e');
    }
  }

  Future<void> _register(String token) async {
    try {
      await ClinicApi.instance.request('POST', '/devices/register', {
        'token': token,
        'platform': defaultTargetPlatform.name,
      });
    } catch (e) {
      debugPrint('Device token registration failed: $e');
    }
  }

  /// Remove this device's token from the backend and delete it locally.
  Future<void> unregister() async {
    final token = _token;
    if (token != null) {
      try {
        await ClinicApi.instance.request('POST', '/devices/unregister', {
          'token': token,
        });
      } catch (_) {
        /* best-effort */
      }
    }
    try {
      await _messaging?.deleteToken();
    } catch (_) {
      /* best-effort */
    }
    _token = null;
  }
}
