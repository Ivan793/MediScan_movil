
import 'package:mediscan_app/models/empresa_model.dart';
import 'package:mediscan_app/services/empresa_service.dart';

class EmpresaController {
  final EmpresaService _empresaService = EmpresaService();

  /// 🔹 Registrar una nueva empresa
  Future<void> registrarEmpresa(Empresa empresa) async {
    try {
      await _empresaService.registrarEmpresa(empresa);
      print('✅ Empresa registrada correctamente');
    } catch (e) {
      print('❌ Error al registrar empresa: $e');
      rethrow;
    }
  }

  /// 🔹 Obtener empresa por ID de usuario
  Future<Empresa?> obtenerEmpresaPorId(String idUsuario) async {
    try {
      final empresa = await _empresaService.obtenerEmpresaPorId(idUsuario);
      if (empresa == null) {
        print('⚠️ No se encontró empresa para el usuario $idUsuario');
      }
      return empresa;
    } catch (e) {
      print('❌ Error al obtener empresa: $e');
      return null;
    }
  }

  /// 🔹 Actualizar datos de empresa
  Future<void> actualizarEmpresa(Empresa empresa) async {
    try {
      await _empresaService.actualizarEmpresa(empresa);
      print('✅ Empresa actualizada correctamente');
    } catch (e) {
      print('❌ Error al actualizar empresa: $e');
      rethrow;
    }
  }

  /// 🔹 Eliminar empresa (por ID de usuario)
  Future<void> eliminarEmpresa(String idUsuario) async {
    try {
      await _empresaService.eliminarEmpresa(idUsuario);
      print('✅ Empresa eliminada correctamente');
    } catch (e) {
      print('❌ Error al eliminar empresa: $e');
      rethrow;
    }
  }

  /// 🔹 Listar todas las empresas
  Future<List<Empresa>> listarEmpresas() async {
    try {
      final empresas = await _empresaService.obtenerEmpresas();
      print('✅ Se encontraron ${empresas.length} empresas');
      return empresas;
    } catch (e) {
      print('❌ Error al listar empresas: $e');
      return [];
    }
  }
}
