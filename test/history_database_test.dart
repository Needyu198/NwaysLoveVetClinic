import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:senior_project/data/clinic_api.dart';
import 'package:senior_project/data/database_stores.dart';
import 'package:senior_project/data/database_sync.dart';
import 'package:senior_project/pet_owner/history_page.dart';
import 'package:senior_project/pet_owner/profile_flows.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'owner history reads pets and writes reviews through database sync',
    (tester) async {
      const ownerId = 'owner-history-test';
      final pet = ProfilePet(
        name: 'Zoe',
        type: 'Cat',
        breed: 'Siamese',
        sex: 'Female',
        dateOfBirth: DateTime(2022, 4, 8),
        weightKg: 4.2,
        color: 'Cream',
        identifyingFeatures: 'Blue eyes',
        allergies: 'None',
        conditions: 'None',
        medicines: 'None',
        vaccination: 'Current',
      );
      final database = <String, List<Map<String, dynamic>>>{
        'pets': [
          {
            'id': '$ownerId:zoe',
            'owner_id': ownerId,
            'version': 1,
            'data': {'key': 'zoe', 'value': pet.toDb()},
          },
        ],
      };

      ClinicApi.instance
        ..account = {'id': ownerId, 'role': 'petOwner'}
        ..token = 'history-test-token'
        ..clientFactory = () => MockClient((request) async {
          if (request.url.path == '/auth/logout') {
            return http.Response('{}', 200);
          }
          final table = request.url.pathSegments[1];
          final records = database.putIfAbsent(table, () => []);
          if (request.method == 'GET') {
            return http.Response(jsonEncode({'records': records}), 200);
          }

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final saved = <Map<String, dynamic>>[];
          for (final rawChange in body['changes'] as List) {
            final change = Map<String, dynamic>.from(rawChange as Map);
            final record = <String, dynamic>{
              'id': change['id'],
              'owner_id': ownerId,
              'version': (change['version'] as int) + 1,
              'data': change['data'],
            };
            records.add(record);
            saved.add(record);
          }
          return http.Response(jsonEncode({'records': saved}), 200);
        });

      registerDatabaseStores();
      await DatabaseSync.instance.start();

      await tester.pumpWidget(const MaterialApp(home: HistoryPage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('history-pet-Zoe')), findsOneWidget);
      expect(find.byKey(const ValueKey('history-pet-Max')), findsNothing);

      final synced = await HistoryReviewStore.instance.save(
        'visit-zoe',
        5,
        'Excellent care.',
      );
      expect(synced, isTrue);
      expect(database['history_reviews'], hasLength(1));

      // A fresh database session rehydrates the review, just like signing back
      // in on a restarted app.
      await DatabaseSync.instance.stop();
      ClinicApi.instance
        ..account = {'id': ownerId, 'role': 'petOwner'}
        ..token = 'history-test-token';
      await DatabaseSync.instance.start();
      expect(HistoryReviewStore.instance.reviewFor('visit-zoe'), (
        rating: 5,
        review: 'Excellent care.',
      ));

      await DatabaseSync.instance.stop();
      ClinicApi.instance.clientFactory = null;
    },
  );
}
