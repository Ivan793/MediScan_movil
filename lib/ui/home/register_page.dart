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

  // Controladores
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

  // ---------------- VALIDADORES ----------------

  String? validarNombre(String? v) {
    if (v == null || v.isEmpty) return 'Campo requerido';
    if (v.length < 3) return 'Mínimo 3 caracteres';
    if (!RegExp(r'^[a-zA-ZÁÉÍÓÚáéíóúñÑ ]+$').hasMatch(v)) return 'Solo letras';
    return null;
  }

  String? validarNumeroDocumento(String? v) {
    if (v == null || v.isEmpty) return 'Campo requerido';
    if (v.length < 6) return 'Mínimo 6 caracteres';

    final tipo = _controllers['tipoDocumento']!.text;

    if (tipo == "Cédula de Ciudadanía") {
      if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Solo números para C.C.';
    } else {
      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(v)) {
        return 'Solo letras y números (sin caracteres especiales)';
      }
    }
    return null;
  }

  String? validarTelefono(String? v) {
    if (!RegExp(r'^[0-9]{10,}$').hasMatch(v ?? "")) {
      return 'Debe tener mínimo 10 dígitos y solo números';
    }
    return null;
  }

  String? validarDireccion(String? v) {
    if (v == null || v.isEmpty) return 'Campo requerido';
    if (v.length > 30) return 'Máximo 30 caracteres';
    return null;
  }

  String? validarCiudadPais(String? v) {
    if (v == null || v.isEmpty) return 'Campo requerido';
    if (v.length > 15) return 'Máximo 15 caracteres';
    if (!RegExp(r'^[a-zA-ZÁÉÍÓÚáéíóúñÑ ]+$').hasMatch(v)) return 'Solo letras';
    return null;
  }

  String? validarAnioGraduacion(String? v) {
    if (!RegExp(r'^[0-9]{4}$').hasMatch(v ?? "")) return 'Debe tener 4 dígitos';
    return null;
  }

  String? validarCorreo(String? v) {
    if (v == null || v.isEmpty) return 'Campo requerido';
    if (!v.contains('@')) return 'Debe contener @';

    final domain = v.split("@").last;
    final dots = ".".allMatches(domain).length;

    if (dots < 1 || dots > 2) return 'Dominio inválido (1–2 puntos)';

    return null;
  }

  String? validarCorreoInstitucional(String? v) {
    if (v == null || v.isEmpty) return 'Campo requerido';
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(v)) return 'Correo institucional inválido';
    return null;
  }

  String? validarContrasenia(String? v) {
    if (v == null || v.isEmpty) return 'Campo requerido';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Debe incluir una mayúscula';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Debe incluir una minúscula';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Debe incluir un número';
    if (v.contains('ñ') || v.contains('Ñ')) return 'No se permite "ñ"';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v)) {
      return 'Debe incluir un carácter especial';
    }
    return null;
  }

  String? validarNIT(String? v) {
    if (v == null || v.isEmpty) return 'Campo requerido';
    if (!RegExp(r'^[0-9\.\-]+$').hasMatch(v)) {
      return 'Solo números, puntos y guiones';
    }
    return null;
  }

  String? validarLicencia(String? v) {
    if (v == null || v.isEmpty) return 'Campo requerido';
    if (!RegExp(r'^[a-zA-Z0-9\.\-]+$').hasMatch(v)) {
      return 'Solo letras, números, puntos y guiones';
    }
    return null;
  }

  String? validarRazonSocial(String? value) {
    if (value == null || value.isEmpty) {
      return 'La razón social es obligatoria';
    }

    if (value.length > 30) {
      return 'Máximo 30 caracteres';
    }

    return null;
  }


  // -------------- INPUT DECORATION ----------------
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
    );
  }

  // ---------------- WIDGET FIELD ----------------
  Widget _field(String key, String label,
      {bool obscure = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: TextFormField(
        controller: _controllers[key],
        obscureText: obscure,
        decoration: _inputDecoration(label),
        validator: validator ?? (v) => (v == null || v.isEmpty)
            ? "Campo requerido"
            : null,
      ),
    );
  }

  // ----------------- CAMPOS ESPECIALES -----------------

  Widget campoTipoDocumento() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration("Tipo Documento *"),
      items: const [
        DropdownMenuItem(
            value: "Cédula de Ciudadanía",
            child: Text("Cédula de Ciudadanía")),
        DropdownMenuItem(
            value: "Cédula de Extranjería",
            child: Text("Cédula de Extranjería")),
      ],
      validator: (v) => v == null ? "Campo requerido" : null,
      onChanged: (v) {
        _controllers['tipoDocumento']!.text = v!;
      },
    );
  }

  Widget campoGenero() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration("Género *"),
      items: const [
        DropdownMenuItem(value: "Masculino", child: Text("Masculino")),
        DropdownMenuItem(value: "Femenino", child: Text("Femenino")),
        DropdownMenuItem(value: "Otro", child: Text("Otro")),
      ],
      validator: (v) => v == null ? "Campo requerido" : null,
      onChanged: (v) {
        _controllers['genero']!.text = v!;
      },
    );
  }

  Widget campoFechaNacimiento() {
    return TextFormField(
      controller: _controllers['fechaNacimiento'],
      readOnly: true,
      decoration: _inputDecoration("Fecha Nacimiento *"),
      validator: (v) => v == null || v.isEmpty ? "Campo requerido" : null,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(1990),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          _controllers['fechaNacimiento']!.text =
              picked.toIso8601String().split("T")[0];
        }
      },
    );
  }

  Widget campoRegimen() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration("Régimen"),
      items: const [
        DropdownMenuItem(
            value: "Régimen Ordinario", child: Text("Régimen Ordinario")),
        DropdownMenuItem(value: "Régimen Simple", child: Text("Régimen Simple")),
        DropdownMenuItem(
            value: "Régimen Especial (ESAL)",
            child: Text("Régimen Especial (ESAL)")),
      ],
      onChanged: (v) => _controllers['regimen']!.text = v!,
    );
  }

  // ---------------- FORMULARIO DOCTOR ----------------
  Widget _buildDoctorForm() {
    return Column(children: [
      _field('nombres', 'Nombres *', validator: validarNombre),
      _field('apellidos', 'Apellidos *', validator: validarNombre),
      campoTipoDocumento(),
      _field('numeroDocumento', 'Número Documento *',
          validator: validarNumeroDocumento),
      campoFechaNacimiento(),
      campoGenero(),
      _field('telefono', 'Teléfono *', validator: validarTelefono),
      _field('direccion', 'Dirección *', validator: validarDireccion),
      _field('ciudad', 'Ciudad *', validator: validarCiudadPais),
      _field('pais', 'País *', validator: validarCiudadPais),
      _field('rethus', 'RETHUS *'),
      _field('tarjetaProfesional', 'Tarjeta Profesional *'),
      _field('especialidades',
          'Especialidades * (separadas por coma)'), // admite varias
      _field('anioGraduacion', 'Año de Graduación *',
          validator: validarAnioGraduacion),
      _field('correo', 'Correo electrónico *', validator: validarCorreo),
      _field('contrasenia', 'Contraseña *',
          obscure: true, validator: validarContrasenia),
    ]);
  }

  // ---------------- FORMULARIO EMPRESA ----------------
  Widget _buildCompanyForm() {
    return Column(children: [
      _field('razonSocial', 'Razón Social *', validator: validarRazonSocial),
      _field('nit', 'NIT *', validator: validarNIT),
      _field('licencia', 'Licencia de Funcionamiento *',
          validator: validarLicencia),
      _field('direccion', 'Dirección *', validator: validarDireccion),
      _field('ciudad', 'Ciudad *', validator: validarCiudadPais),
      _field('departamento', 'Departamento *'),
      _field('pais', 'País *', validator: validarCiudadPais),
      _field('telefono', 'Teléfono *', validator: validarTelefono),
      _field('correoContacto', 'Correo de Contacto *',
          validator: validarCorreoInstitucional),
      campoRegimen(),
      _field('ips', 'IPS (opcional)'),
      _field('correo', 'Correo Usuario *', validator: validarCorreo),
      _field('contrasenia', 'Contraseña *',
          obscure: true, validator: validarContrasenia),
    ]);
  }

  // ---------------- REGISTRO ----------------
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al registrar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
                  const Text("MediScan AI",
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Crear Cuenta",
                      style: TextStyle(color: Colors.grey)),

                  const SizedBox(height: 24),

                  _userTypeSelector(),

                  const SizedBox(height: 24),

                  if (userType == 'doctor') _buildDoctorForm(),
                  if (userType == 'empresa') _buildCompanyForm(),

                  const SizedBox(height: 24),

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

  Widget _userTypeSelector() => Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => userType = 'doctor'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    userType == 'doctor' ? Colors.blue : Colors.grey.shade300,
                foregroundColor:
                    userType == 'doctor' ? Colors.white : Colors.black,
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
                    userType == 'empresa' ? Colors.blue : Colors.grey.shade300,
                foregroundColor:
                    userType == 'empresa' ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              child: const Text("Empresa"),
            ),
          ),
        ],
      );
}
