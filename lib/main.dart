import 'data/database_stores.dart';
import 'data/database_status.dart';
import 'data/firebase_service.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'doctor/doctor_portal.dart';
import 'login/doctor_auth_api.dart';
import 'login/login_page.dart';
import 'login/pet_owner_auth_api.dart';
import 'login/system_admin_auth_api.dart';
import 'login/staff_auth_api.dart';
import 'staff/staff_portal.dart';
import 'pet_owner/appointment_booking_page.dart';
import 'pet_owner/contact_clinic_page.dart';
import 'pet_owner/emergency_service_page.dart';
import 'pet_owner/first_aid_information_page.dart';
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
import 'system_admin/system_admin_portal.dart';

/// Top-level background handler for FCM messages received while the app is not
/// in the foreground. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No heavy work here; the OS displays the notification. This handler exists
  // so the plugin can process data messages in the background.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase before the app starts. This is non-fatal: if Firebase
  // cannot initialize (e.g. missing native config on a platform), the app still
  // runs on the custom backend auth.
  await FirebaseService.instance.ensureInitialized();
  if (FirebaseService.instance.isAvailable) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  registerDatabaseStores();
  runApp(const NwayLoveVetClinicApp());
}

class NwayLoveVetClinicApp extends StatelessWidget {
  const NwayLoveVetClinicApp({
    this.authApi = const PetOwnerAuthApi(),
    this.doctorAuthApi = const DoctorAuthApi(),
    this.systemAdminAuthApi = const SystemAdminAuthApi(),
    this.staffAuthApi = const StaffAuthApi(),
    super.key,
  });

  final PetOwnerAuthApi authApi;
  final DoctorAuthApi doctorAuthApi;
  final SystemAdminAuthApi systemAdminAuthApi;
  final StaffAuthApi staffAuthApi;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) =>
          DatabaseStatus(child: child ?? const SizedBox()),
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
        LoginPage.routeName: (context) => LoginPage(
          authApi: authApi,
          doctorAuthApi: doctorAuthApi,
          systemAdminAuthApi: systemAdminAuthApi,
          staffAuthApi: staffAuthApi,
        ),
        DoctorPortalPage.routeName: (context) => const DoctorPortalPage(),
        SystemAdminDashboardPage.routeName: (context) =>
            const SystemAdminDashboardPage(),
        StaffPortalPage.routeName: (context) => const StaffPortalPage(),
        PetOwnerClinicPage.routeName: (context) => const PetOwnerClinicPage(),
        PetOwnerHomePage.routeName: (context) => const PetOwnerHomePage(),
        PetOwnerProfilePage.routeName: (context) => const PetOwnerProfilePage(),
        AppointmentBookingPage.routeName: (context) =>
            const AppointmentBookingPage(),
        ContactClinicPage.routeName: (context) => const ContactClinicPage(),
        MyAppointmentsPage.routeName: (context) => const MyAppointmentsPage(),
        MyQueuePage.routeName: (context) => const MyQueuePage(),
        QueueHistoryPage.routeName: (context) => const QueueHistoryPage(),
        EmergencyServicePage.routeName: (context) =>
            const EmergencyServicePage(),
        MyEmergencyRequestsPage.routeName: (context) =>
            const MyEmergencyRequestsPage(),
        FirstAidInformationPage.routeName: (context) =>
            const FirstAidInformationPage(),
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
