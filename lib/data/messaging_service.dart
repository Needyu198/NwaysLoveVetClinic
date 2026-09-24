import 'dart:async';

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
  bool _registrationInProgress = false;
  int _apnsRetryCount = 0;
  Timer? _apnsRetryTimer;

  FirebaseMessaging? get _messaging =>
      FirebaseService.instance.isAvailable ? FirebaseMessaging.instance : null;

  /// Request permission, fetch the token, register it, and set up listeners.
  Future<void> registerForPush() async {
    if (_registrationInProgress) return;
    final messaging = _messaging;
    if (messaging == null) return;
    _registrationInProgress = true;
    try {
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Push permission denied; skipping FCM registration.');
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      _wireListeners(messaging);

      // On Apple platforms the APNs token must exist before asking Firebase
      // for an FCM token. It often arrives shortly after permission is granted.
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        String? apnsToken;
        for (var attempt = 0; attempt < 10 && apnsToken == null; attempt++) {
          apnsToken = await messaging.getAPNSToken();
          if (apnsToken == null) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
          }
        }
        if (apnsToken == null) {
          _scheduleApnsRetry();
          return;
        }
        _apnsRetryCount = 0;
      }

      final token = await messaging.getToken();
      if (token == null) return;
      _token = token;
      await _register(token);
    } catch (e) {
      debugPrint('FCM registration error: $e');
    } finally {
      _registrationInProgress = false;
    }
  }

  void _wireListeners(FirebaseMessaging messaging) {
    if (_wired) return;
    _wired = true;
    messaging.onTokenRefresh.listen((token) {
      _token = token;
      _register(token);
    });
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Push received in foreground: ${message.notification?.title}');
    });
  }

  void _scheduleApnsRetry() {
    if (_apnsRetryCount >= 3 || _apnsRetryTimer?.isActive == true) {
      debugPrint('APNs token is not available; push registration postponed.');
      return;
    }
    _apnsRetryCount++;
    _apnsRetryTimer = Timer(
      Duration(seconds: 2 * _apnsRetryCount),
      registerForPush,
    );
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
    _apnsRetryTimer?.cancel();
    _apnsRetryTimer = null;
    _apnsRetryCount = 0;
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
