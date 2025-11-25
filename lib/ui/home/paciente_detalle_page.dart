import 'package:flutter/material.dart';
import 'package:mediscan_app/controllers/paciente_controller.dart';
import 'package:mediscan_app/models/paciente_model.dart';
import 'package:mediscan_app/ui/theme/app_colors.dart';
import 'package:mediscan_app/ui/widgets/app_widgets.dart';

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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirmar eliminación',
                style: TextStyle(fontSize: 18),
              ),
            ),
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.error),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
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
              backgroundColor: AppColors.error,
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
              content: Text('${widget.paciente.nombreCompleto} eliminado'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar con gradiente y avatar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: AppColors.elevatedShadow,
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Text(
                            widget.paciente.nombres[0].toUpperCase() +
                                widget.paciente.apellidos[0].toUpperCase(),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.paciente.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cake, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.paciente.edad} años',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              widget.paciente.genero?.toLowerCase() == 'masculino'
                                  ? Icons.male
                                  : Icons.female,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.paciente.genero ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
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

          // Contenido
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSeccion(
                  'Información Personal',
                  Icons.person,
                  [
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
                  ],
                ),

                const SizedBox(height: 16),

                _buildSeccion(
                  'Contacto',
                  Icons.contact_phone,
                  [
                    _buildInfoRow(Icons.phone, 'Teléfono', widget.paciente.telefono),
                    if (widget.paciente.email != null)
                      _buildInfoRow(Icons.email, 'Email', widget.paciente.email!),
                    _buildInfoRow(Icons.home, 'Dirección', widget.paciente.direccion),
                    _buildInfoRow(Icons.location_city, 'Ciudad', widget.paciente.ciudad),
                    _buildInfoRow(Icons.flag, 'País', widget.paciente.pais),
                  ],
                ),

                const SizedBox(height: 16),

                _buildSeccion(
                  'Información Médica',
                  Icons.medical_services,
                  [
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
                        Icons.local_hospital,
                        'Enfermedades Previas',
                        widget.paciente.enfermedadesPrevias!,
                      ),
                    if (widget.paciente.grupoSanguineo == null &&
                        widget.paciente.alergias == null &&
                        widget.paciente.enfermedadesPrevias == null)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Sin información médica registrada',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildSeccion(
                  'Registro',
                  Icons.event_note,
                  [
                    _buildInfoRow(
                      Icons.event,
                      'Fecha de Registro',
                      '${widget.paciente.fechaRegistro.day}/${widget.paciente.fechaRegistro.month}/${widget.paciente.fechaRegistro.year}',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        text: 'Editar',
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
                        icon: Icons.edit,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _eliminarPaciente,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.delete, size: 20),
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
                
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion(String titulo, IconData icon, List<Widget> children) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
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
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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