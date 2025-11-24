import 'dart:io';
import 'package:mediscan_app/models/analisis_model.dart';
import 'package:mediscan_app/services/analisis_service.dart';
import 'package:mediscan_app/services/paciente_service.dart';

class AnalisisController {
  final AnalisisService _service = AnalisisService();
  final PacienteService _pacienteService = PacienteService();

  /// Subir imagen (Cloudinary)
  Future<String> subirImagen(File imagen, String pacienteId) async {
    try {
      return await _service.subirImagen(imagen, pacienteId);
    } catch (e) {
      rethrow;
    }
  }

  /// Ejecutar modelo IA desde el Controller
  Future<Map<String, dynamic>> ejecutarIA(File imagen) async {
    try {
      return await _service.ejecutarIA(imagen);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> registrarAnalisis(Analisis analisis) async {
    return await _service.registrarAnalisis(analisis);
  }

  Future<List<Analisis>> obtenerAnalisisPaciente(String pacienteId) async {
    return await _service.obtenerAnalisisPorPaciente(pacienteId);
  }

  Stream<List<Analisis>> streamAnalisisDoctor(String doctorId) {
    return _service.streamAnalisisPorDoctor(doctorId).asyncMap((lista) async {
      List<Analisis> resultado = [];

      for (var analisis in lista) {
        final paciente = await _pacienteService.obtenerPacientePorId(
          analisis.pacienteId,
        );

        final nombreCompleto = paciente != null
            ? "${paciente.nombres} ${paciente.apellidos}"
            : "Paciente desconocido";

        resultado.add(analisis.copyWith(nombrePaciente: nombreCompleto));
      }

      return resultado;
    });
  }

  Future<List<Analisis>> obtenerAnalisisPorEstado(
    String doctorId,
    String estado,
  ) async {
    return await _service.obtenerAnalisisPorEstado(doctorId, estado);
  }

  Future<Analisis?> obtenerAnalisisPorId(String id) async {
    return await _service.obtenerAnalisisPorId(id);
  }

  Future<void> actualizarAnalisis(String id, Analisis analisis) async {
    await _service.actualizarAnalisis(id, analisis);
  }

  Future<void> actualizarEstado(String id, String nuevoEstado) async {
    await _service.actualizarEstado(id, nuevoEstado);
  }

  Future<void> actualizarResultado(
    String id,
    String resultado,
    String? diagnostico,
    double? confianza,
    Map<String, dynamic>? datosIA,
  ) async {
    await _service.actualizarResultado(
      id,
      resultado,
      diagnostico,
      confianza,
      datosIA,
    );
  }

  Future<void> eliminarAnalisis(String id, String imagenUrl) async {
    await _service.eliminarAnalisis(id, imagenUrl);
  }

  Stream<List<Analisis>> streamAnalisisPaciente(String pacienteId) {
    return _service.streamAnalisisPorPaciente(pacienteId);
  }

  Future<Map<String, int>> obtenerEstadisticas(String doctorId) async {
    return await _service.obtenerEstadisticas(doctorId);
  }

  bool puedeCrearAnalisis(List<Analisis> analisisExistentes) {
    final pendientes = analisisExistentes
        .where((a) => a.estado == 'pendiente' || a.estado == 'en_proceso')
        .length;

    return pendientes < 5;
  }

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
