import 'package:flutter/material.dart';
import 'package:mediscan_app/controllers/paciente_controller.dart';
import 'package:mediscan_app/models/paciente_model.dart';

class PacienteDetallePage extends StatefulWidget {
  final Paciente paciente;

  const PacienteDetallePage({Key? key, required this.paciente}) : super(key: key);

  @override
  State<PacienteDetallePage> createState() => _PacienteDetallePageState();
}

class _PacienteDetallePageState extends State<PacienteDetallePage> {
  final PacienteController _pacienteController = PacienteController();

  Future<void> _eliminarPaciente() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 12),
            const Text('Confirmar eliminación'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Está seguro de eliminar a ${widget.paciente.nombreCompleto}?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('${widget.paciente.nombreCompleto} eliminado'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Error: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
        title: const Text('Información del Paciente'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar',
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
            tooltip: 'Eliminar',
            onPressed: _eliminarPaciente,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con información principal
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Text(
                            widget.paciente.nombres[0].toUpperCase() +
                                widget.paciente.apellidos[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Nombre
                      Text(
                        widget.paciente.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      
                      // Edad y género
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cake, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.paciente.edad} años',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              widget.paciente.genero?.toLowerCase() == 'masculino'
                                  ? Icons.male
                                  : Icons.female,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.paciente.genero ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSeccion('Información Personal', [
                    _buildInfoCard([
                      _buildInfoRow(
                        Icons.badge,
                        'Documento',
                        '${widget.paciente.tipoDocumento}: ${widget.paciente.numeroDocumento}',
                      ),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Fecha de Nacimiento',
                        '${widget.paciente.fechaNacimiento?.day}/${widget.paciente.fechaNacimiento?.month}/${widget.paciente.fechaNacimiento?.year}',
                      ),
                    ]),
                  ]),

                  const SizedBox(height: 20),
                  _buildSeccion('Contacto', [
                    _buildInfoCard([
                      _buildInfoRow(Icons.phone, 'Teléfono', widget.paciente.telefono),
                      if (widget.paciente.email != null)
                        _buildInfoRow(Icons.email, 'Email', widget.paciente.email!),
                      _buildInfoRow(Icons.home, 'Dirección', widget.paciente.direccion),
                      _buildInfoRow(Icons.location_city, 'Ciudad', widget.paciente.ciudad),
                      _buildInfoRow(Icons.flag, 'País', widget.paciente.pais),
                    ]),
                  ]),

                  const SizedBox(height: 20),
                  _buildSeccion('Información Médica', [
                    _buildInfoCard([
                      if (widget.paciente.grupoSanguineo != null)
                        _buildInfoRow(
                          Icons.bloodtype,
                          'Grupo Sanguíneo',
                          widget.paciente.grupoSanguineo!,
                        ),
                      if (widget.paciente.alergias != null)
                        _buildInfoRow(
                          Icons.warning_amber,
                          'Alergias',
                          widget.paciente.alergias!,
                        ),
                      if (widget.paciente.enfermedadesPrevias != null)
                        _buildInfoRow(
                          Icons.medical_services,
                          'Enfermedades Previas',
                          widget.paciente.enfermedadesPrevias!,
                        ),
                      if (widget.paciente.grupoSanguineo == null &&
                          widget.paciente.alergias == null &&
                          widget.paciente.enfermedadesPrevias == null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Sin información médica registrada',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ]),

                  const SizedBox(height: 20),
                  _buildSeccion('Registro', [
                    _buildInfoCard([
                      _buildInfoRow(
                        Icons.event,
                        'Fecha de Registro',
                        '${widget.paciente.fechaRegistro.day}/${widget.paciente.fechaRegistro.month}/${widget.paciente.fechaRegistro.year}',
                      ),
                    ]),
                  ]),

                  const SizedBox(height: 32),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
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
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.blue.shade700, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(Icons.edit, color: Colors.blue.shade700),
                          label: Text(
                            'Editar',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _eliminarPaciente,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.delete),
                          label: const Text(
                            'Eliminar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blue.shade700),
          ),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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