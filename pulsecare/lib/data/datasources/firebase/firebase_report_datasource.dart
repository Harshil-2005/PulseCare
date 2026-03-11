import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pulsecare/data/datasources/report_datasource.dart';
import 'package:pulsecare/data/report_upload_service.dart';
import 'package:pulsecare/model/report_model.dart';

class FirebaseReportDataSource implements ReportDataSource {
  FirebaseReportDataSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  @override
  Future<List<ReportModel>> getAll() async {
    final snapshot = await _reports.get();
    return snapshot.docs
        .map((doc) => ReportModel.fromJson(_normalizeMap(doc.data())))
        .toList(growable: false);
  }

  @override
  Stream<List<ReportModel>> watchReportsByUser(String userId) {
    return _reports.where('userId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = _normalizeMap(doc.data());
        data['id'] = doc.id;
        return ReportModel.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<void> add(ReportModel report) async {
    final docRef = report.id.isNotEmpty
        ? _reports.doc(report.id)
        : _reports.doc();
    final toStore = ReportModel(
      id: docRef.id,
      userId: report.userId,
      appointmentId: report.appointmentId,
      doctorId: report.doctorId,
      createdAt: report.createdAt,
      updatedAt: report.updatedAt,
      title: report.title,
      uploadedAt: report.uploadedAt,
      icon: report.icon,
      pdfPath: report.pdfPath,
      storageUrl: report.storageUrl,
    );
    final reportWithStorage = await _ensureStorageUpload(toStore);
    await docRef.set(_toFirestoreMap(reportWithStorage));
  }

  @override
  Future<void> remove(ReportModel report) async {
    await _reports.doc(report.id).delete();
  }

  @override
  Future<void> deleteReportsForUser(String userId) async {
    final query = await _reports.where('userId', isEqualTo: userId).get();
    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<ReportModel?> uploadFromFile({
    required String userId,
    String? appointmentId,
    String? doctorId,
  }) async {
    final local = await ReportUploadService.pickAndCreateReportFromFile();
    if (local == null) return null;
    final uploaded = _buildLocalReport(
      local,
      userId: userId,
      appointmentId: appointmentId,
      doctorId: doctorId,
    );
    final reportWithStorage = await _ensureStorageUpload(uploaded);
    final data = _toFirestoreMap(reportWithStorage);
    data['userId'] = userId;
    await _reports.doc(reportWithStorage.id).set(data);
    return reportWithStorage;
  }

  @override
  Future<ReportModel?> uploadFromCamera({
    required String userId,
    String? appointmentId,
    String? doctorId,
  }) async {
    final local = await ReportUploadService.captureAndCreateReportFromCamera();
    if (local == null) return null;
    final uploaded = _buildLocalReport(
      local,
      userId: userId,
      appointmentId: appointmentId,
      doctorId: doctorId,
    );
    final reportWithStorage = await _ensureStorageUpload(uploaded);
    final data = _toFirestoreMap(reportWithStorage);
    data['userId'] = userId;
    await _reports.doc(reportWithStorage.id).set(data);
    return reportWithStorage;
  }

  ReportModel _buildLocalReport(
    ReportModel local, {
    required String userId,
    String? appointmentId,
    String? doctorId,
  }) {
    final docId = local.id.isNotEmpty ? local.id : _reports.doc().id;

    return ReportModel(
      id: docId,
      userId: userId,
      appointmentId: appointmentId,
      doctorId: doctorId,
      createdAt: local.createdAt,
      updatedAt: local.updatedAt,
      title: local.title,
      uploadedAt: local.uploadedAt,
      icon: local.icon,
      pdfPath: local.pdfPath,
      storageUrl: local.storageUrl,
    );
  }

  Future<ReportModel> _ensureStorageUpload(ReportModel report) async {
    if (report.storageUrl != null && report.storageUrl!.trim().isNotEmpty) {
      return report;
    }

    final localPath = report.pdfPath;
    if (localPath == null || localPath.trim().isEmpty) {
      return report;
    }

    final file = File(localPath);
    if (!await file.exists()) {
      return report;
    }

    try {
      final ref = _storage
          .ref()
          .child('reports')
          .child(report.userId)
          .child('${report.id}.pdf');
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      return ReportModel(
        id: report.id,
        userId: report.userId,
        appointmentId: report.appointmentId,
        doctorId: report.doctorId,
        createdAt: report.createdAt,
        updatedAt: report.updatedAt,
        title: report.title,
        uploadedAt: report.uploadedAt,
        icon: report.icon,
        pdfPath: report.pdfPath,
        storageUrl: downloadUrl,
      );
    } catch (_) {
      return report;
    }
  }

  Map<String, dynamic> _toFirestoreMap(ReportModel report) {
    final data = report.toJson();
    if (report.appointmentId == null) {
      data.remove('appointmentId');
    }
    if (report.doctorId == null) {
      data.remove('doctorId');
    }
    if (report.storageUrl == null || report.storageUrl!.trim().isEmpty) {
      data.remove('storageUrl');
    }
    return data;
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    map['id'] = (map['id'] ?? '').toString();
    if (map['createdAt'] is Timestamp) {
      map['createdAt'] = (map['createdAt'] as Timestamp)
          .toDate()
          .toIso8601String();
    }
    if (map['updatedAt'] is Timestamp) {
      map['updatedAt'] = (map['updatedAt'] as Timestamp)
          .toDate()
          .toIso8601String();
    }
    if (map['uploadedAt'] is Timestamp) {
      map['uploadedAt'] = (map['uploadedAt'] as Timestamp)
          .toDate()
          .toIso8601String();
    }
    return map;
  }
}
