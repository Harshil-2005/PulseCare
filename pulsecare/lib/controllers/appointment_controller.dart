import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/repositories/appointment_repository.dart';

class AppointmentController {
  AppointmentController(this._appointmentRepository);

  final AppointmentRepository _appointmentRepository;

  Future<void> createAppointment({
    required String doctorId,
    required String userId,
    required DateTime dateTime,
    required AppointmentStatus status,
    required String symptoms,
    String patientName = '',
    int age = 0,
    String gender = '',
    List<ReportModel> reports = const [],
    String? aiSummaryId,
  }) {
    return _appointmentRepository.createAppointment(
      doctorId: doctorId,
      userId: userId,
      dateTime: dateTime,
      status: status,
      symptoms: symptoms,
      patientName: patientName,
      age: age,
      gender: gender,
      reports: reports,
      aiSummaryId: aiSummaryId,
    );
  }

  Stream<List<Appointment>> watchAppointmentsForDoctor(String doctorId) {
    return _appointmentRepository.watchAppointmentsForDoctor(doctorId);
  }

  Stream<List<Appointment>> watchAppointmentsForUser(String userId) {
    return _appointmentRepository.watchAppointmentsForUser(userId);
  }

  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus newStatus,
  ) {
    return _appointmentRepository.updateAppointmentStatus(
      appointmentId,
      newStatus,
    );
  }
}
