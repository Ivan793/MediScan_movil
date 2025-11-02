import 'package:mediscan_app/models/persona_model.dart';
import 'package:mediscan_app/models/usuario_model.dart';

class Doctor extends Persona {
  final String? id;
  final String? empresaId; // <-- referencia a la empresa
  final String rethus;
  final String numeroTarjetaProfesional;
  final List<String> especialidades;
  final int anioGraduacion;
  final String? archivoTarjetaProfesional;
  final String? archivoTituloGrado;
  final String? archivoRethus;
  final String? archivoEspecialidad;
  final Usuario usuario;

  Doctor({
    this.id,
    this.empresaId, // <-- nuevo campo
    required String nombres,
    required String apellidos,
    required String tipoDocumento,
    required String numeroDocumento,
    required String telefono,
    required String direccion,
    required String ciudad,
    required String pais,
    required DateTime fechaNacimiento,
    required String genero,
    required this.rethus,
    required this.numeroTarjetaProfesional,
    required this.especialidades,
    required this.anioGraduacion,
    this.archivoTarjetaProfesional,
    this.archivoTituloGrado,
    this.archivoRethus,
    this.archivoEspecialidad,
    required this.usuario,
  }) : super(
          nombres: nombres,
          apellidos: apellidos,
          tipoDocumento: tipoDocumento,
          numeroDocumento: numeroDocumento,
          telefono: telefono,
          direccion: direccion,
          ciudad: ciudad,
          pais: pais,
          fechaNacimiento: fechaNacimiento,
          genero: genero,
        );

  @override
  Map<String, dynamic> toMap() {
    final base = super.toMap();
    base.addAll({
      'empresa_id': empresaId, // <-- se agrega aquí
      'rethus': rethus,
      'numero_tarjeta_profesional': numeroTarjetaProfesional,
      'especialidades': especialidades,
      'anio_graduacion': anioGraduacion,
      'archivo_tarjeta_profesional': archivoTarjetaProfesional,
      'archivo_titulo_grado': archivoTituloGrado,
      'archivo_rethus': archivoRethus,
      'archivo_especialidad': archivoEspecialidad,
      'usuario': usuario.toMap(),
    });
    return base;
  }

  factory Doctor.fromMap(Map<String, dynamic> map, [String? id]) => Doctor(
        id: id,
        empresaId: map['empresa_id'], // <-- aquí también
        nombres: map['nombres'] ?? '',
        apellidos: map['apellidos'] ?? '',
        tipoDocumento: map['tipo_documento'] ?? '',
        numeroDocumento: map['numero_documento'] ?? '',
        telefono: map['telefono'] ?? '',
        direccion: map['direccion'] ?? '',
        ciudad: map['ciudad'] ?? '',
        pais: map['pais'] ?? '',
        fechaNacimiento: map['fecha_nacimiento'] != null
            ? DateTime.tryParse(map['fecha_nacimiento']) ?? DateTime.now()
            : DateTime.now(),
        genero: map['genero'] ?? '',
        rethus: map['rethus'] ?? '',
        numeroTarjetaProfesional: map['numero_tarjeta_profesional'] ?? '',
        especialidades: List<String>.from(map['especialidades'] ?? const []),
        anioGraduacion: map['anio_graduacion'] ?? 0,
        archivoTarjetaProfesional: map['archivo_tarjeta_profesional'],
        archivoTituloGrado: map['archivo_titulo_grado'],
        archivoRethus: map['archivo_rethus'],
        archivoEspecialidad: map['archivo_especialidad'],
        usuario: map['usuario'] != null
            ? Usuario.fromMap(map['usuario'])
            : Usuario(
                correo: '',
                contrasenia: '',
                rol: 'doctor',
              ),
      );
}
