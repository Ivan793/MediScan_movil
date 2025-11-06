import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mediscan_app/controllers/paciente_controller.dart';
import 'package:mediscan_app/models/paciente_model.dart';

class PacientesListPage extends StatefulWidget {
  const PacientesListPage({Key? key}) : super(key: key);

  @override
  State<PacientesListPage> createState() => _PacientesListPageState();
}

class _PacientesListPageState extends State<PacientesListPage> {
  final PacienteController _controller = PacienteController();
  final TextEditingController _searchController = TextEditingController();
  List<Paciente> _pacientes = [];
  List<Paciente> _pacientesFiltrados = [];
  bool _isLoading = true;
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _cargarDoctorId();
  }

  Future<void> _cargarDoctorId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => _doctorId = user.uid);
      await _cargarPacientes();
    }
  }

  Future<void> _cargarPacientes() async {
    if (_doctorId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final pacientes = await _controller.obtenerPacientesDoctor(_doctorId!);
      setState(() {
        _pacientes = pacientes;
        _pacientesFiltrados = pacientes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar pacientes: $e')),
        );
      }
    }
  }

  void _filtrarPacientes(String query) {
    setState(() {
      if (query.isEmpty) {
        _pacientesFiltrados = _pacientes;
      } else {
        _pacientesFiltrados = _pacientes.where((p) {
          final nombre = p.nombreCompleto.toLowerCase();
          final documento = p.numeroDocumento.toLowerCase();
          final busqueda = query.toLowerCase();
          return nombre.contains(busqueda) || documento.contains(busqueda);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mis Pacientes'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navegar a formulario de registro (lo crearemos después)
          final resultado = await Navigator.pushNamed(context, '/registrar-paciente');
          if (resultado == true) {
            _cargarPacientes();
          }
        },
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filtrarPacientes,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o documento',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filtrarPacientes('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Lista de pacientes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pacientesFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No hay pacientes registrados'
                                  : 'No se encontraron pacientes',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Presiona + para agregar un paciente',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarPacientes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _pacientesFiltrados.length,
                          itemBuilder: (context, index) {
                            final paciente = _pacientesFiltrados[index];
                            return _buildPacienteCard(paciente);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPacienteCard(Paciente paciente) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          // Navegar a detalle del paciente (lo crearemos después)
          await Navigator.pushNamed(
            context,
            '/detalle-paciente',
            arguments: paciente,
          );
          _cargarPacientes();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  paciente.nombres[0].toUpperCase() + paciente.apellidos[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                      paciente.nombreCompleto,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${paciente.tipoDocumento}: ${paciente.numeroDocumento}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${paciente.edad} años',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          paciente.genero?.toLowerCase() == 'masculino'
                              ? Icons.male
                              : Icons.female,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          paciente.genero ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botón de ver más
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}