import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mediscan_app/controllers/paciente_controller.dart';
import 'package:mediscan_app/models/paciente_model.dart';

class PacienteFormPage extends StatefulWidget {
  final Paciente? paciente; // Para edición

  const PacienteFormPage({Key? key, this.paciente}) : super(key: key);

  @override
  State<PacienteFormPage> createState() => _PacienteFormPageState();
}

class _PacienteFormPageState extends State<PacienteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final PacienteController _controller = PacienteController();
  bool _isLoading = false;

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
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _controller.actualizarPaciente(widget.paciente!.id!, paciente);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Paciente actualizado correctamente'),
              backgroundColor: Colors.blue,
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
            backgroundColor: Colors.red,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.paciente == null ? 'Registrar Paciente' : 'Editar Paciente'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSeccion('Información Personal'),
              _buildTextField('Nombres', _nombresController, Icons.person),
              _buildTextField('Apellidos', _apellidosController, Icons.person_outline),
              
              _buildDropdown(
                'Tipo de Documento',
                _tipoDocumento,
                ['CC', 'TI', 'CE', 'Pasaporte'],
                (value) => setState(() => _tipoDocumento = value!),
              ),
              
              _buildTextField('Número de Documento', _numeroDocumentoController, Icons.badge),
              
              _buildDatePicker(),
              
              _buildDropdown(
                'Género',
                _genero,
                ['Masculino', 'Femenino', 'Otro'],
                (value) => setState(() => _genero = value!),
              ),

              const SizedBox(height: 24),
              _buildSeccion('Contacto'),
              _buildTextField('Teléfono', _telefonoController, Icons.phone, isPhone: true),
              _buildTextField('Email', _emailController, Icons.email, required: false, isEmail: true),
              _buildTextField('Dirección', _direccionController, Icons.home, required: false),
              _buildTextField('Ciudad', _ciudadController, Icons.location_city),
              _buildTextField('País', _paisController, Icons.flag),

              const SizedBox(height: 24),
              _buildSeccion('Información Médica'),
              _buildTextField('Grupo Sanguíneo', _grupoSanguineoController, Icons.bloodtype, required: false),
              _buildTextField('Alergias', _alergiasController, Icons.warning_amber, 
                  required: false, maxLines: 3),
              _buildTextField('Enfermedades Previas', _enfermedadesController, Icons.medical_services,
                  required: false, maxLines: 3),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardarPaciente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.paciente == null ? 'Registrar Paciente' : 'Guardar Cambios',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool required = true,
    bool isPhone = false,
    bool isEmail = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isPhone
            ? TextInputType.phone
            : isEmail
                ? TextInputType.emailAddress
                : TextInputType.text,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: required
            ? (value) => value == null || value.isEmpty ? 'Campo requerido' : null
            : null,
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
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
            prefixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          child: Text(
            '${_fechaNacimiento.day}/${_fechaNacimiento.month}/${_fechaNacimiento.year}',
          ),
        ),
      ),
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