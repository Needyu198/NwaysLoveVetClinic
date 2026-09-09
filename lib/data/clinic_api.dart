import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'firebase_service.dart';

class ClinicApiException implements Exception {
  ClinicApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ClinicApi {
  ClinicApi._();
  static final instance = ClinicApi._();
  static const configuredUrl = String.fromEnvironment('API_BASE_URL');
  // Hosted backend (Render). Used automatically by the production web build and
  // as the default for release mobile builds.
  static const productionUrl = 'https://nwayslovevetclinic.onrender.com';
  // Address of the machine running the backend, used by physical iOS/Android
  // devices (which cannot reach the host via 127.0.0.1).
  //
  // We use the Mac's Bonjour/mDNS hostname instead of a raw IP because the IP
  // changes whenever the Mac reconnects to Wi-Fi, while the ".local" name stays
  // stable and is resolved automatically by devices on the same network.
  // To override at run time: --dart-define=API_BASE_URL=http://<host-or-ip>:5050
  static const lanUrl = 'http://Apples-MacBook-Air-2.local:5050';
  String get baseUrl {
    // Explicit override always wins (e.g. --dart-define=API_BASE_URL=...).
    if (configuredUrl.isNotEmpty) {
      return configuredUrl.replaceAll(RegExp(r'/$'), '');
    }
    // Web: decide from where the page itself is served so the same build
    // works both locally and in production without rebuilding.
    if (kIsWeb) {
      final host = Uri.base.host;
      final isLocal =
          host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0';
      return isLocal ? 'http://127.0.0.1:5050' : productionUrl;
    }
    // Android emulator reaches the host machine via 10.0.2.2.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return kReleaseMode ? productionUrl : 'http://10.0.2.2:5050';
    }
    // Physical iOS/Android devices on the same LAN (debug) or the hosted
    // backend (release).
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android) {
      return kReleaseMode ? productionUrl : lanUrl;
    }
    // Desktop / tests default to the local backend.
    return 'http://127.0.0.1:5050';
  }

  @visibleForTesting
  http.Client Function()? clientFactory;
  String? token;
  Map<String, dynamic>? account;
  String get accountId => account?['id'] as String? ?? '';
  String get role => account?['role'] as String? ?? '';

  Future<Map<String, dynamic>> request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.headers['Content-Type'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);
    final client = clientFactory?.call() ?? http.Client();
    try {
      final response = await http.Response.fromStream(
        await client.send(request),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        throw ClinicApiException(
          data['message'] as String? ?? 'Request failed.',
          response.statusCode,
        );
      }
      return data;
    } on ClinicApiException {
      rethrow;
    } catch (_) {
      throw ClinicApiException(
        'Cannot reach the clinic database. Check the API server and connection.',
      );
    } finally {
      client.close();
    }
  }

  Future<String> login(String username, String password) async {
    final data = await request('POST', '/auth/login', {
      'username': username,
      'password': password,
    });
    final token = data['token'];
    final account = data['account'];
    if (token is! String || account is! Map) {
      throw ClinicApiException(
        'Unexpected response from the server. Please try again.',
      );
    }
    this.token = token;
    this.account = Map<String, dynamic>.from(account);
    // Mirror the session into Firebase Auth (best-effort, never blocks login).
    // Fully isolated: any error (sync or async) is swallowed so it can never
    // affect the backend login result.
    scheduleMicrotask(() async {
      try {
        await FirebaseService.instance.signInOrRegister(
          email: FirebaseService.emailForIdentifier(username),
          password: password,
        );
      } catch (e) {
        debugPrint('Firebase mirror sign-in skipped: $e');
      }
    });
    return role;
  }

  Future<void> logout() async {
    try {
      if (token != null) await request('POST', '/auth/logout');
    } finally {
      token = null;
      account = null;
      scheduleMicrotask(() async {
        try {
          await FirebaseService.instance.signOut();
        } catch (_) {
          /* best-effort */
        }
      });
    }
  }
}
