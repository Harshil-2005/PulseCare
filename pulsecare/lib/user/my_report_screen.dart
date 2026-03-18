import 'package:flutter/material.dart';
import 'package:pulsecare/utils/keyboard_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pulsecare/constrains/primary_icon_button.dart';
import 'package:pulsecare/constrains/report_card.dart';
import 'package:pulsecare/constrains/upload_report_bottom_sheet.dart';
import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/providers/session_provider.dart';
import 'package:pulsecare/user/all_reports_screen.dart';
import 'package:pulsecare/user/my_reports_empty_widget.dart';
import 'package:pulsecare/utils/time_utils.dart';
import '../providers/repository_providers.dart';

final _myReportsProvider = StreamProvider.autoDispose<List<ReportModel>>((ref) {
  final repo = ref.watch(reportRepositoryProvider);
  final userId = ref.watch(sessionUserIdProvider);
  if (userId == null) {
    return const Stream<List<ReportModel>>.empty();
  }
  return repo.watchReportsByUser(userId);
});

class MyReportScreen extends ConsumerStatefulWidget {
  const MyReportScreen({super.key});

  @override
  ConsumerState<MyReportScreen> createState() => _MyReportScreenState();
}

class _MyReportScreenState extends ConsumerState<MyReportScreen> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(_myReportsProvider);
    return PopScope(
      canPop: !_searchFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _searchFocusNode.hasFocus) {
          KeyboardUtils.hideKeyboardKeepFocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 85,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          elevation: 0.3,
          title: const Center(
            child: Text(
              'My Medical Reports',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          shadowColor: Colors.black,
          automaticallyImplyLeading: false,
        ),

        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 24,
                left: 16,
                right: 16,
                bottom: 32,
              ),
              child: PrimaryIconButton(
                text: 'Upload New Report',
                iconPath: 'assets/icons/upload_reports.svg',
                onTap: () {
                  showUploadReportBottomSheet(
                    context,
                    userId: ref.read(sessionUserIdProvider),
                    onReportAdded: () {
                      // Stream updates automatically.
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
              child: TextField(
                focusNode: _searchFocusNode,
                onTapOutside: (_) => KeyboardUtils.hideKeyboardKeepFocus(),
                onEditingComplete: _searchFocusNode.unfocus,
                controller: searchController,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade300,
                  prefixIcon: SizedBox(
                    width: 20,
                    height: 20,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/search.svg',
                        colorFilter: const ColorFilter.mode(
                          Colors.grey,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  hintText: 'Search reports by name or type',
                  hintStyle: const TextStyle(color: Colors.grey),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Reports',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllReportsScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        color: Color(0xff3F67FD),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: reportsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (reports) {
                  final query = searchController.text.trim().toLowerCase();
                  final filteredReports = query.isEmpty
                      ? reports
                      : reports
                            .where(
                              (report) =>
                                  report.title.toLowerCase().contains(query),
                            )
                            .toList(growable: false);
                  if (filteredReports.isEmpty) {
                    return const Center(child: NoReportsWidget());
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = filteredReports[index];
                      return ReportCard(
                        report: report,
                        title: report.title,
                        date:
                            "Uploaded ${TimeUtils.formatDate(report.uploadedAt)}",
                        icon: report.icon,
                        onDownload: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${report.title} downloading..."),
                            ),
                          );
                        },
                        onShare: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${report.title} sharing..."),
                            ),
                          );
                        },
                        onDelete: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete Report"),
                              content: const Text(
                                "Are you sure you want to delete this report?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(reportRepositoryProvider)
                                        .removeReport(report);
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}



