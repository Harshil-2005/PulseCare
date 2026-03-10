class AISummaryModel {
  final String id;
  final String userId;
  final List<String> symptoms;
  final String? duration;
  final String? medications;
  final String? severity;
  final String? temperature;
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
    required this.recommendedSpecialty,
    required this.triageLevel,
    required this.confidence,
    required this.generatedAt,
  }) : symptoms = List.unmodifiable(symptoms);

  AISummaryModel copyWith({
    String? id,
    String? userId,
    List<String>? symptoms,
    String? duration,
    String? medications,
    String? severity,
    String? temperature,
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
        recommendedSpecialty:
            json['recommendedSpecialty'] as String,
        triageLevel: json['triageLevel'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        generatedAt: DateTime.parse(json['generatedAt']),
      );
}
