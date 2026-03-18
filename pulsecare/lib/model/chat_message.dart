class ChatMessage {
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isUser;
  final String message;
  final DateTime sentAt;
  final List<String>? summarySymptoms;
  final String? summaryDuration;
  final String? summaryMedications;
  final String? summarySeverity;
  final String? summaryTemperature;
  final String? summaryFrequency;
  final Map<String, String>? summaryFollowUpAnswers;
  final String? summaryClinicalSummary;

  const ChatMessage({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.isUser,
    required this.message,
    required this.sentAt,
    this.summarySymptoms,
    this.summaryDuration,
    this.summaryMedications,
    this.summarySeverity,
    this.summaryTemperature,
    this.summaryFrequency,
    this.summaryFollowUpAnswers,
    this.summaryClinicalSummary,
  });

  ChatMessage copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isUser,
    String? message,
    DateTime? sentAt,
    List<String>? summarySymptoms,
    String? summaryDuration,
    String? summaryMedications,
    String? summarySeverity,
    String? summaryTemperature,
    String? summaryFrequency,
    Map<String, String>? summaryFollowUpAnswers,
    String? summaryClinicalSummary,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isUser: isUser ?? this.isUser,
      message: message ?? this.message,
      sentAt: sentAt ?? this.sentAt,
      summarySymptoms: summarySymptoms ?? this.summarySymptoms,
      summaryDuration: summaryDuration ?? this.summaryDuration,
      summaryMedications: summaryMedications ?? this.summaryMedications,
      summarySeverity: summarySeverity ?? this.summarySeverity,
      summaryTemperature: summaryTemperature ?? this.summaryTemperature,
      summaryFrequency: summaryFrequency ?? this.summaryFrequency,
      summaryFollowUpAnswers:
          summaryFollowUpAnswers ?? this.summaryFollowUpAnswers,
      summaryClinicalSummary:
          summaryClinicalSummary ?? this.summaryClinicalSummary,
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
      'summarySymptoms': summarySymptoms,
      'summaryDuration': summaryDuration,
      'summaryMedications': summaryMedications,
      'summarySeverity': summarySeverity,
      'summaryTemperature': summaryTemperature,
      'summaryFrequency': summaryFrequency,
      'summaryFollowUpAnswers': summaryFollowUpAnswers,
      'summaryClinicalSummary': summaryClinicalSummary,
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
      summarySymptoms: (json['summarySymptoms'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      summaryDuration: json['summaryDuration'] as String?,
      summaryMedications: json['summaryMedications'] as String?,
      summarySeverity: json['summarySeverity'] as String?,
      summaryTemperature: json['summaryTemperature'] as String?,
      summaryFrequency: json['summaryFrequency'] as String?,
      summaryFollowUpAnswers: (json['summaryFollowUpAnswers'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      summaryClinicalSummary: json['summaryClinicalSummary'] as String?,
    );
  }
}
