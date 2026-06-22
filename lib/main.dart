import 'package:flutter/material.dart';

import 'login/login_page.dart';
import 'login/pet_owner_auth_api.dart';
import 'pet_owner/pet_owner_home_page.dart';
import 'pet_owner/pet_owner_profile_page.dart';
import 'pet_owner/pet_profile_page.dart';
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
        PetOwnerHomePage.routeName: (context) => const PetOwnerHomePage(),
        PetOwnerProfilePage.routeName: (context) => const PetOwnerProfilePage(),
        PetProfilePage.routeName: (context) => const PetProfilePage(),
        PetAddReminderPage.routeName: (context) => const PetAddReminderPage(),
        PetReminderPage.routeName: (context) => const PetReminderPage(),
      },
    );
  }
}
