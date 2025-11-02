import 'package:mediscan_app/models/usuario_model.dart';
import '../services/usuario_service.dart';

class UsuarioController {
  final UsuarioService _service = UsuarioService();

  /// Registrar usuario nuevo
  Future<Usuario?> registrar(
      String correo, String contrasenia, String rol) async {
    Usuario usuario = Usuario(
      correo: correo,
      contrasenia: contrasenia,
      rol: rol,
    );
    return await _service.registrarUsuario(usuario);
  }

  /// Iniciar sesión
  Future<Usuario?> login(String correo, String contrasenia) async {
    return await _service.iniciarSesion(correo, contrasenia);
  }

  /// Obtener usuario actual
  Future<Usuario?> obtenerUsuarioActual() async {
    return await _service.obtenerUsuarioActual();
  }

  /// Actualizar datos de usuario
  Future<void> actualizarUsuario(Usuario usuario) async {
    await _service.actualizarUsuario(usuario);
  }

  /// Cerrar sesión
  Future<void> cerrarSesion() async {
    await _service.cerrarSesion();
  }
}
