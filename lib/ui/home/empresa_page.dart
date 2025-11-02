import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mediscan_app/controllers/empresa_controller.dart';
import 'package:mediscan_app/models/empresa_model.dart';
import 'package:mediscan_app/ui/home/doctor_empresa_module.dart';
import 'package:mediscan_app/ui/home/perfil_empresa.dart';
import 'servicios_module.dart';
import 'sedes_module.dart';
import 'reportes_module.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  final EmpresaController _empresaController = EmpresaController();
  Empresa? empresa;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEmpresa();
  }

  Future<void> _cargarEmpresa() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final empresaData = await _empresaController.obtenerEmpresaPorId(user.uid);
    setState(() {
      empresa = empresaData;
      isLoading = false;
    });
  }

  void _abrirModulo(String modulo) {
    switch (modulo) {
      case 'doctores':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DoctorEmpresaModule(empresa: empresa!)),
        );
        break;
      case 'servicios':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ServiciosModule(empresa: empresa!)),
        );
        break;
      case 'sedes':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SedesModule(empresa: empresa!)),
        );
        break;
      case 'reportes':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReportesModule(empresa: empresa!)),
        );
        break;
    }
  }

  // 🔹 Cerrar sesión
  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  // 🔹 Menú hamburguesa (actualizado)
  Widget _menuHamburguesa() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu, color: Colors.black87),
      onSelected: (value) {
        if (value == 'perfil' && empresa != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PerfilEmpresa(empresa: empresa!)),
          );
        } else if (value == 'logout') {
          _cerrarSesion();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'perfil',
          child: ListTile(
            leading: Icon(Icons.account_circle, color: Colors.indigo),
            title: Text('Ver perfil de empresa'),
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.redAccent),
            title: Text('Cerrar sesión'),
          ),
        ),
      ],
    );
  }

  void _mostrarOpciones() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person_add_alt_1, color: Colors.blue),
              title: const Text("Gestionar Doctores"),
              onTap: () => _abrirModulo('doctores'),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services, color: Colors.green),
              title: const Text("Servicios Médicos"),
              onTap: () => _abrirModulo('servicios'),
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.orange),
              title: const Text("Sedes"),
              onTap: () => _abrirModulo('sedes'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.purple),
              title: const Text("Ver Reportes"),
              onTap: () => _abrirModulo('reportes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1976D2))),
      );
    }

    if (empresa == null) {
      return Scaffold(
        body: const Center(child: Text("No se encontró información de la empresa.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarOpciones,
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarEmpresa,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _HeaderEmpresa(empresa: empresa!)),
                  _menuHamburguesa(), // 👈 menú actualizado
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: "Resumen General",
                child: Column(
                  children: [
                    _InfoRow(label: "NIT", value: empresa!.nit),
                    _InfoRow(label: "Teléfono", value: empresa!.telefono),
                    _InfoRow(label: "Ciudad", value: empresa!.ciudad),
                    _InfoRow(label: "Estado", value: empresa!.estado ?? "Pendiente"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: "Módulos rápidos",
                child: Column(
                  children: [
                    _ActionButton(icon: Icons.person_add, label: "Doctores", onPressed: () => _abrirModulo('doctores')),
                    _ActionButton(icon: Icons.medical_services_outlined, label: "Servicios", onPressed: () => _abrirModulo('servicios')),
                    _ActionButton(icon: Icons.location_city, label: "Sedes", onPressed: () => _abrirModulo('sedes')),
                    _ActionButton(icon: Icons.bar_chart, label: "Reportes", onPressed: () => _abrirModulo('reportes')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderEmpresa extends StatelessWidget {
  final Empresa empresa;

  const _HeaderEmpresa({required this.empresa});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF1976D2),
            radius: 30,
            child: Icon(Icons.business, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(empresa.razonSocial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(empresa.correoContacto, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: Colors.blue),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}
