import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/model/report_model.dart';
import 'package:pulsecare/utils/time_utils.dart';

class ReportSearchDelegate extends SearchDelegate {
  final List<ReportModel> reports;

  ReportSearchDelegate(this.reports);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  // 🔹 LIVE SUGGESTIONS
  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = reports
        .where((r) =>
            r.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final report = suggestions[index];
        return ListTile(
          leading: SvgPicture.asset(report.icon, width: 28),
          title: Text(report.title),
          subtitle: Text("Uploaded ${TimeUtils.formatDate(report.uploadedAt)}"),
          onTap: () {
            query = report.title;
            showResults(context);
          },
        );
      },
    );
  }

  // 🔹 FINAL SEARCH RESULTS
  @override
  Widget buildResults(BuildContext context) {
    final results = reports
        .where((r) =>
            r.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final report = results[index];
        return ListTile(
          leading: SvgPicture.asset(report.icon, width: 28),
          title: Text(report.title),
          subtitle: Text("Uploaded ${TimeUtils.formatDate(report.uploadedAt)}"),
        );
      },
    );
  }
}
