import 'package:pulsecare/data/datasources/appointment_datasource.dart';
import 'package:pulsecare/model/appointment_model.dart';

class ApiAppointmentDataSource implements AppointmentDataSource {
  @override
  Future<void> add(Appointment appointment) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<List<Appointment>> getAll() async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<List<Appointment>> getForUser(String userId) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<List<Appointment>> getForDoctor(String doctorId) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<List<Appointment>> getForDoctorAt(
    String doctorId,
    DateTime scheduledAt,
  ) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<Appointment?> getById(String id) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Stream<List<Appointment>> watchForUser(String userId) {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Stream<List<Appointment>> watchForDoctor(String doctorId) {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<void> remove(Appointment appointment) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<void> update(Appointment appointment) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<void> updateStatusRaw(String appointmentId, String rawStatus) {
    // TODO: implement updateStatusRaw
    throw UnimplementedError();
  }
}
