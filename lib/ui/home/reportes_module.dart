import 'package:flutter/material.dart';
import 'package:mediscan_app/models/empresa_model.dart';

class ReportesModule extends StatelessWidget {
  final Empresa empresa;
  const ReportesModule({super.key, required this.empresa});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reportes - ${empresa.razonSocial}')),
      body: Center(
        child: Text('Aquí se generarán y visualizarán los reportes de ${empresa.razonSocial}.'),
      ),
    );
  }
}
