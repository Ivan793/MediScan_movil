import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mediscan_app/models/analisis_model.dart';

class AnalisisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String collectionName = 'analisis';

  /// Subir imagen a Firebase Storage
  Future<String> subirImagen(File imagen, String pacienteId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'analisis_${pacienteId}_$timestamp.jpg';
      final ref = _storage.ref().child('analisis/$pacienteId/$fileName');
      
      // Subir archivo
      final uploadTask = await ref.putFile(imagen);
      
      // Obtener URL de descarga
      final url = await uploadTask.ref.getDownloadURL();
      
      return url;
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Registrar un nuevo análisis
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

  /// Obtener análisis de un paciente
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
      throw Exception('Error al obtener análisis: $e');
    }
  }

  /// Obtener análisis de un doctor
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
      throw Exception('Error al obtener análisis: $e');
    }
  }

  /// Obtener análisis por estado
  Future<List<Analisis>> obtenerAnalisisPorEstado(
      String doctorId, String estado) async {
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
      throw Exception('Error al obtener análisis: $e');
    }
  }

  /// Obtener un análisis por ID
  Future<Analisis?> obtenerAnalisisPorId(String id) async {
    try {
      final doc = await _firestore.collection(collectionName).doc(id).get();
      if (doc.exists) {
        return Analisis.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener análisis: $e');
    }
  }

  /// Actualizar análisis completo
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

  /// Actualizar solo el estado
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

  /// Actualizar resultado del análisis (después de procesarlo con IA)
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
      throw Exception('Error al actualizar resultado: $e');
    }
  }

  /// Eliminar análisis (incluye eliminar imagen de Storage)
  Future<void> eliminarAnalisis(String id, String imagenUrl) async {
    try {
      // Eliminar imagen de Storage
      try {
        final ref = _storage.refFromURL(imagenUrl);
        await ref.delete();
      } catch (e) {
        print('Error al eliminar imagen de Storage: $e');
        // Continuamos aunque falle la eliminación de la imagen
      }

      // Eliminar documento de Firestore
      await _firestore.collection(collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar análisis: $e');
    }
  }

  /// Stream de análisis de un paciente (para actualizaciones en tiempo real)
  Stream<List<Analisis>> streamAnalisisPorPaciente(String pacienteId) {
    return _firestore
        .collection(collectionName)
        .where('paciente_id', isEqualTo: pacienteId)
        .orderBy('fecha_creacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Analisis.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream de análisis de un doctor (para actualizaciones en tiempo real)
  Stream<List<Analisis>> streamAnalisisPorDoctor(String doctorId) {
    return _firestore
        .collection(collectionName)
        .where('doctor_id', isEqualTo: doctorId)
        .orderBy('fecha_creacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Analisis.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Obtener estadísticas de análisis del doctor
  Future<Map<String, int>> obtenerEstadisticas(String doctorId) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('doctor_id', isEqualTo: doctorId)
          .get();

      int total = snapshot.docs.length;
      int pendientes = 0;
      int enProceso = 0;
      int finalizados = 0;

      for (var doc in snapshot.docs) {
        final estado = doc.data()['estado'] ?? 'pendiente';
        switch (estado) {
          case 'pendiente':
            pendientes++;
            break;
          case 'en_proceso':
            enProceso++;
            break;
          case 'finalizado':
            finalizados++;
            break;
        }
      }

      return {
        'total': total,
        'pendientes': pendientes,
        'en_proceso': enProceso,
        'finalizados': finalizados,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}