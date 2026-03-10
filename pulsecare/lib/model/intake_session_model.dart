enum IntakeStage {
  symptoms,
  duration,
  medications,
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

  const IntakeSession({
    required this.conversationId,
    required this.stage,
    required this.symptoms,
    this.duration,
    this.medications,
    this.severity,
    this.temperature,
  });

  IntakeSession copyWith({
    IntakeStage? stage,
    List<String>? symptoms,
    String? duration,
    String? medications,
    String? severity,
    String? temperature,
  }) {
    return IntakeSession(
      conversationId: conversationId,
      stage: stage ?? this.stage,
      symptoms: symptoms ?? this.symptoms,
      duration: duration ?? this.duration,
      medications: medications ?? this.medications,
      severity: severity ?? this.severity,
      temperature: temperature ?? this.temperature,
    );
  }
}
