import 'package:pulsecare/model/intake_session_model.dart';

class AIResponse {
  final String rawText;
  final List<String> detectedSymptoms;
  final String recommendedSpecialty;
  final String triageLevel;
  final double confidence;
  final DateTime generatedAt;
  final IntakeStage stage;
  final String? duration;
  final String? medications;
  final String? severity;
  final String? temperature;
  final String? summaryId;

  AIResponse({
    required this.rawText,
    required List<String> detectedSymptoms,
    required this.recommendedSpecialty,
    required this.triageLevel,
    required this.confidence,
    required this.generatedAt,
    required this.stage,
    this.duration,
    this.medications,
    this.severity,
    this.temperature,
    this.summaryId,
  }) : detectedSymptoms = List.unmodifiable(detectedSymptoms);

  AIResponse copyWith({
    String? rawText,
    List<String>? detectedSymptoms,
    String? recommendedSpecialty,
    String? triageLevel,
    double? confidence,
    DateTime? generatedAt,
    IntakeStage? stage,
    String? duration,
    String? medications,
    String? severity,
    String? temperature,
  }) {
    return AIResponse(
      rawText: rawText ?? this.rawText,
      detectedSymptoms: detectedSymptoms ?? this.detectedSymptoms,
      recommendedSpecialty:
          recommendedSpecialty ?? this.recommendedSpecialty,
      triageLevel: triageLevel ?? this.triageLevel,
      confidence: confidence ?? this.confidence,
      generatedAt: generatedAt ?? this.generatedAt,
      stage: stage ?? this.stage,
      duration: duration ?? this.duration,
      medications: medications ?? this.medications,
      severity: severity ?? this.severity,
      temperature: temperature ?? this.temperature,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rawText': rawText,
      'detectedSymptoms': detectedSymptoms,
      'recommendedSpecialty': recommendedSpecialty,
      'triageLevel': triageLevel,
      'confidence': confidence,
      'generatedAt': generatedAt.toIso8601String(),
      'stage': stage.name,
      'duration': duration,
      'medications': medications,
      'severity': severity,
      'temperature': temperature,
      'summaryId': summaryId,
    };
  }

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      rawText: json['rawText'] as String,
      detectedSymptoms: (json['detectedSymptoms'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      recommendedSpecialty: json['recommendedSpecialty'] as String,
      triageLevel: json['triageLevel'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      stage: IntakeStage.values.firstWhere(
        (value) => value.name == (json['stage'] as String? ?? ''),
        orElse: () => IntakeStage.symptoms,
      ),
      duration: json['duration'] as String?,
      medications: json['medications'] as String?,
      severity: json['severity'] as String?,
      temperature: json['temperature'] as String?,
      summaryId: json['summaryId'] as String?,
    );
  }
}
