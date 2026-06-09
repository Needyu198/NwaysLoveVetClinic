import 'package:flutter/material.dart';

import 'login/login_page.dart';

void main() {
  runApp(const NwayLoveVetClinicApp());
}

class NwayLoveVetClinicApp extends StatelessWidget {
  const NwayLoveVetClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nway Love Vet Clinic',
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
      home: const LoginPage(),
    );
  }
}
