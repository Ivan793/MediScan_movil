import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediscan_app/controllers/doctor_controller.dart';
import 'package:mediscan_app/models/doctor_model.dart';
import 'package:mediscan_app/models/empresa_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorIndependientePage extends StatefulWidget {
  const DoctorIndependientePage({Key? key}) : super(key: key);

  @override
  State<DoctorIndependientePage> createState() =>
      _DoctorIndependientePageState();
}

class _DoctorIndependientePageState extends State<DoctorIndependientePage> {
  final DoctorController _doctorController = DoctorController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Doctor? _doctorActual;
  Empresa? _empresaAsociada;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDoctorActual();
  }

  Future<void> _cargarDoctorActual() async {
    setState(() => _cargando = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No hay usuario autenticado");
      }

      final docSnapshot = await _firestore
          .collection('doctores')
          .doc(user.uid)
          .get();

      if (!docSnapshot.exists) {
        throw Exception("Doctor no encontrado");
      }

      _doctorActual = Doctor.fromMap(docSnapshot.data()!, docSnapshot.id);

      if (_doctorActual!.empresaId != null &&
          _doctorActual!.empresaId!.isNotEmpty) {
        final empresaSnapshot = await _firestore
            .collection('empresas')
            .doc(_doctorActual!.empresaId)
            .get();

        if (empresaSnapshot.exists) {
          _empresaAsociada = Empresa.fromMap(
            empresaSnapshot.data()!,
            empresaSnapshot.id,
          );
        }
      }
    } catch (e) {
      print("Error al cargar el doctor actual: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Inicio del Doctor"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _doctorActual == null
          ? const Center(child: Text("No se encontró información del doctor"))
          : RefreshIndicator(
              onRefresh: _cargarDoctorActual,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _encabezadoPerfil(),
                    const SizedBox(height: 20),

                    if (_empresaAsociada != null) ...[
                      _seccionEmpresaAsociada(),
                      const SizedBox(height: 20),
                    ],

                    // Acciones principales
                    _accionesPrincipales(),
                    const SizedBox(height: 20),

                    _seccionInfoPersonal(),
                    const SizedBox(height: 20),
                    _seccionInfoProfesional(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _encabezadoPerfil() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 45, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_doctorActual!.nombres} ${_doctorActual!.apellidos}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_doctorActual!.especialidades.isNotEmpty)
                  Text(
                    _doctorActual!.especialidades.first,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccionEmpresaAsociada() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.indigo.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Empresa Asociada",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _fila("🏢 Razón Social:", _empresaAsociada!.razonSocial),
            _fila("🆔 NIT:", _empresaAsociada!.nit),
            _fila("📞 Teléfono:", _empresaAsociada!.telefono),
            _fila("🌍 Ciudad:", _empresaAsociada!.ciudad),
          ],
        ),
      ),
    );
  }

  Widget _accionesPrincipales() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Acciones Rápidas",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _botonAccionGrande(
                Icons.people,
                "Pacientes",
                Colors.blue,
                () => Navigator.pushNamed(context, '/pacientes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _botonAccionGrande(
                Icons.medical_services,
                "Análisis",
                Colors.orange,
                () => Navigator.pushNamed(context, '/analisis'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _botonAccionGrande(
            Icons.edit,
            "Editar Perfil",
            Colors.green,
            () async {
              if (_doctorActual!.empresaId != null &&
                  _doctorActual!.empresaId!.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Los doctores asociados a una empresa no pueden editar su perfil.",
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final actualizado = await _mostrarModalEditarDoctor(
                _doctorActual!,
              );

              if (actualizado == true) {
                await _cargarDoctorActual();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _botonAccionGrande(
    IconData icono,
    String texto,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                texto,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccionInfoPersonal() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Información Personal",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _fila("Documento", _doctorActual!.numeroDocumento),
            _fila("Teléfono", _doctorActual!.telefono),
            _fila("Dirección", _doctorActual!.direccion),
            _fila("Ciudad", _doctorActual!.ciudad),
            _fila("País", _doctorActual!.pais),
            _fila("Correo", _doctorActual!.usuario.correo),
          ],
        ),
      ),
    );
  }

  Widget _seccionInfoProfesional() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Información Profesional",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _fila("Rethus", _doctorActual!.rethus),
            _fila(
              "Tarjeta Profesional",
              _doctorActual!.numeroTarjetaProfesional,
            ),
            _fila(
              "Año de Graduación",
              _doctorActual!.anioGraduacion.toString(),
            ),
            _fila("Especialidades", _doctorActual!.especialidades.join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _fila(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value.isNotEmpty ? value : "No especificado",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _mostrarModalEditarDoctor(Doctor doctor) {
    final _formKey = GlobalKey<FormState>();
    final DoctorController _doctorController = DoctorController();

    final telefonoController = TextEditingController(text: doctor.telefono);
    final direccionController = TextEditingController(text: doctor.direccion);
    final ciudadController = TextEditingController(text: doctor.ciudad);
    final paisController = TextEditingController(text: doctor.pais);

    bool guardando = false;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Center(
                        child: Text(
                          "Editar Información Personal",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _campoTexto("Teléfono", telefonoController),
                      const SizedBox(height: 16),
                      _campoTexto("Dirección", direccionController),
                      const SizedBox(height: 16),
                      _campoTexto("Ciudad", ciudadController),
                      const SizedBox(height: 16),
                      _campoTexto("País", paisController),
                      const SizedBox(height: 25),
                      ElevatedButton.icon(
                        onPressed: guardando
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                setModalState(() => guardando = true);

                                try {
                                  final doctorActualizado = Doctor(
                                    id: doctor.id,
                                    empresaId: doctor.empresaId,
                                    nombres: doctor.nombres,
                                    apellidos: doctor.apellidos,
                                    tipoDocumento: doctor.tipoDocumento,
                                    numeroDocumento: doctor.numeroDocumento,
                                    telefono: telefonoController.text.trim(),
                                    direccion: direccionController.text.trim(),
                                    ciudad: ciudadController.text.trim(),
                                    pais: paisController.text.trim(),
                                    fechaNacimiento: doctor.fechaNacimiento ?? DateTime(2000, 1, 1),
                                    genero: doctor.genero ?? '',
                                    rethus: doctor.rethus,
                                    numeroTarjetaProfesional:
                                        doctor.numeroTarjetaProfesional,
                                    especialidades: doctor.especialidades,
                                    anioGraduacion: doctor.anioGraduacion,
                                    archivoTarjetaProfesional:
                                        doctor.archivoTarjetaProfesional,
                                    archivoTituloGrado:
                                        doctor.archivoTituloGrado,
                                    archivoRethus: doctor.archivoRethus,
                                    archivoEspecialidad:
                                        doctor.archivoEspecialidad,
                                    usuario: doctor.usuario,
                                  );

                                  await _doctorController.actualizarDoctor(
                                    doctor.id!,
                                    doctorActualizado,
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Perfil actualizado correctamente",
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                  Navigator.pop(context, true);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Error al guardar: $e"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  setModalState(() => guardando = false);
                                }
                              },
                        icon: guardando
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text("Guardar cambios"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _campoTexto(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Ingrese $label";
        }
        return null;
      },
    );
  }
}