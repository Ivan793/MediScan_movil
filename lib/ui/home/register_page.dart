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
    'razonSocial': TextEditingController(),
    'nit': TextEditingController(),
    'licencia': TextEditingController(),
    'departamento': TextEditingController(),
    'correoContacto': TextEditingController(),
    'regimen': TextEditingController(),
    'ips': TextEditingController(),
  };

  bool _isLoading = false;
  bool _obscurePassword = true;

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
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(v)) {
      return 'Correo institucional inválido';
    }
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
    if (value == null || value.isEmpty) return 'La razón social es obligatoria';
    if (value.length > 30) return 'Máximo 30 caracteres';
    return null;
  }

  // -------------- INPUT DECORATION ----------------
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // ---------------- WIDGET FIELD ----------------
  Widget _field(String key, String label, IconData icon,
      {bool obscure = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: _controllers[key],
        obscureText: obscure && _obscurePassword,
        decoration: _inputDecoration(label, icon).copyWith(
          suffixIcon: obscure
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF1976D2),
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
        ),
        validator: validator ?? (v) => (v == null || v.isEmpty) ? "Campo requerido" : null,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  // ---------------- SECCIÓN HEADER ----------------
  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF1976D2), size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------- CAMPOS ESPECIALES -----------------
  Widget campoTipoDocumento() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        decoration: _inputDecoration("Tipo Documento *", Icons.badge),
        items: const [
          DropdownMenuItem(value: "Cédula de Ciudadanía", child: Text("Cédula de Ciudadanía")),
          DropdownMenuItem(value: "Cédula de Extranjería", child: Text("Cédula de Extranjería")),
        ],
        validator: (v) => v == null ? "Campo requerido" : null,
        onChanged: (v) => _controllers['tipoDocumento']!.text = v!,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      ),
    );
  }

  Widget campoGenero() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        decoration: _inputDecoration("Género *", Icons.person),
        items: const [
          DropdownMenuItem(value: "Masculino", child: Text("Masculino")),
          DropdownMenuItem(value: "Femenino", child: Text("Femenino")),
          DropdownMenuItem(value: "Otro", child: Text("Otro")),
        ],
        validator: (v) => v == null ? "Campo requerido" : null,
        onChanged: (v) => _controllers['genero']!.text = v!,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      ),
    );
  }

  Widget campoFechaNacimiento() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: _controllers['fechaNacimiento'],
        readOnly: true,
        decoration: _inputDecoration("Fecha Nacimiento *", Icons.calendar_today),
        validator: (v) => v == null || v.isEmpty ? "Campo requerido" : null,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(1990),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF1976D2),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            _controllers['fechaNacimiento']!.text = picked.toIso8601String().split("T")[0];
          }
        },
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Widget campoRegimen() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        decoration: _inputDecoration("Régimen", Icons.account_balance),
        items: const [
          DropdownMenuItem(value: "Régimen Ordinario", child: Text("Régimen Ordinario")),
          DropdownMenuItem(value: "Régimen Simple", child: Text("Régimen Simple")),
          DropdownMenuItem(value: "Régimen Especial (ESAL)", child: Text("Régimen Especial (ESAL)")),
        ],
        onChanged: (v) => _controllers['regimen']!.text = v!,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      ),
    );
  }

  // ---------------- FORMULARIO DOCTOR ----------------
  Widget _buildDoctorForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Información Personal', Icons.person_outline),
        _field('nombres', 'Nombres *', Icons.person, validator: validarNombre),
        _field('apellidos', 'Apellidos *', Icons.person_outline, validator: validarNombre),
        campoTipoDocumento(),
        _field('numeroDocumento', 'Número Documento *', Icons.badge, validator: validarNumeroDocumento),
        campoFechaNacimiento(),
        campoGenero(),
        
        _sectionHeader('Contacto', Icons.contact_phone),
        _field('telefono', 'Teléfono *', Icons.phone, validator: validarTelefono),
        _field('direccion', 'Dirección *', Icons.home, validator: validarDireccion),
        _field('ciudad', 'Ciudad *', Icons.location_city, validator: validarCiudadPais),
        _field('pais', 'País *', Icons.flag, validator: validarCiudadPais),
        
        _sectionHeader('Información Profesional', Icons.medical_services),
        _field('rethus', 'RETHUS *', Icons.verified_user),
        _field('tarjetaProfesional', 'Tarjeta Profesional *', Icons.card_membership),
        _field('especialidades', 'Especialidades * (separadas por coma)', Icons.local_hospital),
        _field('anioGraduacion', 'Año de Graduación *', Icons.school, validator: validarAnioGraduacion),
        
        _sectionHeader('Credenciales de Acceso', Icons.lock_outline),
        _field('correo', 'Correo electrónico *', Icons.email, validator: validarCorreo),
        _field('contrasenia', 'Contraseña *', Icons.lock, obscure: true, validator: validarContrasenia),
      ],
    );
  }

  // ---------------- FORMULARIO EMPRESA ----------------
  Widget _buildCompanyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Información de Empresa', Icons.business),
        _field('razonSocial', 'Razón Social *', Icons.business, validator: validarRazonSocial),
        _field('nit', 'NIT *', Icons.numbers, validator: validarNIT),
        _field('licencia', 'Licencia de Funcionamiento *', Icons.verified, validator: validarLicencia),
        
        _sectionHeader('Ubicación', Icons.location_on),
        _field('direccion', 'Dirección *', Icons.home, validator: validarDireccion),
        _field('ciudad', 'Ciudad *', Icons.location_city, validator: validarCiudadPais),
        _field('departamento', 'Departamento *', Icons.map),
        _field('pais', 'País *', Icons.flag, validator: validarCiudadPais),
        
        _sectionHeader('Información Adicional', Icons.contact_phone),
        _field('telefono', 'Teléfono *', Icons.phone, validator: validarTelefono),
        _field('correoContacto', 'Correo de Contacto *', Icons.email, validator: validarCorreoInstitucional),
        campoRegimen(),
        _field('ips', 'IPS (opcional)', Icons.local_hospital),
        
        _sectionHeader('Credenciales de Acceso', Icons.lock_outline),
        _field('correo', 'Correo Usuario *', Icons.email, validator: validarCorreo),
        _field('contrasenia', 'Contraseña *', Icons.lock, obscure: true, validator: validarContrasenia),
      ],
    );
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
          fechaNacimiento: DateTime.parse(_controllers['fechaNacimiento']!.text),
          genero: _controllers['genero']!.text,
          rethus: _controllers['rethus']!.text,
          numeroTarjetaProfesional: _controllers['tarjetaProfesional']!.text,
          especialidades: _controllers['especialidades']!.text.split(',').map((e) => e.trim()).toList(),
          anioGraduacion: int.tryParse(_controllers['anioGraduacion']!.text) ?? 0,
          usuario: usuarioCreado,
        );

        await _firestore.collection('doctores').doc(usuarioCreado.id_usuario).set(doctor.toMap());
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

        await _firestore.collection('empresas').doc(usuarioCreado.id_usuario).set(empresa.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text("Registro completado correctamente"),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pushNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text("Error: $e")),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header profesional
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1976D2),
                      const Color(0xFF1976D2).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1976D2).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "MediScan AI",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Crear Nueva Cuenta",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Formulario
              Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Selector de tipo de usuario
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildUserTypeButton(
                                'doctor',
                                'Doctor',
                                Icons.medical_services,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildUserTypeButton(
                                'empresa',
                                'Empresa',
                                Icons.business,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Formulario específico
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: userType == 'doctor' ? _buildDoctorForm() : _buildCompanyForm(),
                      ),

                      const SizedBox(height: 24),

                      // Botón de registro
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Registrarse",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Link a login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "¿Ya tienes cuenta? ",
                            style: TextStyle(color: Colors.grey),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/login'),
                            child: const Text(
                              "Inicia sesión",
                              style: TextStyle(
                                color: Color(0xFF1976D2),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeButton(String type, String label, IconData icon) {
    final isSelected = userType == type;
    return InkWell(
      onTap: () => setState(() => userType = type),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}