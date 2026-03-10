import 'package:pulsecare/model/ai_summary_model.dart';

abstract class AISummaryDataSource {
  AISummaryModel addSummary(AISummaryModel summary);
  AISummaryModel? getById(String id);
  List<AISummaryModel> getByUserId(String userId);
  void remove(String id);
  List<AISummaryModel> getAll();
}

class LocalAISummaryDataSource implements AISummaryDataSource {
  final List<AISummaryModel> _storage = [];

  @override
  AISummaryModel addSummary(AISummaryModel summary) {
    final generatedSummary = summary.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _storage.removeWhere((s) => s.id == generatedSummary.id);
    _storage.add(generatedSummary);
    return generatedSummary;
  }

  @override
  AISummaryModel? getById(String id) {
    try {
      return _storage.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  List<AISummaryModel> getByUserId(String userId) {
    return _storage.where((s) => s.userId == userId).toList();
  }

  @override
  void remove(String id) {
    _storage.removeWhere((s) => s.id == id);
  }

  @override
  List<AISummaryModel> getAll() {
    return List.unmodifiable(_storage);
  }
}
