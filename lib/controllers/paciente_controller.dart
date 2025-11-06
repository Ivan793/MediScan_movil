import 'package:mediscan_app/models/paciente_model.dart';
import 'package:mediscan_app/services/paciente_service.dart';

class PacienteController {
  final PacienteService _service = PacienteService();

  /// Registrar nuevo paciente
  Future<String> registrarPaciente(Paciente paciente) async {
    try {
      return await _service.registrarPaciente(paciente);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener pacientes del doctor
  Future<List<Paciente>> obtenerPacientesDoctor(String doctorId) async {
    try {
      return await _service.obtenerPacientesPorDoctor(doctorId);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener pacientes de una empresa
  Future<List<Paciente>> obtenerPacientesEmpresa(String empresaId) async {
    try {
      return await _service.obtenerPacientesPorEmpresa(empresaId);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener un paciente por ID
  Future<Paciente?> obtenerPacientePorId(String id) async {
    try {
      return await _service.obtenerPacientePorId(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Buscar paciente por documento
  Future<List<Paciente>> buscarPorDocumento(String numeroDocumento, String doctorId) async {
    try {
      return await _service.buscarPorDocumento(numeroDocumento, doctorId);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar paciente
  Future<void> actualizarPaciente(String id, Paciente paciente) async {
    try {
      await _service.actualizarPaciente(id, paciente);
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar paciente
  Future<void> eliminarPaciente(String id) async {
    try {
      await _service.eliminarPaciente(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Stream de pacientes
  Stream<List<Paciente>> streamPacientes(String doctorId) {
    return _service.streamPacientesPorDoctor(doctorId);
  }
}