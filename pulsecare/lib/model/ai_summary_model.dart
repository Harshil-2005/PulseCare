class AISummaryModel {
  final String id;
  final String userId;
  final List<String> symptoms;
  final String? duration;
  final String? medications;
  final String? severity;
  final String? temperature;
  final String? frequency;
  final Map<String, String> followUpAnswers;
  final String? clinicalSummary;
  final String recommendedSpecialty;
  final String triageLevel;
  final double confidence;
  final DateTime generatedAt;

  AISummaryModel({
    required this.id,
    required this.userId,
    required List<String> symptoms,
    this.duration,
    this.medications,
    this.severity,
    this.temperature,
    this.frequency,
    Map<String, String>? followUpAnswers,
    this.clinicalSummary,
    required this.recommendedSpecialty,
    required this.triageLevel,
    required this.confidence,
    required this.generatedAt,
  }) : symptoms = List.unmodifiable(symptoms),
       followUpAnswers = Map.unmodifiable(followUpAnswers ?? const {});

  AISummaryModel copyWith({
    String? id,
    String? userId,
    List<String>? symptoms,
    String? duration,
    String? medications,
    String? severity,
    String? temperature,
    String? frequency,
    Map<String, String>? followUpAnswers,
    String? clinicalSummary,
    String? recommendedSpecialty,
    String? triageLevel,
    double? confidence,
    DateTime? generatedAt,
  }) {
    return AISummaryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      symptoms: symptoms ?? this.symptoms,
      duration: duration ?? this.duration,
      medications: medications ?? this.medications,
      severity: severity ?? this.severity,
      temperature: temperature ?? this.temperature,
      frequency: frequency ?? this.frequency,
      followUpAnswers: followUpAnswers ?? this.followUpAnswers,
      clinicalSummary: clinicalSummary ?? this.clinicalSummary,
      recommendedSpecialty:
          recommendedSpecialty ?? this.recommendedSpecialty,
      triageLevel: triageLevel ?? this.triageLevel,
      confidence: confidence ?? this.confidence,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'symptoms': symptoms,
        'duration': duration,
        'medications': medications,
        'severity': severity,
        'temperature': temperature,
        'frequency': frequency,
        'followUpAnswers': followUpAnswers,
        'clinicalSummary': clinicalSummary,
        'recommendedSpecialty': recommendedSpecialty,
        'triageLevel': triageLevel,
        'confidence': confidence,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory AISummaryModel.fromJson(Map<String, dynamic> json) =>
      AISummaryModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        symptoms: List<String>.from(json['symptoms']),
        duration: json['duration'] as String?,
        medications: json['medications'] as String?,
        severity: json['severity'] as String?,
        temperature: json['temperature'] as String?,
        frequency: json['frequency'] as String?,
        followUpAnswers: (json['followUpAnswers'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ) ??
            const {},
        clinicalSummary: json['clinicalSummary'] as String?,
        recommendedSpecialty:
            json['recommendedSpecialty'] as String,
        triageLevel: json['triageLevel'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        generatedAt: DateTime.parse(json['generatedAt']),
      );
}
