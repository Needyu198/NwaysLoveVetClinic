import 'dart:convert';
import 'dart:async';
import '../data/database_sync.dart';
import '../data/clinic_api.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../login/login_page.dart';
import '../pet_owner/appointment_booking_page.dart';
import '../pet_owner/contact_clinic_page.dart';
import '../pet_owner/emergency_service_page.dart';
import '../pet_owner/home_visit_booking_page.dart';
import '../pet_owner/profile_pet_avatar.dart';
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
part 'doctor_profile_repository.dart';
part 'doctor_profile_page.dart';
part 'doctor_appointment_repository.dart';
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
  late final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorStyles.page,
      body: PageView(
        key: const ValueKey('doctor-directional-pages'),
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          DoctorDashboardPage(
            onOpenAppointments: _openAppointments,
            onOpenProfile: () => _selectTab(2),
          ),
          DoctorAppointmentsPage(
            key: ValueKey('doctor-appointments-$_appointmentFilter'),
            initialFilter: _appointmentFilter,
            onBack: () => _selectTab(0),
          ),
          DoctorProfilePage(onLogoTap: () => _selectTab(0)),
        ],
      ),
      bottomNavigationBar: DoctorNavigationBar(
        selectedIndex: _index,
        onSelected: _selectTab,
      ),
    );
  }

  void _openAppointments(String filter) {
    setState(() => _appointmentFilter = filter);
    _selectTab(1);
  }
}
