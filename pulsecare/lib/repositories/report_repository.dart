import 'package:flutter/material.dart';
import 'package:pulsecare/data/datasources/report_datasource.dart';
import 'package:pulsecare/model/report_model.dart';

class ReportRepository extends ChangeNotifier {
  ReportRepository._privateConstructor(this._dataSource);

  static ReportRepository? _instance;

  factory ReportRepository([ReportDataSource? dataSource]) {
    _instance ??= ReportRepository._privateConstructor(
      dataSource ?? LocalReportDataSource(),
    );
    return _instance!;
  }

  final ReportDataSource _dataSource;

  Future<List<ReportModel>> getReports() async {
    return await _dataSource.getAll();
  }

  Stream<List<ReportModel>> watchReportsByUser(String userId) {
    return _dataSource.watchReportsByUser(userId);
  }

  void addReport(ReportModel report) {
    _dataSource.add(report);
    notifyListeners();
  }

  void removeReport(ReportModel report) {
    _dataSource.remove(report);
    notifyListeners();
  }

  Future<void> deleteReportsForUser(String userId) async {
    await _dataSource.deleteReportsForUser(userId);
    notifyListeners();
  }

  Future<ReportModel?> uploadFromFile({
    required String userId,
    String? appointmentId,
    String? doctorId,
  }) async {
    _validateUserOwnership(userId: userId);
    final report = await _dataSource.uploadFromFile(
      userId: userId,
      appointmentId: appointmentId,
      doctorId: doctorId,
    );
    if (report != null) {
      notifyListeners();
    }
    return report;
  }

  Future<ReportModel?> uploadFromCamera({
    required String userId,
    String? appointmentId,
    String? doctorId,
  }) async {
    _validateUserOwnership(userId: userId);
    final report = await _dataSource.uploadFromCamera(
      userId: userId,
      appointmentId: appointmentId,
      doctorId: doctorId,
    );
    if (report != null) {
      notifyListeners();
    }
    return report;
  }

  void _validateUserOwnership({required String userId}) {
    if (userId.trim().isEmpty) {
      throw StateError('missing_report_user');
    }
  }
}
