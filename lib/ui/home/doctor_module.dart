/* import 'package:flutter/material.dart';
import 'package:mediscan_app/models/empresa_model.dart';

class DoctorModule extends StatelessWidget {
  final Empresa empresa;
  const DoctorModule({super.key, required this.empresa});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Doctores - ${empresa.razonSocial}')),
      body: Center(
        child: Text('Aquí se mostrarán los doctores asociados a ${empresa.razonSocial}.'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aquí abrirías el formulario para registrar un nuevo doctor
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
 */