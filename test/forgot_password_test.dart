import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:senior_project/data/clinic_api.dart';
import 'package:senior_project/main.dart';

void main() {
  tearDown(() {
    ClinicApi.instance.clientFactory = null;
  });

  testWidgets('forgot password requests a code and resets the password', (
    tester,
  ) async {
    final requests = <http.Request>[];
    ClinicApi.instance.clientFactory = () => MockClient((request) async {
      requests.add(request);
      if (request.url.path == '/auth/forgot-password') {
        return http.Response(
          jsonEncode({
            'message':
                'If an active account matches those details, a verification code has been sent to its registered email.',
          }),
          200,
        );
      }
      if (request.url.path == '/auth/reset-password') {
        return http.Response(jsonEncode({'ok': true}), 200);
      }
      return http.Response(jsonEncode({'message': 'Not found'}), 404);
    });

    await tester.pumpWidget(const NwayLoveVetClinicApp());
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('contact-field')),
      'owner@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('forgot-password')));
    await tester.pumpAndSettle();

    expect(find.text('Forgot Password'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('reset-identifier')))
          .controller
          ?.text,
      'owner@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('send-reset-code')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reset-code')), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('reset-code')), '123456');
    await tester.enterText(
      find.byKey(const ValueKey('reset-new-password')),
      'NewPassword@123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reset-confirm-password')),
      'NewPassword@123',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('confirm-password-reset')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-password-reset')));
    await tester.pumpAndSettle();

    expect(find.text('Password updated'), findsOneWidget);
    expect(requests.map((request) => request.url.path), [
      '/auth/forgot-password',
      '/auth/reset-password',
    ]);
    final resetBody = jsonDecode(requests.last.body) as Map<String, dynamic>;
    expect(resetBody['identifier'], 'owner@example.com');
    expect(resetBody['code'], '123456');
    expect(resetBody['newPassword'], 'NewPassword@123');
  });
}
