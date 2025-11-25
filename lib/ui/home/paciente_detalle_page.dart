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
    // Obtener dimensiones de la pantalla
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calcular tamaños responsive
    final avatarRadius = screenWidth < 360 ? 35.0 : screenWidth < 400 ? 38.0 : 40.0;
    final nameFontSize = screenWidth < 360 ? 20.0 : screenWidth < 400 ? 22.0 : 24.0;
    final infoBadgeFontSize = screenWidth < 360 ? 12.0 : 14.0;
    final iconSize = screenWidth < 360 ? 14.0 : 16.0;
    final expandedHeight = screenHeight < 600 ? 200.0 : screenHeight < 800 ? 220.0 : 240.0;
    final horizontalPadding = screenWidth < 360 ? 12.0 : 16.0;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // AppBar responsive
          SliverAppBar(
            expandedHeight: expandedHeight,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final double top = constraints.biggest.height;
                final double collapsedHeight = kToolbarHeight;
                final double expandedHeightValue = expandedHeight + MediaQuery.of(context).padding.top;
                
                // Factor de opacidad para fade out al colapsar
                final double opacity = ((top - collapsedHeight) / 
                    (expandedHeightValue - collapsedHeight)).clamp(0.0, 1.0);
                
                return FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: SafeArea(
                      child: Opacity(
                        opacity: opacity,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Avatar
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: screenWidth < 360 ? 2 : 3,
                                  ),
                                  boxShadow: AppColors.elevatedShadow,
                                ),
                                child: CircleAvatar(
                                  radius: avatarRadius,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    widget.paciente.nombres[0].toUpperCase() +
                                        widget.paciente.apellidos[0].toUpperCase(),
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: avatarRadius * 0.8,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight < 600 ? 12 : 16),
                              
                              // Nombre
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                                child: Text(
                                  widget.paciente.nombreCompleto,
                                  style: TextStyle(
                                    fontSize: nameFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Badge con edad y género - Layout flexible
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth < 360 ? 12 : 16,
                                  vertical: screenWidth < 360 ? 5 : 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.cake, color: Colors.white, size: iconSize),
                                    SizedBox(width: screenWidth < 360 ? 4 : 6),
                                    Flexible(
                                      child: Text(
                                        '${widget.paciente.edad} años',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: infoBadgeFontSize,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: screenWidth < 360 ? 8 : 12),
                                    Icon(
                                      widget.paciente.genero?.toLowerCase() == 'masculino'
                                          ? Icons.male
                                          : Icons.female,
                                      color: Colors.white,
                                      size: iconSize,
                                    ),
                                    SizedBox(width: screenWidth < 360 ? 4 : 6),
                                    Flexible(
                                      child: Text(
                                        widget.paciente.genero ?? '',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: infoBadgeFontSize,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight < 600 ? 16 : 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            actions: const [], 
          ),

          // Contenido con padding responsive
          SliverPadding(
            padding: EdgeInsets.all(horizontalPadding),
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

                SizedBox(height: horizontalPadding),

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

                SizedBox(height: horizontalPadding),

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

                SizedBox(height: horizontalPadding),

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

                // Botones de acción responsive
                screenWidth < 360
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 48,
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
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _eliminarPaciente,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text(
                                'Eliminar',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _eliminarPaciente,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final sectionPadding = screenWidth < 360 ? 16.0 : 20.0;
    final titleFontSize = screenWidth < 360 ? 16.0 : 18.0;
    final iconBoxSize = screenWidth < 360 ? 6.0 : 8.0;
    final iconSizeValue = screenWidth < 360 ? 18.0 : 20.0;
    
    return AppCard(
      padding: EdgeInsets.all(sectionPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconBoxSize),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: iconSizeValue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSizeValue = screenWidth < 360 ? 18.0 : 20.0;
    final labelFontSize = screenWidth < 360 ? 11.0 : 12.0;
    final valueFontSize = screenWidth < 360 ? 14.0 : 15.0;
    
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth < 360 ? 12 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: iconSizeValue, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}