import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediscan_app/services/usuario_service.dart';
import 'package:mediscan_app/models/usuario_model.dart';
import 'package:mediscan_app/ui/home/doctor_independiente_page.dart';
import 'package:mediscan_app/ui/home/empresa_page.dart';
import 'package:mediscan_app/ui/theme/app_colors.dart';
import 'package:mediscan_app/ui/widgets/app_widgets.dart';

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
  bool _obscurePassword = true;

  void _iniciarSesion() async {
    String correo = emailController.text.trim();
    String contrasenia = passwordController.text.trim();

    if (correo.isEmpty || contrasenia.isEmpty) {
      _showSnackBar('Por favor, complete todos los campos', AppColors.warning);
      return;
    }

    setState(() => _isLoading = true);

    try {
      Usuario? usuario = await _usuarioService.iniciarSesion(correo, contrasenia);

      if (usuario == null) {
        throw Exception('Credenciales incorrectas');
      }

      if (usuario.rol.toLowerCase() == 'empresa') {
        _showSnackBar('Bienvenido, Empresa', AppColors.success);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CompanyDashboard()),
        );
      } else if (usuario.rol.toLowerCase() == 'doctor') {
        final doctorDoc = await _firestore
            .collection('doctores')
            .doc(usuario.id_usuario)
            .get();

        if (doctorDoc.exists) {
          final doctorData = doctorDoc.data()!;
          final empresaId = doctorData['empresa_id'];

          if (empresaId != null && empresaId.toString().isNotEmpty) {
            final empresaDoc = await _firestore
                .collection('empresas')
                .doc(empresaId)
                .get();

            if (empresaDoc.exists) {
              final empresaNombre = empresaDoc.data()?['razon_social'] ?? 'su empresa';
              _showSnackBar('Bienvenido Dr./Dra.\nAsociado a: $empresaNombre', AppColors.success);
            } else {
              _showSnackBar('Bienvenido Doctor', AppColors.success);
            }
          } else {
            _showSnackBar('Bienvenido Doctor Independiente', AppColors.success);
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const DoctorIndependientePage()),
          );
        } else {
          throw Exception('Perfil de doctor no encontrado');
        }
      } else {
        throw Exception('Rol de usuario desconocido: ${usuario.rol}');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', AppColors.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo y título
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppColors.elevatedShadow,
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  const Text(
                    "MediScan AI",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    "Sistema Inteligente de Análisis Médico",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Formulario
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Iniciar Sesión",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        AppTextField(
                          label: 'Correo electrónico',
                          controller: emailController,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            labelStyle: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            filled: true,
                            fillColor: AppColors.grey50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.grey200,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        AppPrimaryButton(
                          text: 'Iniciar Sesión',
                          onPressed: _iniciarSesion,
                          isLoading: _isLoading,
                          icon: Icons.login,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "¿No tienes cuenta? ",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/register'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                "Regístrate",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    "© 2025 MediScan AI. Todos los derechos reservados.",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
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