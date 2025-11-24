import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediscan_app/models/doctor_model.dart';
import 'package:mediscan_app/models/empresa_model.dart';
import 'package:mediscan_app/models/usuario_model.dart';
import 'package:mediscan_app/services/usuario_service.dart';

class DoctorEmpresaModule extends StatefulWidget {
  final Empresa empresa;

  const DoctorEmpresaModule({Key? key, required this.empresa}) : super(key: key);

  @override
  State<DoctorEmpresaModule> createState() => _DoctorEmpresaModuleState();
}

class _DoctorEmpresaModuleState extends State<DoctorEmpresaModule> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UsuarioService _usuarioService = UsuarioService();

  // Controladores de información personal
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _especialidadController = TextEditingController();
  final TextEditingController _tarjetaProfesionalController = TextEditingController();
  
  // 🔹 Nuevos controladores para credenciales de acceso
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contraseniaController = TextEditingController();

  String? _editingDoctorId;
  bool _isLoading = false;

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
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validación de contraseña (mínimo 6 caracteres)
    if (_contraseniaController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_editingDoctorId == null) {
        // 🔹 CREAR NUEVO DOCTOR CON CUENTA DE USUARIO
        
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Doctor registrado exitosamente\n'
              'Usuario: ${usuario.correo}\n'
              'El doctor ya puede iniciar sesión',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // 🔹 ACTUALIZAR DOCTOR EXISTENTE (sin cambiar credenciales)
        
        final doctorData = {
          'nombres': _nombresController.text,
          'apellidos': _apellidosController.text,
          'numero_documento': _documentoController.text,
          'telefono': _telefonoController.text,
          'numero_tarjeta_profesional': _tarjetaProfesionalController.text,
          'especialidades': [_especialidadController.text],
        };

        await _db.collection('doctores').doc(_editingDoctorId).update(doctorData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Doctor actualizado exitosamente'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      _limpiarFormulario();
      Navigator.pop(context);
    } catch (e) {
      print('Error al guardar doctor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarDoctor(String id, String correo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Deseas eliminar este doctor?'),
            const SizedBox(height: 10),
            const Text(
              'Nota: La cuenta de usuario NO se eliminará de Firebase Auth, '
              'pero el doctor ya no aparecerá en tu lista.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.collection('doctores').doc(id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor eliminado de la empresa'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
      
      // Al editar, mostramos el correo pero NO permitimos cambiarlo
      _correoController.text = doctor.usuario.correo;
      _contraseniaController.clear();
    } else {
      _editingDoctorId = null;
      _limpiarFormulario();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editingDoctorId == null ? 'Registrar nuevo doctor' : 'Editar doctor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Información personal
              const Text(
                '👤 Información Personal',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              TextField(
                controller: _nombresController,
                decoration: const InputDecoration(labelText: 'Nombres *'),
              ),
              TextField(
                controller: _apellidosController,
                decoration: const InputDecoration(labelText: 'Apellidos *'),
              ),
              TextField(
                controller: _documentoController,
                decoration: const InputDecoration(labelText: 'Documento *'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: _tarjetaProfesionalController,
                decoration: const InputDecoration(labelText: 'Tarjeta profesional *'),
              ),
              TextField(
                controller: _especialidadController,
                decoration: const InputDecoration(labelText: 'Especialidad *'),
              ),
              
              const SizedBox(height: 20),
              
              // 🔹 Credenciales de acceso
              const Text(
                '🔐 Credenciales de Acceso',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              
              if (_editingDoctorId == null) ...[
                // Solo mostrar estos campos al crear un nuevo doctor
                TextField(
                  controller: _correoController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico *',
                    hintText: 'doctor@ejemplo.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _contraseniaController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña *',
                    hintText: 'Mínimo 6 caracteres',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                const Text(
                  '💡 El doctor usará estas credenciales para iniciar sesión',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                // Al editar, solo mostramos el correo (sin permitir edición)
                TextField(
                  controller: _correoController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    enabled: false,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ℹ️ No se pueden modificar las credenciales al editar',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _limpiarFormulario();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _guardarDoctor,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
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
                : Text(_editingDoctorId == null ? 'Registrar' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  void _mostrarInformacionDoctor(Doctor doctor) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Información del doctor'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '👤 ${doctor.nombres} ${doctor.apellidos}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              const SizedBox(height: 10),
              _infoRow('📄 Documento:', doctor.numeroDocumento),
              _infoRow('📞 Teléfono:', doctor.telefono),
              _infoRow('💼 Especialidad:', 
                  doctor.especialidades.isNotEmpty ? doctor.especialidades.first : 'N/A'),
              _infoRow('🎓 Año de graduación:', doctor.anioGraduacion.toString()),
              _infoRow('🪪 Tarjeta profesional:', doctor.numeroTarjetaProfesional),
              _infoRow('🌍 Ciudad:', doctor.ciudad),
              _infoRow('🏢 Empresa:', widget.empresa.razonSocial),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                '🔐 Credenciales de acceso:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              _infoRow('✉️ Correo:', doctor.usuario.correo),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '💡 El doctor puede iniciar sesión con su correo y contraseña',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctores de ${widget.empresa.razonSocial}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () => _mostrarDialogoDoctor(),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('doctores')
              .where('empresa_id', isEqualTo: widget.empresa.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay doctores asociados',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Presiona + para agregar un doctor',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final doctores = snapshot.data!.docs.map((doc) {
              return Doctor.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            }).toList();

            return ListView.builder(
              itemCount: doctores.length,
              itemBuilder: (context, index) {
                final doctor = doctores[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: Text(
                        '${doctor.nombres[0]}${doctor.apellidos[0]}'.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      '${doctor.nombres} ${doctor.apellidos}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Especialidad: ${doctor.especialidades.isNotEmpty ? doctor.especialidades.first : 'N/A'}',
                        ),
                        Text(
                          '📧 ${doctor.usuario.correo}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'Tel: ${doctor.telefono}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () => _mostrarInformacionDoctor(doctor),
                    trailing: PopupMenuButton<String>(
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
                              Icon(Icons.visibility, size: 18),
                              SizedBox(width: 8),
                              Text('Ver detalles'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
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