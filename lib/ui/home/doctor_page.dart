import 'package:flutter/material.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF), // Gradiente azul claro
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Color(0xFFBBDEFB),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              "EP",
                              style: TextStyle(
                                color: Color(0xFF1976D2),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Estela Paredes",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Médico General",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.menu, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- RESUMEN DE ANÁLISIS ---
              _SectionCard(
                title: "Resumen de Análisis",
                subtitle: "Hoy",
                child: Column(
                  children: [
                    _SummaryItem(
                      title: "Análisis Hoy",
                      value: "24",
                      color: Colors.blue.shade50,
                      valueColor: Colors.black,
                      indicatorColor: Colors.green,
                      indicatorText: "+27% desde ayer",
                      icon: Icons.trending_up,
                    ),
                    const SizedBox(height: 12),
                    _SummaryItem(
                      title: "Anomalías Encontradas",
                      value: "7",
                      color: Colors.red.shade50,
                      valueColor: Colors.black,
                      indicatorColor: Colors.red,
                      indicatorText: "Requieren atención",
                      icon: Icons.warning,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- ACCIONES RÁPIDAS ---
              _SectionCard(
                title: "Acciones Rápidas",
                child: Column(
                  children: [
                    _ActionButton(
                      label: "Nuevo Análisis",
                      icon: Icons.add,
                      filled: true,
                      onPressed: () {},
                    ),
                    _ActionButton(
                      label: "Ver Historial",
                      icon: Icons.history,
                      filled: false,
                      onPressed: () {},
                    ),
                    _ActionButton(
                      label: "Mis Pacientes",
                      icon: Icons.person_outline,
                      filled: false,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- ACTIVIDAD RECIENTE ---
              _SectionCard(
                title: "Actividad Reciente",
                child: Column(
                  children: const [
                    _ActivityTile(
                      patient: "María González",
                      time: "Hace 15 min",
                      statusColor: Colors.green,
                    ),
                    _ActivityTile(
                      patient: "Carlos Ruiz",
                      time: "Hace 1 hora",
                      statusColor: Colors.amber,
                    ),
                    _ActivityTile(
                      patient: "Ana Martínez",
                      time: "Hace 2 horas",
                      statusColor: Colors.green,
                    ),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Color valueColor;
  final Color indicatorColor;
  final String indicatorText;
  final IconData icon;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.color,
    required this.valueColor,
    required this.indicatorColor,
    required this.indicatorText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Icon(icon, color: indicatorColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    indicatorText,
                    style: TextStyle(color: indicatorColor, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: filled ? Colors.white : Colors.black87),
        label: Text(label, style: TextStyle(color: filled ? Colors.white : Colors.black87)),
        style: ElevatedButton.styleFrom(
          elevation: filled ? 2 : 0,
          backgroundColor: filled ? const Color(0xFF1976D2) : Colors.white,
          side: filled ? BorderSide.none : const BorderSide(color: Color(0xFFE0E0E0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String patient;
  final String time;
  final Color statusColor;

  const _ActivityTile({
    required this.patient,
    required this.time,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final initials = patient
        .split(" ")
        .map((n) => n[0])
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  initials,
                  style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
