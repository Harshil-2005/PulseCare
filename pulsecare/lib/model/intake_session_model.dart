enum IntakeStage {
  symptoms,
  duration,
  medications,
  frequency,
  severity,
  temperature,
  completed,
}

class IntakeSession {
  final String conversationId;
  final IntakeStage stage;

  final List<String> symptoms;
  final String? duration;
  final String? medications;
  final String? severity;
  final String? temperature;
  final String? frequency;
  final Map<String, String> followUpAnswers;

  IntakeSession({
    required this.conversationId,
    required this.stage,
    required this.symptoms,
    this.duration,
    this.medications,
    this.severity,
    this.temperature,
    this.frequency,
    Map<String, String>? followUpAnswers,
  }) : followUpAnswers = Map.unmodifiable(followUpAnswers ?? {});

  IntakeSession copyWith({
    IntakeStage? stage,
    List<String>? symptoms,
    String? duration,
    String? medications,
    String? severity,
    String? temperature,
    String? frequency,
    Map<String, String>? followUpAnswers,
  }) {
    return IntakeSession(
      conversationId: conversationId,
      stage: stage ?? this.stage,
      symptoms: symptoms ?? this.symptoms,
      duration: duration ?? this.duration,
      medications: medications ?? this.medications,
      severity: severity ?? this.severity,
      temperature: temperature ?? this.temperature,
      frequency: frequency ?? this.frequency,
      followUpAnswers: followUpAnswers ?? this.followUpAnswers,
    );
  }
}
