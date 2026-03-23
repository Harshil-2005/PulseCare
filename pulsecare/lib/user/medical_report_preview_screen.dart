import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pulsecare/constrains/app_toast.dart';
import 'package:pulsecare/constrains/primary_icon_button.dart';
import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/user/ai_chat_screen.dart';
import 'package:pulsecare/utils/time_utils.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalReportPreviewScreen extends StatefulWidget {
  final ReportModel? report;
  final bool isDoctorView;

  const MedicalReportPreviewScreen({
    super.key,
    required this.report,
    this.isDoctorView = false,
  });

  @override
  State<MedicalReportPreviewScreen> createState() =>
      _MedicalReportPreviewScreenState();
}

class _MedicalReportPreviewScreenState
    extends State<MedicalReportPreviewScreen> {
  static const String _reportPreviewImage = 'assets/images/report_img.png';

  String? get _remotePdfUrl {
    final url = widget.report?.storageUrl?.trim();
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return null;
  }

  String _headerTitle() {
    final report = widget.report;
    if (report == null) return 'Medical Report: 10 Nov';
    return 'Medical Report: ${TimeUtils.formatDate(report.uploadedAt)}';
  }

  Future<void> _openPdfViewer(int pageNumber) async {
    final pdfPath = widget.report?.pdfPath;
    final hasLocalPdf = pdfPath != null && File(pdfPath).existsSync();
    final remoteUrl = _remotePdfUrl;
    if (!hasLocalPdf && remoteUrl == null) return;

    final targetUri = hasLocalPdf ? Uri.file(pdfPath) : Uri.parse(remoteUrl!);
    bool opened = false;
    try {
      opened = await launchUrl(targetUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (opened || !mounted) return;

    showAppToast(context, 'Unable to open PDF reader on this device');
  }

  Widget _buildSinglePreviewPanel(int pageNumber) {
    final pdfPath = widget.report?.pdfPath;
    final hasLocalPdf = pdfPath != null && File(pdfPath).existsSync();
    final remoteUrl = _remotePdfUrl;

    return InkWell(
      onTap: () => _openPdfViewer(pageNumber),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(8),
        child: hasLocalPdf
            ? SfPdfViewer.file(
                File(pdfPath),
                initialPageNumber: pageNumber,
                canShowScrollHead: false,
                canShowPaginationDialog: false,
                enableDoubleTapZooming: true,
              )
            : remoteUrl != null
            ? SfPdfViewer.network(
                remoteUrl,
                initialPageNumber: pageNumber,
                canShowScrollHead: false,
                canShowPaginationDialog: false,
                enableDoubleTapZooming: true,
              )
            : InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.asset(_reportPreviewImage, fit: BoxFit.cover),
              ),
      ),
    );
  }

  Widget _buildReportImagePreview() {
    return Padding(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Expanded(child: _buildSinglePreviewPanel(1)),
          const SizedBox(width: 8),
          Expanded(child: _buildSinglePreviewPanel(2)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        titleSpacing: 0,
        toolbarHeight: 85,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
        elevation: 0.3,
        title: Text(
          _headerTitle(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        shadowColor: Colors.black,
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: SvgPicture.asset(
            'assets/icons/backarrow.svg',
            width: 24,
            height: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 206, 201, 255),
                  borderRadius: BorderRadius.circular(18),
                ),
                height: 230,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _buildReportImagePreview(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 24),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 25),
                      child: Text(
                        'Key Vitals',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 28,
                        right: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Blood Pressure',
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          SizedBox(
                            width: 150,
                            child: Text(
                              '118/80 mmHg - Normal',
                              maxLines: 2,
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 18,
                      ),
                      child: Divider(height: 4, color: Colors.grey.shade400),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 18,
                        right: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Heart Rate',
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          SizedBox(
                            width: 150,
                            child: Text(
                              '72 bpm - Normal',
                              maxLines: 2,
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 18,
                      ),
                      child: Divider(height: 4, color: Colors.grey.shade400),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 18,
                        right: 16,
                        bottom: 25,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Heart Rate',
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          SizedBox(
                            width: 150,
                            child: Text(
                              '72 bpm - Normal',
                              maxLines: 2,
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: 30,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 19),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color.fromARGB(
                              255,
                              180,
                              212,
                              255,
                            ),
                            child: SvgPicture.asset('assets/icons/ai_chat.svg'),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'AI Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 10,
                        right: 16,
                        bottom: 18,
                      ),
                      child: Text(
                        'Your report looks healthy overall Keyvitals are within the normal range, withonly cholesterol being borderline.Continue to maintain a healthy lifestyleand diet.',
                        softWrap: true,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!widget.isDoctorView)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 30),
                child: PrimaryIconButton(
                  text: 'Ask AI for Advice',
                  iconPath: 'assets/icons/ai_chat_.svg',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AiChatScreen()),
                    );
                  },
                  height: 56,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
