class ChatHistoryEntry {
  final String id;
  final String title;
  final String subtitle;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChatHistoryEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required List<String> tags,
    required this.createdAt,
    this.updatedAt,
  }) : tags = List.unmodifiable(tags);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ChatHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ChatHistoryEntry(
      id: json['id'] as String? ?? '',
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
    );
  }
}
