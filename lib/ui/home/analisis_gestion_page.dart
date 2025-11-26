import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mediscan_app/controllers/paciente_controller.dart';
import 'package:mediscan_app/controllers/analisis_controller.dart';
import 'package:mediscan_app/models/paciente_model.dart';
import 'package:mediscan_app/models/analisis_model.dart';
import 'package:mediscan_app/ui/theme/app_colors.dart';
import 'package:mediscan_app/ui/widgets/app_widgets.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController _searchHistorialController = TextEditingController();

  List<Paciente> _pacientes = [];
  List<Paciente> _pacientesFiltrados = [];
  List<Analisis> _todosAnalisis = [];
  
  bool _isLoading = true;
  String? _doctorId;
  
  // Variables de filtro
  String? _diagnosticoSeleccionado;
  String _terminoBusquedaActivo = '';
  List<String> _diagnosticosDisponibles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  void _actualizarAnalisis(List<Analisis> analisis) {
    _todosAnalisis = analisis;
    
    // Extraer diagnósticos únicos
    final diagnosticos = analisis
        .where((a) => a.diagnostico != null && a.diagnostico!.isNotEmpty)
        .map((a) => a.diagnostico!)
        .toSet()
        .toList();
    diagnosticos.sort();
    
    _diagnosticosDisponibles = diagnosticos;
  }

  List<Analisis> get _analisisFiltrados {
    final filtrados = _todosAnalisis.where((analisis) {
      // Filtro por búsqueda de texto (solo si se ha presionado buscar)
      if (_terminoBusquedaActivo.isNotEmpty) {
        final searchTerm = _terminoBusquedaActivo.toLowerCase();
        final nombrePaciente = (analisis.nombrePaciente ?? '').toLowerCase();
        final diagnostico = (analisis.diagnostico ?? '').toLowerCase();
        
        if (!nombrePaciente.contains(searchTerm) && 
            !diagnostico.contains(searchTerm)) {
          return false;
        }
      }
      
      // Filtro por diagnóstico
      if (_diagnosticoSeleccionado != null && 
          _diagnosticoSeleccionado != 'Todos') {
        if (analisis.diagnostico != _diagnosticoSeleccionado) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Ordenar por fecha más reciente primero
    filtrados.sort((a, b) {
      if (a.fechaAnalisis == null) return 1;
      if (b.fechaAnalisis == null) return -1;
      return b.fechaAnalisis!.compareTo(a.fechaAnalisis!);
    });
    
    return filtrados;
  }

  void _aplicarBusqueda() {
    setState(() {
      _terminoBusquedaActivo = _searchHistorialController.text;
    });
  }

  void _aplicarFiltros() {
    setState(() {});
  }

  void _limpiarFiltros() {
    setState(() {
      _diagnosticoSeleccionado = null;
      _searchHistorialController.clear();
      _terminoBusquedaActivo = '';
    });
    _aplicarFiltros();
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
      default:
        return estado;
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Fecha desconocida';
    
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);
    
    if (diferencia.inDays == 0) {
      return 'Hoy ${DateFormat('HH:mm').format(fecha)}';
    }
    
    if (diferencia.inDays == 1) {
      return 'Ayer ${DateFormat('HH:mm').format(fecha)}';
    }
    
    if (diferencia.inDays < 7) {
      return '${diferencia.inDays} días atrás';
    }
    
    if (fecha.year == ahora.year) {
      return DateFormat('d MMM, HH:mm', 'es').format(fecha);
    }
    
    return DateFormat('d MMM yyyy', 'es').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header con diseño mejorado
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // AppBar con botón de retroceder
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gestión de Análisis',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Crea y consulta análisis médicos',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Tabs rediseñados
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.white,
                      labelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text("Nuevo"),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text("Historial"),
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
          
          // Contenido de las tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNuevoAnalisisTab(),
                _buildHistorialTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNuevoAnalisisTab() {
    return Column(
      children: [
        // Buscador mejorado
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona un paciente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: _filtrarPacientes,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o documento...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _filtrarPacientes('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
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
                ),
              ),
            ],
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
            CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Cargando pacientes...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_pacientesFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchController.text.isEmpty ? Icons.person_off : Icons.search_off,
                size: 64,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay pacientes registrados'
                  : 'No se encontraron pacientes',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'Registra pacientes para crear análisis'
                  : 'Intenta con otro término de búsqueda',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        paciente.nombres[0].toUpperCase() +
                            paciente.apellidos[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
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
                        Row(
                          children: [
                            Icon(
                              Icons.badge,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${paciente.tipoDocumento}: ${paciente.numeroDocumento}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                      size: 22,
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return StreamBuilder<List<Analisis>>(
      stream: _analisisController.streamAnalisisDoctor(_doctorId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Error al cargar historial",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Intenta recargar la página",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
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
                    Icons.history_rounded,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "No hay análisis registrados",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Los análisis aparecerán aquí",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // Actualizar análisis sin setState
        _actualizarAnalisis(snapshot.data!);

        final analisisMostrar = _analisisFiltrados;
        return Column(
          children: [
            // Barra de búsqueda y filtros
            _buildFiltrosHistorial(),
            
            // Lista de análisis filtrados
            Expanded(
              child: analisisMostrar.isEmpty
                  ? _buildEstadoVacioFiltrado()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: analisisMostrar.length,
                      itemBuilder: (context, index) {
                        final a = analisisMostrar[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCardAnalisis(a),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFiltrosHistorial() {
    final hayFiltrosActivos = _diagnosticoSeleccionado != null || 
                              _terminoBusquedaActivo.isNotEmpty;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de búsqueda con botón
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchHistorialController,
                  onSubmitted: (_) => _aplicarBusqueda(),
                  decoration: InputDecoration(
                    hintText: 'Buscar por paciente o diagnóstico...',
                    hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 22),
                    suffixIcon: _searchHistorialController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20, color: AppColors.textSecondary),
                            onPressed: () {
                              _searchHistorialController.clear();
                              setState(() {
                                _terminoBusquedaActivo = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
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
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _aplicarBusqueda,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Buscar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Chips de filtros
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Filtro por diagnóstico
                      _buildFilterChip(
                        label: _diagnosticoSeleccionado ?? 'Diagnóstico',
                        icon: Icons.medical_information,
                        isSelected: _diagnosticoSeleccionado != null,
                        onTap: _mostrarFiltroDiagnostico,
                      ),
                      
                      // Botón limpiar filtros
                      if (hayFiltrosActivos) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _limpiarFiltros,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.clear_all, size: 16, color: AppColors.error),
                                const SizedBox(width: 4),
                                Text(
                                  'Limpiar',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Contador de resultados
          if (_todosAnalisis.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${_analisisFiltrados.length} de ${_todosAnalisis.length} ${_analisisFiltrados.length == 1 ? "análisis" : "análisis"}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : AppColors.grey300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFiltroDiagnostico() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.medical_information,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Filtrar por Diagnóstico',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Opción "Todos"
              ListTile(
                leading: Radio<String?>(
                  value: null,
                  groupValue: _diagnosticoSeleccionado,
                  onChanged: (value) {
                    setState(() {
                      _diagnosticoSeleccionado = value;
                    });
                    _aplicarFiltros();
                    Navigator.pop(context);
                  },
                  activeColor: AppColors.primary,
                ),
                title: const Text(
                  'Todos los diagnósticos',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  setState(() {
                    _diagnosticoSeleccionado = null;
                  });
                  _aplicarFiltros();
                  Navigator.pop(context);
                },
              ),
              
              const Divider(),
              
              // Lista de diagnósticos disponibles
              if (_diagnosticosDisponibles.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No hay diagnósticos disponibles',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ...(_diagnosticosDisponibles.map((diagnostico) {
                  return ListTile(
                    leading: Radio<String>(
                      value: diagnostico,
                      groupValue: _diagnosticoSeleccionado,
                      onChanged: (value) {
                        setState(() {
                          _diagnosticoSeleccionado = value;
                        });
                        _aplicarFiltros();
                        Navigator.pop(context);
                      },
                      activeColor: AppColors.primary,
                    ),
                    title: Text(diagnostico),
                    onTap: () {
                      setState(() {
                        _diagnosticoSeleccionado = diagnostico;
                      });
                      _aplicarFiltros();
                      Navigator.pop(context);
                    },
                  );
                }).toList()),
              
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstadoVacioFiltrado() {
    return Center(
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
              Icons.filter_alt_off,
              size: 64,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No se encontraron análisis",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Intenta ajustar los filtros",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: _limpiarFiltros,
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Limpiar filtros'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardAnalisis(Analisis analisis) {
    final estadoColor = _getEstadoColor(analisis.estado);
    
    return AppCard(
      onTap: () => _mostrarDetalleAnalisis(analisis),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: estadoColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: estadoColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.medical_services_rounded,
              color: estadoColor,
              size: 30,
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
                if (analisis.diagnostico != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.medical_information,
                        size: 14,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          analisis.diagnostico!,
                          style: const TextStyle(
                            color: AppColors.info,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatearFecha(analisis.fechaAnalisis),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StatusChip(
                  label: _getEstadoLabel(analisis.estado),
                  color: estadoColor,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
            size: 24,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatearFecha(a.fechaCreacion),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
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

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchHistorialController.dispose();
    super.dispose();
  }
}