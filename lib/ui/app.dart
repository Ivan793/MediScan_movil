import 'package:flutter/material.dart';
import 'package:mediscan_app/models/paciente_model.dart';
import 'package:mediscan_app/ui/home/analisis_gestion_page.dart';
import 'package:mediscan_app/ui/home/analisis_page.dart';
import 'package:mediscan_app/ui/home/doctor_page.dart';
import 'package:mediscan_app/ui/home/empresa_page.dart';
import 'package:mediscan_app/ui/home/login_page.dart';
import 'package:mediscan_app/ui/home/paciente_detalle_page.dart';
import 'package:mediscan_app/ui/home/paciente_page.dart';
import 'package:mediscan_app/ui/home/pacientes_list_page.dart';
import 'package:mediscan_app/ui/home/register_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medi-Scan',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/company': (context) => const CompanyDashboard(),
        '/doctor': (context) => const DoctorDashboard(),
        
        // Rutas de Pacientes (solo gestión)
        '/pacientes': (context) => const PacientesListPage(),
        '/registrar-paciente': (context) {
          final paciente =
              ModalRoute.of(context)?.settings.arguments as Paciente?;
          return PacienteFormPage(paciente: paciente);
        },
        '/detalle-paciente': (context) {
          final paciente =
              ModalRoute.of(context)!.settings.arguments as Paciente;
          return PacienteDetallePage(paciente: paciente);
        },
        
        // Rutas de Análisis
        '/analisis': (context) => const AnalisisGestionPage(),
        '/nuevo-analisis': (context) {
          final paciente =
              ModalRoute.of(context)!.settings.arguments as Paciente;
          return AnalisisFormPage(paciente: paciente);
        },
      },
    );
  }
}