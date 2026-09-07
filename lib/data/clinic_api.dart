import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
  // LAN IP of the machine running the backend. Used by physical iOS/Android
  // devices, which cannot reach the host via 127.0.0.1.
  static const lanUrl = 'http://10.120.209.24:5050';
  String get baseUrl => configuredUrl.isNotEmpty
      ? configuredUrl.replaceAll(RegExp(r'/$'), '')
      : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:5050'
      : !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.android)
      ? lanUrl
      : 'http://127.0.0.1:5050';
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
    token = data['token'] as String;
    account = Map<String, dynamic>.from(data['account'] as Map);
    return role;
  }

  Future<void> logout() async {
    try {
      if (token != null) await request('POST', '/auth/logout');
    } finally {
      token = null;
      account = null;
    }
  }
}
