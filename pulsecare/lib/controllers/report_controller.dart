import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/repositories/report_repository.dart';

class ReportController {
  ReportController(this._reportRepository);

  final ReportRepository _reportRepository;

  Stream<List<ReportModel>> watchReportsByUser(String userId) {
    return _reportRepository.watchReportsByUser(userId);
  }

  Future<ReportModel?> uploadFromFile({
    required String userId,
    String? appointmentId,
    String? doctorId,
  }) {
    return _reportRepository.uploadFromFile(
      userId: userId,
      appointmentId: appointmentId,
      doctorId: doctorId,
    );
  }

  Future<ReportModel?> uploadFromCamera({
    required String userId,
    String? appointmentId,
    String? doctorId,
  }) {
    return _reportRepository.uploadFromCamera(
      userId: userId,
      appointmentId: appointmentId,
      doctorId: doctorId,
    );
  }
}
