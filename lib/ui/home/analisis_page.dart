import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mediscan_app/controllers/analisis_controller.dart';
import 'package:mediscan_app/models/analisis_model.dart';
import 'package:mediscan_app/models/paciente_model.dart';
import 'package:mediscan_app/services/cloudinary_service.dart'; // ⬅️ IMPORTANTE

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
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
            if (_imagenSeleccionada != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Eliminar imagen',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imagenSeleccionada = null);
                },
              ),
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
            // Timer dentro del diálogo para actualizar mensajes
            timer = Timer.periodic(const Duration(seconds: 1), (_) {
              setStateDialog(() {
                index = (index + 1) % mensajes.length;
              });
            });

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),

                    // MENSAJE QUE CAMBIA AUTOMÁTICAMENTE
                    Text(
                      mensajes[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 20),
                    const LinearProgressIndicator(),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Cancelar timer cuando se cierre el diálogo
      if (timer.isActive) timer.cancel();
    });
  }

  Future<void> _iniciarAnalisis() async {
    if (_imagenSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione una imagen'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    mostrarDialogoProcesandoConMensajes(); // ⬅ Popup con mensajes dinámicos

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      // 1️⃣ Subir imagen a Cloudinary
      final String imagenUrl = await _controller.subirImagen(
        _imagenSeleccionada!,
        widget.paciente.id!,
      );

      // 2️⃣ Procesar con IA
      final resultadoIA = await _controller.ejecutarIA(_imagenSeleccionada!);

      final diagnostico = resultadoIA["diagnostico"];
      final confianza = (resultadoIA["confianza"] as num?)?.toDouble() ?? 0.0;
      final predicciones = Map<String, dynamic>.from(
        resultadoIA["predicciones"] ?? {},
      );

      // 3️⃣ Crear análisis
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

      // 4️⃣ Guardar en Firestore
      await _controller.registrarAnalisis(analisis);

      Navigator.pop(context); // ⬅ Cerrar diálogo
      Navigator.pop(context, true); // ⬅ Cerrar la pantalla

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Análisis completado correctamente"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // ⬅ Cerrar diálogo si hay error

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Nuevo Análisis'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        widget.paciente.nombres[0].toUpperCase() +
                            widget.paciente.apellidos[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.paciente.edad} años - ${widget.paciente.numeroDocumento}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Tipo de Análisis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tipoAnalisis,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.medical_services),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
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

            Text(
              'Imagen del Análisis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 12),

            _imagenSeleccionada == null
                ? _buildSeleccionarImagenCard()
                : _buildImagenPreview(),

            const SizedBox(height: 24),

            Text(
              'Observaciones (Opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _observacionesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Agregue observaciones sobre el análisis...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 32),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _iniciarAnalisis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.analytics_outlined),
                label: const Text(
                  "Iniciar análisis",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeleccionarImagenCard() {
    return InkWell(
      onTap: _mostrarOpcionesImagen,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Toque para seleccionar imagen',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _imagenSeleccionada!,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: _mostrarOpcionesImagen,
            icon: const Icon(Icons.edit),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade700,
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
