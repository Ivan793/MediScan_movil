import 'package:flutter/material.dart';
import 'package:mediscan_app/controllers/doctor_controller.dart';
import 'package:mediscan_app/models/doctor_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorIndependientePage extends StatefulWidget {
  const DoctorIndependientePage({Key? key}) : super(key: key);

  @override
  State<DoctorIndependientePage> createState() => _DoctorIndependientePageState();
}

class _DoctorIndependientePageState extends State<DoctorIndependientePage> {
  final DoctorController _doctorController = DoctorController();
  Doctor? _doctorActual;
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

      // Obtener todos los doctores y filtrar por el correo del usuario
      final doctores = await _doctorController.obtenerDoctores();
      _doctorActual = doctores.firstWhere(
        (doc) => doc.usuario.correo == user.email,
        orElse: () => throw Exception("Doctor no encontrado"),
      );
    } catch (e) {
      print("Error al cargar el doctor actual: $e");
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Inicio del Doctor"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _doctorActual == null
              ? const Center(
                  child: Text("No se encontró información del doctor"),
                )
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
                        _seccionInfoPersonal(),
                        const SizedBox(height: 20),
                        _seccionInfoProfesional(),
                        const SizedBox(height: 20),
                        _accionesRapidas(),
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
            child: Text(
              "${_doctorActual!.nombres} ${_doctorActual!.apellidos}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
            const Text("Información Personal",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _fila("Documento", _doctorActual!.numeroDocumento),
            _fila("Teléfono", _doctorActual!.telefono),
            _fila("Dirección", _doctorActual!.direccion),
            _fila("Ciudad", _doctorActual!.ciudad),
            _fila("País", _doctorActual!.pais),
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
            const Text("Información Profesional",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _fila("Rethus", _doctorActual!.rethus),
            _fila("Tarjeta Profesional", _doctorActual!.numeroTarjetaProfesional),
            _fila("Año de Graduación", _doctorActual!.anioGraduacion.toString()),
            _fila("Especialidades", _doctorActual!.especialidades.join(', ')),
            const SizedBox(height: 10),
            const Text("Archivos cargados:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            _archivo("Tarjeta Profesional", _doctorActual!.archivoTarjetaProfesional),
            _archivo("Título de Grado", _doctorActual!.archivoTituloGrado),
            _archivo("Registro Rethus", _doctorActual!.archivoRethus),
            _archivo("Especialidad", _doctorActual!.archivoEspecialidad),
          ],
        ),
      ),
    );
  }

  Widget _accionesRapidas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Acciones Rápidas",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _botonAccion(Icons.edit, "Editar Perfil", Colors.blue, () {
              // Aquí puedes navegar a la pantalla de edición
            }),
            _botonAccion(Icons.people, "Pacientes", Colors.green, () {
              // Navegar a la vista de pacientes
            }),
            _botonAccion(Icons.medical_services, "Servicios", Colors.orange, () {
              // Navegar a servicios ofrecidos
            }),
          ],
        ),
      ],
    );
  }

  Widget _botonAccion(IconData icono, String texto, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 5),
        Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _fila(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text("$label:",
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
              flex: 5,
              child: Text(value.isNotEmpty ? value : "No especificado",
                  style: const TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _archivo(String label, String? archivo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text("- $label: ${archivo ?? 'No disponible'}",
          style: const TextStyle(color: Colors.grey)),
    );
  }
}
