import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_project/doctor/doctor_portal.dart';
import 'package:senior_project/pet_owner/appointment_booking_page.dart';
import 'package:senior_project/pet_owner/home_visit_booking_page.dart';
import 'package:senior_project/pet_owner/profile_flows.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('doctor workflow pages show the owner-uploaded pet photo', (
    tester,
  ) async {
    final originalProfile = DoctorProfileStore.instance.data;
    addTearDown(() async {
      await DoctorProfileStore.instance.saveProfile(
        name: originalProfile.name,
        specialty: originalProfile.specialty,
        biography: originalProfile.biography,
        phone: originalProfile.phone,
        email: originalProfile.email,
        experience: originalProfile.experience,
      );
    });
    ProfilePetStore.instance.reset();
    AppointmentStore.instance.clear();
    DoctorMedicalRecordStore.instance.clear();
    HomeVisitStore.instance.clear();

    ProfilePetStore.instance.add(
      ProfilePet(
        name: 'Milo',
        type: 'Cat',
        breed: 'Siamese',
        sex: 'Male',
        dateOfBirth: DateTime(2022, 6, 15),
        weightKg: 4.5,
        color: 'Cream',
        identifyingFeatures: 'Blue eyes',
        allergies: 'None',
        conditions: 'None',
        medicines: 'None',
        vaccination: 'Current',
        hasCustomPhoto: true,
        photoUrl:
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );

    final booking = BookedAppointment(
      id: 'PHOTO-APPOINTMENT',
      createdAt: DateTime(2026, 9, 15),
      pet: const BookingPet(
        name: 'Milo',
        species: 'Cat',
        breed: 'Siamese',
        age: '4 years',
        icon: Icons.pets_rounded,
        color: Colors.teal,
      ),
      service: BookingService(
        name: 'General Checkup',
        description: 'Routine examination',
        icon: Icons.health_and_safety_outlined,
        homeVisit: false,
        doctors: [DoctorAppointmentStore.doctorName],
      ),
      veterinarian: DoctorAppointmentStore.doctorName,
      date: DateTime.now(),
      time: '12:01 AM',
      symptoms: 'Low appetite',
      reason: 'Checkup',
      notes: '',
      address: '',
      status: 'Confirmed',
    );
    AppointmentStore.instance.add(booking);
    final appointment = DoctorAppointmentRecord.fromBooking(booking);
    DoctorMedicalRecordStore.instance.saveFromConsultation(
      appointment,
      finalized: true,
      testResult: '',
    );
    final medicalRecord = DoctorMedicalRecordStore.instance.records.single;

    final visit = HomeVisit(
      id: 'PHOTO-HOME-VISIT',
      pet: const HomeVisitPet(
        name: 'Milo',
        breed: 'Siamese',
        age: '4 years',
        medicalHistory: 'Vaccinations current',
        color: Colors.teal,
      ),
      veterinarian: DoctorAppointmentStore.doctorName,
      date: DateTime(2026, 9, 21),
      time: '2:00 PM',
      reason: 'Follow-up',
      symptoms: 'Low appetite',
      address: 'Nay Pyi Taw',
      contactPerson: 'Pet Owner',
      phone: '09-1234567',
    );
    HomeVisitStore.instance.add(visit);

    Future<void> show(Widget page) async {
      await tester.pumpWidget(MaterialApp(home: page));
      await tester.pumpAndSettle();
    }

    void expectUploadedPhoto(String key) {
      final photo = find.byKey(ValueKey(key));
      expect(photo, findsOneWidget);
      expect(
        find.descendant(of: photo, matching: find.byType(Image)),
        findsOneWidget,
      );
    }

    await DoctorProfileStore.instance.saveProfile(
      name: 'Dashboard Name',
      specialty: originalProfile.specialty,
      biography: originalProfile.biography,
      phone: originalProfile.phone,
      email: originalProfile.email,
      experience: originalProfile.experience,
    );
    DoctorAppointmentStore.instance.clearDemoSchedule();
    await show(
      DoctorDashboardPage(onOpenAppointments: (_) {}, onOpenProfile: () {}),
    );
    expect(find.textContaining('Dr. Dashboard Name'), findsOneWidget);
    expectUploadedPhoto('doctor-up-next-pet-photo-${appointment.id}');

    await show(DoctorAppointmentCard(record: appointment));
    expectUploadedPhoto('doctor-appointment-list-photo-${appointment.id}');

    await show(DoctorAppointmentDetailsPage(record: appointment));
    expect(find.byKey(const ValueKey('doctor-header-logo')), findsOneWidget);
    expectUploadedPhoto('doctor-appointment-details-photo-${appointment.id}');

    await show(DoctorConsultationPage(record: appointment));
    expectUploadedPhoto('doctor-consultation-photo-${appointment.id}');

    await show(const DoctorMedicalRecordsPage());
    expectUploadedPhoto('doctor-medical-list-photo-${medicalRecord.id}');

    await show(DoctorMedicalRecordDetailsPage(record: medicalRecord));
    expectUploadedPhoto('doctor-medical-details-photo-${medicalRecord.id}');

    await show(const DoctorHomeVisitsPage());
    expectUploadedPhoto('doctor-home-list-photo-${visit.id}');

    await show(DoctorHomeVisitDetailsPage(visit: visit));
    expectUploadedPhoto('doctor-home-details-photo-${visit.id}');
  });
}
