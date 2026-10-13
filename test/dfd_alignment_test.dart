import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/data/clinic_api.dart';
import 'package:senior_project/data/clinic_directory.dart';
import 'package:senior_project/doctor/doctor_portal.dart';
import 'package:senior_project/pet_owner/appointment_booking_page.dart';
import 'package:senior_project/pet_owner/contact_clinic_page.dart';
import 'package:senior_project/pet_owner/profile_flows.dart';
import 'package:senior_project/staff/staff_portal.dart';

void main() {
  testWidgets('appointment booking lists only available veterinarians', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    ClinicApi.instance.token = 'test-token';
    ProfilePetStore.instance.reset();
    ProfilePetStore.instance.add(_profilePet('Milo'));
    ClinicDirectory.instance.replaceForTesting({
      'available-doctor': {
        'id': 'available-doctor',
        'name': 'Dr. Available',
        'role': 'doctor',
        'available': true,
      },
      'unavailable-doctor': {
        'id': 'unavailable-doctor',
        'name': 'Dr. Unavailable',
        'role': 'doctor',
        'available': false,
      },
    });
    addTearDown(() {
      ClinicApi.instance.token = null;
      ProfilePetStore.instance.reset();
      ClinicDirectory.instance.replaceForTesting({});
    });

    await tester.pumpWidget(const MaterialApp(home: AppointmentBookingPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Milo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('General Checkup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find Veterinarians'));
    await tester.pumpAndSettle();

    expect(find.text('Dr. Available'), findsOneWidget);
    expect(find.text('Dr. Unavailable'), findsNothing);
  });

  testWidgets('staff updates only administrative medical-record details', (
    tester,
  ) async {
    final record = DoctorMedicalRecord(
      id: 'MED-DFD',
      appointmentId: 'APT-DFD',
      petName: 'Milo',
      ownerName: 'Test Owner',
      service: 'General Checkup',
      date: DateTime(2026, 10, 13),
      symptoms: 'Low appetite',
      findings: 'Clinical finding',
      diagnosis: 'Clinical diagnosis',
      treatment: 'Clinical treatment',
      prescription: 'Clinical prescription',
      vaccination: '',
      nextDoseDate: '',
      followUp: 'Doctor follow-up',
      testResult: '',
      finalized: true,
    );
    await tester.pumpWidget(
      MaterialApp(home: StaffMedicalRecordDetailPage(record: record)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('staff-edit-medical-administration')),
      400,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('staff-edit-medical-administration')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('staff-medical-administrative-notes')),
      'Owner contacted; follow-up arranged.',
    );
    await tester.tap(
      find.byKey(const ValueKey('staff-save-medical-administration')),
    );
    await tester.pumpAndSettle();

    expect(record.administrativeNotes, 'Owner contacted; follow-up arranged.');
    expect(record.diagnosis, 'Clinical diagnosis');
    expect(find.text('Owner contacted; follow-up arranged.'), findsOneWidget);
  });

  testWidgets('staff messaging opens an owner conversation before replying', (
    tester,
  ) async {
    ContactClinicStore.instance.clear();
    addTearDown(ContactClinicStore.instance.clear);
    ContactClinicStore.instance.send(
      text: 'Milo needs an appointment.',
      category: ContactCategory.appointment,
      petName: 'Milo',
    );

    await tester.pumpWidget(
      const MaterialApp(home: StaffMessagesPage(standalone: true)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('staff-conversation-list')),
      findsOneWidget,
    );
    await tester.tap(find.text('Milo owner'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('staff-conversation-thread')),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'Please come at 10:00 AM.');
    await tester.tap(
      find.byKey(const ValueKey('staff-send-conversation-reply')),
    );
    await tester.pump();
    expect(find.text('Please come at 10:00 AM.'), findsOneWidget);
  });
}

ProfilePet _profilePet(String name) => ProfilePet(
  name: name,
  type: 'Cat',
  breed: 'Domestic Shorthair',
  sex: 'Male',
  dateOfBirth: DateTime(2022, 1, 1),
  weightKg: 4.2,
  color: 'Orange',
  identifyingFeatures: '',
  allergies: 'None',
  conditions: 'None',
  medicines: 'None',
  vaccination: 'Up to date',
);
