import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/constrains/app_toast.dart';
import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import '../providers/repository_providers.dart';

void showUploadReportBottomSheet(
  BuildContext context, {
  String? appointmentId,
  String? userId,
  String? doctorId,
  VoidCallback? onReportAdded,
  ValueChanged<ReportModel>? onReportUploaded,
}) {
  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) {
      return _UploadReportSheet(
        appointmentId: appointmentId,
        userId: userId,
        doctorId: doctorId,
        onReportAdded: onReportAdded,
        onReportUploaded: onReportUploaded,
      );
    },
  );
}

class _UploadReportSheet extends StatefulWidget {
  final String? appointmentId;
  final String? userId;
  final String? doctorId;
  final VoidCallback? onReportAdded;
  final ValueChanged<ReportModel>? onReportUploaded;

  const _UploadReportSheet({
    this.appointmentId,
    this.userId,
    this.doctorId,
    this.onReportAdded,
    this.onReportUploaded,
  });

  @override
  State<_UploadReportSheet> createState() => _UploadReportSheetState();
}

class _UploadReportSheetState extends State<_UploadReportSheet> {
  bool _isUploading = false;
  String? _uploadingText;

  Future<void> _handleUpload({required bool fromCamera}) async {
    if (_isUploading) return;
    setState(() {
      _isUploading = true;
      _uploadingText = fromCamera ? 'Uploading (Camera)...' : 'Uploading...';
    });
    final effectiveUserId = widget.userId != null && widget.userId!.trim().isNotEmpty
        ? widget.userId!.trim()
        : (() {
            try {
              return SessionRepository().getCurrentUserId();
            } catch (_) {
              return null;
            }
          })();
    if (effectiveUserId == null || effectiveUserId.isEmpty) {
      if (context.mounted) {
        showAppToast(
          context,
          'Report upload requires user context.',
        );
      }
      setState(() {
        _isUploading = false;
      });
      return;
    }
    final reportRepository = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(reportRepositoryProvider);
    try {
      final report = fromCamera
          ? await reportRepository.uploadFromCamera(
              userId: effectiveUserId,
              appointmentId: widget.appointmentId,
              doctorId: widget.doctorId,
            )
          : await reportRepository.uploadFromFile(
              userId: effectiveUserId,
              appointmentId: widget.appointmentId,
              doctorId: widget.doctorId,
            );
      if (!context.mounted) return;
      if (report != null) {
        widget.onReportUploaded?.call(report);
        widget.onReportAdded?.call();
        Navigator.pop(context);
      } else {
        showAppToast(context, fromCamera ? 'No image captured' : 'No file selected');
      }
    } catch (error) {
      if (!context.mounted) return;
      final message = error.toString();
      showAppToast(context, 'Upload failed: $message');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 375,
      child: Column(
        children: [
          const SizedBox(height: 18),
          Container(
            width: 45,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Upload Report',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _uploadingText ?? 'Uploading...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff3F67FD),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xff3F67FD)),
                      strokeWidth: 2.2,
                    ),
                  ),
                ],
              ),
            ),
          if (!_isUploading) ...[
            InkWell(
              onTap: () => _handleUpload(fromCamera: false),
              child: _uploadOption(
                icon: 'assets/icons/upload_report.svg',
                title: 'Upload File',
              ),
            ),
            InkWell(
              onTap: () => _handleUpload(fromCamera: true),
              child: _uploadOption(
                icon: 'assets/icons/camera.svg',
                title: 'Scan with Camera',
              ),
            ),
          ],
          const SizedBox(height: 30),
          TextButton(
            onPressed: _isUploading ? null : () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xff3F67FD),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

Widget _uploadOption({required String icon, required String title}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 201, 212, 253),
        borderRadius: BorderRadius.circular(35),
      ),
      child: Row(
        children: [
          const SizedBox(width: 30),
          SvgPicture.asset(
            icon,
            width: 23,
            height: 26,
            colorFilter: const ColorFilter.mode(
              Color(0xff3F67FD),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    ),
  );
}
