import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mediscan_app/controllers/paciente_controller.dart';
import 'package:mediscan_app/models/paciente_model.dart';
import 'package:mediscan_app/ui/theme/app_colors.dart';
import 'package:mediscan_app/ui/widgets/app_widgets.dart';

class PacienteFormPage extends StatefulWidget {
  final Paciente? paciente;

  const PacienteFormPage({Key? key, this.paciente}) : super(key: key);

  @override
  State<PacienteFormPage> createState() => _PacienteFormPageState();
}

class _PacienteFormPageState extends State<PacienteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final PacienteController _controller = PacienteController();
  bool _isLoading = false;
  int _currentStep = 0;

  // Controladores
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _numeroDocumentoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _paisController = TextEditingController();
  final _emailController = TextEditingController();
  final _grupoSanguineoController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _enfermedadesController = TextEditingController();

  String _tipoDocumento = 'CC';
  String _genero = 'Masculino';
  DateTime _fechaNacimiento = DateTime(2000, 1, 1);

  @override
  void initState() {
    super.initState();
    if (widget.paciente != null) {
      _cargarDatos();
    }
  }

  void _cargarDatos() {
    final p = widget.paciente!;
    _nombresController.text = p.nombres;
    _apellidosController.text = p.apellidos;
    _tipoDocumento = p.tipoDocumento;
    _numeroDocumentoController.text = p.numeroDocumento;
    _telefonoController.text = p.telefono;
    _direccionController.text = p.direccion;
    _ciudadController.text = p.ciudad;
    _paisController.text = p.pais;
    _genero = p.genero ?? 'Masculino';
    _fechaNacimiento = p.fechaNacimiento ?? DateTime(2000, 1, 1);
    _emailController.text = p.email ?? '';
    _grupoSanguineoController.text = p.grupoSanguineo ?? '';
    _alergiasController.text = p.alergias ?? '';
    _enfermedadesController.text = p.enfermedadesPrevias ?? '';
  }

  Future<void> _guardarPaciente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      final paciente = Paciente(
        id: widget.paciente?.id,
        nombres: _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        tipoDocumento: _tipoDocumento,
        numeroDocumento: _numeroDocumentoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
        ciudad: _ciudadController.text.trim(),
        pais: _paisController.text.trim(),
        fechaNacimiento: _fechaNacimiento,
        genero: _genero,
        email: _emailController.text.trim().isNotEmpty 
            ? _emailController.text.trim() 
            : null,
        grupoSanguineo: _grupoSanguineoController.text.trim().isNotEmpty
            ? _grupoSanguineoController.text.trim()
            : null,
        alergias: _alergiasController.text.trim().isNotEmpty
            ? _alergiasController.text.trim()
            : null,
        enfermedadesPrevias: _enfermedadesController.text.trim().isNotEmpty
            ? _enfermedadesController.text.trim()
            : null,
        doctorId: user.uid,
      );

      if (widget.paciente == null) {
        await _controller.registrarPaciente(paciente);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Paciente registrado correctamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await _controller.actualizarPaciente(widget.paciente!.id!, paciente);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Paciente actualizado correctamente'),
              backgroundColor: AppColors.info,
            ),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.paciente == null ? 'Registrar Paciente' : 'Editar Paciente',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _guardarPaciente();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  Expanded(
                    child: AppPrimaryButton(
                      text: _currentStep == 2 
                          ? (widget.paciente == null ? 'Registrar' : 'Guardar')
                          : 'Continuar',
                      onPressed: details.onStepContinue,
                      isLoading: _isLoading,
                      icon: _currentStep == 2 ? Icons.save : Icons.arrow_forward,
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppSecondaryButton(
                        text: 'Atrás',
                        onPressed: details.onStepCancel,
                        icon: Icons.arrow_back,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Información Personal'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _buildPersonalInfo(),
            ),
            Step(
              title: const Text('Contacto'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: _buildContactInfo(),
            ),
            Step(
              title: const Text('Información Médica'),
              isActive: _currentStep >= 2,
              content: _buildMedicalInfo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Nombres *',
          controller: _nombresController,
          prefixIcon: Icons.person,
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          label: 'Apellidos *',
          controller: _apellidosController,
          prefixIcon: Icons.person_outline,
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        
        DropdownButtonFormField<String>(
          value: _tipoDocumento,
          decoration: InputDecoration(
            labelText: 'Tipo de Documento *',
            prefixIcon: const Icon(Icons.badge, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.grey50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey200),
            ),
          ),
          items: ['CC', 'TI', 'CE', 'Pasaporte'].map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: (value) => setState(() => _tipoDocumento = value!),
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          label: 'Número de Documento *',
          controller: _numeroDocumentoController,
          prefixIcon: Icons.credit_card,
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _fechaNacimiento,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => _fechaNacimiento = picked);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Fecha de Nacimiento *',
              prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.grey50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey200),
              ),
            ),
            child: Text(
              '${_fechaNacimiento.day}/${_fechaNacimiento.month}/${_fechaNacimiento.year}',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        DropdownButtonFormField<String>(
          value: _genero,
          decoration: InputDecoration(
            labelText: 'Género *',
            prefixIcon: const Icon(Icons.wc, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.grey50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.grey200),
            ),
          ),
          items: ['Masculino', 'Femenino', 'Otro'].map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: (value) => setState(() => _genero = value!),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      children: [
        AppTextField(
          label: 'Teléfono *',
          controller: _telefonoController,
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          label: 'Email (Opcional)',
          controller: _emailController,
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          label: 'Dirección *',
          controller: _direccionController,
          prefixIcon: Icons.home,
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          label: 'Ciudad *',
          controller: _ciudadController,
          prefixIcon: Icons.location_city,
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          label: 'País *',
          controller: _paisController,
          prefixIcon: Icons.flag,
          validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
      ],
    );
  }

  Widget _buildMedicalInfo() {
    return Column(
      children: [
        AppTextField(
          label: 'Grupo Sanguíneo (Opcional)',
          controller: _grupoSanguineoController,
          prefixIcon: Icons.bloodtype,
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          label: 'Alergias (Opcional)',
          controller: _alergiasController,
          prefixIcon: Icons.warning_amber,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          label: 'Enfermedades Previas (Opcional)',
          controller: _enfermedadesController,
          prefixIcon: Icons.medical_services,
          maxLines: 3,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _numeroDocumentoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _paisController.dispose();
    _emailController.dispose();
    _grupoSanguineoController.dispose();
    _alergiasController.dispose();
    _enfermedadesController.dispose();
    super.dispose();
  }
}