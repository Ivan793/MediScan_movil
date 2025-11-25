import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mediscan_app/controllers/doctor_controller.dart';
import 'package:mediscan_app/models/doctor_model.dart';
import 'package:mediscan_app/models/empresa_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mediscan_app/ui/theme/app_colors.dart';
import 'package:mediscan_app/ui/widgets/app_widgets.dart';

class DoctorIndependientePage extends StatefulWidget {
  const DoctorIndependientePage({super.key});

  @override
  State<DoctorIndependientePage> createState() =>
      _DoctorIndependientePageState();
}

class _DoctorIndependientePageState extends State<DoctorIndependientePage> {
  final DoctorController _doctorController = DoctorController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Doctor? _doctorActual;
  Empresa? _empresaAsociada;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDoctorActual();
  }

  Future<void> _cargarDoctorActual() async {
    setState(() => _cargando = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No hay usuario autenticado");
      }

      final docSnapshot = await _firestore
          .collection('doctores')
          .doc(user.uid)
          .get();

      if (!docSnapshot.exists) {
        throw Exception("Doctor no encontrado");
      }

      _doctorActual = Doctor.fromMap(docSnapshot.data()!, docSnapshot.id);

      if (_doctorActual!.empresaId != null &&
          _doctorActual!.empresaId!.isNotEmpty) {
        final empresaSnapshot = await _firestore
            .collection('empresas')
            .doc(_doctorActual!.empresaId)
            .get();

        if (empresaSnapshot.exists) {
          _empresaAsociada = Empresa.fromMap(
            empresaSnapshot.data()!,
            empresaSnapshot.id,
          );
        }
      }
    } catch (e) {
      print("Error al cargar el doctor actual: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _doctorActual == null
          ? const Center(child: Text("No se encontró información del doctor"))
          : RefreshIndicator(
              onRefresh: _cargarDoctorActual,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  // App Bar con gradiente
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                      ),
                                      child: const CircleAvatar(
                                        radius: 36,
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          Icons.person,
                                          size: 40,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${_doctorActual!.nombres} ${_doctorActual!.apellidos}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (_doctorActual!.especialidades
                                              .isNotEmpty)
                                            Text(
                                              _doctorActual!.especialidades.first,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: _cerrarSesion,
                        tooltip: 'Cerrar sesión',
                      ),
                    ],
                  ),

                  // Contenido
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Empresa asociada
                        if (_empresaAsociada != null) ...[
                          AppCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.business,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        "Empresa Asociada",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                _infoRow(
                                  "Razón Social:",
                                  _empresaAsociada!.razonSocial,
                                ),
                                _infoRow("NIT:", _empresaAsociada!.nit),
                                _infoRow(
                                  "Teléfono:",
                                  _empresaAsociada!.telefono,
                                ),
                                _infoRow("Ciudad:", _empresaAsociada!.ciudad),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Título de acciones
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            "Acciones Rápidas",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),

                        // Botones de acciones principales
                        Row(
                          children: [
                            Expanded(
                              child: _accionCard(
                                Icons.people,
                                "Pacientes",
                                AppColors.primary,
                                () => Navigator.pushNamed(context, '/pacientes'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _accionCard(
                                Icons.medical_services,
                                "Análisis",
                                AppColors.secondary,
                                () => Navigator.pushNamed(context, '/analisis'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        AppCard(
                          onTap: () async {
                            if (_doctorActual!.empresaId != null &&
                                _doctorActual!.empresaId!.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Los doctores asociados a una empresa no pueden editar su perfil.",
                                  ),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                              return;
                            }

                            final actualizado = await _mostrarModalEditarDoctor(
                              _doctorActual!,
                            );

                            if (actualizado == true) {
                              await _cargarDoctorActual();
                            }
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: AppColors.info,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  "Editar Perfil",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Información personal
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            "Información Personal",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),

                        AppCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow(
                                "Documento",
                                _doctorActual!.numeroDocumento,
                              ),
                              _infoRow("Teléfono", _doctorActual!.telefono),
                              _infoRow("Dirección", _doctorActual!.direccion),
                              _infoRow("Ciudad", _doctorActual!.ciudad),
                              _infoRow("País", _doctorActual!.pais),
                              _infoRow("Correo", _doctorActual!.usuario.correo),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Información profesional
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            "Información Profesional",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),

                        AppCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow("Rethus", _doctorActual!.rethus),
                              _infoRow(
                                "Tarjeta Profesional",
                                _doctorActual!.numeroTarjetaProfesional,
                              ),
                              _infoRow(
                                "Año de Graduación",
                                _doctorActual!.anioGraduacion.toString(),
                              ),
                              _infoRow(
                                "Especialidades",
                                _doctorActual!.especialidades.join(', '),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _accionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : "No especificado",
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _mostrarModalEditarDoctor(Doctor doctor) {
    final _formKey = GlobalKey<FormState>();
    final DoctorController _doctorController = DoctorController();

    final telefonoController = TextEditingController(text: doctor.telefono);
    final direccionController = TextEditingController(text: doctor.direccion);
    final ciudadController = TextEditingController(text: doctor.ciudad);
    final paisController = TextEditingController(text: doctor.pais);

    bool guardando = false;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Center(
                        child: Text(
                          "Editar Información Personal",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        label: "Teléfono",
                        controller: telefonoController,
                        prefixIcon: Icons.phone,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: "Dirección",
                        controller: direccionController,
                        prefixIcon: Icons.home,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: "Ciudad",
                        controller: ciudadController,
                        prefixIcon: Icons.location_city,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: "País",
                        controller: paisController,
                        prefixIcon: Icons.flag,
                      ),
                      const SizedBox(height: 24),
                      AppPrimaryButton(
                        text: "Guardar cambios",
                        onPressed: guardando
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                setModalState(() => guardando = true);

                                try {
                                  final doctorActualizado = Doctor(
                                    id: doctor.id,
                                    empresaId: doctor.empresaId,
                                    nombres: doctor.nombres,
                                    apellidos: doctor.apellidos,
                                    tipoDocumento: doctor.tipoDocumento,
                                    numeroDocumento: doctor.numeroDocumento,
                                    telefono: telefonoController.text.trim(),
                                    direccion: direccionController.text.trim(),
                                    ciudad: ciudadController.text.trim(),
                                    pais: paisController.text.trim(),
                                    fechaNacimiento: doctor.fechaNacimiento ?? DateTime(2000, 1, 1),
                                    genero: doctor.genero ?? '',
                                    rethus: doctor.rethus,
                                    numeroTarjetaProfesional:
                                        doctor.numeroTarjetaProfesional,
                                    especialidades: doctor.especialidades,
                                    anioGraduacion: doctor.anioGraduacion,
                                    archivoTarjetaProfesional:
                                        doctor.archivoTarjetaProfesional,
                                    archivoTituloGrado:
                                        doctor.archivoTituloGrado,
                                    archivoRethus: doctor.archivoRethus,
                                    archivoEspecialidad:
                                        doctor.archivoEspecialidad,
                                    usuario: doctor.usuario,
                                  );

                                  await _doctorController.actualizarDoctor(
                                    doctor.id!,
                                    doctorActualizado,
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Perfil actualizado correctamente",
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                  Navigator.pop(context, true);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Error al guardar: $e"),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                } finally {
                                  setModalState(() => guardando = false);
                                }
                              },
                        isLoading: guardando,
                        icon: Icons.save,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}