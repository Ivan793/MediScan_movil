import 'package:mediscan_app/models/usuario_model.dart';

class Empresa {
  final String? id; // <-- ID único para Firestore o base de datos
  final String nit;
  final String razonSocial;
  final String licenciaFuncionamiento;
  final String direccion;
  final String ciudad;
  final String departamento;
  final String pais;
  final String telefono;
  final String correoContacto;
  final String? regimen;
  final String? ips;
  final List<String>? servicios;
  final List<String>? sedes;
  final String? estado;
  final DateTime? fechaVerificacion;
  final Usuario usuario;

  Empresa({
    this.id, // <-- nuevo campo opcional
    required this.nit,
    required this.razonSocial,
    required this.licenciaFuncionamiento,
    required this.direccion,
    required this.ciudad,
    required this.departamento,
    required this.pais,
    required this.telefono,
    required this.correoContacto,
    required this.usuario,
    this.regimen,
    this.ips,
    this.servicios,
    this.sedes,
    this.estado,
    this.fechaVerificacion,
  });

  Map<String, dynamic> toMap() => {
        'id': id, // <-- se agrega aquí
        'nit': nit,
        'razon_social': razonSocial,
        'licencia_funcionamiento': licenciaFuncionamiento,
        'direccion': direccion,
        'ciudad': ciudad,
        'departamento': departamento,
        'pais': pais,
        'telefono': telefono,
        'correo_contacto': correoContacto,
        'regimen': regimen,
        'ips': ips,
        'servicios': servicios,
        'sedes': sedes,
        'estado': estado ?? 'pendiente',
        'fecha_verificacion': fechaVerificacion?.toIso8601String(),
        'usuario': usuario.toMap(),
      };

  factory Empresa.fromMap(Map<String, dynamic> map, [String? id]) => Empresa(
        id: id ?? map['id'], // <-- aquí también
        nit: map['nit'],
        razonSocial: map['razon_social'],
        licenciaFuncionamiento: map['licencia_funcionamiento'],
        direccion: map['direccion'],
        ciudad: map['ciudad'],
        departamento: map['departamento'],
        pais: map['pais'],
        telefono: map['telefono'],
        correoContacto: map['correo_contacto'],
        regimen: map['regimen'],
        ips: map['ips'],
        servicios: List<String>.from(map['servicios'] ?? []),
        sedes: List<String>.from(map['sedes'] ?? []),
        estado: map['estado'],
        fechaVerificacion: map['fecha_verificacion'] != null
            ? DateTime.parse(map['fecha_verificacion'])
            : null,
        usuario: Usuario.fromMap(map['usuario']),
      );
}
