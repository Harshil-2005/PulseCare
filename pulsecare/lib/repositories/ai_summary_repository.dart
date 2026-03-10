import 'package:flutter/foundation.dart';
import 'package:pulsecare/model/ai_summary_model.dart';
import 'package:pulsecare/data/datasources/ai_summary_datasource.dart';

class AISummaryRepository extends ChangeNotifier {
  final AISummaryDataSource _dataSource;

  AISummaryRepository._privateConstructor(this._dataSource);

  static AISummaryRepository? _instance;

  factory AISummaryRepository([AISummaryDataSource? dataSource]) {
    _instance ??= AISummaryRepository._privateConstructor(
      dataSource ?? LocalAISummaryDataSource(),
    );
    return _instance!;
  }

  AISummaryModel addSummary(AISummaryModel summary) {
    final storedSummary = _dataSource.addSummary(summary);
    notifyListeners();
    return storedSummary;
  }

  AISummaryModel? getById(String id) {
    return _dataSource.getById(id);
  }

  List<AISummaryModel> getByUserId(String userId) {
    return _dataSource.getByUserId(userId);
  }

  void remove(String id) {
    _dataSource.remove(id);
    notifyListeners();
  }

  List<AISummaryModel> getAll() {
    return _dataSource.getAll();
  }
}
