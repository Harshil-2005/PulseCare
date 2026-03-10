class ChatMessage {
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isUser;
  final String message;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.isUser,
    required this.message,
    required this.sentAt,
  });

  ChatMessage copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isUser,
    String? message,
    DateTime? sentAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isUser: isUser ?? this.isUser,
      message: message ?? this.message,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isUser': isUser,
      'message': message,
      'sentAt': sentAt.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      isUser: json['isUser'] as bool,
      message: json['message'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}
