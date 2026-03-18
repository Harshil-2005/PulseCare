import 'dart:convert';

import 'package:pulsecare/model/chat_history_entry.dart';
import 'package:pulsecare/model/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ChatDataSource {
  Future<List<ChatMessage>> getMessages(String conversationId);
  bool hasConversation(String conversationId);
  void setMessages(String conversationId, List<ChatMessage> messages);
  void addMessage(String conversationId, ChatMessage message);
  void clearMessages(String conversationId);
  String startNewConversation(String userId);
  Future<List<ChatHistoryEntry>> getHistory(String userId);
  Future<void> saveChatHistory(
    String userId,
    ChatHistoryEntry entry,
  );
  Future<void> deleteHistoryEntry(String messageId);
}

class LocalChatDataSource implements ChatDataSource {
  LocalChatDataSource();

  static const String _storageKey = 'ai_chat_history_entries';
  final Map<String, List<ChatMessage>> _messagesByConversation = {};

  @override
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final key = conversationId.isEmpty ? '_guest' : conversationId;
    return List.unmodifiable(
      _messagesByConversation[key] ?? const <ChatMessage>[],
    );
  }

  @override
  bool hasConversation(String conversationId) {
    final key = conversationId.isEmpty ? '_guest' : conversationId;
    return (_messagesByConversation[key]?.isNotEmpty ?? false);
  }

  @override
  void setMessages(String conversationId, List<ChatMessage> messages) {
    final key = conversationId.isEmpty ? '_guest' : conversationId;
    _messagesByConversation[key] = List<ChatMessage>.from(messages);
  }

  @override
  void addMessage(String conversationId, ChatMessage message) {
    final key = conversationId.isEmpty ? '_guest' : conversationId;
    final current = _messagesByConversation[key] ?? <ChatMessage>[];
    current.add(message);
    _messagesByConversation[key] = current;
  }

  @override
  void clearMessages(String conversationId) {
    final key = conversationId.isEmpty ? '_guest' : conversationId;
    _messagesByConversation[key] = <ChatMessage>[];
  }

  static const Map<String, String> _tagKeywordMap = {
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

  @override
  String startNewConversation(String userId) {
    final conversationId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
    _messagesByConversation[conversationId] = <ChatMessage>[];
    return conversationId;
  }

  @override
  Future<List<ChatHistoryEntry>> getHistory(String userId) async {
    final items = await _loadAllHistory();
    final filtered = items.where((entry) => _belongsToUser(entry, userId));
    final result = filtered.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<void> saveChatHistory(String userId, ChatHistoryEntry entry) async {
    final now = DateTime.now();
    final historyUserId = userId.isEmpty ? '_guest' : userId;
    final items = await _loadAllHistory();
    final index = items.indexWhere(
      (existing) => existing.conversationId == entry.conversationId,
    );
    if (index >= 0) {
      final existing = items[index];
      final updated = ChatHistoryEntry(
        id: existing.id,
        conversationId: entry.conversationId,
        title: entry.title,
        subtitle: entry.subtitle,
        tags: entry.tags,
        createdAt: existing.createdAt,
        updatedAt: now,
        isCompleted: entry.isCompleted,
      );
      items
        ..removeAt(index)
        ..insert(0, updated);
    } else {
      final stored = ChatHistoryEntry(
        id: entry.conversationId.isEmpty
            ? '${historyUserId}_${now.microsecondsSinceEpoch}'
            : entry.conversationId,
        conversationId: entry.conversationId,
        title: entry.title,
        subtitle: entry.subtitle,
        tags: entry.tags,
        createdAt: entry.createdAt,
        updatedAt: now,
        isCompleted: entry.isCompleted,
      );
      items.insert(0, stored);
    }
    await _saveAllHistory(items);
  }

  @override
  Future<void> deleteHistoryEntry(String messageId) async {
    final items = await _loadAllHistory();
    items.removeWhere((entry) => entry.id == messageId);
    await _saveAllHistory(items);
  }

  Future<List<ChatHistoryEntry>> _loadAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <ChatHistoryEntry>[];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((e) => ChatHistoryEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return <ChatHistoryEntry>[];
    }
  }

  Future<void> _saveAllHistory(List<ChatHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  bool _belongsToUser(ChatHistoryEntry entry, String userId) {
    if (userId.isEmpty) return true;
    return entry.conversationId.startsWith('${userId}_');
  }

  String _buildChatTitle(String userMessage) {
    final cleaned = userMessage.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return 'AI Symptom Check';

    final words = cleaned.split(' ');
    if (words.length <= 5) {
      return cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    final short = words.take(5).join(' ');
    return '${short[0].toUpperCase()}${short.substring(1)}...';
  }

  List<String> _extractTags(String text) {
    final lower = text.toLowerCase();
    final tags = <String>{};

    _tagKeywordMap.forEach((keyword, tag) {
      if (lower.contains(keyword)) {
        tags.add(tag);
      }
    });

    if (tags.isEmpty) {
      tags.add('General');
    }
    return tags.take(3).toList();
  }
}
