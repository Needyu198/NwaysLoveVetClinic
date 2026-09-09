import 'dart:convert';
import '../data/database_sync.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../login/login_page.dart';
import '../pet_owner/appointment_booking_page.dart';
import '../pet_owner/emergency_service_page.dart';
import '../staff/staff_portal.dart';

part 'system_admin_navigation_bar.dart';
part 'system_admin_dashboard_page.dart';
part 'system_admin_management_page.dart';
part 'system_admin_widgets.dart';
part 'system_admin_styles.dart';
part 'system_admin_models.dart';
part 'system_admin_users_page.dart';
part 'system_admin_verification_page.dart';
part 'system_admin_audit_page.dart';
part 'system_admin_profile_page.dart';

class SystemAdminDashboardPage extends StatefulWidget {
  const SystemAdminDashboardPage({super.key});

  static const routeName = '/system-admin';

  @override
  State<SystemAdminDashboardPage> createState() =>
      _SystemAdminDashboardPageState();
}

class _SystemAdminDashboardPageState extends State<SystemAdminDashboardPage> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _index,
        children: [
          const _AdminDashboardTab(),
          const _AdminManagementTab(),
          AdminProfileTab(onLogout: () => _logout(context)),
        ],
      ),
      bottomNavigationBar: SystemAdminNavigationBar(
        selectedIndex: _index,
        onSelected: (index) => setState(() => _index = index),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('End the system administrator session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-system-admin-logout'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await DatabaseSync.instance.stop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
        return;
      }
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(LoginPage.routeName, (_) => false);
    }
  }
}
