import 'package:flutter/material.dart';
import 'package:mediscan_app/models/empresa_model.dart';

class SedesModule extends StatelessWidget {
  final Empresa empresa;
  const SedesModule({super.key, required this.empresa});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sedes - ${empresa.razonSocial}')),
      body: Center(
        child: Text('Aquí se mostrarán y administrarán las sedes de ${empresa.razonSocial}.'),
      ),
    );
  }
}
