import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediscan_app/models/doctor_model.dart';
import 'package:mediscan_app/models/empresa_model.dart';
import 'package:mediscan_app/models/usuario_model.dart';

class DoctorEmpresaModule extends StatefulWidget {
  final Empresa empresa;

  const DoctorEmpresaModule({Key? key, required this.empresa}) : super(key: key);

  @override
  State<DoctorEmpresaModule> createState() => _DoctorEmpresaModuleState();
}

class _DoctorEmpresaModuleState extends State<DoctorEmpresaModule> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _especialidadController = TextEditingController();
  final TextEditingController _tarjetaProfesionalController = TextEditingController();

  String? _editingDoctorId;

  Future<void> _guardarDoctor() async {
    if (_nombresController.text.isEmpty ||
        _apellidosController.text.isEmpty ||
        _documentoController.text.isEmpty ||
        _tarjetaProfesionalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, complete todos los campos')),
      );
      return;
    }

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
      usuario: Usuario(
        correo:
            '${_nombresController.text.toLowerCase()}.${_apellidosController.text.toLowerCase()}@${widget.empresa.razonSocial.toLowerCase()}.com',
        contrasenia: '123456',
        rol: 'doctor',
      ),
      empresaId: widget.empresa.id,
    ).toMap();

    if (_editingDoctorId == null) {
      await _db.collection('doctores').add(doctorData);
    } else {
      await _db.collection('doctores').doc(_editingDoctorId).update(doctorData);
    }

    _limpiarFormulario();
    Navigator.pop(context);
  }

  Future<void> _eliminarDoctor(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Deseas eliminar este doctor?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) await _db.collection('doctores').doc(id).delete();
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
            children: [
              TextField(controller: _nombresController, decoration: const InputDecoration(labelText: 'Nombres')),
              TextField(controller: _apellidosController, decoration: const InputDecoration(labelText: 'Apellidos')),
              TextField(controller: _documentoController, decoration: const InputDecoration(labelText: 'Documento')),
              TextField(controller: _telefonoController, decoration: const InputDecoration(labelText: 'Teléfono')),
              TextField(controller: _tarjetaProfesionalController, decoration: const InputDecoration(labelText: 'Tarjeta profesional')),
              TextField(controller: _especialidadController, decoration: const InputDecoration(labelText: 'Especialidad')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: _guardarDoctor,
            child: Text(_editingDoctorId == null ? 'Guardar' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  void _mostrarInformacionDoctor(Doctor doctor) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Información del doctor'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('👤 ${doctor.nombres} ${doctor.apellidos}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('📄 Documento: ${doctor.numeroDocumento}'),
              Text('📞 Teléfono: ${doctor.telefono}'),
              Text('💼 Especialidad: ${doctor.especialidades.isNotEmpty ? doctor.especialidades.first : 'N/A'}'),
              Text('🎓 Año de graduación: ${doctor.anioGraduacion}'),
              Text('🪪 Tarjeta profesional: ${doctor.numeroTarjetaProfesional}'),
              Text('🌍 Ciudad: ${doctor.ciudad}'),
              Text('🏢 Empresa: ${widget.empresa.razonSocial}'),
              Text('✉️ Correo: ${doctor.usuario.correo}'),
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

  void _limpiarFormulario() {
    _nombresController.clear();
    _apellidosController.clear();
    _documentoController.clear();
    _telefonoController.clear();
    _especialidadController.clear();
    _tarjetaProfesionalController.clear();
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
          stream: _db.collection('doctores')
              .where('empresa_id', isEqualTo: widget.empresa.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No hay doctores asociados'));
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
                    leading: const Icon(Icons.person, color: Colors.indigo),
                    title: Text('${doctor.nombres} ${doctor.apellidos}'),
                    subtitle: Text(
                      'Especialidad: ${doctor.especialidades.isNotEmpty ? doctor.especialidades.first : 'N/A'}\n'
                      'Tel: ${doctor.telefono}',
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
                          _eliminarDoctor(doctor.id!);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'editar', child: Text('Editar')),
                        const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
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
}
