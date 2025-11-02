import 'package:flutter/material.dart';
import 'package:mediscan_app/ui/home/doctor_page.dart';
import 'package:mediscan_app/ui/home/empresa_page.dart';
import 'package:mediscan_app/ui/home/login_page.dart';
import 'package:mediscan_app/ui/home/register_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medi-Scan',
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/company': (context) => const CompanyDashboard(),
        '/doctor': (context) => const DoctorDashboard(),
      },
    );
  }
}
