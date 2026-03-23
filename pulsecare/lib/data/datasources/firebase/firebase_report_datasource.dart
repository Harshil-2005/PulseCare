import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pulsecare/data/datasources/report_datasource.dart';
import 'package:pulsecare/data/report_upload_service.dart';
import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/services/supabase_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FirebaseReportDataSource implements ReportDataSource {
  FirebaseReportDataSource({
    FirebaseFirestore? firestore,
    SupabaseStorageService? supabaseStorageService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _supabaseStorageService =
           supabaseStorageService ?? SupabaseStorageService();

  final FirebaseFirestore _firestore;
  final SupabaseStorageService _supabaseStorageService;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  @override
  Future<List<ReportModel>> getAll() async {
    final snapshot = await _reports.get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return ReportModel.fromJson(_normalizeMap(data));
        })
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
      storagePath: report.storagePath,
    );
    final reportWithStorage = await _ensureStorageUpload(toStore);
    await docRef.set(_toFirestoreMap(reportWithStorage));
  }

  @override
  Future<void> remove(ReportModel report) async {
    String? storagePath = report.storagePath;
    String? storageUrl = report.storageUrl;

    final snapshot = await _reports.doc(report.id).get();
    final docData = snapshot.data();
    if (docData != null) {
      storagePath ??= docData['storagePath']?.toString();
      storageUrl ??= docData['storageUrl']?.toString();
    }

    await _deleteStorageObject(
      storagePath: storagePath,
      storageUrl: storageUrl,
    );
    await _reports.doc(report.id).delete();
  }

  @override
  Future<void> deleteReportsForUser(String userId) async {
    final query = await _reports.where('userId', isEqualTo: userId).get();
    for (final doc in query.docs) {
      final data = doc.data();
      final storagePath = data['storagePath']?.toString();
      final storageUrl = data['storageUrl']?.toString();
      await _deleteStorageObject(
        storagePath: storagePath,
        storageUrl: storageUrl,
      );
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
    if (reportWithStorage.storageUrl == null ||
        reportWithStorage.storageUrl!.trim().isEmpty) {
      throw StateError('report_storage_upload_failed');
    }
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
    if (reportWithStorage.storageUrl == null ||
        reportWithStorage.storageUrl!.trim().isEmpty) {
      throw StateError('report_storage_upload_failed');
    }
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
      storagePath: local.storagePath,
    );
  }

  Future<ReportModel> _ensureStorageUpload(ReportModel report) async {
    if (report.storageUrl != null && report.storageUrl!.trim().isNotEmpty) {
      debugPrint(
        '[FirebaseReportDataSource] Skip upload, storageUrl already present for reportId=${report.id}',
      );
      return report;
    }

    final localPath = report.pdfPath;
    if (localPath == null || localPath.trim().isEmpty) {
      debugPrint(
        '[FirebaseReportDataSource] Cannot upload, local pdfPath missing for reportId=${report.id}',
      );
      return report;
    }

    final file = File(localPath);
    if (!await file.exists()) {
      debugPrint(
        '[FirebaseReportDataSource] Cannot upload, file does not exist path=$localPath reportId=${report.id}',
      );
      return report;
    }

    try {
      final storagePath = 'reports/${report.id}.pdf';
      debugPrint(
        '[FirebaseReportDataSource] Uploading reportId=${report.id} to storagePath=$storagePath',
      );
      final downloadUrl = await _supabaseStorageService.uploadReport(
        file,
        report.id,
      );
      if (downloadUrl.trim().isEmpty) {
        throw StateError('empty_supabase_download_url');
      }
      debugPrint(
        '[FirebaseReportDataSource] Upload completed reportId=${report.id}',
      );
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
        storagePath: storagePath,
      );
    } catch (error) {
      debugPrint(
        '[FirebaseReportDataSource] Upload failed reportId=${report.id} error=$error',
      );
      throw StateError('failed_to_upload_report_to_supabase: $error');
    }
  }

  Future<void> _deleteStorageObject({
    String? storagePath,
    String? storageUrl,
  }) async {
    final normalizedPath = storagePath?.trim().isNotEmpty == true
        ? storagePath!.trim()
        : _extractSupabaseStoragePath(storageUrl);
    if (normalizedPath == null || normalizedPath.isEmpty) {
      return;
    }

    try {
      await Supabase.instance.client.storage
          .from(SupabaseStorageService.reportsBucket)
          .remove([normalizedPath]);
    } catch (_) {
      // Keep delete flow resilient if object is already missing.
    }
  }

  String? _extractSupabaseStoragePath(String? storageUrl) {
    final normalizedUrl = storageUrl?.trim();
    if (normalizedUrl == null || normalizedUrl.isEmpty) {
      return null;
    }
    final marker =
        '/storage/v1/object/public/${SupabaseStorageService.reportsBucket}/';
    final markerIndex = normalizedUrl.indexOf(marker);
    if (markerIndex == -1) {
      return null;
    }
    return normalizedUrl.substring(markerIndex + marker.length);
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
    if (report.storagePath == null || report.storagePath!.trim().isEmpty) {
      data.remove('storagePath');
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
