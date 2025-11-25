import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mediscan_app/controllers/paciente_controller.dart';
import 'package:mediscan_app/controllers/analisis_controller.dart';
import 'package:mediscan_app/models/paciente_model.dart';
import 'package:mediscan_app/models/analisis_model.dart';
import 'package:mediscan_app/ui/theme/app_colors.dart';
import 'package:mediscan_app/ui/widgets/app_widgets.dart';

class AnalisisGestionPage extends StatefulWidget {
  const AnalisisGestionPage({Key? key}) : super(key: key);

  @override
  State<AnalisisGestionPage> createState() => _AnalisisGestionPageState();
}

class _AnalisisGestionPageState extends State<AnalisisGestionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
            backgroundColor: AppColors.error,
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

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'finalizado':
        return AppColors.success;
      case 'en_proceso':
        return AppColors.warning;
      case 'pendiente':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getEstadoLabel(String estado) {
    switch (estado.toLowerCase()) {
      case 'finalizado':
        return 'Finalizado';
      case 'en_proceso':
        return 'En Proceso';
      case 'pendiente':
        return 'Pendiente';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
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
                                  Icons.analytics,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gestión de Análisis',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Administra los análisis médicos',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
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
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.add_circle), text: "Nuevo"),
                  Tab(icon: Icon(Icons.history), text: "Historial"),
                  Tab(icon: Icon(Icons.pending_actions), text: "Pendientes"),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildNuevoAnalisisTab(),
            _buildHistorialTab(),
            _buildPendientesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildNuevoAnalisisTab() {
    return Column(
      children: [
        // Buscador
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: TextField(
            controller: _searchController,
            onChanged: _filtrarPacientes,
            decoration: InputDecoration(
              hintText: 'Buscar paciente...',
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _filtrarPacientes('');
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
            ),
          ),
        ),

        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Cargando pacientes...', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (_pacientesFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80, color: AppColors.textTertiary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay pacientes registrados'
                  : 'No se encontraron pacientes',
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarPacientes,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pacientesFiltrados.length,
        itemBuilder: (context, index) {
          final paciente = _pacientesFiltrados[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              onTap: () => _seleccionarPaciente(paciente),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paciente.nombreCompleto,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${paciente.tipoDocumento}: ${paciente.numeroDocumento}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistorialTab() {
    if (_doctorId == null) {
      return const Center(child: Text("Cargando información..."));
    }

    return StreamBuilder<List<Analisis>>(
      stream: _analisisController.streamAnalisisDoctor(_doctorId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error al cargar historial",
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: AppColors.textTertiary.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  "No hay análisis registrados",
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        final analisis = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: analisis.length,
          itemBuilder: (context, index) {
            final a = analisis[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCardAnalisis(a),
            );
          },
        );
      },
    );
  }

  Widget _buildPendientesTab() {
    if (_doctorId == null) {
      return const Center(child: Text("Cargando..."));
    }

    return StreamBuilder<List<Analisis>>(
      stream: _analisisController
          .streamAnalisisDoctor(_doctorId!)
          .map((lista) => lista.where((a) => a.estado != "finalizado").toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final pendientes = snapshot.data!;

        if (pendientes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 80, color: AppColors.success.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  "No hay análisis pendientes",
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendientes.length,
          itemBuilder: (context, index) {
            final a = pendientes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCardAnalisis(a),
            );
          },
        );
      },
    );
  }

  Widget _buildCardAnalisis(Analisis analisis) {
    final estadoColor = _getEstadoColor(analisis.estado);
    
    return AppCard(
      onTap: () => _mostrarDetalleAnalisis(analisis),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: estadoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medical_services,
              color: estadoColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analisis.nombrePaciente ?? "Paciente desconocido",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                StatusChip(
                  label: _getEstadoLabel(analisis.estado),
                  color: estadoColor,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  void _mostrarDetalleAnalisis(Analisis a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.grey300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Nombre del paciente
                  Center(
                    child: Column(
                      children: [
                        Text(
                          a.nombrePaciente ?? "Paciente desconocido",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StatusChip(
                          label: _getEstadoLabel(a.estado),
                          color: _getEstadoColor(a.estado),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Imagen
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      a.imagenUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (a.diagnostico != null) ...[
                    _buildInfoCard(
                      'Diagnóstico',
                      a.diagnostico!,
                      Icons.medical_information,
                      AppColors.error,
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (a.confianza != null) ...[
                    _buildInfoCard(
                      'Confianza del modelo',
                      "${a.confianza!.toStringAsFixed(2)}%",
                      Icons.verified,
                      AppColors.success,
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (a.datosIA != null && a.datosIA!.isNotEmpty) ...[
                    const Text(
                      "Predicciones IA",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...a.datosIA!.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildInfoCard(
                          e.key,
                          "${(double.tryParse(e.value.toString()) ?? 0).toStringAsFixed(2)}%",
                          Icons.list_alt,
                          AppColors.info,
                        ),
                      );
                    }).toList(),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}