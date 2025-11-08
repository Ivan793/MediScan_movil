import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mediscan_app/controllers/paciente_controller.dart';
import 'package:mediscan_app/models/paciente_model.dart';

class AnalisisGestionPage extends StatefulWidget {
  const AnalisisGestionPage({Key? key}) : super(key: key);

  @override
  State<AnalisisGestionPage> createState() => _AnalisisGestionPageState();
}

class _AnalisisGestionPageState extends State<AnalisisGestionPage> {
  final PacienteController _pacienteController = PacienteController();
  final TextEditingController _searchController = TextEditingController();
  List<Paciente> _pacientes = [];
  List<Paciente> _pacientesFiltrados = [];
  bool _isLoading = true;
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
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
      final pacientes = await _pacienteController.obtenerPacientesDoctor(_doctorId!);
      setState(() {
        _pacientes = pacientes;
        _pacientesFiltrados = pacientes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar pacientes: $e'),
            backgroundColor: Colors.red,
          ),
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

  void _seleccionarPaciente(Paciente paciente) {
    Navigator.pushNamed(
      context,
      '/nuevo-analisis',
      arguments: paciente,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Nuevo Análisis'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Instrucción
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_search,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccione un paciente',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Toque en un paciente para iniciar el análisis',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filtrarPacientes,
              decoration: InputDecoration(
                hintText: 'Buscar paciente...',
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
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando pacientes...'),
          ],
        ),
      );
    }

    if (_pacientesFiltrados.isEmpty) {
      return Center(
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
            if (_searchController.text.isEmpty)
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/registrar-paciente'),
                icon: const Icon(Icons.person_add),
                label: const Text('Registrar primer paciente'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarPacientes,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _pacientesFiltrados.length,
        itemBuilder: (context, index) {
          final paciente = _pacientesFiltrados[index];
          return _buildPacienteCard(paciente);
        },
      ),
    );
  }

  Widget _buildPacienteCard(Paciente paciente) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _seleccionarPaciente(paciente),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    paciente.nombres[0].toUpperCase() + 
                    paciente.apellidos[0].toUpperCase(),
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
                      paciente.nombreCompleto,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${paciente.tipoDocumento}: ${paciente.numeroDocumento}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.cake, size: 14, color: Colors.grey[600]),
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
                          size: 14,
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

              // Botón de selección
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.blue.shade700,
                ),
              ),
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