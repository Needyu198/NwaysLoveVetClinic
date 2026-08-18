import 'package:flutter/material.dart';

import 'login/login_page.dart';
import 'login/pet_owner_auth_api.dart';
import 'pet_owner/appointment_booking_page.dart';
import 'pet_owner/emergency_service_page.dart';
import 'pet_owner/home_visit_booking_page.dart';
import 'pet_owner/history_page.dart';
import 'pet_owner/medical_services_page.dart';
import 'pet_owner/pet_care_booking_page.dart';
import 'pet_owner/pet_owner_clinic_page.dart';
import 'pet_owner/pet_owner_home_page.dart';
import 'pet_owner/pet_owner_profile_page.dart';
import 'pet_owner/pet_profile_page.dart';
import 'pet_owner/pet_products_page.dart';
import 'pet_owner/pet_add_reminder_page.dart';
import 'pet_owner/pet_reminder_page.dart';

void main() {
  runApp(const NwayLoveVetClinicApp());
}

class NwayLoveVetClinicApp extends StatelessWidget {
  const NwayLoveVetClinicApp({
    this.authApi = const PetOwnerAuthApi(),
    super.key,
  });

  final PetOwnerAuthApi authApi;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Nway's Love Vet Clinic",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFA1FDD8),
          onPrimary: Color(0xFF000000),
          surface: Color(0xFFF6F8F7),
          onSurface: Color(0xFF000000),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      initialRoute: LoginPage.routeName,
      routes: {
        LoginPage.routeName: (context) => LoginPage(authApi: authApi),
        PetOwnerClinicPage.routeName: (context) => const PetOwnerClinicPage(),
        PetOwnerHomePage.routeName: (context) => const PetOwnerHomePage(),
        PetOwnerProfilePage.routeName: (context) => const PetOwnerProfilePage(),
        AppointmentBookingPage.routeName: (context) =>
            const AppointmentBookingPage(),
        MyAppointmentsPage.routeName: (context) => const MyAppointmentsPage(),
        MyQueuePage.routeName: (context) => const MyQueuePage(),
        QueueHistoryPage.routeName: (context) => const QueueHistoryPage(),
        EmergencyServicePage.routeName: (context) =>
            const EmergencyServicePage(),
        MyEmergencyRequestsPage.routeName: (context) =>
            const MyEmergencyRequestsPage(),
        HistoryPage.routeName: (context) => const HistoryPage(),
        HomeVisitBookingPage.routeName: (context) =>
            const HomeVisitBookingPage(),
        MyHomeVisitsPage.routeName: (context) => const MyHomeVisitsPage(),
        MedicalServicesPage.routeName: (context) => const MedicalServicesPage(),
        PetCareServicesPage.routeName: (context) => const PetCareServicesPage(),
        MyServiceBookingsPage.routeName: (context) =>
            const MyServiceBookingsPage(),
        PetProfilePage.routeName: (context) => const PetProfilePage(),
        PetProductsPage.routeName: (context) => const PetProductsPage(),
        ProductDetailsPage.routeName: (context) => const ProductDetailsPage(),
        PetAddReminderPage.routeName: (context) => const PetAddReminderPage(),
        PetReminderPage.routeName: (context) => const PetReminderPage(),
      },
    );
  }
}
