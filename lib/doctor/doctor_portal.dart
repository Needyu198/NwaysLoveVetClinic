import 'package:flutter/material.dart';

import '../login/login_page.dart';
import '../pet_owner/appointment_booking_page.dart';
import '../pet_owner/contact_clinic_page.dart';
import '../pet_owner/emergency_service_page.dart';
import '../pet_owner/home_visit_booking_page.dart';
import '../pet_owner/profile_flows.dart';

part 'doctor_navigation_bar.dart';
part 'doctor_models.dart';
part 'doctor_dashboard_page.dart';
part 'doctor_appointments_page.dart';
part 'doctor_pet_details_page.dart';
part 'doctor_pet_history_page.dart';
part 'doctor_consultation_page.dart';
part 'doctor_queue_page.dart';
part 'doctor_medical_records_page.dart';
part 'doctor_notifications_page.dart';
part 'doctor_emergency_cases_page.dart';
part 'doctor_home_visits_page.dart';
part 'doctor_create_post_page.dart';
part 'doctor_profile_page.dart';
part 'doctor_widgets.dart';
part 'doctor_styles.dart';

class DoctorPortalPage extends StatefulWidget {
  const DoctorPortalPage({super.key});

  static const routeName = '/doctor';

  @override
  State<DoctorPortalPage> createState() => _DoctorPortalPageState();
}

class _DoctorPortalPageState extends State<DoctorPortalPage> {
  var _index = 0;
  var _appointmentFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.page,
      body: IndexedStack(
        index: _index,
        children: [
          DoctorDashboardPage(
            onOpenAppointments: _openAppointments,
            onOpenProfile: () => setState(() => _index = 2),
          ),
          DoctorAppointmentsPage(
            key: ValueKey('doctor-appointments-$_appointmentFilter'),
            initialFilter: _appointmentFilter,
            onBack: () => setState(() => _index = 0),
          ),
          const DoctorProfilePage(),
        ],
      ),
      bottomNavigationBar: DoctorNavigationBar(
        selectedIndex: _index,
        onSelected: (index) => setState(() => _index = index),
      ),
    );
  }

  void _openAppointments(String filter) {
    setState(() {
      _appointmentFilter = filter;
      _index = 1;
    });
  }
}
