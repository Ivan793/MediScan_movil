import 'package:flutter/material.dart';
import 'package:mediscan_app/controllers/analisis_controller.dart';
import 'package:mediscan_app/controllers/paciente_controller.dart';
import 'package:mediscan_app/models/analisis_model.dart';
import 'package:mediscan_app/models/paciente_model.dart';

class PacienteDetallePage extends StatefulWidget {
  final Paciente paciente;

  const PacienteDetallePage({Key? key, required this.paciente}) : super(key: key);

  @override
  State<PacienteDetallePage> createState() => _PacienteDetallePageState();
}

class _PacienteDetallePageState extends State<PacienteDetallePage> {
  final AnalisisController _analisisController = AnalisisController();
  final PacienteController _pacienteController = PacienteController();
  
  int _selectedTab = 0;
  List<Analisis> _analisis = [];
  bool _isLoadingAnalisis = true;

  @override
  void initState() {
    super.initState();
    _cargarAnalisis();
  }

  Future<void> _cargarAnalisis() async {
    setState(() => _isLoadingAnalisis = true);
    try {
      final analisis = await _analisisController.obtenerAnalisisPaciente(widget.paciente.id!);
      setState(() {
        _analisis = analisis;
        _isLoadingAnalisis = false;
      });
    } catch (e) {
      setState(() => _isLoadingAnalisis = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar análisis: $e')),
        );
      }
    }
  }

  Future<void> _eliminarPaciente() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar a ${widget.paciente.nombreCompleto}?'),
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

    if (confirmar == true) {
      try {
        await _pacienteController.eliminarPaciente(widget.paciente.id!);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paciente eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.paciente.nombreCompleto),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final resultado = await Navigator.pushNamed(
                context,
                '/registrar-paciente',
                arguments: widget.paciente,
              );
              if (resultado == true && mounted) {
                setState(() {});
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _eliminarPaciente,
          ),
        ],
      ),
      floatingActionButton: _selectedTab == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                final resultado = await Navigator.pushNamed(
                  context,
                  '/nuevo-analisis',
                  arguments: widget.paciente,
                );
                if (resultado == true) {
                  _cargarAnalisis();
                }
              },
              backgroundColor: Colors.blue.shade700,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Análisis'),
            )
          : null,
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildTab('Información', 0),
                ),
                Expanded(
                  child: _buildTab('Análisis', 1),
                ),
              ],
            ),
          ),

          // Contenido
          Expanded(
            child: _selectedTab == 0
                ? _buildInformacionTab()
                : _buildAnalisisTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue.shade700 : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue.shade700 : Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInformacionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con avatar
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    widget.paciente.nombres[0].toUpperCase() +
                        widget.paciente.apellidos[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.paciente.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.paciente.edad} años',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSeccion('Información Personal'),
          _buildInfoCard([
            _buildInfoRow(Icons.badge, 'Documento', 
                '${widget.paciente.tipoDocumento}: ${widget.paciente.numeroDocumento}'),
            _buildInfoRow(Icons.cake, 'Fecha de Nacimiento',
                '${widget.paciente.fechaNacimiento?.day}/${widget.paciente.fechaNacimiento?.month}/${widget.paciente.fechaNacimiento?.year}'),
            _buildInfoRow(
                widget.paciente.genero?.toLowerCase() == 'masculino' ? Icons.male : Icons.female,
                'Género',
                widget.paciente.genero ?? 'No especificado'),
          ]),

          const SizedBox(height: 16),
          _buildSeccion('Contacto'),
          _buildInfoCard([
            _buildInfoRow(Icons.phone, 'Teléfono', widget.paciente.telefono),
            if (widget.paciente.email != null)
              _buildInfoRow(Icons.email, 'Email', widget.paciente.email!),
            _buildInfoRow(Icons.home, 'Dirección', widget.paciente.direccion),
            _buildInfoRow(Icons.location_city, 'Ciudad', widget.paciente.ciudad),
            _buildInfoRow(Icons.flag, 'País', widget.paciente.pais),
          ]),

          const SizedBox(height: 16),
          _buildSeccion('Información Médica'),
          _buildInfoCard([
            if (widget.paciente.grupoSanguineo != null)
              _buildInfoRow(Icons.bloodtype, 'Grupo Sanguíneo', widget.paciente.grupoSanguineo!),
            if (widget.paciente.alergias != null)
              _buildInfoRow(Icons.warning_amber, 'Alergias', widget.paciente.alergias!),
            if (widget.paciente.enfermedadesPrevias != null)
              _buildInfoRow(Icons.medical_services, 'Enfermedades Previas',
                  widget.paciente.enfermedadesPrevias!),
          ]),
        ],
      ),
    );
  }

  Widget _buildAnalisisTab() {
    if (_isLoadingAnalisis) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_analisis.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No hay análisis registrados',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Presiona + para agregar un análisis',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarAnalisis,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _analisis.length,
        itemBuilder: (context, index) {
          return _buildAnalisisCard(_analisis[index]);
        },
      ),
    );
  }

  Widget _buildAnalisisCard(Analisis analisis) {
    Color estadoColor;
    IconData estadoIcon;

    switch (analisis.estado) {
      case 'pendiente':
        estadoColor = Colors.orange;
        estadoIcon = Icons.pending;
        break;
      case 'en_proceso':
        estadoColor = Colors.blue;
        estadoIcon = Icons.hourglass_empty;
        break;
      case 'finalizado':
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        break;
      default:
        estadoColor = Colors.grey;
        estadoIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/detalle-analisis', arguments: analisis);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(estadoIcon, color: estadoColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          analisis.tipoAnalisis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estado: ${analisis.estado}',
                          style: TextStyle(color: estadoColor, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${analisis.fechaCreacion.day}/${analisis.fechaCreacion.month}/${analisis.fechaCreacion.year}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  if (analisis.confianza != null) ...[
                    Icon(Icons.analytics, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Confianza: ${(analisis.confianza! * 100).toStringAsFixed(1)}%',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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