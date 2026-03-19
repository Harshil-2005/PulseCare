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
          frequency: aiResponse.frequency,
          followUpAnswers: aiResponse.followUpAnswers,
          clinicalSummary: aiResponse.clinicalSummary,
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
          frequency: aiResponse.frequency,
          followUpAnswers: aiResponse.followUpAnswers,
          clinicalSummary: aiResponse.clinicalSummary ?? aiResponse.rawText,
          recommendedSpecialty: aiResponse.recommendedSpecialty,
          triageLevel: aiResponse.triageLevel,
          confidence: aiResponse.confidence,
          generatedAt: DateTime.now(),
        );
        AISummaryModel storedSummary;
        try {
          storedSummary = await _aiSummaryRepository.addSummaryAsync(summary);
        } catch (_) {
          // Keep the intake flow alive if remote persistence fails.
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
          frequency: aiResponse.frequency,
          followUpAnswers: aiResponse.followUpAnswers,
          clinicalSummary: aiResponse.clinicalSummary,
          summaryId: storedSummary.id,
        );

        _summaryIdByConversation[conversationId] = storedSummary.id;
        responseToReturn = completedResponse;
      }
    }

    final messages = await _dataSource.getMessages(conversationId);
    final newId = messages.length.toString();
    final isSummary = aiResponse.stage == IntakeStage.completed;
    _dataSource.addMessage(
      conversationId,
      ChatMessage(
        id: newId,
        message: aiResponse.rawText,
        isUser: false,
        sentAt: DateTime.now(),
        summarySymptoms: isSummary ? aiResponse.detectedSymptoms : null,
        summaryDuration: isSummary ? aiResponse.duration : null,
        summaryMedications: isSummary ? aiResponse.medications : null,
        summarySeverity: isSummary ? aiResponse.severity : null,
        summaryTemperature:
            isSummary && aiResponse.detectedSymptoms.contains('fever')
                ? aiResponse.temperature
                : null,
        summaryFrequency: isSummary ? aiResponse.frequency : null,
        summaryFollowUpAnswers: isSummary ? aiResponse.followUpAnswers : null,
        summaryClinicalSummary: isSummary ? aiResponse.clinicalSummary : null,
      ),
    );

    if (aiResponse.stage == IntakeStage.completed) {
      final updatedMessages = await _dataSource.getMessages(conversationId);
      final explanationId = updatedMessages.length.toString();
      _dataSource.addMessage(
        conversationId,
        ChatMessage(
          id: explanationId,
          message: _buildRecommendationExplanation(
            aiResponse.detectedSymptoms,
            aiResponse.recommendedSpecialty,
          ),
          isUser: false,
          sentAt: DateTime.now(),
        ),
      );
    }

    final updatedMessages = await _dataSource.getMessages(conversationId);
    await saveChatToHistory(
      userId: userId,
      conversationId: conversationId,
      messages: updatedMessages,
      aiResponse: responseToReturn,
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
        } catch (_) {
        }
      }),
    );
  }

  Future<void> saveChatToHistory({
    required String userId,
    required String conversationId,
    required List<ChatMessage> messages,
    required AIResponse aiResponse,
  }) async {
    final isCompleted = aiResponse.stage == IntakeStage.completed;
    final lastUser = messages
        .where((message) => message.isUser)
        .map((message) => message.message)
        .cast<String?>()
        .lastWhere((message) => message != null, orElse: () => '')!
        .trim();

    String title;
    String subtitle;
    List<String> tags;

    if (isCompleted) {
      final summaryId = aiResponse.summaryId;
      final summary = summaryId == null
          ? null
          : _aiSummaryRepository.getById(summaryId) ??
              await _aiSummaryRepository.getByIdAsync(summaryId);
      if (summary != null) {
        title = _buildFirstMessageFromSymptoms(summary.symptoms);
        subtitle = _buildHistorySummaryText(summary);
        tags = summary.symptoms.map(_formatSymptomLabel).toList();
      } else {
        title = lastUser.isEmpty ? 'AI Symptom Check' : lastUser;
        subtitle = 'Summary generated';
        tags = lastUser.isEmpty ? <String>['General'] : _extractTags(lastUser);
      }
    } else {
      title = lastUser.isEmpty ? 'AI Symptom Check' : lastUser;
      subtitle = 'In progress';
      tags = lastUser.isEmpty ? <String>['General'] : _extractTags(lastUser);
    }

    final entry = ChatHistoryEntry(
      id: conversationId,
      conversationId: conversationId,
      title: title,
      subtitle: isCompleted ? 'AI: $subtitle' : subtitle,
      tags: tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isCompleted: isCompleted,
    );

    await _dataSource.saveChatHistory(userId, entry);
  }

  String _buildFirstMessageFromSymptoms(List<String> symptoms) {
    if (symptoms.isEmpty) return 'AI Symptom Check';
    return _formatSymptomLabel(symptoms.first);
  }

  String _buildHistorySummaryText(AISummaryModel summary) {
    final symptoms = summary.symptoms.isEmpty
        ? 'Not provided'
        : summary.symptoms.map(_formatSymptomLabel).join(', ');
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
    final frequency = _shouldShowFrequency(summary.symptoms, summary.frequency)
        ? summary.frequency!.trim()
        : null;
    return 'Summary: Symptoms $symptoms. Duration $duration. '
        '${frequency == null ? '' : 'Frequency $frequency. '}'
        'Severity $severity. '
        'Medications $medications. Temperature $temperature.';
  }

  List<String> _extractTags(String text) {
    final lower = text.toLowerCase();
    final tags = <String>{};
    const tagMap = <String, String>{
      'blood pressure': 'Blood Pressure',
      'sleep': 'Sleep',
      'headache': 'Headache',
      'dizziness': 'Dizziness',
      'allergy': 'Allergy',
      'sugar': 'Blood Sugar',
      'glucose': 'Blood Sugar',
      'nutrition': 'Nutrition',
      'diet': 'Diet',
      'fever': 'Fever',
      'cough': 'Cough',
      'stress': 'Stress',
      'anxiety': 'Anxiety',
    };

    tagMap.forEach((keyword, tag) {
      if (lower.contains(keyword)) {
        tags.add(tag);
      }
    });

    if (tags.isEmpty) {
      tags.add('General');
    }
    return tags.take(3).toList();
  }

  bool _shouldShowFrequency(List<String> symptoms, String? frequency) {
    if (frequency == null || frequency.trim().isEmpty) return false;
    const frequencySymptoms = <String>{
      'headache',
      'palpitations',
      'dizziness',
      'nausea',
      'vomiting',
      'diarrhea',
      'constipation',
      'sneezing',
      'anxiety',
      'muscle_pain',
    };
    return symptoms.any(frequencySymptoms.contains);
  }

  String _formatSymptomLabel(String symptom) {
    final normalized = symptom.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return normalized;
    final words = normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) =>
            '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .toList(growable: false);
    return words.join(' ');
  }

  String _buildRecommendationExplanation(
    List<String> symptoms,
    String recommendedSpecialty,
  ) {
    final symptomsText = symptoms.isEmpty
        ? 'your reported symptoms'
        : symptoms.join(', ');
    final specialty = recommendedSpecialty.trim().isEmpty
        ? 'General Physician'
        : recommendedSpecialty;

    return 'Based on your symptoms ($symptomsText), '
        'a $specialty may be the most suitable specialist for further evaluation.';
  }

  Future<List<ChatHistoryEntry>> getHistory(String userId) async {
    final history = await _dataSource.getHistory(userId);
    return List.unmodifiable(history);
  }

  Future<void> deleteMessage(String messageId) {
    return _dataSource.deleteHistoryEntry(messageId);
  }
}
