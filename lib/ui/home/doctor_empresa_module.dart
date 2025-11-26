import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediscan_app/models/doctor_model.dart';
import 'package:mediscan_app/models/empresa_model.dart';
import 'package:mediscan_app/models/usuario_model.dart';
import 'package:mediscan_app/services/usuario_service.dart';
import 'package:mediscan_app/ui/theme/app_colors.dart';
import 'package:mediscan_app/ui/widgets/app_widgets.dart';

class DoctorEmpresaModule extends StatefulWidget {
  final Empresa empresa;

  const DoctorEmpresaModule({Key? key, required this.empresa}) : super(key: key);

  @override
  State<DoctorEmpresaModule> createState() => _DoctorEmpresaModuleState();
}

class _DoctorEmpresaModuleState extends State<DoctorEmpresaModule> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UsuarioService _usuarioService = UsuarioService();
  final TextEditingController _searchController = TextEditingController();

  // Controladores de información personal
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _especialidadController = TextEditingController();
  final TextEditingController _tarjetaProfesionalController = TextEditingController();
  
  // Controladores para credenciales de acceso
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contraseniaController = TextEditingController();

  String? _editingDoctorId;
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  List<Doctor> _doctores = [];
  List<Doctor> _doctoresFiltrados = [];

  void _filtrarDoctores(String query) {
    setState(() {
      if (query.isEmpty) {
        _doctoresFiltrados = _doctores;
      } else {
        _doctoresFiltrados = _doctores.where((d) {
          final nombre = '${d.nombres} ${d.apellidos}'.toLowerCase();
          final documento = d.numeroDocumento.toLowerCase();
          final correo = d.usuario.correo.toLowerCase();
          final busqueda = query.toLowerCase();
          return nombre.contains(busqueda) || 
                 documento.contains(busqueda) || 
                 correo.contains(busqueda);
        }).toList();
      }
    });
  }

  Future<void> _guardarDoctor() async {
    // Validación básica
    if (_nombresController.text.isEmpty ||
        _apellidosController.text.isEmpty ||
        _documentoController.text.isEmpty ||
        _tarjetaProfesionalController.text.isEmpty ||
        _correoController.text.isEmpty ||
        _contraseniaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, complete todos los campos obligatorios'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Validación de contraseña (mínimo 6 caracteres)
    if (_contraseniaController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_editingDoctorId == null) {
        // CREAR NUEVO DOCTOR CON CUENTA DE USUARIO
        
        // 1. Crear el usuario en Firebase Auth
        final usuario = await _usuarioService.registrarUsuario(Usuario(
          correo: _correoController.text.trim(),
          contrasenia: _contraseniaController.text.trim(),
          rol: 'doctor',
        ));

        if (usuario == null) {
          throw Exception('Error al crear la cuenta de usuario');
        }

        // 2. Crear el documento del doctor en Firestore
        final doctorData = Doctor(
          nombres: _nombresController.text,
          apellidos: _apellidosController.text,
          tipoDocumento: 'CC',
          numeroDocumento: _documentoController.text,
          telefono: _telefonoController.text,
          direccion: widget.empresa.direccion,
          ciudad: widget.empresa.ciudad,
          pais: widget.empresa.pais,
          fechaNacimiento: DateTime.now(),
          genero: 'No especificado',
          rethus: 'N/A',
          numeroTarjetaProfesional: _tarjetaProfesionalController.text,
          especialidades: [_especialidadController.text],
          anioGraduacion: DateTime.now().year,
          usuario: usuario,
          empresaId: widget.empresa.id,
        );

        // 3. Guardar en Firestore con el ID del usuario como documento ID
        await _db.collection('doctores').doc(usuario.id_usuario).set(doctorData.toMap());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Doctor registrado exitosamente\n'
                'Usuario: ${usuario.correo}\n'
                'El doctor ya puede iniciar sesión',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        // ACTUALIZAR DOCTOR EXISTENTE (sin cambiar credenciales)
        
        final doctorData = {
          'nombres': _nombresController.text,
          'apellidos': _apellidosController.text,
          'numero_documento': _documentoController.text,
          'telefono': _telefonoController.text,
          'numero_tarjeta_profesional': _tarjetaProfesionalController.text,
          'especialidades': [_especialidadController.text],
        };

        await _db.collection('doctores').doc(_editingDoctorId).update(doctorData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Doctor actualizado exitosamente'),
              backgroundColor: AppColors.info,
            ),
          );
        }
      }

      _limpiarFormulario();
      Navigator.pop(context);
    } catch (e) {
      print('Error al guardar doctor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarDoctor(String id, String correo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_rounded, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirmar eliminación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Deseas eliminar este doctor?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.warning),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'La cuenta de usuario NO se eliminará de Firebase Auth, pero el doctor ya no aparecerá en tu lista.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.collection('doctores').doc(id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Doctor eliminado de la empresa'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _mostrarDialogoDoctor({Doctor? doctor}) {
    if (doctor != null) {
      _editingDoctorId = doctor.id;
      _nombresController.text = doctor.nombres;
      _apellidosController.text = doctor.apellidos;
      _documentoController.text = doctor.numeroDocumento;
      _telefonoController.text = doctor.telefono;
      _tarjetaProfesionalController.text = doctor.numeroTarjetaProfesional;
      _especialidadController.text =
          doctor.especialidades.isNotEmpty ? doctor.especialidades.first : '';
      
      _correoController.text = doctor.usuario.correo;
      _contraseniaController.clear();
    } else {
      _editingDoctorId = null;
      _limpiarFormulario();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del diálogo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _editingDoctorId == null ? Icons.person_add : Icons.edit,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _editingDoctorId == null ? 'Registrar nuevo doctor' : 'Editar doctor',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          _limpiarFormulario();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),

                // Contenido del formulario
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sección: Información Personal
                        _buildSectionTitle(Icons.person, 'Información Personal'),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _nombresController,
                          label: 'Nombres',
                          hint: 'Ej: Juan Carlos',
                          icon: Icons.badge,
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),
                        
                        _buildTextField(
                          controller: _apellidosController,
                          label: 'Apellidos',
                          hint: 'Ej: García López',
                          icon: Icons.badge,
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),
                        
                        _buildTextField(
                          controller: _documentoController,
                          label: 'Número de Documento',
                          hint: 'Ej: 1234567890',
                          icon: Icons.credit_card,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),
                        
                        _buildTextField(
                          controller: _telefonoController,
                          label: 'Teléfono',
                          hint: 'Ej: 3001234567',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 24),

                        // Sección: Información Profesional
                        _buildSectionTitle(Icons.medical_services, 'Información Profesional'),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _tarjetaProfesionalController,
                          label: 'Tarjeta Profesional',
                          hint: 'Ej: TP-123456',
                          icon: Icons.card_membership,
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),
                        
                        _buildTextField(
                          controller: _especialidadController,
                          label: 'Especialidad',
                          hint: 'Ej: Cardiología',
                          icon: Icons.local_hospital,
                          isRequired: true,
                        ),

                        const SizedBox(height: 24),

                        // Sección: Credenciales de Acceso
                        _buildSectionTitle(Icons.lock, 'Credenciales de Acceso'),
                        const SizedBox(height: 16),

                        if (_editingDoctorId == null) ...[
                          _buildTextField(
                            controller: _correoController,
                            label: 'Correo Electrónico',
                            hint: 'doctor@ejemplo.com',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            isRequired: true,
                          ),
                          const SizedBox(height: 12),
                          
                          _buildTextField(
                            controller: _contraseniaController,
                            label: 'Contraseña',
                            hint: 'Mínimo 6 caracteres',
                            icon: Icons.password,
                            obscureText: _obscurePassword,
                            isRequired: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.info.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 20, color: AppColors.info),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'El doctor usará estas credenciales para iniciar sesión en la aplicación',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          _buildTextField(
                            controller: _correoController,
                            label: 'Correo Electrónico',
                            icon: Icons.email,
                            enabled: false,
                          ),
                          const SizedBox(height: 12),
                          
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.grey300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lock_outline, size: 20, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'No se pueden modificar las credenciales al editar un doctor',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Botones de acción
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _limpiarFormulario();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _guardarDoctor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _editingDoctorId == null ? Icons.save : Icons.update,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_editingDoctorId == null ? 'Registrar' : 'Actualizar'),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool isRequired = false,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: AppColors.error, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
            prefixIcon: icon != null ? Icon(icon, color: AppColors.primary, size: 20) : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? Colors.white : AppColors.grey100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey200, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey200, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarInformacionDoctor(Doctor doctor) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${doctor.nombres[0]}${doctor.apellidos[0]}'.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información del Doctor',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '${doctor.nombres} ${doctor.apellidos}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Contenido
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection(
                        'Información Personal',
                        Icons.person,
                        [
                          _buildInfoRow('Documento', doctor.numeroDocumento, Icons.badge),
                          _buildInfoRow('Teléfono', doctor.telefono, Icons.phone),
                          _buildInfoRow('Ciudad', doctor.ciudad, Icons.location_city),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildInfoSection(
                        'Información Profesional',
                        Icons.medical_services,
                        [
                          _buildInfoRow(
                            'Especialidad',
                            doctor.especialidades.isNotEmpty ? doctor.especialidades.first : 'N/A',
                            Icons.local_hospital,
                          ),
                          _buildInfoRow(
                            'Tarjeta Profesional',
                            doctor.numeroTarjetaProfesional,
                            Icons.card_membership,
                          ),
                          _buildInfoRow(
                            'Año de Graduación',
                            doctor.anioGraduacion.toString(),
                            Icons.school,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildInfoSection(
                        'Empresa',
                        Icons.business,
                        [
                          _buildInfoRow('Razón Social', widget.empresa.razonSocial, Icons.business),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.info.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lock, color: AppColors.info, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Credenciales de Acceso',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow('Correo', doctor.usuario.correo, Icons.email),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: AppColors.info),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      'El doctor puede iniciar sesión con su correo y contraseña',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer con botón
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: SizedBox(
                  width: double.infinity,
                                    child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _limpiarFormulario() {
    _nombresController.clear();
    _apellidosController.clear();
    _documentoController.clear();
    _telefonoController.clear();
    _especialidadController.clear();
    _tarjetaProfesionalController.clear();
    _correoController.clear();
    _contraseniaController.clear();
    _editingDoctorId = null;
    _obscurePassword = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar con gradiente
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.medical_services,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Doctores',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    widget.empresa.razonSocial,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color.fromARGB(179, 255, 255, 255),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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

          // Barra de búsqueda
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _filtrarDoctores,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, documento o correo',
                  hintStyle: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _filtrarDoctores('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.grey50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.grey200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Lista de doctores
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoDoctor(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Doctor'),
        elevation: 4,
      ),
    );
  }

  Widget _buildContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('doctores')
          .where('empresa_id', isEqualTo: widget.empresa.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Cargando doctores...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_off,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No hay doctores registrados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Presiona + para agregar un doctor',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        _doctores = snapshot.data!.docs.map((doc) {
          return Doctor.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        if (_searchController.text.isEmpty) {
          _doctoresFiltrados = _doctores;
        }

        // Contador de doctores
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '${_doctoresFiltrados.length} ${_doctoresFiltrados.length == 1 ? "doctor" : "doctores"}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }

              final doctor = _doctoresFiltrados[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildDoctorCard(doctor),
              );
            },
            childCount: _doctoresFiltrados.length + 1,
          ),
        );
      },
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return AppCard(
      onTap: () => _mostrarInformacionDoctor(doctor),
      child: Row(
        children: [
          // Avatar con iniciales
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${doctor.nombres[0]}${doctor.apellidos[0]}'.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${doctor.nombres} ${doctor.apellidos}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.local_hospital, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        doctor.especialidades.isNotEmpty ? doctor.especialidades.first : 'N/A',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email, size: 14, color: AppColors.info),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        doctor.usuario.correo,
                        style: const TextStyle(
                          color: AppColors.info,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Menú de opciones
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.more_vert,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'ver') {
                _mostrarInformacionDoctor(doctor);
              } else if (value == 'editar') {
                _mostrarDialogoDoctor(doctor: doctor);
              } else if (value == 'eliminar') {
                _eliminarDoctor(doctor.id!, doctor.usuario.correo);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'ver',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 18, color: AppColors.info),
                    SizedBox(width: 12),
                    Text('Ver detalles'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18, color: AppColors.warning),
                    SizedBox(width: 12),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'eliminar',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Eliminar', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _documentoController.dispose();
    _telefonoController.dispose();
    _especialidadController.dispose();
    _tarjetaProfesionalController.dispose();
    _correoController.dispose();
    _contraseniaController.dispose();
    super.dispose();
  }
}