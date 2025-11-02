import 'package:mediscan_app/models/persona_model.dart';

import '../models/doctor_model.dart';

import '../services/doctor_service.dart';

class DoctorController {
  final DoctorService _doctorService = DoctorService();

  Future<void> registrarDoctor(Doctor doctor, Persona persona) async {
    await _doctorService.registrarDoctor(doctor, persona);
  }

  Future<List<Doctor>> obtenerDoctores() async {
    return await _doctorService.obtenerDoctores();
  }

  Future<Doctor?> obtenerDoctorPorId(String id) async {
    return await _doctorService.obtenerDoctorPorId(id);
  }

  Future<void> actualizarDoctor(String id, Doctor doctor) async {
    await _doctorService.actualizarDoctor(id, doctor);
  }

  Future<void> eliminarDoctor(String id) async {
    await _doctorService.eliminarDoctor(id);
  }
}
