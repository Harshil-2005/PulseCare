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
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) {
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

            InkWell(
              onTap: () async {
                final effectiveUserId =
                    userId != null && userId.trim().isNotEmpty
                    ? userId.trim()
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
                  return;
                }
                final reportRepository = ProviderScope.containerOf(
                  context,
                  listen: false,
                ).read(reportRepositoryProvider);
                final report = await reportRepository.uploadFromFile(
                  userId: effectiveUserId,
                  appointmentId: appointmentId,
                  doctorId: doctorId,
                );
                if (report != null) {
                  onReportUploaded?.call(report);
                  onReportAdded?.call();
                  Navigator.pop(context);
                }
              },
              child: _uploadOption(
                icon: 'assets/icons/upload_report.svg',
                title: 'Upload File',
              ),
            ),

            InkWell(
              onTap: () async {
                final effectiveUserId =
                    userId != null && userId.trim().isNotEmpty
                    ? userId.trim()
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
                  return;
                }
                final reportRepository = ProviderScope.containerOf(
                  context,
                  listen: false,
                ).read(reportRepositoryProvider);
                final report = await reportRepository.uploadFromCamera(
                  userId: effectiveUserId,
                  appointmentId: appointmentId,
                  doctorId: doctorId,
                );
                if (report != null) {
                  onReportUploaded?.call(report);
                  onReportAdded?.call();
                  Navigator.pop(context);
                }
              },
              child: _uploadOption(
                icon: 'assets/icons/camera.svg',
                title: 'Scan with Camera',
              ),
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () => Navigator.pop(context),
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
    },
  );
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
