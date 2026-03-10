import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/data/report_upload_service.dart';

abstract class ReportDataSource {
  Future<List<ReportModel>> getAll();
  Stream<List<ReportModel>> watchReportsByUser(String userId);
  Future<void> add(ReportModel report);
  Future<void> remove(ReportModel report);
  Future<void> deleteReportsForUser(String userId);
  Future<ReportModel?> uploadFromFile({
    required String userId,
    String? appointmentId,
    String? doctorId,
  });
  Future<ReportModel?> uploadFromCamera({
    required String userId,
    String? appointmentId,
    String? doctorId,
  });
}

class LocalReportDataSource implements ReportDataSource {
  LocalReportDataSource();

  final List<ReportModel> _reports = [
    ReportModel(
      id: 'seed_1',
      userId: 'u1',
      title: 'Annual Blood Work',
      uploadedAt: DateTime(2025, 11, 10),
      icon: 'assets/icons/blood.svg',
    ),
    ReportModel(
      id: 'seed_2',
      userId: 'u1',
      title: 'Blood Test_2',
      uploadedAt: DateTime(2025, 10, 26),
      icon: 'assets/icons/lungs.svg',
    ),
    ReportModel(
      id: 'seed_3',
      userId: 'u1',
      title: 'ECG Report',
      uploadedAt: DateTime(2025, 9, 12),
      icon: 'assets/icons/ecg.svg',
    ),
    ReportModel(
      id: 'seed_4',
      userId: 'u1',
      title: 'Chest X-Ray Results',
      uploadedAt: DateTime(2025, 8, 6),
      icon: 'assets/icons/lungs.svg',
    ),
    ReportModel(
      id: 'seed_5',
      userId: 'u1',
      title: 'Blood Test',
      uploadedAt: DateTime(2025, 6, 17),
      icon: 'assets/icons/lungs.svg',
    ),
    ReportModel(
      id: 'seed_6',
      userId: 'u1',
      title: 'Annual Blood Work',
      uploadedAt: DateTime(2025, 11, 10),
      icon: 'assets/icons/blood.svg',
    ),
    ReportModel(
      id: 'seed_7',
      userId: 'u1',
      title: 'Blood Test',
      uploadedAt: DateTime(2025, 10, 26),
      icon: 'assets/icons/lungs.svg',
    ),
  ];

  @override
  Future<List<ReportModel>> getAll() async => List.unmodifiable(_reports);

  @override
  Stream<List<ReportModel>> watchReportsByUser(String userId) {
    return Stream.value(
      _reports
          .where((report) => report.userId == userId)
          .toList(growable: false),
    );
  }

  @override
  Future<void> add(ReportModel report) async {
    _reports.insert(0, report);
  }

  @override
  Future<void> remove(ReportModel report) async {
    _reports.removeWhere((r) => r.id == report.id);
  }

  @override
  Future<void> deleteReportsForUser(String userId) async {
    _reports.removeWhere((report) => report.userId == userId);
  }

  @override
  Future<ReportModel?> uploadFromFile({
    required String userId,
    String? appointmentId,
    String? doctorId,
  }) async {
    final report = await ReportUploadService.pickAndCreateReportFromFile();
    if (report != null) {
      final owned = ReportModel(
        id: report.id,
        userId: userId,
        appointmentId: appointmentId,
        doctorId: doctorId,
        createdAt: report.createdAt,
        updatedAt: report.updatedAt,
        title: report.title,
        uploadedAt: report.uploadedAt,
        icon: report.icon,
        pdfPath: report.pdfPath,
      );
      _reports.insert(0, owned);
      return owned;
    }
    return null;
  }

  @override
  Future<ReportModel?> uploadFromCamera({
    required String userId,
    String? appointmentId,
    String? doctorId,
  }) async {
    final report = await ReportUploadService.captureAndCreateReportFromCamera();
    if (report != null) {
      final owned = ReportModel(
        id: report.id,
        userId: userId,
        appointmentId: appointmentId,
        doctorId: doctorId,
        createdAt: report.createdAt,
        updatedAt: report.updatedAt,
        title: report.title,
        uploadedAt: report.uploadedAt,
        icon: report.icon,
        pdfPath: report.pdfPath,
      );
      _reports.insert(0, owned);
      return owned;
    }
    return null;
  }
}
