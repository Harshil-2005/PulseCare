import 'package:pulsecare/data/datasources/chat_datasource.dart';
import 'package:pulsecare/model/chat_history_entry.dart';
import 'package:pulsecare/model/chat_message.dart';

class ApiChatDataSource implements ChatDataSource {
  @override
  void addMessage(String conversationId, ChatMessage message) {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  void clearMessages(String conversationId) {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<void> deleteHistoryEntry(String messageId) {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<List<ChatHistoryEntry>> getHistory(String userId) {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  bool hasConversation(String conversationId) {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<void> saveChatHistory(String userId, String userMessage, String aiReply) {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  void setMessages(String conversationId, List<ChatMessage> messages) {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  String startNewConversation(String userId) {
    throw UnimplementedError('API not implemented yet');
  }
}
