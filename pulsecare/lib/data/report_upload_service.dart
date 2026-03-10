import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pulsecare/model/report_model.dart';

class ReportUploadService {
  static Future<ReportModel?> pickAndCreateReportFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.single.path == null) return null;
    final filePath = result.files.single.path!;
    return _createReportFromPath(filePath);
  }

  static Future<ReportModel?> captureAndCreateReportFromCamera() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (photo == null) return null;
    return _createReportFromPath(photo.path);
  }

  static Future<ReportModel> _createReportFromPath(String path) async {
    final ext = _extension(path).toLowerCase();
    final isPdf = ext == '.pdf';
    final pdfPath = isPdf ? path : await _convertImageToPdf(path);
    final title = _basenameWithoutExtension(path).replaceAll('_', ' ');

    return ReportModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      userId: '',
      title: title.isEmpty ? 'Scanned Report' : title,
      uploadedAt: DateTime.now(),
      icon: 'assets/icons/report.svg',
      pdfPath: pdfPath,
    );
  }

  static Future<String> _convertImageToPdf(String imagePath) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final doc = pw.Document();
    final image = pw.MemoryImage(imageBytes);

    doc.addPage(
      pw.Page(
        build: (_) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );

    final parentDir = File(imagePath).parent;
    final reportsDir = Directory(
      '${parentDir.path}${Platform.pathSeparator}reports',
    );
    if (!reportsDir.existsSync()) {
      reportsDir.createSync(recursive: true);
    }

    final pdfFile = File(
      '${reportsDir.path}${Platform.pathSeparator}report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await pdfFile.writeAsBytes(await doc.save(), flush: true);
    return pdfFile.path;
  }

  static String _extension(String filePath) {
    final dot = filePath.lastIndexOf('.');
    if (dot < 0 || dot < filePath.lastIndexOf(RegExp(r'[\\/]+'))) {
      return '';
    }

    return filePath.substring(dot);
  }

  static String _basenameWithoutExtension(String filePath) {
    final normalized = filePath.replaceAll('\\', '/');
    final basename = normalized.split('/').last;
    final dot = basename.lastIndexOf('.');
    if (dot <= 0) return basename;
    return basename.substring(0, dot);
  }
}
