import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:senior_project/data/clinic_api.dart';
import 'package:senior_project/data/database_stores.dart';
import 'package:senior_project/data/database_sync.dart';
import 'package:senior_project/pet_owner/appointment_booking_page.dart';
import 'package:senior_project/pet_owner/owner_shared_stores.dart';
import 'package:senior_project/staff/staff_portal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'booking, queue, reminder and inventory survive reload; failed saves remain pending',
    () async {
      final database = <String, Map<String, Map<String, dynamic>>>{};
      var failWrites = false;
      ClinicApi.instance.account = {
        'id': 'owner-test',
        'role': 'petOwner',
        'fullName': 'Test Owner',
      };
      ClinicApi.instance.token = 'test-token';
      ClinicApi.instance.clientFactory = () => MockClient((request) async {
        if (request.url.path == '/auth/logout') return http.Response('{}', 200);
        final table = request.url.pathSegments[1];
        final records = database.putIfAbsent(table, () => {});
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({'records': records.values.toList()}),
            200,
          );
        }
        if (failWrites) {
          return http.Response('{"message":"Database unavailable"}', 503);
        }
        final body = jsonDecode(request.body) as Map;
        final saved = <Map<String, dynamic>>[];
        for (final change in body['changes'] as List) {
          final existing = records[change['id']];
          if ((existing?['version'] ?? 0) != change['version']) {
            return http.Response('{"message":"Conflict"}', 409);
          }
          final record = <String, dynamic>{
            'id': change['id'],
            'owner_id': 'owner-test',
            'data': change['data'],
            'version': (change['version'] as int) + 1,
          };
          records[change['id'] as String] = record;
          saved.add(record);
        }
        for (final item in body['deletions'] as List) {
          records.remove(item['id']);
        }
        return http.Response(jsonEncode({'records': saved}), 200);
      });
      registerDatabaseStores();
      final sync = DatabaseSync.instance;
      await sync.start();
      expect(AppointmentStore.instance.appointments, isEmpty);
      expect(
        StaffOperationsStore.instance.inventory,
        isEmpty,
      ); // no demo stock is uploaded
      final booking = BookedAppointment(
        id: 'booking-test',
        createdAt: DateTime(2026, 9, 8),
        pet: const BookingPet(
          name: 'Milo',
          species: 'Dog',
          breed: 'Mixed',
          age: '2 years',
          icon: Icons.pets,
          color: Colors.brown,
        ),
        service: const BookingService(
          name: 'Checkup',
          description: 'Exam',
          icon: Icons.medical_services,
          homeVisit: false,
          doctors: ['Dr Test'],
        ),
        veterinarian: 'Dr Test',
        date: DateTime(2027, 1, 1),
        time: '10:00 AM',
        symptoms: 'None',
        reason: 'Checkup',
        notes: 'Bring records',
        address: '',
        status: 'Confirmed',
      );
      AppointmentStore.instance.add(booking);
      QueueStore.instance.entryFor(booking);
      ReminderStore.instance.addNew(
        title: 'Follow-up',
        type: ReminderType.checkup,
        dateTime: DateTime(2027, 1, 2),
        petName: 'Milo',
      );
      StaffOperationsStore.instance.inventory.add(
        InventoryItem(
          id: 'stock-test',
          name: 'Bandage',
          category: 'Supplies',
          quantity: 10,
          reorderLevel: 2,
          unit: 'roll',
          expiresOn: DateTime(2028),
        ),
      );
      // Existing staff mutations notify the store after editing its public inventory.
      StaffOperationsStore.instance.notifyListeners();
      await Future<void>.delayed(Duration.zero);
      await sync.flush();
      expect(sync.error, isNull);
      expect(database['appointments']!.length, 1);
      expect(database['queue_entries']!.length, 1);
      await sync.refresh();
      final restored = AppointmentStore.instance.appointments.single;
      expect(restored.pet.name, 'Milo');
      expect(restored.notes, 'Bring records');
      expect(
        identical(QueueStore.instance.active.single.appointment, restored),
        isTrue,
      );
      expect(ReminderStore.instance.reminders.single.title, 'Follow-up');
      expect(StaffOperationsStore.instance.inventory.single.quantity, 10);
      failWrites = true;
      AppointmentStore.instance.reschedule(
        restored,
        date: DateTime(2027, 1, 3),
        time: '11:00 AM',
      );
      await sync.flush();
      expect(sync.error, contains('Database unavailable'));
      expect(sync.pending, isTrue);
      await expectLater(sync.stop(), throwsA(isA<ClinicApiException>()));
      failWrites = false;
      await sync.flush();
      expect(sync.error, isNull);
      await sync.refresh();
      expect(AppointmentStore.instance.appointments.single.time, '11:00 AM');
      await sync.stop();
      expect(AppointmentStore.instance.appointments, isEmpty);
      expect(ClinicApi.instance.token, isNull);
      ClinicApi.instance.clientFactory = null;
    },
  );
}
