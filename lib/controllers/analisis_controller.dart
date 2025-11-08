import 'dart:io';
import 'package:mediscan_app/models/analisis_model.dart';
import 'package:mediscan_app/services/analisis_service.dart';

class AnalisisController {
  final AnalisisService _service = AnalisisService();

  /// Subir imagen a Firebase Storage
  Future<String> subirImagen(File imagen, String pacienteId) async {
    try {
      return await _service.subirImagen(imagen, pacienteId);
    } catch (e) {
      rethrow;
    }
  }

  /// Registrar un nuevo análisis
  Future<String> registrarAnalisis(Analisis analisis) async {
    try {
      return await _service.registrarAnalisis(analisis);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener análisis de un paciente
  Future<List<Analisis>> obtenerAnalisisPaciente(String pacienteId) async {
    try {
      return await _service.obtenerAnalisisPorPaciente(pacienteId);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener análisis del doctor
  Future<List<Analisis>> obtenerAnalisisDoctor(String doctorId) async {
    try {
      return await _service.obtenerAnalisisPorDoctor(doctorId);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener análisis por estado (pendiente, en_proceso, finalizado)
  Future<List<Analisis>> obtenerAnalisisPorEstado(
      String doctorId, String estado) async {
    try {
      return await _service.obtenerAnalisisPorEstado(doctorId, estado);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener un análisis por ID
  Future<Analisis?> obtenerAnalisisPorId(String id) async {
    try {
      return await _service.obtenerAnalisisPorId(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar análisis completo
  Future<void> actualizarAnalisis(String id, Analisis analisis) async {
    try {
      await _service.actualizarAnalisis(id, analisis);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar solo el estado del análisis
  Future<void> actualizarEstado(String id, String nuevoEstado) async {
    try {
      await _service.actualizarEstado(id, nuevoEstado);
    } catch (e) {
      rethrow;
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
      await _service.actualizarResultado(
        id,
        resultado,
        diagnostico,
        confianza,
        datosIA,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar análisis (incluye eliminar imagen de Storage)
  Future<void> eliminarAnalisis(String id, String imagenUrl) async {
    try {
      await _service.eliminarAnalisis(id, imagenUrl);
    } catch (e) {
      rethrow;
    }
  }

  /// Stream de análisis de un paciente (para actualizaciones en tiempo real)
  Stream<List<Analisis>> streamAnalisisPaciente(String pacienteId) {
    return _service.streamAnalisisPorPaciente(pacienteId);
  }

  /// Stream de análisis del doctor (para actualizaciones en tiempo real)
  Stream<List<Analisis>> streamAnalisisDoctor(String doctorId) {
    return _service.streamAnalisisPorDoctor(doctorId);
  }

  /// Obtener estadísticas de análisis
  Future<Map<String, int>> obtenerEstadisticas(String doctorId) async {
    try {
      return await _service.obtenerEstadisticas(doctorId);
    } catch (e) {
      rethrow;
    }
  }

  /// Validar si un paciente puede tener un nuevo análisis
  /// (opcional: puedes implementar lógica de negocio aquí)
  bool puedeCrearAnalisis(List<Analisis> analisisExistentes) {
    // Por ejemplo, verificar si hay análisis pendientes
    final pendientes = analisisExistentes
        .where((a) => a.estado == 'pendiente' || a.estado == 'en_proceso')
        .length;
    
    // Permitir máximo 5 análisis pendientes/en proceso
    return pendientes < 5;
  }

  /// Calcular progreso de análisis de un doctor
  Map<String, dynamic> calcularProgreso(Map<String, int> estadisticas) {
    final total = estadisticas['total'] ?? 0;
    if (total == 0) {
      return {
        'porcentaje_completado': 0.0,
        'porcentaje_pendiente': 0.0,
        'porcentaje_en_proceso': 0.0,
      };
    }

    final finalizados = estadisticas['finalizados'] ?? 0;
    final pendientes = estadisticas['pendientes'] ?? 0;
    final enProceso = estadisticas['en_proceso'] ?? 0;

    return {
      'porcentaje_completado': (finalizados / total) * 100,
      'porcentaje_pendiente': (pendientes / total) * 100,
      'porcentaje_en_proceso': (enProceso / total) * 100,
    };
  }
}