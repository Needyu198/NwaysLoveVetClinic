import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:senior_project/data/clinic_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    ClinicApi.instance.clientFactory = null;
    ClinicApi.instance.token = null;
    ClinicApi.instance.account = null;
  });

  test(
    'read-only API requests retry one transient connection failure',
    () async {
      var attempts = 0;
      ClinicApi.instance.clientFactory = () => MockClient((_) async {
        attempts++;
        if (attempts == 1) throw const SocketException('Wi-Fi route waking');
        return http.Response('{"records":[]}', 200);
      });

      final result = await ClinicApi.instance.request('GET', '/data/pets');

      expect(result['records'], isEmpty);
      expect(attempts, 2);
    },
  );

  test('mutating API requests are not retried', () async {
    var attempts = 0;
    ClinicApi.instance.clientFactory = () => MockClient((_) async {
      attempts++;
      throw const SocketException('connection dropped');
    });

    await expectLater(
      ClinicApi.instance.request('POST', '/devices/register', const {}),
      throwsA(isA<ClinicApiException>()),
    );
    expect(attempts, 1);
  });
}
