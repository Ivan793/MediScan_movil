import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediscan_app/models/doctor_model.dart';
import 'package:mediscan_app/models/empresa_model.dart';
import 'package:mediscan_app/models/usuario_model.dart';
import 'package:mediscan_app/services/usuario_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final UsuarioService _usuarioService = UsuarioService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userType = 'doctor';
  final _formKey = GlobalKey<FormState>();

  // Controladores generales
  final Map<String, TextEditingController> _controllers = {
    'nombres': TextEditingController(),
    'apellidos': TextEditingController(),
    'tipoDocumento': TextEditingController(),
    'numeroDocumento': TextEditingController(),
    'telefono': TextEditingController(),
    'direccion': TextEditingController(),
    'ciudad': TextEditingController(),
    'pais': TextEditingController(),
    'fechaNacimiento': TextEditingController(),
    'genero': TextEditingController(),
    'rethus': TextEditingController(),
    'tarjetaProfesional': TextEditingController(),
    'especialidades': TextEditingController(),
    'anioGraduacion': TextEditingController(),
    'correo': TextEditingController(),
    'contrasenia': TextEditingController(),

    // Empresa
    'razonSocial': TextEditingController(),
    'nit': TextEditingController(),
    'licencia': TextEditingController(),
    'departamento': TextEditingController(),
    'correoContacto': TextEditingController(),
    'regimen': TextEditingController(),
    'ips': TextEditingController(),
  };

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Logo
                  const Text("MediScan AI",
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Crear Cuenta",
                      style: TextStyle(color: Colors.grey)),

                  const SizedBox(height: 24),

                  // Selección tipo de usuario
                  _userTypeSelector(),

                  const SizedBox(height: 24),

                  // Formulario
                  if (userType == 'doctor') _buildDoctorForm(),
                  if (userType == 'empresa') _buildCompanyForm(),

                  const SizedBox(height: 24),

                  // Botón registrar
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Registrar",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),

                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/login'),
                    child: const Text("¿Ya tienes cuenta? Inicia sesión",
                        style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- Widgets ----
  Widget _userTypeSelector() => Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => userType = 'doctor'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    userType == 'doctor' ? Colors.blue : Colors.grey.shade200,
                foregroundColor:
                    userType == 'doctor' ? Colors.white : Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              child: const Text("Doctor"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => userType = 'empresa'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    userType == 'empresa' ? Colors.blue : Colors.grey.shade200,
                foregroundColor:
                    userType == 'empresa' ? Colors.white : Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              child: const Text("Empresa"),
            ),
          ),
        ],
      );

  Widget _buildDoctorForm() {
    return Column(
      children: [
        _field('nombres', 'Nombres *'),
        _field('apellidos', 'Apellidos *'),
        _field('tipoDocumento', 'Tipo Documento *'),
        _field('numeroDocumento', 'Número Documento *'),
        _field('fechaNacimiento', 'Fecha Nacimiento (YYYY-MM-DD) *'),
        _field('genero', 'Género *'),
        _field('telefono', 'Teléfono'),
        _field('direccion', 'Dirección'),
        _field('ciudad', 'Ciudad'),
        _field('pais', 'País'),
        _field('rethus', 'RETHUS *'),
        _field('tarjetaProfesional', 'Tarjeta Profesional *'),
        _field('especialidades', 'Especialidades * (separadas por coma)'),
        _field('anioGraduacion', 'Año de Graduación *'),
        _field('correo', 'Correo electrónico *'),
        _field('contrasenia', 'Contraseña *', obscure: true),
      ],
    );
  }

  Widget _buildCompanyForm() {
    return Column(
      children: [
        _field('razonSocial', 'Razón Social *'),
        _field('nit', 'NIT *'),
        _field('licencia', 'Licencia de Funcionamiento *'),
        _field('direccion', 'Dirección *'),
        _field('ciudad', 'Ciudad *'),
        _field('departamento', 'Departamento *'),
        _field('pais', 'País *'),
        _field('telefono', 'Teléfono *'),
        _field('correoContacto', 'Correo de Contacto *'),
        _field('regimen', 'Régimen (opcional)'),
        _field('ips', 'IPS (opcional)'),
        _field('correo', 'Correo Usuario *'),
        _field('contrasenia', 'Contraseña *', obscure: true),
      ],
    );
  }

  Widget _field(String key, String label, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: TextFormField(
        controller: _controllers[key],
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Campo requerido' : null,
      ),
    );
  }

  // ---- Registro ----
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final usuario = Usuario(
        correo: _controllers['correo']!.text.trim(),
        contrasenia: _controllers['contrasenia']!.text.trim(),
        rol: userType,
      );

      final usuarioCreado = await _usuarioService.registrarUsuario(usuario);
      if (usuarioCreado == null) throw Exception('Error al registrar usuario');

      if (userType == 'doctor') {
        final doctor = Doctor(
          nombres: _controllers['nombres']!.text,
          apellidos: _controllers['apellidos']!.text,
          tipoDocumento: _controllers['tipoDocumento']!.text,
          numeroDocumento: _controllers['numeroDocumento']!.text,
          telefono: _controllers['telefono']!.text,
          direccion: _controllers['direccion']!.text,
          ciudad: _controllers['ciudad']!.text,
          pais: _controllers['pais']!.text,
          fechaNacimiento:
              DateTime.parse(_controllers['fechaNacimiento']!.text),
          genero: _controllers['genero']!.text,
          rethus: _controllers['rethus']!.text,
          numeroTarjetaProfesional:
              _controllers['tarjetaProfesional']!.text,
          especialidades: _controllers['especialidades']!.text
              .split(',')
              .map((e) => e.trim())
              .toList(),
          anioGraduacion:
              int.tryParse(_controllers['anioGraduacion']!.text) ?? 0,
          usuario: usuarioCreado,
        );

        await _firestore
            .collection('doctores')
            .doc(usuarioCreado.id_usuario)
            .set(doctor.toMap());
      } else {
        final empresa = Empresa(
          nit: _controllers['nit']!.text,
          razonSocial: _controllers['razonSocial']!.text,
          licenciaFuncionamiento: _controllers['licencia']!.text,
          direccion: _controllers['direccion']!.text,
          ciudad: _controllers['ciudad']!.text,
          departamento: _controllers['departamento']!.text,
          pais: _controllers['pais']!.text,
          telefono: _controllers['telefono']!.text,
          correoContacto: _controllers['correoContacto']!.text,
          usuario: usuarioCreado,
          regimen: _controllers['regimen']!.text,
          ips: _controllers['ips']!.text,
        );

        await _firestore
            .collection('empresas')
            .doc(usuarioCreado.id_usuario)
            .set(empresa.toMap());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registro completado correctamente"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error al registrar: $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
