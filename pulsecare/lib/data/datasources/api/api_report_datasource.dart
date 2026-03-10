import 'package:pulsecare/data/datasources/report_datasource.dart';
import 'package:pulsecare/model/report_model.dart';

class ApiReportDataSource implements ReportDataSource {
  @override
  Future<void> add(ReportModel report) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<List<ReportModel>> getAll() async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Stream<List<ReportModel>> watchReportsByUser(String userId) {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<void> remove(ReportModel report) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<void> deleteReportsForUser(String userId) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<ReportModel?> uploadFromCamera({
    required String userId,
    String? appointmentId,
    String? doctorId,
  }) {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<ReportModel?> uploadFromFile({
    required String userId,
    String? appointmentId,
    String? doctorId,
  }) {
    throw UnimplementedError('API not implemented yet');
  }
}
