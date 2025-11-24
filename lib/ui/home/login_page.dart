import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediscan_app/services/usuario_service.dart';
import 'package:mediscan_app/models/usuario_model.dart';
import 'package:mediscan_app/ui/home/doctor_independiente_page.dart';
import 'package:mediscan_app/ui/home/empresa_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final UsuarioService _usuarioService = UsuarioService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  void _iniciarSesion() async {
    String correo = emailController.text.trim();
    String contrasenia = passwordController.text.trim();

    if (correo.isEmpty || contrasenia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, complete todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Iniciar sesión
      Usuario? usuario = await _usuarioService.iniciarSesion(correo, contrasenia);

      if (usuario == null) {
        throw Exception('Credenciales incorrectas');
      }

      // 2. Verificar el rol y obtener información adicional
      print('Usuario logeado: ${usuario.correo}');
      print('Rol detectado: ${usuario.rol}');

      if (usuario.rol.toLowerCase() == 'empresa') {
        // Redireccionar a dashboard de empresa
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Bienvenido, Empresa'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CompanyDashboard()),
        );
      } else if (usuario.rol.toLowerCase() == 'doctor') {
        // 🔹 Verificar si el doctor está asociado a una empresa
        final doctorDoc = await _firestore
            .collection('doctores')
            .doc(usuario.id_usuario)
            .get();

        if (doctorDoc.exists) {
          final doctorData = doctorDoc.data()!;
          final empresaId = doctorData['empresa_id'];

          if (empresaId != null && empresaId.toString().isNotEmpty) {
            // 🔹 Doctor asociado a empresa
            final empresaDoc = await _firestore
                .collection('empresas')
                .doc(empresaId)
                .get();

            if (empresaDoc.exists) {
              final empresaNombre = empresaDoc.data()?['razon_social'] ?? 'su empresa';
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Bienvenido Dr./Dra.\nAsociado a: $empresaNombre'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Bienvenido Doctor'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            // Doctor independiente (sin empresa)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Bienvenido Doctor Independiente'),
                backgroundColor: Colors.green,
              ),
            );
          }

          // Redirigir al dashboard de doctor
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const DoctorIndependientePage()),
          );
        } else {
          // No existe documento de doctor (caso extraño)
          throw Exception('Perfil de doctor no encontrado');
        }
      } else {
        // Rol desconocido
        print('Rol desconocido recibido: ${usuario.rol}');
        throw Exception('Rol de usuario desconocido: ${usuario.rol}');
      }
    } catch (e) {
      print('Error en login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: 380,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // LOGO
                    Column(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            color: Color(0xFFBBDEFB),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.local_hospital,
                                color: Color(0xFF1976D2), size: 48),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "MediScan AI",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // FORMULARIO
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Email",
                            style: TextStyle(color: Colors.black87)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'correo@ejemplo.com',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text("Contraseña",
                            style: TextStyle(color: Colors.black87)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // BOTÓN LOGIN
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _iniciarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                "Iniciar Sesión",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // REGISTRO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("¿No tienes cuenta? ",
                            style: TextStyle(color: Colors.grey)),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: const Text(
                            "Regístrate",
                            style: TextStyle(
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}