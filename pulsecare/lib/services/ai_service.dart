import 'package:pulsecare/model/ai_response_model.dart';
import 'package:pulsecare/model/chat_message.dart';
import 'package:pulsecare/model/intake_session_model.dart';

abstract class AIService {
  Future<AIResponse> generateResponse({
    required String conversationId,
    required String userId,
    required List<ChatMessage> conversation,
  });
}

class MockAIService implements AIService {
  final Map<String, IntakeSession> _sessions = {};

  @override
  Future<AIResponse> generateResponse({
    required String conversationId,
    required String userId,
    required List<ChatMessage> conversation,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final lastUserMessage = conversation.reversed
        .where((message) => message.isUser)
        .map((message) => message.message)
        .cast<String?>()
        .firstWhere((message) => message != null, orElse: () => '')!;
    final normalizedUserText = lastUserMessage.trim();

    _sessions.putIfAbsent(
      conversationId,
      () => IntakeSession(
        conversationId: conversationId,
        stage: IntakeStage.symptoms,
        symptoms: const <String>[],
      ),
    );

    final session = _sessions[conversationId]!;

    switch (session.stage) {
      case IntakeStage.symptoms:
        final symptoms = _extractSymptoms(normalizedUserText);
        final updatedSession = session.copyWith(
          symptoms: symptoms,
          stage: IntakeStage.duration,
        );
        _sessions[conversationId] = updatedSession;
        return AIResponse(
          rawText: 'How long have you been experiencing these symptoms?',
          detectedSymptoms: symptoms,
          recommendedSpecialty: 'General Physician',
          triageLevel: 'Medium',
          confidence: 0.85,
          generatedAt: DateTime.now(),
          stage: IntakeStage.duration,
          duration: updatedSession.duration,
          medications: updatedSession.medications,
          severity: updatedSession.severity,
          temperature: updatedSession.temperature,
        );

      case IntakeStage.duration:
        final updatedSession = session.copyWith(
          duration: normalizedUserText,
          stage: IntakeStage.medications,
        );
        _sessions[conversationId] = updatedSession;
        return AIResponse(
          rawText: 'Are you currently taking any medications?',
          detectedSymptoms: updatedSession.symptoms,
          recommendedSpecialty: 'General Physician',
          triageLevel: 'Medium',
          confidence: 0.85,
          generatedAt: DateTime.now(),
          stage: IntakeStage.medications,
          duration: updatedSession.duration,
          medications: updatedSession.medications,
          severity: updatedSession.severity,
          temperature: updatedSession.temperature,
        );

      case IntakeStage.medications:
        final updatedSession = session.copyWith(
          medications: normalizedUserText,
          stage: IntakeStage.severity,
        );
        _sessions[conversationId] = updatedSession;
        return AIResponse(
          rawText: 'On a scale of 1-10, how severe are your symptoms?',
          detectedSymptoms: updatedSession.symptoms,
          recommendedSpecialty: 'General Physician',
          triageLevel: 'Medium',
          confidence: 0.85,
          generatedAt: DateTime.now(),
          stage: IntakeStage.severity,
          duration: updatedSession.duration,
          medications: updatedSession.medications,
          severity: updatedSession.severity,
          temperature: updatedSession.temperature,
        );

      case IntakeStage.severity:
        final updatedSession = session.copyWith(
          severity: normalizedUserText,
          stage: IntakeStage.temperature,
        );
        _sessions[conversationId] = updatedSession;
        return AIResponse(
          rawText: 'Do you have a fever? If yes, what is your temperature?',
          detectedSymptoms: updatedSession.symptoms,
          recommendedSpecialty: 'General Physician',
          triageLevel: 'Medium',
          confidence: 0.85,
          generatedAt: DateTime.now(),
          stage: IntakeStage.temperature,
          duration: updatedSession.duration,
          medications: updatedSession.medications,
          severity: updatedSession.severity,
          temperature: updatedSession.temperature,
        );

      case IntakeStage.temperature:
        final completedSession = session.copyWith(
          temperature: normalizedUserText,
          stage: IntakeStage.completed,
        );
        _sessions[conversationId] = completedSession;
        return _buildCompletedResponse(completedSession);

      case IntakeStage.completed:
        return _buildCompletedResponse(session);
    }
  }

  List<String> _extractSymptoms(String text) {
    final lower = text.toLowerCase();
    final symptoms = <String>[];

    if (lower.contains('fever')) symptoms.add('Fever');
    if (lower.contains('headache')) symptoms.add('Headache');
    if (lower.contains('cough')) symptoms.add('Cough');
    if (lower.contains('cold')) symptoms.add('Cold');
    if (lower.contains('fatigue')) symptoms.add('Fatigue');

    return symptoms;
  }

  AIResponse _buildCompletedResponse(IntakeSession session) {
    final severityScore = int.tryParse(
      RegExp(r'\d+').firstMatch(session.severity ?? '')?.group(0) ?? '',
    );
    final triage = (severityScore ?? 0) > 7 ? 'High' : 'Medium';

    final symptomsText = session.symptoms.isEmpty
        ? 'No specific symptoms identified'
        : session.symptoms.join(', ');

    final rawText =
        'Summary: Symptoms: $symptomsText. Duration: ${session.duration ?? 'Not provided'}. '
        'Medications: ${session.medications ?? 'Not provided'}. Severity: ${session.severity ?? 'Not provided'}. '
        'Temperature: ${session.temperature ?? 'Not provided'}.';

    return AIResponse(
      rawText: rawText,
      detectedSymptoms: session.symptoms,
      recommendedSpecialty: 'General Physician',
      triageLevel: triage,
      confidence: 0.85,
      generatedAt: DateTime.now(),
      stage: IntakeStage.completed,
      duration: session.duration,
      medications: session.medications,
      severity: session.severity,
      temperature: session.temperature,
    );
  }
}
