import 'package:pulsecare/model/ai_summary_model.dart';
import 'package:pulsecare/repositories/ai_summary_repository.dart';

class AIController {
  AIController(this._aiSummaryRepository);

  final AISummaryRepository _aiSummaryRepository;

  Future<AISummaryModel> addSummary(AISummaryModel summary) {
    return _aiSummaryRepository.addSummaryAsync(summary);
  }

  Future<AISummaryModel?> getSummaryById(String id) {
    return _aiSummaryRepository.getByIdAsync(id);
  }

  Future<List<AISummaryModel>> getSummariesByUser(String userId) {
    return _aiSummaryRepository.getByUserIdAsync(userId);
  }
}
