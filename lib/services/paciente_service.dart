import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediscan_app/models/paciente_model.dart';

class PacienteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'pacientes';

  /// Registrar un nuevo paciente
  Future<String> registrarPaciente(Paciente paciente) async {
    try {
      final docRef = await _firestore.collection(collectionName).add(paciente.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al registrar paciente: $e');
    }
  }

  /// Obtener todos los pacientes de un doctor
  Future<List<Paciente>> obtenerPacientesPorDoctor(String doctorId) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('doctor_id', isEqualTo: doctorId)
          .orderBy('fecha_registro', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Paciente.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener pacientes: $e');
    }
  }

  /// Obtener pacientes por empresa
  Future<List<Paciente>> obtenerPacientesPorEmpresa(String empresaId) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('empresa_id', isEqualTo: empresaId)
          .orderBy('fecha_registro', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Paciente.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener pacientes: $e');
    }
  }

  /// Obtener un paciente por ID
  Future<Paciente?> obtenerPacientePorId(String id) async {
    try {
      final doc = await _firestore.collection(collectionName).doc(id).get();
      if (doc.exists) {
        return Paciente.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener paciente: $e');
    }
  }

  /// Buscar pacientes por documento
  Future<List<Paciente>> buscarPorDocumento(String numeroDocumento, String doctorId) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('numero_documento', isEqualTo: numeroDocumento)
          .where('doctor_id', isEqualTo: doctorId)
          .get();

      return snapshot.docs
          .map((doc) => Paciente.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar paciente: $e');
    }
  }

  /// Actualizar paciente
  Future<void> actualizarPaciente(String id, Paciente paciente) async {
    try {
      await _firestore.collection(collectionName).doc(id).update(paciente.toMap());
    } catch (e) {
      throw Exception('Error al actualizar paciente: $e');
    }
  }

  /// Eliminar paciente
  Future<void> eliminarPaciente(String id) async {
    try {
      await _firestore.collection(collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar paciente: $e');
    }
  }

  /// Stream de pacientes de un doctor (para actualizaciones en tiempo real)
  Stream<List<Paciente>> streamPacientesPorDoctor(String doctorId) {
    return _firestore
        .collection(collectionName)
        .where('doctor_id', isEqualTo: doctorId)
        .orderBy('fecha_registro', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Paciente.fromMap(doc.data(), doc.id))
            .toList());
  }
}