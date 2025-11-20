import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediscan_app/models/paciente_model.dart';

class PacienteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'pacientes';

  /// Registrar un nuevo paciente
  Future<String> registrarPaciente(Paciente paciente) async {
    try {
      print('📝 Registrando paciente para doctor: ${paciente.doctorId}');
      final docRef = await _firestore.collection(collectionName).add(paciente.toMap());
      print('✅ Paciente registrado con ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error al registrar paciente: $e');
      throw Exception('Error al registrar paciente: $e');
    }
  }

  /// Obtener todos los pacientes de un doctor
  Future<List<Paciente>> obtenerPacientesPorDoctor(String doctorId) async {
    try {
      print('🔍 Buscando pacientes para doctor: $doctorId');
      
      // Primero obtenemos todos los pacientes del doctor sin ordenar
      final snapshot = await _firestore
          .collection(collectionName)
          .where('doctor_id', isEqualTo: doctorId)
          .get();

      print('📊 Documentos encontrados: ${snapshot.docs.length}');
      
      if (snapshot.docs.isEmpty) {
        print('⚠️ No se encontraron pacientes para el doctor $doctorId');
        
        // Verificar si hay algún paciente en la colección (para debug)
        final totalSnapshot = await _firestore.collection(collectionName).limit(5).get();
        print('📊 Total de pacientes en BD (primeros 5): ${totalSnapshot.docs.length}');
        
        if (totalSnapshot.docs.isNotEmpty) {
          print('🔍 Ejemplo de doctor_id en BD: ${totalSnapshot.docs.first.data()['doctor_id']}');
        }
      }

      final pacientes = snapshot.docs
          .map((doc) {
            try {
              return Paciente.fromMap(doc.data(), doc.id);
            } catch (e) {
              print('❌ Error al parsear paciente ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Paciente>()
          .toList();

      // Ordenamos en memoria en lugar de en Firestore
      pacientes.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));

      print('✅ Pacientes parseados correctamente: ${pacientes.length}');
      return pacientes;
    } catch (e) {
      print('❌ Error al obtener pacientes: $e');
      throw Exception('Error al obtener pacientes: $e');
    }
  }

  /// Obtener pacientes por empresa
  Future<List<Paciente>> obtenerPacientesPorEmpresa(String empresaId) async {
    try {
      print('🔍 Buscando pacientes para empresa: $empresaId');
      
      // Sin ordenar en Firestore para evitar necesidad de índices
      final snapshot = await _firestore
          .collection(collectionName)
          .where('empresa_id', isEqualTo: empresaId)
          .get();

      print('📊 Documentos encontrados: ${snapshot.docs.length}');

      final pacientes = snapshot.docs
          .map((doc) => Paciente.fromMap(doc.data(), doc.id))
          .toList();
      
      // Ordenamos en memoria
      pacientes.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
      
      return pacientes;
    } catch (e) {
      print('❌ Error al obtener pacientes por empresa: $e');
      throw Exception('Error al obtener pacientes: $e');
    }
  }

  /// Obtener un paciente por ID
  Future<Paciente?> obtenerPacientePorId(String id) async {
    try {
      print('🔍 Buscando paciente por ID: $id');
      
      final doc = await _firestore.collection(collectionName).doc(id).get();
      
      if (doc.exists) {
        print('✅ Paciente encontrado');
        return Paciente.fromMap(doc.data()!, doc.id);
      }
      
      print('⚠️ Paciente no encontrado');
      return null;
    } catch (e) {
      print('❌ Error al obtener paciente: $e');
      throw Exception('Error al obtener paciente: $e');
    }
  }

  /// Buscar pacientes por documento
  Future<List<Paciente>> buscarPorDocumento(String numeroDocumento, String doctorId) async {
    try {
      print('🔍 Buscando paciente con documento: $numeroDocumento para doctor: $doctorId');
      
      final snapshot = await _firestore
          .collection(collectionName)
          .where('numero_documento', isEqualTo: numeroDocumento)
          .where('doctor_id', isEqualTo: doctorId)
          .get();

      print('📊 Pacientes encontrados: ${snapshot.docs.length}');

      return snapshot.docs
          .map((doc) => Paciente.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error al buscar paciente: $e');
      throw Exception('Error al buscar paciente: $e');
    }
  }

  /// Actualizar paciente
  Future<void> actualizarPaciente(String id, Paciente paciente) async {
    try {
      print('📝 Actualizando paciente: $id');
      await _firestore.collection(collectionName).doc(id).update(paciente.toMap());
      print('✅ Paciente actualizado correctamente');
    } catch (e) {
      print('❌ Error al actualizar paciente: $e');
      throw Exception('Error al actualizar paciente: $e');
    }
  }

  /// Eliminar paciente
  Future<void> eliminarPaciente(String id) async {
    try {
      print('🗑️ Eliminando paciente: $id');
      await _firestore.collection(collectionName).doc(id).delete();
      print('✅ Paciente eliminado correctamente');
    } catch (e) {
      print('❌ Error al eliminar paciente: $e');
      throw Exception('Error al eliminar paciente: $e');
    }
  }

  /// Stream de pacientes de un doctor (para actualizaciones en tiempo real)
  Stream<List<Paciente>> streamPacientesPorDoctor(String doctorId) {
    print('🔄 Iniciando stream de pacientes para doctor: $doctorId');
    
    // Sin ordenar en Firestore para evitar necesidad de índices
    return _firestore
        .collection(collectionName)
        .where('doctor_id', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
          print('📊 Stream actualizado: ${snapshot.docs.length} pacientes');
          
          final pacientes = snapshot.docs
              .map((doc) => Paciente.fromMap(doc.data(), doc.id))
              .toList();
          
          // Ordenamos en memoria
          pacientes.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
          
          return pacientes;
        });
  }
}