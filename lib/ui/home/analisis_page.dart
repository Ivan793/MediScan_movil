import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mediscan_app/controllers/analisis_controller.dart';
import 'package:mediscan_app/models/analisis_model.dart';
import 'package:mediscan_app/models/paciente_model.dart';
import 'package:mediscan_app/ui/theme/app_colors.dart';
import 'package:mediscan_app/ui/widgets/app_widgets.dart';

class AnalisisFormPage extends StatefulWidget {
  final Paciente paciente;

  const AnalisisFormPage({Key? key, required this.paciente}) : super(key: key);

  @override
  State<AnalisisFormPage> createState() => _AnalisisFormPageState();
}

class _AnalisisFormPageState extends State<AnalisisFormPage> {
  final AnalisisController _controller = AnalisisController();
  final _observacionesController = TextEditingController();

  File? _imagenSeleccionada;
  bool _isLoading = false;
  String _tipoAnalisis = 'Radiografía de Tórax';

  final List<String> _tiposAnalisis = [
    'Radiografía de Tórax',
    'Radiografía de Abdomen',
    'Tomografía',
    'Resonancia Magnética',
    'Ecografía',
    'Otro',
  ];

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imagenSeleccionada = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.primary),
              ),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: AppColors.secondary),
              ),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
            if (_imagenSeleccionada != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete, color: AppColors.error),
                ),
                title: const Text(
                  'Eliminar imagen',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imagenSeleccionada = null);
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void mostrarDialogoProcesandoConMensajes() {
    final mensajes = [
      "📤 Subiendo imagen...",
      "🤖 Procesando análisis con IA...",
      "🧠 Interpretando resultados...",
      "📝 Generando informe...",
      "⏳ Casi listo...",
    ];

    int index = 0;
    late Timer timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            timer = Timer.periodic(const Duration(seconds: 1), (_) {
              setStateDialog(() {
                index = (index + 1) % mensajes.length;
              });
            });

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      mensajes[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.grey200,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      if (timer.isActive) timer.cancel();
    });
  }

  Future<void> _iniciarAnalisis() async {
    if (_imagenSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione una imagen'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    mostrarDialogoProcesandoConMensajes();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      final String imagenUrl = await _controller.subirImagen(
        _imagenSeleccionada!,
        widget.paciente.id!,
      );

      final resultadoIA = await _controller.ejecutarIA(_imagenSeleccionada!);

      final diagnostico = resultadoIA["diagnostico"];
      final confianza = (resultadoIA["confianza"] as num?)?.toDouble() ?? 0.0;
      final predicciones = Map<String, dynamic>.from(
        resultadoIA["predicciones"] ?? {},
      );

      final analisis = Analisis(
        pacienteId: widget.paciente.id!,
        doctorId: user.uid,
        empresaId: widget.paciente.empresaId,
        tipoAnalisis: _tipoAnalisis,
        imagenUrl: imagenUrl,
        estado: "finalizado",
        observaciones: _observacionesController.text.trim().isNotEmpty
            ? _observacionesController.text.trim()
            : null,
        diagnostico: diagnostico,
        resultado: diagnostico,
        confianza: confianza,
        datosIA: predicciones,
        fechaAnalisis: DateTime.now(),
      );

      await _controller.registrarAnalisis(analisis);

      Navigator.pop(context); // Cerrar diálogo
      Navigator.pop(context, true); // Cerrar la pantalla

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Análisis completado correctamente"),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Cerrar diálogo

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nuevo Análisis'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del paciente
            AppCard(
              padding: const EdgeInsets.all(20),
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
                        widget.paciente.nombres[0].toUpperCase() +
                            widget.paciente.apellidos[0].toUpperCase(),
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
                          widget.paciente.nombreCompleto,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.paciente.edad} años - ${widget.paciente.numeroDocumento}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tipo de análisis
            const Text(
              'Tipo de Análisis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            DropdownButtonFormField<String>(
              value: _tipoAnalisis,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.medical_services, color: AppColors.primary),
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
              items: _tiposAnalisis.map((tipo) {
                return DropdownMenuItem(value: tipo, child: Text(tipo));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _tipoAnalisis = value);
                }
              },
            ),

            const SizedBox(height: 24),

            // Imagen
            const Text(
              'Imagen del Análisis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _imagenSeleccionada == null
                ? _buildSeleccionarImagenCard()
                : _buildImagenPreview(),

            const SizedBox(height: 24),

            // Observaciones
            const Text(
              'Observaciones (Opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            AppTextField(
              controller: _observacionesController,
              maxLines: 4,
              label: 'Agregue observaciones sobre el análisis...',
            ),

            const SizedBox(height: 32),

            // Botón
            AppPrimaryButton(
              text: "Iniciar análisis",
              onPressed: _iniciarAnalisis,
              icon: Icons.analytics_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeleccionarImagenCard() {
    return InkWell(
      onTap: _mostrarOpcionesImagen,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey300, width: 2, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Toque para seleccionar imagen',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagenPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            _imagenSeleccionada!,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: AppColors.cardShadow,
            ),
            child: IconButton(
              onPressed: _mostrarOpcionesImagen,
              icon: const Icon(Icons.edit, color: AppColors.primary),
              tooltip: 'Cambiar imagen',
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }
}