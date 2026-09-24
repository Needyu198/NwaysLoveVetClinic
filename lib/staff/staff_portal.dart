import 'dart:convert';
import 'dart:async';
import '../data/database_sync.dart';
import '../data/clinic_api.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../doctor/doctor_portal.dart';
import '../data/clinic_directory.dart';
import '../login/login_page.dart';
import '../pet_owner/appointment_booking_page.dart';
import '../pet_owner/contact_clinic_page.dart';
import '../pet_owner/emergency_service_page.dart';
import '../pet_owner/home_visit_booking_page.dart';
import '../pet_owner/owner_shared_stores.dart';
import '../pet_owner/profile_pet_avatar.dart';
import '../pet_owner/profile_flows.dart';

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
part 'staff_inventory_detail_page.dart';
part 'staff_add_inventory_page.dart';
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
      backgroundColor: Colors.white,
      body: PageView(
        key: const ValueKey('staff-directional-pages'),
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          StaffDashboardPage(onOpenProfile: () => _selectTab(2)),
          StaffManagementPage(onLogoTap: () => _selectTab(0)),
          StaffProfilePage(onLogoTap: () => _selectTab(0)),
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
                            onTap: () => _selectTab(i),
                            child: SizedBox(
                              height: 58,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (i < 2)
                                    _StaffNavAssetIcon(
                                      key: ValueKey(
                                        i == 0
                                            ? 'staff-dashboard-nav-icon'
                                            : 'staff-management-nav-icon',
                                      ),
                                      asset: i == 0
                                          ? 'assets/photos/icon/staff_dashboard_nav.png'
                                          : 'assets/photos/icon/staff_management_nav.png',
                                    )
                                  else
                                    const Icon(
                                      Icons.account_circle_outlined,
                                      color: Color(0xFF78968F),
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

class _StaffNavAssetIcon extends StatelessWidget {
  const _StaffNavAssetIcon({required this.asset, super.key});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 30,
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFF78968F), BlendMode.srcIn),
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }
}
