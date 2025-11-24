import 'package:flutter/material.dart';
import 'package:mediscan_app/models/empresa_model.dart';

class ServiciosModule extends StatelessWidget {
  final Empresa empresa;
  const ServiciosModule({super.key, required this.empresa});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Servicios - ${empresa.razonSocial}')),
      body: Center(
        child: Text('Aquí podrás gestionar los servicios médicos de ${empresa.razonSocial}.'),
      ),
    );
  }
}
