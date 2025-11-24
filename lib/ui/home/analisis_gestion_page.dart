import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mediscan_app/controllers/paciente_controller.dart';
import 'package:mediscan_app/controllers/analisis_controller.dart';
import 'package:mediscan_app/models/paciente_model.dart';
import 'package:mediscan_app/models/analisis_model.dart';

class AnalisisGestionPage extends StatefulWidget {
  const AnalisisGestionPage({Key? key}) : super(key: key);

  @override
  State<AnalisisGestionPage> createState() => _AnalisisGestionPageState();
}

class _AnalisisGestionPageState extends State<AnalisisGestionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controladores existentes
  final PacienteController _pacienteController = PacienteController();
  final AnalisisController _analisisController = AnalisisController();
  final TextEditingController _searchController = TextEditingController();

  List<Paciente> _pacientes = [];
  List<Paciente> _pacientesFiltrados = [];
  bool _isLoading = true;
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _inicializar();
  }

  Future<void> _inicializar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _doctorId = user.uid;
      await _cargarPacientes();
    }
  }

  Future<void> _cargarPacientes() async {
    if (_doctorId == null) return;

    setState(() => _isLoading = true);

    try {
      final pacientes = await _pacienteController.obtenerPacientesDoctor(
        _doctorId!,
      );
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
    Navigator.pushNamed(context, '/nuevo-analisis', arguments: paciente);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        title: const Text('Gestión de Análisis'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,

        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle), text: "Nuevo análisis"),
            Tab(icon: Icon(Icons.history), text: "Historial"),
            Tab(icon: Icon(Icons.pending_actions), text: "Pendientes"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNuevoAnalisisTab(),
          _buildHistorialTab(),
          _buildPendientesTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🔵 TAB 1: NUEVO ANÁLISIS (TU CÓDIGO ORIGINAL)
  // ---------------------------------------------------------------------------

  Widget _buildNuevoAnalisisTab() {
    return Column(
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
                      style: TextStyle(color: Colors.white70, fontSize: 14),
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

        Expanded(child: _buildContent()),
      ],
    );
  }

  // Reutilizamos tu código original sin cambiarlo
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
            if (_searchController.text.isNotEmpty)
              TextButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/registrar-paciente'),
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
                child: Icon(Icons.arrow_forward, color: Colors.blue.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🟩 TAB 2: HISTORIAL
  // ---------------------------------------------------------------------------

  Widget _buildHistorialTab() {
    if (_doctorId == null) {
      return const Center(child: Text("Cargando información..."));
    }

    return StreamBuilder<List<Analisis>>(
      stream: _analisisController.streamAnalisisDoctor(_doctorId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error al cargar historial: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No hay análisis registrados",
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        final analisis = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: analisis.length,
          itemBuilder: (context, index) {
            final a = analisis[index];
            return _buildCardAnalisis(a);
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 🟧 TAB 3: PENDIENTES
  // ---------------------------------------------------------------------------

  Widget _buildPendientesTab() {
    if (_doctorId == null) {
      return const Center(child: Text("Cargando..."));
    }

    return StreamBuilder<List<Analisis>>(
      stream: _analisisController
          .streamAnalisisDoctor(_doctorId!)
          .map(
            (lista) => lista.where((a) => a.estado != "finalizado").toList(),
          ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendientes = snapshot.data!;

        if (pendientes.isEmpty) {
          return const Center(child: Text("No hay análisis pendientes"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: pendientes.length,
          itemBuilder: (context, index) {
            final a = pendientes[index];
            return _buildCardAnalisis(a);
          },
        );
      },
    );
  }

  Widget _tituloSeccion(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _tarjetaInfo({
    required IconData icon,
    required Color color,
    required String contenido,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              contenido,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalleAnalisis(Analisis a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.90,
          minChildSize: 0.65,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra superior
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // 🧑‍⚕️ ENCABEZADO: Nombre del paciente
                  Center(
                    child: Column(
                      children: [
                        Text(
                          a.nombrePaciente ?? "Paciente desconocido",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Análisis clínico",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 📸 Imagen del análisis
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      a.imagenUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 🩺 Diagnóstico principal
                  _tituloSeccion("Diagnóstico"),
                  _tarjetaInfo(
                    icon: Icons.medical_information,
                    color: Colors.red.shade700,
                    contenido: a.diagnostico ?? "Sin diagnóstico",
                  ),

                  const SizedBox(height: 15),

                  // 📊 Confianza
                  _tituloSeccion("Confianza del modelo"),
                  _tarjetaInfo(
                    icon: Icons.verified,
                    color: Colors.green.shade700,
                    contenido: "${((a.confianza ?? 0)).toStringAsFixed(2)}%",
                  ),

                  const SizedBox(height: 15),

                  // 🔍 Predicciones IA
                  if (a.datosIA != null && a.datosIA!.isNotEmpty) ...[
                    _tituloSeccion("Predicciones IA"),
                    Column(
                      children: a.datosIA!.entries.map((e) {
                        return _tarjetaInfo(
                          icon: Icons.list_alt,
                          color: Colors.blue.shade700,
                          contenido:
                              "${e.key}: ${(double.tryParse(e.value.toString())!).toStringAsFixed(2)}%",
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 15),
                  ],

                  // 📝 Tipo de análisis
                  _tituloSeccion("Tipo de análisis"),
                  _tarjetaInfo(
                    icon: Icons.category,
                    color: Colors.purple.shade700,
                    contenido: a.tipoAnalisis ?? "No especificado",
                  ),

                  const SizedBox(height: 15),

                  // 📅 Fecha
                  _tituloSeccion("Fecha del análisis"),
                  _tarjetaInfo(
                    icon: Icons.calendar_month,
                    color: Colors.orange.shade700,
                    contenido: a.fechaAnalisis.toString(),
                  ),

                  const SizedBox(height: 15),

                  // 📘 Observaciones
                  _tituloSeccion("Observaciones"),
                  _tarjetaInfo(
                    icon: Icons.description,
                    color: Colors.grey.shade700,
                    contenido: a.observaciones ?? "Sin observaciones",
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCardAnalisis(Analisis analisis) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.analytics, color: Colors.blue),
        ),
        title: Text(
          analisis.diagnostico ?? "Sin diagnóstico",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Fecha: ${analisis.fechaAnalisis}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () => _mostrarDetalleAnalisis(analisis),
      ),
    );
  }
}
