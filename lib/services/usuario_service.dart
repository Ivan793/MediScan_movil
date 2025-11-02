import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mediscan_app/models/usuario_model.dart';

class UsuarioService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crear usuario en Firebase Auth y guardar datos en Firestore
  Future<Usuario?> registrarUsuario(Usuario usuario) async {
    try {
      // Registrar en Auth
      UserCredential credencial = await _auth.createUserWithEmailAndPassword(
        email: usuario.correo,
        password: usuario.contrasenia,
      );

      // Crear objeto con id
      final nuevoUsuario = Usuario(
        id_usuario: credencial.user!.uid,
        correo: usuario.correo,
        contrasenia: usuario.contrasenia,
        rol: usuario.rol,
        fotoPerfilUrl: usuario.fotoPerfilUrl,
      );

      // Guardar en Firestore
      await _firestore
          .collection('usuarios')
          .doc(nuevoUsuario.id_usuario)
          .set(nuevoUsuario.toMap());

      return nuevoUsuario;
    } catch (e) {
      print('Error al registrar usuario: $e');
      return null;
    }
  }

  /// Iniciar sesión con correo y contraseña
  Future<Usuario?> iniciarSesion(String correo, String contrasenia) async {
    try {
      UserCredential credencial = await _auth.signInWithEmailAndPassword(
        email: correo,
        password: contrasenia,
      );

      DocumentSnapshot doc = await _firestore
          .collection('usuarios')
          .doc(credencial.user!.uid)
          .get();

      if (doc.exists) {
        return Usuario.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error al iniciar sesión: $e');
      return null;
    }
  }

  /// Obtener usuario actual
  Future<Usuario?> obtenerUsuarioActual() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc =
          await _firestore.collection('usuarios').doc(user.uid).get();

      if (doc.exists) {
        return Usuario.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error al obtener usuario actual: $e');
      return null;
    }
  }

  /// Cerrar sesión
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  /// Actualizar datos del usuario
  Future<void> actualizarUsuario(Usuario usuario) async {
    try {
      await _firestore
          .collection('usuarios')
          .doc(usuario.id_usuario)
          .update(usuario.toMap());
    } catch (e) {
      print('Error al actualizar usuario: $e');
    }
  }
}
