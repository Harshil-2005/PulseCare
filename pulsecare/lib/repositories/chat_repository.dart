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

      final storedSummary = await _aiSummaryRepository.addSummaryAsync(summary);

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
      responseToReturn = completedResponse;
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

  Future<void> saveChatToHistory({
    required String userId,
    required String userMessage,
    required String aiReply,
  }) async {
    await _dataSource.saveChatHistory(userId, userMessage, aiReply);
  }

  Future<List<ChatHistoryEntry>> getHistory(String userId) async {
    final history = await _dataSource.getHistory(userId);
    return List.unmodifiable(history);
  }

  Future<void> deleteMessage(String messageId) {
    return _dataSource.deleteHistoryEntry(messageId);
  }
}
