import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:senior_project/data/clinic_api.dart';
import 'package:senior_project/data/database_stores.dart';
import 'package:senior_project/data/database_sync.dart';
import 'package:senior_project/data/realtime_client.dart';
import 'package:senior_project/system_admin/system_admin_portal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'admin Add User provisions the database login before succeeding',
    (tester) async {
      tester.view.physicalSize = const Size(440, 956);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Map<String, dynamic>? provisionedValue;
      ClinicApi.instance
        ..token = 'admin-token'
        ..account = {
          'id': 'admin-test',
          'role': 'systemAdmin',
          'fullName': 'Test Admin',
        }
        ..clientFactory = () => MockClient((request) async {
          if (request.url.path == '/auth/logout') {
            return http.Response(
              '{"ok":true}',
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          if (request.method == 'GET') {
            return http.Response(
              '{"records":[]}',
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final changes = body['changes'] as List<dynamic>;
          final records = <Map<String, dynamic>>[];
          for (final raw in changes) {
            final change = Map<String, dynamic>.from(raw as Map);
            final data = Map<String, dynamic>.from(change['data'] as Map);
            final value = Map<String, dynamic>.from(data['value'] as Map);
            if (request.url.path == '/data/user_directory/sync') {
              provisionedValue = Map<String, dynamic>.from(value);
              value.remove('password');
              data['value'] = value;
            }
            records.add({
              'id': change['id'],
              'owner_id': 'admin-test',
              'version': (change['version'] as int) + 1,
              'data': data,
            });
          }
          return http.Response(
            jsonEncode({'records': records}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });
      addTearDown(() async {
        if (DatabaseSync.instance.active) await DatabaseSync.instance.stop();
        ClinicApi.instance.clientFactory = null;
      });

      registerDatabaseStores();
      await DatabaseSync.instance.start();
      RealtimeClient.instance.disconnect();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminAddUserPage(),
                  ),
                ),
                child: const Text('Open add user'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open add user'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('admin-user-name')),
        'New Staff Member',
      );
      await tester.enterText(
        find.byKey(const ValueKey('admin-user-email')),
        'New.Staff@Clinic.Test',
      );
      await tester.enterText(
        find.byKey(const ValueKey('admin-user-phone')),
        '0912345678',
      );
      await tester.enterText(
        find.byKey(const ValueKey('admin-user-password')),
        'Secure@123',
      );
      await tester.enterText(
        find.byKey(const ValueKey('admin-user-confirm-password')),
        'Secure@123',
      );
      await tester.tap(find.byKey(const ValueKey('admin-user-role')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Staff').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('admin-save-user')));
      await tester.tap(find.byKey(const ValueKey('admin-save-user')));
      await tester.pumpAndSettle();

      expect(find.text('Open add user'), findsOneWidget);
      expect(provisionedValue, isNotNull);
      expect(provisionedValue!['email'], 'new.staff@clinic.test');
      expect(provisionedValue!['role'], 'staff');
      expect(provisionedValue!['status'], 'pending');
      expect(provisionedValue!['password'], 'Secure@123');
      final saved = UserAccountStore.instance.users.single;
      expect(saved.email, 'new.staff@clinic.test');
      expect(saved.password, isEmpty);
      await DatabaseSync.instance.stop();
      ClinicApi.instance.clientFactory = null;
    },
  );
}
