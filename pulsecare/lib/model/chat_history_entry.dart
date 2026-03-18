class ChatHistoryEntry {
  final String id;
  final String conversationId;
  final String title;
  final String subtitle;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isCompleted;

  ChatHistoryEntry({
    required this.id,
    required this.conversationId,
    required this.title,
    required this.subtitle,
    required List<String> tags,
    required this.createdAt,
    this.updatedAt,
    this.isCompleted = false,
  }) : tags = List.unmodifiable(tags);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'title': title,
      'subtitle': subtitle,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory ChatHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ChatHistoryEntry(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ??
          json['id'] as String? ??
          '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')
              ?.toLocal() ??
          DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())?.toLocal()
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
