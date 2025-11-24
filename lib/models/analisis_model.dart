class Analisis {
  final String? id;
  final String pacienteId;
  final String doctorId;
  final String? empresaId;
  final String tipoAnalisis;
  final String imagenUrl;
  final String estado; // 'pendiente', 'en_proceso', 'finalizado'
  final DateTime fechaCreacion;
  final DateTime? fechaAnalisis;
  final String? resultado;
  final String? diagnostico;
  final String? observaciones;
  final double? confianza;
  final Map<String, dynamic>? datosIA;

  // 🔵 Nuevo campo que NO se guarda en Firestore
  final String? nombrePaciente;

  Analisis({
    this.id,
    required this.pacienteId,
    required this.doctorId,
    this.empresaId,
    required this.tipoAnalisis,
    required this.imagenUrl,
    this.estado = 'pendiente',
    DateTime? fechaCreacion,
    this.fechaAnalisis,
    this.resultado,
    this.diagnostico,
    this.observaciones,
    this.confianza,
    this.datosIA,
    this.nombrePaciente, // <-- NUEVO
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'paciente_id': pacienteId,
    'doctor_id': doctorId,
    'empresa_id': empresaId,
    'tipo_analisis': tipoAnalisis,
    'imagen_url': imagenUrl,
    'estado': estado,
    'fecha_creacion': fechaCreacion.toIso8601String(),
    'fecha_analisis': fechaAnalisis?.toIso8601String(),
    'resultado': resultado,
    'diagnostico': diagnostico,
    'observaciones': observaciones,
    'confianza': confianza,
    'datos_ia': datosIA,

    // ❗ NO guardamos nombrePaciente en Firestore
    // Para evitar datos duplicados
  };

  factory Analisis.fromMap(Map<String, dynamic> map, [String? id]) {
    return Analisis(
      id: id,
      pacienteId: map['paciente_id'] ?? '',
      doctorId: map['doctor_id'] ?? '',
      empresaId: map['empresa_id'],
      tipoAnalisis: map['tipo_analisis'] ?? '',
      imagenUrl: map['imagen_url'] ?? '',
      estado: map['estado'] ?? 'pendiente',
      fechaCreacion: map['fecha_creacion'] != null
          ? DateTime.parse(map['fecha_creacion'])
          : DateTime.now(),
      fechaAnalisis: map['fecha_analisis'] != null
          ? DateTime.parse(map['fecha_analisis'])
          : null,
      resultado: map['resultado'],
      diagnostico: map['diagnostico'],
      observaciones: map['observaciones'],
      confianza: (map['confianza'] != null)
          ? double.tryParse(map['confianza'].toString())
          : null,
      datosIA: map['datos_ia'] != null
          ? Map<String, dynamic>.from(map['datos_ia'])
          : null,

      // ❗ Firestore NO devuelve esto, se agrega después en Controller
      nombrePaciente: map['nombre_paciente'], // opcional si existe
    );
  }

  Analisis copyWith({
    String? id,
    String? pacienteId,
    String? doctorId,
    String? empresaId,
    String? tipoAnalisis,
    String? imagenUrl,
    String? estado,
    DateTime? fechaCreacion,
    DateTime? fechaAnalisis,
    String? resultado,
    String? diagnostico,
    String? observaciones,
    double? confianza,
    Map<String, dynamic>? datosIA,

    // 🔵 Nuevo campo en copyWith
    String? nombrePaciente,
  }) {
    return Analisis(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      doctorId: doctorId ?? this.doctorId,
      empresaId: empresaId ?? this.empresaId,
      tipoAnalisis: tipoAnalisis ?? this.tipoAnalisis,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaAnalisis: fechaAnalisis ?? this.fechaAnalisis,
      resultado: resultado ?? this.resultado,
      diagnostico: diagnostico ?? this.diagnostico,
      observaciones: observaciones ?? this.observaciones,
      confianza: confianza ?? this.confianza,
      datosIA: datosIA ?? this.datosIA,

      // Nuevo
      nombrePaciente: nombrePaciente ?? this.nombrePaciente,
    );
  }
}
