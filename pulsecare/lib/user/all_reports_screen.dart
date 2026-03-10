import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pulsecare/constrains/report_card.dart';
import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/providers/session_provider.dart';
import 'package:pulsecare/user/my_reports_empty_widget.dart';
import 'package:pulsecare/utils/time_utils.dart';
import '../providers/repository_providers.dart';

final _allReportsProvider = StreamProvider.autoDispose<List<ReportModel>>((ref) {
  final repo = ref.watch(reportRepositoryProvider);
  final userId = ref.watch(sessionUserIdProvider);

  if (userId == null) {
    return const Stream<List<ReportModel>>.empty();
  }

  return repo.watchReportsByUser(userId);
});

class AllReportsScreen extends ConsumerStatefulWidget {
  const AllReportsScreen({super.key});

  @override
  ConsumerState<AllReportsScreen> createState() => _AllReportsScreenState();
}

class _AllReportsScreenState extends ConsumerState<AllReportsScreen> {
  final alltextcontroller = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    alltextcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(_allReportsProvider);
    return PopScope(
      canPop: !_searchFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 40,
          titleSpacing: 0,
          toolbarHeight: 85,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          elevation: 0.3,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'All Reports',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ],
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
              height: 20,
            ),
          ),
        ),

        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
              child: TextField(
                focusNode: _searchFocusNode,
                onTapOutside: (_) => _searchFocusNode.unfocus(),
                onEditingComplete: _searchFocusNode.unfocus,
                controller: alltextcontroller,
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
                        colorFilter: ColorFilter.mode(
                          Colors.grey,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  hintText: 'Search reports by name or type ',
                  hintStyle: TextStyle(color: Colors.grey),
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
            const SizedBox(height: 10),
            Expanded(
              child: reportsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (reports) {
                  final query = alltextcontroller.text.trim().toLowerCase();
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
