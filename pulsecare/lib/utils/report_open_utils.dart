import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/services/supabase_storage_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openReportExternally(ReportModel report) async {
  final localFile = await prepareReportLocalFile(report);
  if (localFile != null) {
    final openedLocal = await _tryLaunchFile(localFile.path);
    if (openedLocal) return true;
  }

  final remoteUrl = report.storageUrl?.trim() ?? '';
  if (remoteUrl.startsWith('http://') || remoteUrl.startsWith('https://')) {
    final openedExternal = await _tryLaunchExternalNonBrowser(remoteUrl);
    if (openedExternal) return true;
  }

  return false;
}

Future<File?> prepareReportLocalFile(ReportModel report) async {
  final localPath = report.pdfPath?.trim() ?? '';
  if (localPath.isNotEmpty && File(localPath).existsSync()) {
    debugPrint('[ReportOpen] Using local path: $localPath');
    return File(localPath);
  }

  final downloadedFromStorage = await _downloadFromSupabaseStorage(report);
  if (downloadedFromStorage != null) {
    debugPrint(
      '[ReportOpen] Using downloaded storage file: $downloadedFromStorage',
    );
    return File(downloadedFromStorage);
  }

  final derivedPath = _extractStoragePathFromUrl(report.storageUrl);
  if (derivedPath != null) {
    final downloadedFromDerivedPath = await _downloadFromStoragePath(
      reportId: report.id,
      storagePath: derivedPath,
    );
    if (downloadedFromDerivedPath != null) {
      debugPrint(
        '[ReportOpen] Using downloaded derived storage file: $downloadedFromDerivedPath',
      );
      return File(downloadedFromDerivedPath);
    }
  }

  final remoteUrl = report.storageUrl?.trim() ?? '';
  if (remoteUrl.startsWith('http://') || remoteUrl.startsWith('https://')) {
    final downloadedPath = await _downloadRemotePdfToTemp(
      reportId: report.id,
      url: remoteUrl,
    );
    if (downloadedPath != null) {
      debugPrint('[ReportOpen] Using downloaded remote file: $downloadedPath');
      return File(downloadedPath);
    }
  }

  return null;
}

Future<String?> saveReportWithSystemDialog(ReportModel report) async {
  final localFile = await prepareReportLocalFile(report);
  if (localFile == null) {
    return null;
  }

  final baseName = _safeFileName(
    report.title.trim().isEmpty ? 'report' : report.title.trim(),
  );
  final fileName = '${baseName}_${DateTime.now().millisecondsSinceEpoch}.pdf';

  try {
    final data = await localFile.readAsBytes();
    final savedPath = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: data,
        fileName: fileName,
        mimeTypesFilter: const ['application/pdf'],
      ),
    );
    debugPrint(
      '[ReportSave] Save result path=$savedPath source=${localFile.path}',
    );
    return savedPath;
  } catch (error) {
    debugPrint(
      '[ReportSave] Save failed for source=${localFile.path} error=$error',
    );
    return null;
  }
}

Future<bool> shareReportFile(ReportModel report) async {
  final localFile = await prepareReportLocalFile(report);
  if (localFile != null) {
    try {
      await Share.shareXFiles([XFile(localFile.path)], text: report.title);
      return true;
    } catch (error) {
      debugPrint(
        '[ReportShare] File-path share failed for ${localFile.path} error=$error',
      );
      try {
        final data = await localFile.readAsBytes();
        await Share.shareXFiles([
          XFile.fromData(
            data,
            mimeType: 'application/pdf',
            name: '${_safeFileName(report.title)}.pdf',
          ),
        ], text: report.title);
        return true;
      } catch (fallbackError) {
        debugPrint(
          '[ReportShare] Byte share fallback failed for ${localFile.path} error=$fallbackError',
        );
      }
    }
  }

  final remoteUrl = report.storageUrl?.trim() ?? '';
  if (remoteUrl.startsWith('http://') || remoteUrl.startsWith('https://')) {
    try {
      await Share.share(remoteUrl);
      return true;
    } catch (error) {
      debugPrint(
        '[ReportShare] URL share fallback failed for $remoteUrl error=$error',
      );
    }
  }

  return false;
}

Future<bool> _tryLaunchFile(String path) async {
  try {
    final result = await OpenFilex.open(path);
    debugPrint(
      '[ReportOpen] OpenFilex result=${result.type} message=${result.message} path=$path',
    );
    return result.type == ResultType.done;
  } catch (_) {
    return false;
  }
}

Future<String?> _downloadFromSupabaseStorage(ReportModel report) async {
  final storagePath = report.storagePath?.trim() ?? '';
  if (storagePath.isEmpty) {
    return null;
  }

  return _downloadFromStoragePath(
    reportId: report.id,
    storagePath: storagePath,
  );
}

Future<String?> _downloadFromStoragePath({
  required String reportId,
  required String storagePath,
}) async {
  try {
    final bytes = await Supabase.instance.client.storage
        .from(SupabaseStorageService.reportsBucket)
        .download(storagePath);
    if (bytes.isEmpty) {
      return null;
    }
    return _writeTempPdf(bytes, reportId);
  } catch (_) {
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from(SupabaseStorageService.reportsBucket)
          .createSignedUrl(storagePath, 120);
      final response = await http.get(Uri.parse(signedUrl));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _writeTempPdf(response.bodyBytes, reportId);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

Future<String?> _downloadRemotePdfToTemp({
  required String reportId,
  required String url,
}) async {
  try {
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    return _writeTempPdf(response.bodyBytes, reportId);
  } catch (_) {
    return null;
  }
}

Future<bool> _tryLaunchExternalNonBrowser(String url) async {
  try {
    final uri = Uri.parse(url);
    return await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
  } catch (_) {
    return false;
  }
}

Future<String> _writeTempPdf(List<int> bytes, String reportId) async {
  final tempDir = await getTemporaryDirectory();
  final normalizedId = reportId.trim().isEmpty
      ? DateTime.now().millisecondsSinceEpoch.toString()
      : reportId.trim();
  final filePath = '${tempDir.path}/report_$normalizedId.pdf';
  final file = File(filePath);
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

String _safeFileName(String input) {
  final value = input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  return value.isEmpty ? 'report' : value;
}

String? _extractStoragePathFromUrl(String? storageUrl) {
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

  final rawPath = normalizedUrl.substring(markerIndex + marker.length);
  final noQuery = rawPath.split('?').first;
  final decoded = Uri.decodeComponent(noQuery);
  return decoded.isEmpty ? null : decoded;
}
