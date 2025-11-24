import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediscan_app/models/persona_model.dart';
import '../models/doctor_model.dart';


class DoctorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registrar un doctor junto con su persona asociada
  Future<void> registrarDoctor(Doctor doctor, Persona persona) async {
    try {
      // Guardar persona primero
      DocumentReference personaRef =
          await _firestore.collection('personas').add(persona.toMap());

      // Guardar doctor con referencia a la persona
      await _firestore.collection('doctores').add({
        ...doctor.toMap(),
        'persona_id': personaRef.id,
      });
    } catch (e) {
      print('Error al registrar doctor: $e');
    }
  }

  /// Obtener lista de doctores
  Future<List<Doctor>> obtenerDoctores() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('doctores').get();
      return snapshot.docs
          .map((doc) => Doctor.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      print('Error al obtener doctores: $e');
      return [];
    }
  }

  Future<List<Doctor>> obtenerDoctoresPorEmpresa(String empresaId) async {
  try {
    QuerySnapshot snapshot = await _firestore
        .collection('doctores')
        .where('empresa_id', isEqualTo: empresaId)
        .get();

    return snapshot.docs
        .map((doc) => Doctor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  } catch (e) {
    print('Error al obtener doctores por empresa: $e');
    return [];
  }
}
  /// Obtener un doctor por ID
  Future<Doctor?> obtenerDoctorPorId(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('doctores').doc(id).get();
      if (!doc.exists) return null;

      return Doctor.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Error al obtener doctor: $e');
      return null;
    }
  }

  /// Actualizar información del doctor
  Future<void> actualizarDoctor(String id, Doctor doctor) async {
    try {
      await _firestore.collection('doctores').doc(id).update(doctor.toMap());
    } catch (e) {
      print('Error al actualizar doctor: $e');
    }
  }

  /// Eliminar un doctor
  Future<void> eliminarDoctor(String id) async {
    try {
      await _firestore.collection('doctores').doc(id).delete();
    } catch (e) {
      print('Error al eliminar doctor: $e');
    }
  }
}
