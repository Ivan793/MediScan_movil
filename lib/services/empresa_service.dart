import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediscan_app/models/empresa_model.dart';

class EmpresaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'empresas';

  /// 🔹 Registrar una nueva empresa
  Future<void> registrarEmpresa(Empresa empresa) async {
    try {
      // Generamos o usamos el id_usuario como ID de documento
      final docRef = _firestore.collection(collectionName).doc(empresa.usuario.id_usuario);

      final data = empresa.toMap();
      data['id'] = docRef.id; // 🔹 Guardamos el ID dentro del documento

      await docRef.set(data);
    } catch (e) {
      throw Exception('Error al registrar la empresa: $e');
    }
  }

  /// 🔹 Obtener una empresa por ID de usuario
  Future<Empresa?> obtenerEmpresaPorId(String idUsuario) async {
    try {
      final doc = await _firestore.collection(collectionName).doc(idUsuario).get();
      if (doc.exists) {
        return Empresa.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener la empresa: $e');
    }
  }

  /// 🔹 Obtener todas las empresas
  Future<List<Empresa>> obtenerEmpresas() async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();
      return snapshot.docs
          .map((doc) => Empresa.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener las empresas: $e');
    }
  }

  /// 🔹 Actualizar una empresa existente
  Future<void> actualizarEmpresa(Empresa empresa) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(empresa.usuario.id_usuario)
          .update(empresa.toMap());
    } catch (e) {
      throw Exception('Error al actualizar la empresa: $e');
    }
  }

  /// 🔹 Eliminar una empresa
  Future<void> eliminarEmpresa(String idUsuario) async {
    try {
      await _firestore.collection(collectionName).doc(idUsuario).delete();
    } catch (e) {
      throw Exception('Error al eliminar la empresa: $e');
    }
  }
}
