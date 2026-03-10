import 'package:pulsecare/data/datasources/doctor_datasource.dart';
import 'package:pulsecare/model/doctor_model.dart';

class ApiDoctorDataSource implements DoctorDataSource {
  @override
  Future<Doctor?> getByUserId(String userId) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<Doctor> createDoctor(Doctor doctor) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<List<Doctor>> getAll() async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<Doctor?> getById(String id) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Stream<Doctor?> watchById(String id) {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Stream<Doctor?> watchByUserId(String userId) {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Stream<List<Doctor>> watchAll() {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<void> update(Doctor doctor) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<void> incrementPatients(String doctorId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDoctorProfileForUser(String userId) async {
    throw UnimplementedError('API not implemented yet');
  }
}
