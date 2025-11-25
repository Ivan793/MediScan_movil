import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:mediscan_app/models/analisis_model.dart';
import 'package:mediscan_app/services/cloudinary_service.dart';

class AnalisisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinary = CloudinaryService();
  final String apiUrl = "http://172.20.10.9:8000/predict";
  static const String collectionName = 'analisis';

  /// SUBIR IMAGEN A CLOUDINARY
  Future<String> subirImagen(File imagen, String pacienteId) async {
    try {
      final imageUrl = await _cloudinary.uploadImage(imagen);

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception("Cloudinary no devolvió una URL válida.");
      }

      return imageUrl; // URL lista para guardar en Firestore
    } catch (e) {
      throw Exception("Error al subir imagen a Cloudinary: $e");
    }
  }

  /// REGISTRAR UN NUEVO ANÁLISIS EN FIRESTORE
  Future<String> registrarAnalisis(Analisis analisis) async {
    try {
      final docRef = await _firestore
          .collection(collectionName)
          .add(analisis.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al registrar análisis: $e');
    }
  }

  /// OBTENER ANÁLISIS POR PACIENTE
  Future<List<Analisis>> obtenerAnalisisPorPaciente(String pacienteId) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('paciente_id', isEqualTo: pacienteId)
          .orderBy('fecha_creacion', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Analisis.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener análisis por paciente: $e');
    }
  }

  /// OBTENER ANÁLISIS POR DOCTOR
  Future<List<Analisis>> obtenerAnalisisPorDoctor(String doctorId) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('doctor_id', isEqualTo: doctorId)
          .orderBy('fecha_creacion', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Analisis.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener análisis por doctor: $e');
    }
  }

  /// OBTENER ANÁLISIS POR ESTADO
  Future<List<Analisis>> obtenerAnalisisPorEstado(
    String doctorId,
    String estado,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('doctor_id', isEqualTo: doctorId)
          .where('estado', isEqualTo: estado)
          .orderBy('fecha_creacion', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Analisis.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener análisis por estado: $e');
    }
  }

  /// OBTENER ANÁLISIS POR ID
  Future<Analisis?> obtenerAnalisisPorId(String id) async {
    try {
      final doc = await _firestore.collection(collectionName).doc(id).get();
      if (!doc.exists) return null;

      return Analisis.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Error al obtener análisis por ID: $e');
    }
  }

  /// ACTUALIZAR ANÁLISIS COMPLETO
  Future<void> actualizarAnalisis(String id, Analisis analisis) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(id)
          .update(analisis.toMap());
    } catch (e) {
      throw Exception('Error al actualizar análisis: $e');
    }
  }

  /// ACTUALIZAR ESTADO
  Future<void> actualizarEstado(String id, String nuevoEstado) async {
    try {
      await _firestore.collection(collectionName).doc(id).update({
        'estado': nuevoEstado,
        'fecha_analisis': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al actualizar estado: $e');
    }
  }

  Future<Map<String, dynamic>> ejecutarIA(File imagen) async {
    try {
      final request = http.MultipartRequest("POST", Uri.parse(apiUrl));

      request.files.add(await http.MultipartFile.fromPath('file', imagen.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      return jsonDecode(body);
    } catch (e) {
      throw Exception("Error al procesar imagen con IA: $e");
    }
  }

  /// ACTUALIZAR RESULTADOS DE IA
  Future<void> actualizarResultado(
    String id,
    String resultado,
    String? diagnostico,
    double? confianza,
    Map<String, dynamic>? datosIA,
  ) async {
    try {
      await _firestore.collection(collectionName).doc(id).update({
        'resultado': resultado,
        'diagnostico': diagnostico,
        'confianza': confianza,
        'datos_ia': datosIA,
        'estado': 'finalizado',
        'fecha_analisis': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al actualizar el resultado: $e');
    }
  }

  /// ELIMINAR ANÁLISIS
  Future<void> eliminarAnalisis(String id, String imagenUrl) async {
    try {
      await _firestore.collection(collectionName).doc(id).delete();
      // Aquí NO puedes borrar la imagen porque Cloudinary requiere API secret.
    } catch (e) {
      throw Exception('Error al eliminar análisis: $e');
    }
  }

  /// STREAM: ANÁLISIS DEL PACIENTE EN TIEMPO REAL
  Stream<List<Analisis>> streamAnalisisPorPaciente(String pacienteId) {
    return _firestore
        .collection(collectionName)
        .where('paciente_id', isEqualTo: pacienteId)
        .orderBy('fecha_creacion', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Analisis.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Analisis>> streamAnalisisPorDoctor(String doctorId) {
    return _firestore
        .collection('analisis')
        .where('doctor_id', isEqualTo: doctorId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Analisis.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// ESTADÍSTICAS DEL DOCTOR
  Future<Map<String, int>> obtenerEstadisticas(String doctorId) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('doctor_id', isEqualTo: doctorId)
          .get();

      int pendientes = 0;
      int enProceso = 0;
      int finalizados = 0;

      for (var doc in snapshot.docs) {
        final estado = doc.data()['estado'] ?? 'pendiente';

        if (estado == 'pendiente') pendientes++;
        if (estado == 'en_proceso') enProceso++;
        if (estado == 'finalizado') finalizados++;
      }

      return {
        'total': snapshot.docs.length,
        'pendientes': pendientes,
        'en_proceso': enProceso,
        'finalizados': finalizados,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}
  