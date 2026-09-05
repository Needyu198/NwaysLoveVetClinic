import 'package:flutter/material.dart';

import '../doctor/doctor_portal.dart';
import '../login/login_page.dart';
import '../pet_owner/appointment_booking_page.dart';
import '../pet_owner/contact_clinic_page.dart';
import '../pet_owner/emergency_service_page.dart';
import '../pet_owner/home_visit_booking_page.dart';

part 'staff_styles.dart';
part 'staff_models.dart';
part 'staff_widgets.dart';
part 'staff_dashboard_page.dart';
part 'staff_management_page.dart';
part 'staff_appointments_page.dart';
part 'staff_queue_page.dart';
part 'staff_walk_in_page.dart';
part 'staff_emergency_page.dart';
part 'staff_home_visits_page.dart';
part 'staff_payments_page.dart';
part 'staff_inventory_page.dart';
part 'staff_medical_records_page.dart';
part 'staff_health_posts_page.dart';
part 'staff_patients_page.dart';
part 'staff_messages_page.dart';
part 'staff_reports_page.dart';
part 'staff_profile_page.dart';

class StaffPortalPage extends StatefulWidget {
  const StaffPortalPage({super.key});

  static const routeName = '/staff/dashboard';

  @override
  State<StaffPortalPage> createState() => _StaffPortalPageState();
}

class _StaffPortalPageState extends State<StaffPortalPage> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _index,
        children: [
          StaffDashboardPage(onOpenProfile: () => setState(() => _index = 2)),
          const StaffManagementPage(),
          const StaffProfilePage(),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              key: const ValueKey('staff-navigation-bar'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      flex: _index == i ? 3 : 1,
                      child: Semantics(
                        selected: _index == i,
                        button: true,
                        label: const ['Dashboard', 'Management', 'Profile'][i],
                        child: Material(
                          color: _index == i
                              ? const Color(0xFFF5F8F6)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(48),
                          child: InkWell(
                            key: ValueKey(
                              const [
                                'staff-dashboard-tab',
                                'staff-management-tab',
                                'staff-profile-tab',
                              ][i],
                            ),
                            borderRadius: BorderRadius.circular(48),
                            onTap: () => setState(() => _index = i),
                            child: SizedBox(
                              height: 58,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    const [
                                      Icons.desktop_windows_outlined,
                                      Icons.app_settings_alt,
                                      Icons.account_circle_outlined,
                                    ][i],
                                    color: const Color(0xFF78968F),
                                    size: 32,
                                  ),
                                  if (_index == i) ...[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        const [
                                          'Dashboard',
                                          'Management',
                                          'Profile',
                                        ][i],
                                        maxLines: 1,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
