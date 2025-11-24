class Persona {
  final String nombres;
  final String apellidos;
  final String tipoDocumento;
  final String numeroDocumento;
  final String telefono;
  final String direccion;
  final String ciudad;
  final String pais;
  final DateTime? fechaNacimiento;
  final String? genero;

  Persona({
    required this.nombres,
    required this.apellidos,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.telefono,
    required this.direccion,
    required this.ciudad,
    required this.pais,
    this.fechaNacimiento,
    this.genero,
  });

  Map<String, dynamic> toMap() => {
        'nombres': nombres,
        'apellidos': apellidos,
        'tipo_documento': tipoDocumento,
        'numero_documento': numeroDocumento,
        'telefono': telefono,
        'direccion': direccion,
        'ciudad': ciudad,
        'pais': pais,
        'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
        'genero': genero,
      };

  factory Persona.fromMap(Map<String, dynamic> map) => Persona(
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
            : null,
        genero: map['genero'],
      );
}
