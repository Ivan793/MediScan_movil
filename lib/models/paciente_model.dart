import 'package:mediscan_app/models/persona_model.dart';

class Paciente extends Persona {
  final String? id;
  final String? email;
  final String? grupoSanguineo;
  final String? alergias;
  final String? enfermedadesPrevias;
  final String doctorId; // ID del doctor que lo registró
  final String? empresaId; // ID de la empresa si aplica
  final DateTime fechaRegistro;

  Paciente({
    this.id,
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
    this.email,
    this.grupoSanguineo,
    this.alergias,
    this.enfermedadesPrevias,
    required this.doctorId,
    this.empresaId,
    DateTime? fechaRegistro,
  })  : fechaRegistro = fechaRegistro ?? DateTime.now(),
        super(
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

  String get nombreCompleto => '$nombres $apellidos';

  int get edad {
    final hoy = DateTime.now();
    int edad = hoy.year - fechaNacimiento!.year;
    if (hoy.month < fechaNacimiento!.month ||
        (hoy.month == fechaNacimiento!.month && hoy.day < fechaNacimiento!.day)) {
      edad--;
    }
    return edad;
  }

  @override
  Map<String, dynamic> toMap() {
    final base = super.toMap();
    base.addAll({
      'email': email,
      'grupo_sanguineo': grupoSanguineo,
      'alergias': alergias,
      'enfermedades_previas': enfermedadesPrevias,
      'doctor_id': doctorId,
      'empresa_id': empresaId,
      'fecha_registro': fechaRegistro.toIso8601String(),
    });
    return base;
  }

  factory Paciente.fromMap(Map<String, dynamic> map, [String? id]) => Paciente(
        id: id,
        nombres: map['nombres'] ?? '',
        apellidos: map['apellidos'] ?? '',
        tipoDocumento: map['tipo_documento'] ?? '',
        numeroDocumento: map['numero_documento'] ?? '',
        telefono: map['telefono'] ?? '',
        direccion: map['direccion'] ?? '',
        ciudad: map['ciudad'] ?? '',
        pais: map['pais'] ?? '',
        fechaNacimiento: map['fecha_nacimiento'] != null
            ? DateTime.parse(map['fecha_nacimiento'])
            : DateTime.now(),
        genero: map['genero'] ?? '',
        email: map['email'],
        grupoSanguineo: map['grupo_sanguineo'],
        alergias: map['alergias'],
        enfermedadesPrevias: map['enfermedades_previas'],
        doctorId: map['doctor_id'] ?? '',
        empresaId: map['empresa_id'],
        fechaRegistro: map['fecha_registro'] != null
            ? DateTime.parse(map['fecha_registro'])
            : DateTime.now(),
      );
}