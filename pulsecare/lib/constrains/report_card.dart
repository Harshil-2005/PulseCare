import 'package:flutter/material.dart';
import 'package:pulsecare/constrains/app_toast.dart';
import 'package:pulsecare/utils/keyboard_utils.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/utils/report_open_utils.dart';

class ReportCard extends StatelessWidget {
  final ReportModel report;
  final String title;
  final String date;
  final String icon;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final bool isDoctorView;
  final EdgeInsets? outerPadding;

  const ReportCard({
    super.key,
    required this.report,
    required this.title,
    required this.date,
    required this.icon,
    this.isDoctorView = false,
    this.outerPadding,
    this.onDelete,
    this.onDownload,
    this.onShare,
  });

  Future<void> _openReport(BuildContext context) async {
    final opened = await openReportExternally(report);
    if (opened) return;

    if (!context.mounted) return;
    showAppToast(context, 'Unable to open PDF reader on this device');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          outerPadding ??
          const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
      child: InkWell(
        onTap: () async {
          KeyboardUtils.hideKeyboardKeepFocus();
          await _openReport(context);
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                  left: 15,
                  bottom: 16,
                  right: 23,
                ),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 213, 221, 251),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SizedBox(
                    height: 20,
                    width: 14,
                    child: Center(child: SvgPicture.asset(icon)),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isDoctorView)
                Padding(
                  padding: const EdgeInsets.only(top: 16, right: 10),
                  child: InkWell(
                    onTapDown: (TapDownDetails details) {
                      final RenderBox overlay =
                          Overlay.of(context).context.findRenderObject()
                              as RenderBox;

                      const double popupWidth = 130;
                      const double rightMargin = 32;
                      const double verticalOffset = 16;

                      final double left =
                          overlay.size.width - rightMargin - popupWidth;

                      final double top =
                          details.globalPosition.dy + verticalOffset;

                      showMenu(
                        context: context,
                        position: RelativeRect.fromLTRB(
                          left,
                          top,
                          rightMargin,
                          overlay.size.height - top,
                        ),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        items: [
                          PopupMenuItem(
                            value: 'download',
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/download.svg',
                                  height: 16,
                                ),
                                const SizedBox(width: 10),
                                const Text('Download'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/share.svg',
                                  height: 16,
                                ),
                                const SizedBox(width: 10),
                                const Text('Share'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/delete.svg',
                                  height: 16,
                                ),
                                const SizedBox(width: 10),
                                const Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ).then((value) {
                        if (value == 'download') {
                          onDownload?.call();
                        } else if (value == 'share') {
                          onShare?.call();
                        } else if (value == 'delete') {
                          onDelete?.call();
                        }
                      });
                    },
                    child: SizedBox(
                      height: 28,
                      width: 30,
                      child: Column(
                        children: [
                          SvgPicture.asset('assets/icons/dot.svg'),
                          const SizedBox(height: 2),
                          SvgPicture.asset('assets/icons/dot.svg'),
                          const SizedBox(height: 2),
                          SvgPicture.asset('assets/icons/dot.svg'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
