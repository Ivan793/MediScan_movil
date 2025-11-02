import 'package:flutter/material.dart';
import 'package:mediscan_app/models/empresa_model.dart';

class PerfilEmpresa extends StatelessWidget {
  final Empresa empresa;

  const PerfilEmpresa({super.key, required this.empresa});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        title: const Text("Perfil de la Empresa", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Encabezado con logo/avatar
              CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xFF1976D2),
                child: const Icon(Icons.business, color: Colors.white, size: 45),
              ),
              const SizedBox(height: 16),
              Text(
                empresa.razonSocial,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                empresa.correoContacto,
                style: const TextStyle(color: Colors.grey),
              ),
              const Divider(height: 30, thickness: 1.2),
              
              // Información principal
              _buildInfoTile(Icons.badge, "NIT", empresa.nit),
              _buildInfoTile(Icons.phone, "Teléfono", empresa.telefono),
              _buildInfoTile(Icons.location_city, "Ciudad", empresa.ciudad),
              _buildInfoTile(Icons.email_outlined, "Correo de Contacto", empresa.correoContacto),
              _buildInfoTile(Icons.flag_circle, "Estado", empresa.estado ?? "Pendiente"),

              const SizedBox(height: 20),

              // Botón volver
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text(
                  "Regresar",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1976D2), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
