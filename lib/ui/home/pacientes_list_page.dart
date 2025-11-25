import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mediscan_app/controllers/paciente_controller.dart';
import 'package:mediscan_app/models/paciente_model.dart';
import 'package:mediscan_app/ui/theme/app_colors.dart';
import 'package:mediscan_app/ui/widgets/app_widgets.dart';

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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await _cargarDoctorId();
    if (_doctorId != null) {
      await _cargarPacientes();
    }
  }

  Future<void> _cargarDoctorId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _doctorId = user.uid;
        });
      } else {
        setState(() {
          _errorMessage = 'No hay usuario autenticado';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar información del usuario';
      });
    }
  }

  Future<void> _cargarPacientes() async {
    if (_doctorId == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pacientes = await _controller.obtenerPacientesDoctor(_doctorId!);
      
      setState(() {
        _pacientes = pacientes;
        _pacientesFiltrados = pacientes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar pacientes: ${e.toString()}';
      });
      
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
                                Icons.people,
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
                                    'Mis Pacientes',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Gestiona tu lista de pacientes',
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
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _cargarPacientes,
                tooltip: 'Recargar',
              ),
            ],
          ),

          // Barra de búsqueda
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _filtrarPacientes,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o documento',
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Contador de pacientes
          if (!_isLoading && _pacientes.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${_pacientesFiltrados.length} ${_pacientesFiltrados.length == 1 ? "paciente" : "pacientes"}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Lista de pacientes
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.pushNamed(context, '/registrar-paciente');
          if (resultado == true) {
            _cargarPacientes();
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Paciente'),
        elevation: 4,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Cargando pacientes...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: AppColors.error.withOpacity(0.5)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 16, color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                text: 'Reintentar',
                onPressed: _cargarPacientes,
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      );
    }

    if (_doctorId == null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber, size: 80, color: AppColors.warning.withOpacity(0.5)),
              const SizedBox(height: 16),
              const Text(
                'No se pudo identificar al doctor',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_pacientesFiltrados.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 80,
                color: AppColors.textTertiary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty
                    ? 'No hay pacientes registrados'
                    : 'No se encontraron pacientes',
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              if (_searchController.text.isEmpty)
                const Text(
                  'Presiona + para agregar un paciente',
                  style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
                ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final paciente = _pacientesFiltrados[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPacienteCard(paciente),
          );
        },
        childCount: _pacientesFiltrados.length,
      ),
    );
  }

  Widget _buildPacienteCard(Paciente paciente) {
    return AppCard(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          '/detalle-paciente',
          arguments: paciente,
        );
        _cargarPacientes();
      },
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
                paciente.nombres[0].toUpperCase() + paciente.apellidos[0].toUpperCase(),
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
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.badge, size: 14, color: AppColors.textSecondary),
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.cake, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${paciente.edad} años',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      paciente.genero?.toLowerCase() == 'masculino'
                          ? Icons.male
                          : Icons.female,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      paciente.genero ?? '',
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

          // Icono de navegación
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.chevron_right,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}