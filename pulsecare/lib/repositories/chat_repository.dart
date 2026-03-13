import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pulsecare/data/datasources/chat_datasource.dart';
import 'package:pulsecare/model/ai_response_model.dart';
import 'package:pulsecare/model/ai_summary_model.dart';
import 'package:pulsecare/model/chat_history_entry.dart';
import 'package:pulsecare/model/chat_message.dart';
import 'package:pulsecare/model/intake_session_model.dart';
import 'package:pulsecare/repositories/ai_summary_repository.dart';
import 'package:pulsecare/services/ai_service.dart';

class ChatRepository extends ChangeNotifier {
  ChatRepository({
    ChatDataSource? dataSource,
    required AISummaryRepository aiSummaryRepository,
    required AIService aiService,
  }) : _dataSource = dataSource ?? LocalChatDataSource(),
       _aiSummaryRepository = aiSummaryRepository,
       _aiService = aiService;

  final ChatDataSource _dataSource;
  final AISummaryRepository _aiSummaryRepository;
  final AIService _aiService;
  final Set<String> _savedConsultationHistory = <String>{};
  final Map<String, String> _summaryIdByConversation = <String, String>{};

  String startNewConversation(String userId) {
    return _dataSource.startNewConversation(userId);
  }

  String ensureConversationStarted(String userId) {
    final conversationId = startNewConversation(userId);
    if (_dataSource.hasConversation(conversationId)) return conversationId;
    _dataSource.setMessages(conversationId, <ChatMessage>[
      ChatMessage(
        id: '0',
        isUser: false,
        message: 'Hello! I\'m Dr. Elara.\nHow can I help you today?',
        sentAt: DateTime.now(),
      ),
    ]);
    return conversationId;
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    return List.unmodifiable(await _dataSource.getMessages(conversationId));
  }

  Future<ChatMessage> addUserMessage(String conversationId, String text) async {
    final messages = await _dataSource.getMessages(conversationId);
    final newId = messages.length.toString();
    final message = ChatMessage(
      id: newId,
      isUser: true,
      message: text,
      sentAt: DateTime.now(),
    );
    _dataSource.addMessage(conversationId, message);
    notifyListeners();
    return message;
  }

  Future<ChatMessage> addAiMessage(String conversationId, String text) async {
    final messages = await _dataSource.getMessages(conversationId);
    final newId = messages.length.toString();
    final message = ChatMessage(
      id: newId,
      isUser: false,
      message: text,
      sentAt: DateTime.now(),
    );
    _dataSource.addMessage(conversationId, message);
    notifyListeners();
    return message;
  }

  Future<AIResponse> generateAndStoreAiResponse(
    String conversationId,
    String userId,
  ) async {
    final aiResponse = await _aiService.generateResponse(
      conversationId: conversationId,
      userId: userId,
      conversation: await _dataSource.getMessages(conversationId),
    );
    var responseToReturn = aiResponse;

    if (aiResponse.stage == IntakeStage.completed) {
      final existingSummaryId = _summaryIdByConversation[conversationId];
      if (existingSummaryId != null && existingSummaryId.isNotEmpty) {
        responseToReturn = AIResponse(
          rawText: aiResponse.rawText,
          detectedSymptoms: aiResponse.detectedSymptoms,
          recommendedSpecialty: aiResponse.recommendedSpecialty,
          triageLevel: aiResponse.triageLevel,
          confidence: aiResponse.confidence,
          generatedAt: aiResponse.generatedAt,
          stage: aiResponse.stage,
          duration: aiResponse.duration,
          medications: aiResponse.medications,
          severity: aiResponse.severity,
          temperature: aiResponse.temperature,
          summaryId: existingSummaryId,
        );
      } else {
      final summary = AISummaryModel(
        id: '',
        userId: userId,
        symptoms: aiResponse.detectedSymptoms,
        duration: aiResponse.duration,
        medications: aiResponse.medications,
        severity: aiResponse.severity,
        temperature: aiResponse.temperature,
        recommendedSpecialty: aiResponse.recommendedSpecialty,
        triageLevel: aiResponse.triageLevel,
        confidence: aiResponse.confidence,
        generatedAt: DateTime.now(),
      );
      AISummaryModel storedSummary;
      try {
        storedSummary = await _aiSummaryRepository.addSummaryAsync(summary);
      } catch (error, stackTrace) {
        // Keep the intake flow alive if remote persistence fails.
        debugPrint('AISummary remote save failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        storedSummary = _aiSummaryRepository.addSummary(summary);
        _scheduleSummaryRetry(storedSummary);
      }

      final completedResponse = AIResponse(
        rawText: aiResponse.rawText,
        detectedSymptoms: aiResponse.detectedSymptoms,
        recommendedSpecialty: aiResponse.recommendedSpecialty,
        triageLevel: aiResponse.triageLevel,
        confidence: aiResponse.confidence,
        generatedAt: aiResponse.generatedAt,
        stage: aiResponse.stage,
        duration: aiResponse.duration,
        medications: aiResponse.medications,
        severity: aiResponse.severity,
        temperature: aiResponse.temperature,
        summaryId: storedSummary.id,
      );

      _summaryIdByConversation[conversationId] = storedSummary.id;
      await saveChatToHistory(
        userId: userId,
        conversationId: conversationId,
        summaryId: storedSummary.id,
        intakeStage: aiResponse.stage,
      );
      responseToReturn = completedResponse;
      }
    }

    final messages = await _dataSource.getMessages(conversationId);
    final newId = messages.length.toString();
    _dataSource.addMessage(
      conversationId,
      ChatMessage(
        id: newId,
        message: aiResponse.rawText,
        isUser: false,
        sentAt: DateTime.now(),
      ),
    );
    notifyListeners();

    return responseToReturn;
  }

  void _scheduleSummaryRetry(AISummaryModel summary) {
    unawaited(
      Future<void>(() async {
        // Give the network/auth layer a moment before retrying remote sync.
        await Future<void>.delayed(const Duration(seconds: 2));
        try {
          await _aiSummaryRepository.addSummaryAsync(summary);
          debugPrint('AISummary retry sync succeeded for id=${summary.id}');
        } catch (error, stackTrace) {
          debugPrint(
            'AISummary retry sync failed for id=${summary.id}: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
        }
      }),
    );
  }

  Future<void> saveChatToHistory({
    required String userId,
    required String conversationId,
    required String summaryId,
    required IntakeStage intakeStage,
  }) async {
    if (intakeStage != IntakeStage.completed) {
      return;
    }

    if (_savedConsultationHistory.contains(conversationId)) {
      return;
    }

    final summary =
        _aiSummaryRepository.getById(summaryId) ??
        await _aiSummaryRepository.getByIdAsync(summaryId);
    if (summary == null) {
      return;
    }

    final message = _buildFirstMessageFromSymptoms(summary.symptoms);
    final summaryText = _buildHistorySummaryText(summary);

    final existing = await _dataSource.getHistory(userId);
    final alreadySaved = existing.any(
      (entry) =>
          entry.title.trim().toLowerCase() == message.toLowerCase() &&
          entry.subtitle.trim().toLowerCase() ==
              'ai: ${summaryText.toLowerCase()}',
    );
    if (alreadySaved) {
      _savedConsultationHistory.add(conversationId);
      return;
    }

    await _dataSource.saveChatHistory(userId, message, summaryText);
    _savedConsultationHistory.add(conversationId);
  }

  String _buildFirstMessageFromSymptoms(List<String> symptoms) {
    if (symptoms.isEmpty) return 'AI Symptom Check';
    return symptoms.first;
  }

  String _buildHistorySummaryText(AISummaryModel summary) {
    final symptoms =
        summary.symptoms.isEmpty ? 'Not provided' : summary.symptoms.join(', ');
    final duration = summary.duration?.trim().isNotEmpty == true
        ? summary.duration!.trim()
        : 'Not provided';
    final severity = summary.severity?.trim().isNotEmpty == true
        ? summary.severity!.trim()
        : 'Not provided';
    final medications = summary.medications?.trim().isNotEmpty == true
        ? summary.medications!.trim()
        : 'Not provided';
    final temperature = summary.temperature?.trim().isNotEmpty == true
        ? summary.temperature!.trim()
        : 'Not provided';
    return 'Summary: Symptoms $symptoms. Duration $duration. Severity $severity. '
        'Medications $medications. Temperature $temperature.';
  }

  Future<List<ChatHistoryEntry>> getHistory(String userId) async {
    final history = await _dataSource.getHistory(userId);
    return List.unmodifiable(history);
  }

  Future<void> deleteMessage(String messageId) {
    return _dataSource.deleteHistoryEntry(messageId);
  }
}
