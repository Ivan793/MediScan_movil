class Usuario {
  final String correo;
  final String contrasenia;
  final String rol; // 'empresa' o 'doctor'
  final String? id_usuario;
  final String? fotoPerfilUrl;

  Usuario({
    this.id_usuario,
    required this.correo,
    required this.contrasenia,
    required this.rol,
    this.fotoPerfilUrl,
  });

  Map<String, dynamic> toMap() => {
        'id_usuario': id_usuario,
        'correo': correo,
        'rol': rol,
        'foto_perfil_url': fotoPerfilUrl,
      };

  factory Usuario.fromMap(Map<String, dynamic> map) => Usuario(
  id_usuario: map['id_usuario'],
  correo: map['correo'],
  contrasenia: map['contrasenia'] ?? '',
  rol: map['rol'] ?? map['Rol'] ?? map['role'] ?? map['tipo'] ?? 'desconocido',
  fotoPerfilUrl: map['foto_perfil_url'],
);
}
