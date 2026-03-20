import 'package:pulsecare/model/ai_response_model.dart';
import 'package:pulsecare/model/chat_message.dart';
import 'package:pulsecare/model/intake_session_model.dart';
import 'package:pulsecare/repositories/user_repository.dart';
import '../data/triage/triage_data.dart';

abstract class AIService {
  Future<AIResponse> generateResponse({
    required String conversationId,
    required String userId,
    required List<ChatMessage> conversation,
  });
}

class ProductionAIService implements AIService {
  @override
  Future<AIResponse> generateResponse({
    required String conversationId,
    required String userId,
    required List<ChatMessage> conversation,
  }) async {
    return AIResponse(
      rawText:
          'AI assistant is currently unavailable. Please try again shortly.',
      detectedSymptoms: const <String>[],
      recommendedSpecialty: 'General Physician',
      triageLevel: 'Low',
      confidence: 0.0,
      generatedAt: DateTime.now(),
      stage: IntakeStage.completed,
      followUpAnswers: const <String, String>{},
    );
  }
}

class MockAIService implements AIService {
  final Map<String, IntakeSession> _sessions = {};
  final Map<String, List<FollowUpQuestion>> _pendingFollowUps = {};
  final Map<String, String> _lastFollowUpKey = {};
  final Map<String, String> _patientNames = {};
  final Map<String, Map<String, int>> _detectedCategoryCounts = {};
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
    final rawUserText = lastUserMessage.trim();
    final lastAiMessage = conversation.reversed
        .where((message) => !message.isUser)
        .map((message) => message.message)
        .cast<String?>()
        .firstWhere((message) => message != null, orElse: () => '')!;
    final lastAiText = lastAiMessage.trim().toLowerCase();

    if (!_patientNames.containsKey(conversationId)) {
      final user = await UserRepository().getUserById(userId);
      final firstName = user?.firstName.trim() ?? '';
      _patientNames[conversationId] = firstName.isNotEmpty
          ? 'Mr. $firstName'
          : 'Patient';
    }

    _sessions.putIfAbsent(
      conversationId,
      () => IntakeSession(
        conversationId: conversationId,
        stage: IntakeStage.symptoms,
        symptoms: const <String>[],
        followUpAnswers: const {},
      ),
    );

    var session = _sessions[conversationId]!;
    final lastFollowUpKey = _lastFollowUpKey.remove(conversationId);
    if (lastFollowUpKey != null && rawUserText.isNotEmpty) {
      if (!_isTemperatureFollowUpKey(lastFollowUpKey)) {
        final updatedAnswers = Map<String, String>.from(
          session.followUpAnswers,
        );
        final followUp = _followUpById(lastFollowUpKey);
        if (followUp != null && followUp.options.isNotEmpty) {
          final parsed = _parseMergedFollowUpAnswers(followUp, rawUserText);
          if (parsed.isEmpty) {
            updatedAnswers[lastFollowUpKey] = rawUserText;
          } else {
            updatedAnswers.addAll(parsed);
          }
        } else {
          updatedAnswers[lastFollowUpKey] = rawUserText;
        }
        session = session.copyWith(followUpAnswers: updatedAnswers);
        _sessions[conversationId] = session;
      }
    }
    var parsedDuration = _extractDuration(rawUserText);
    final parsedTemperature = _extractTemperature(rawUserText);
    var parsedSeverity = _extractSeverity(rawUserText);
    var parsedMedication = _extractMedication(rawUserText);
    var parsedFrequency = _extractFrequency(rawUserText);
    if (parsedDuration == null &&
        (lastAiText.contains('how long') ||
            lastAiText.contains('how many days'))) {
      parsedDuration = rawUserText.isEmpty ? null : rawUserText;
    }
    if (parsedFrequency == null && lastAiText.contains('times per day')) {
      parsedFrequency = rawUserText.isEmpty ? null : rawUserText;
    }
    if (parsedMedication == null &&
        (lastAiText.contains('medication') ||
            lastAiText.contains('medicine') ||
            lastAiText.contains('medications'))) {
      parsedMedication = rawUserText.isEmpty ? null : rawUserText;
    }
    if (parsedSeverity == null &&
        (lastAiText.contains('severe') ||
            lastAiText.contains('scale') ||
            lastAiText.contains('1-10') ||
            lastAiText.contains('1-10') ||
            lastAiText.contains('pain level'))) {
      final match = RegExp(r'\b(10|[1-9])\b').firstMatch(rawUserText);
      if (match != null) {
        parsedSeverity = match.group(1);
      } else if (rawUserText.isNotEmpty) {
        parsedSeverity = rawUserText;
      }
    }
    session = session.copyWith(
      duration: parsedDuration ?? session.duration,
      temperature: parsedTemperature ?? session.temperature,
      severity: parsedSeverity ?? session.severity,
      medications: parsedMedication ?? session.medications,
      frequency: parsedFrequency ?? session.frequency,
    );
    _sessions[conversationId] = session;

    switch (session.stage) {
      case IntakeStage.symptoms:
        final existingFollowUps =
            _pendingFollowUps[conversationId] ?? const <FollowUpQuestion>[];

        if (existingFollowUps.isNotEmpty) {
          final nextFollowUp = existingFollowUps.removeAt(0);
          _lastFollowUpKey[conversationId] = nextFollowUp.id;
          _pendingFollowUps[conversationId] = existingFollowUps;
          return AIResponse(
            rawText: nextFollowUp.question,
            detectedSymptoms: session.symptoms,
            recommendedSpecialty: _recommendedSpecialtyForSymptoms(
              session.symptoms,
            ),
            triageLevel: 'Medium',
            confidence: _recommendationConfidence(
              conversationId,
              session.symptoms,
            ),
            generatedAt: DateTime.now(),
            stage: IntakeStage.symptoms,
            duration: session.duration,
            medications: session.medications,
            severity: session.severity,
            temperature: session.temperature,
            frequency: session.frequency,
            followUpAnswers: session.followUpAnswers,
          );
        }

        if (session.symptoms.isEmpty) {
          final symptoms = _extractSymptoms(rawUserText);
          _detectedCategoryCounts[conversationId] = _buildCategoryCounts(
            symptoms,
          );
          final followUps = _buildFollowUps(symptoms);
          final orderedFollowUps = _sortFollowUps(List.of(followUps));
          final updatedSession = session.copyWith(symptoms: symptoms);
          _sessions[conversationId] = updatedSession;
          _pendingFollowUps[conversationId] = orderedFollowUps;

          if (orderedFollowUps.isNotEmpty) {
            final nextFollowUp = orderedFollowUps.removeAt(0);
            _lastFollowUpKey[conversationId] = nextFollowUp.id;
            final message = nextFollowUp.question;
            return AIResponse(
              rawText: message,
              detectedSymptoms: symptoms,
              recommendedSpecialty: _recommendedSpecialtyForSymptoms(symptoms),
              triageLevel: 'Medium',
              confidence: _recommendationConfidence(conversationId, symptoms),
              generatedAt: DateTime.now(),
              stage: IntakeStage.symptoms,
              duration: updatedSession.duration,
              medications: updatedSession.medications,
              severity: updatedSession.severity,
              temperature: updatedSession.temperature,
              frequency: updatedSession.frequency,
              followUpAnswers: updatedSession.followUpAnswers,
            );
          }
        }

        final nextQuestion = _nextMissingQuestion(session);
        if (nextQuestion == null) {
          final completedSession = session.copyWith(
            stage: IntakeStage.completed,
          );
          _sessions[conversationId] = completedSession;
          return _buildCompletedResponse(completedSession);
        }
        final nextStage = _stageForQuestion(nextQuestion);
        final progressedSession = session.copyWith(stage: nextStage);
        _sessions[conversationId] = progressedSession;
        return _buildQuestionResponse(
          session: progressedSession,
          conversationId: conversationId,
          question: nextQuestion,
          stage: nextStage,
        );

      case IntakeStage.duration:
        var updatedSession = session;
        if (updatedSession.duration == null ||
            updatedSession.duration!.trim().isEmpty) {
          updatedSession = updatedSession.copyWith(duration: rawUserText);
        }
        _sessions[conversationId] = updatedSession;
        final nextQuestion = _nextMissingQuestion(updatedSession);
        if (nextQuestion == null) {
          final completedSession = updatedSession.copyWith(
            stage: IntakeStage.completed,
          );
          _sessions[conversationId] = completedSession;
          return _buildCompletedResponse(completedSession);
        }
        final nextStage = _stageForQuestion(nextQuestion);
        final progressedSession = updatedSession.copyWith(stage: nextStage);
        _sessions[conversationId] = progressedSession;
        return _buildQuestionResponse(
          session: progressedSession,
          conversationId: conversationId,
          question: nextQuestion,
          stage: nextStage,
        );

      case IntakeStage.medications:
        var updatedSession = session;
        if (updatedSession.medications == null ||
            updatedSession.medications!.trim().isEmpty) {
          updatedSession = updatedSession.copyWith(medications: rawUserText);
        }
        _sessions[conversationId] = updatedSession;
        final nextQuestion = _nextMissingQuestion(updatedSession);
        if (nextQuestion == null) {
          final completedSession = updatedSession.copyWith(
            stage: IntakeStage.completed,
          );
          _sessions[conversationId] = completedSession;
          return _buildCompletedResponse(completedSession);
        }
        final nextStage = _stageForQuestion(nextQuestion);
        final progressedSession = updatedSession.copyWith(stage: nextStage);
        _sessions[conversationId] = progressedSession;
        return _buildQuestionResponse(
          session: progressedSession,
          conversationId: conversationId,
          question: nextQuestion,
          stage: nextStage,
        );

      case IntakeStage.frequency:
        var updatedSession = session;
        if (updatedSession.frequency == null ||
            updatedSession.frequency!.trim().isEmpty) {
          updatedSession = updatedSession.copyWith(frequency: rawUserText);
        }
        _sessions[conversationId] = updatedSession;
        final nextQuestion = _nextMissingQuestion(updatedSession);
        if (nextQuestion == null) {
          final completedSession = updatedSession.copyWith(
            stage: IntakeStage.completed,
          );
          _sessions[conversationId] = completedSession;
          return _buildCompletedResponse(completedSession);
        }
        final nextStage = _stageForQuestion(nextQuestion);
        final progressedSession = updatedSession.copyWith(stage: nextStage);
        _sessions[conversationId] = progressedSession;
        return _buildQuestionResponse(
          session: progressedSession,
          conversationId: conversationId,
          question: nextQuestion,
          stage: nextStage,
        );

      case IntakeStage.severity:
        var updatedSession = session;
        if (updatedSession.severity == null ||
            updatedSession.severity!.trim().isEmpty) {
          updatedSession = updatedSession.copyWith(severity: rawUserText);
        }
        _sessions[conversationId] = updatedSession;
        final nextQuestion = _nextMissingQuestion(updatedSession);
        if (nextQuestion == null) {
          var completedSession = updatedSession.copyWith(
            stage: IntakeStage.completed,
          );
          if (!completedSession.symptoms.contains('fever') &&
              (completedSession.temperature == null ||
                  completedSession.temperature!.trim().isEmpty)) {
            completedSession = completedSession.copyWith(
              temperature: 'Not reported',
            );
          }
          _sessions[conversationId] = completedSession;
          return _buildCompletedResponse(completedSession);
        }
        final nextStage = _stageForQuestion(nextQuestion);
        final progressedSession = updatedSession.copyWith(stage: nextStage);
        _sessions[conversationId] = progressedSession;
        return _buildQuestionResponse(
          session: progressedSession,
          conversationId: conversationId,
          question: nextQuestion,
          stage: nextStage,
        );

      case IntakeStage.temperature:
        if (session.temperature != null &&
            session.temperature!.trim().isNotEmpty) {
          final completedSession = session.copyWith(
            stage: IntakeStage.completed,
          );
          _sessions[conversationId] = completedSession;
          final nextQuestion = _nextMissingQuestion(completedSession);
          if (nextQuestion != null) {
            final nextStage = _stageForQuestion(nextQuestion);
            final progressedSession = completedSession.copyWith(
              stage: nextStage,
            );
            _sessions[conversationId] = progressedSession;
            return _buildQuestionResponse(
              session: progressedSession,
              conversationId: conversationId,
              question: nextQuestion,
              stage: nextStage,
            );
          }
          return _buildCompletedResponse(completedSession);
        }
        final completedSession = session.copyWith(
          temperature: rawUserText,
          stage: IntakeStage.completed,
        );
        _sessions[conversationId] = completedSession;
        final nextQuestion = _nextMissingQuestion(completedSession);
        if (nextQuestion != null) {
          final nextStage = _stageForQuestion(nextQuestion);
          final progressedSession = completedSession.copyWith(stage: nextStage);
          _sessions[conversationId] = progressedSession;
          return _buildQuestionResponse(
            session: progressedSession,
            conversationId: conversationId,
            question: nextQuestion,
            stage: nextStage,
          );
        }
        return _buildCompletedResponse(completedSession);

      case IntakeStage.completed:
        final nextQuestion = _nextMissingQuestion(session);
        if (nextQuestion != null) {
          final nextStage = _stageForQuestion(nextQuestion);
          final progressedSession = session.copyWith(stage: nextStage);
          _sessions[conversationId] = progressedSession;
          return _buildQuestionResponse(
            session: progressedSession,
            conversationId: conversationId,
            question: nextQuestion,
            stage: nextStage,
          );
        }
        return _buildCompletedResponse(session);
    }
  }

  String normalizeInput(String text) {
    final lower = text.toLowerCase();
    final withoutPunctuation = lower.replaceAll(RegExp(r'[^\w\s]'), ' ');
    return withoutPunctuation.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _naturalQuestion(String question) {
    return question;
  }

  bool _isTemperatureFollowUpKey(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('temperature') || normalized.contains('temp');
  }

  FollowUpQuestion? _followUpById(String id) {
    for (final symptom in triageSymptoms) {
      for (final followUp in symptom.followUps) {
        if (followUp.id == id) {
          return followUp;
        }
      }
    }
    return null;
  }

  Map<String, String> _parseMergedFollowUpAnswers(
    FollowUpQuestion followUp,
    String rawUserText,
  ) {
    final normalized = rawUserText.toLowerCase();
    if (normalized.trim().isEmpty) return {};

    final hasNegation = RegExp(
      r'\b(no|none|nope|not|neither)\b',
    ).hasMatch(normalized);
    final matchesAnyKeyword = followUp.options.any(
      (option) => option.keywords.any(
        (keyword) => normalized.contains(keyword.toLowerCase()),
      ),
    );

    if (!matchesAnyKeyword && hasNegation) {
      return {for (final option in followUp.options) option.id: 'No'};
    }

    final answers = <String, String>{};
    for (final option in followUp.options) {
      final keywordMatch = option.keywords.firstWhere(
        (keyword) => normalized.contains(keyword.toLowerCase()),
        orElse: () => '',
      );
      if (keywordMatch.isEmpty) continue;

      final escaped = RegExp.escape(keywordMatch.toLowerCase());
      final negated = RegExp(r'\b(no|not)\s+' + escaped).hasMatch(normalized);
      answers[option.id] = negated ? 'No' : 'Yes';
    }

    return answers;
  }

  IntakeStage _stageForQuestion(String question) {
    final normalized = question.toLowerCase();
    if (normalized.contains('how long')) {
      return IntakeStage.duration;
    }
    if (normalized.contains('medication') ||
        normalized.contains('medicine') ||
        normalized.contains('medications')) {
      return IntakeStage.medications;
    }
    if (normalized.contains('times per day')) {
      return IntakeStage.frequency;
    }
    if (normalized.contains('scale') ||
        normalized.contains('severe') ||
        normalized.contains('severity')) {
      return IntakeStage.severity;
    }
    return IntakeStage.temperature;
  }

  AIResponse _buildQuestionResponse({
    required IntakeSession session,
    required String conversationId,
    required String question,
    required IntakeStage stage,
  }) {
    return AIResponse(
      rawText: _naturalQuestion(question),
      detectedSymptoms: session.symptoms,
      recommendedSpecialty: _recommendedSpecialtyForSymptoms(session.symptoms),
      triageLevel: 'Medium',
      confidence: _recommendationConfidence(conversationId, session.symptoms),
      generatedAt: DateTime.now(),
      stage: stage,
      duration: session.duration,
      medications: session.medications,
      severity: session.severity,
      temperature: session.temperature,
      frequency: session.frequency,
      followUpAnswers: session.followUpAnswers,
    );
  }

  List<FollowUpQuestion> _sortFollowUps(List<FollowUpQuestion> list) {
    int priority(FollowUpQuestion f) {
      final q = f.question.toLowerCase();

      // Priority 1: Primary identification (location/type)
      if (q.contains('where') ||
          q.contains('which') ||
          q.contains('location')) {
        return 1;
      }

      // Priority 2: Pattern / behavior
      if (q.contains('constant') ||
          q.contains('comes and goes') ||
          q.contains('spread') ||
          q.contains('when')) {
        return 2;
      }

      // Priority 3: Associated symptoms
      if (q.contains('do you have') ||
          q.contains('also have') ||
          q.contains('along with')) {
        return 3;
      }

      // Default
      return 4;
    }

    list.sort((a, b) => priority(a).compareTo(priority(b)));
    return list;
  }

  String? _nextMissingQuestion(IntakeSession session) {
    final hasFever = session.symptoms.contains('fever');
    final shouldAskFrequency = _shouldAskFrequency(session.symptoms);

    if (session.duration == null || session.duration!.trim().isEmpty) {
      return 'How long have you been experiencing these symptoms?';
    }

    if (session.medications == null || session.medications!.trim().isEmpty) {
      return 'Are you currently taking any medications?';
    }

    if (shouldAskFrequency &&
        (session.frequency == null || session.frequency!.trim().isEmpty)) {
      return 'How many times per day are your symptoms occurring?';
    }

    if (session.severity == null || session.severity!.trim().isEmpty) {
      return 'On a scale of 1-10, how severe are your symptoms?';
    }

    if (hasFever &&
        (session.temperature == null || session.temperature!.trim().isEmpty)) {
      return 'What is your temperature?';
    }

    return null;
  }

  bool _shouldAskFrequency(List<String> symptoms) {
    if (symptoms.isEmpty) return false;
    const frequencySymptoms = <String>{
      'headache',
      'palpitations',
      'dizziness',
      'nausea',
      'vomiting',
      'diarrhea',
      'constipation',
      'sneezing',
      'anxiety',
      'muscle_pain',
    };
    return symptoms.any(frequencySymptoms.contains);
  }

  String? _extractDuration(String text) {
    final match = RegExp(
      r'(\d+)\s*(day|days|week|weeks)',
    ).firstMatch(text.toLowerCase());
    if (match != null) {
      return match.group(0);
    }
    return null;
  }

  String? _extractFrequency(String text) {
    final normalized = text.toLowerCase();
    final match = RegExp(
      r'(\d+)\s*(times|x)\s*(per|a)\s*day',
    ).firstMatch(normalized);
    if (match != null) {
      return match.group(1);
    }
    final shortMatch = RegExp(r'(\d+)\s*/\s*day').firstMatch(normalized);
    if (shortMatch != null) {
      return shortMatch.group(1);
    }
    return null;
  }

  String? _extractTemperature(String text) {
    final normalized = text.toLowerCase();
    final explicitMatch = RegExp(
      '(\\d{2,3}(?:\\.\\d+)?)\\s*(?:\\u00B0\\s*)?[fc]',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (explicitMatch != null) {
      return explicitMatch.group(0);
    }

    final numbers = RegExp(r'\b\d{2,3}(?:\.\d+)?\b')
        .allMatches(normalized)
        .map((m) => double.tryParse(m.group(0)!))
        .whereType<double>()
        .toList();
    if (numbers.isEmpty) return null;

    bool isTempRange(double value) {
      return (value >= 95 && value <= 110) || (value >= 35 && value <= 43);
    }

    double? pickNearKeyword() {
      const keywords = ['temperature', 'temp', 'fever'];
      for (final keyword in keywords) {
        final idx = normalized.indexOf(keyword);
        if (idx == -1) continue;
        final windowStart = idx;
        final windowEnd = (idx + 30).clamp(0, normalized.length);
        final window = normalized.substring(windowStart, windowEnd);
        final match = RegExp(r'\b\d{2,3}(?:\.\d+)?\b').firstMatch(window);
        if (match != null) {
          final value = double.tryParse(match.group(0)!);
          if (value != null && isTempRange(value)) return value;
        }
      }
      return null;
    }

    final nearKeyword = pickNearKeyword();
    if (nearKeyword != null) {
      return nearKeyword % 1 == 0
          ? nearKeyword.toInt().toString()
          : nearKeyword.toString();
    }

    final rangeValue = numbers.firstWhere(
      isTempRange,
      orElse: () => double.nan,
    );
    if (rangeValue.isNaN) return null;
    return rangeValue % 1 == 0
        ? rangeValue.toInt().toString()
        : rangeValue.toString();
  }

  String? _extractSeverity(String text) {
    final lower = text.toLowerCase();

    final patterns = [
      RegExp(r'(\d{1,2})\s*/\s*10'), // 5/10
      RegExp(r'(\d{1,2})\s*out\s*of\s*10'), // 7 out of 10
      RegExp(r'severity\s*(\d{1,2})'), // severity 6
      RegExp(r'pain\s*level\s*(\d{1,2})'), // pain level 8
      RegExp(r'level\s*(\d{1,2})'), // level 4
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final value = int.tryParse(match.group(1)!);
        if (value != null && value >= 1 && value <= 10) {
          return value.toString();
        }
      }
    }

    return null;
  }

  String? _extractMedication(String text) {
    final normalized = text.toLowerCase();
    if (normalized.contains(RegExp(r'\b(no|none|not taking)\b'))) {
      return 'No';
    }
    if (normalized.contains(RegExp(r'\b(yes)\b'))) {
      return 'Yes';
    }
    if (normalized.contains(RegExp(r'\b(medication|medicine|meds)\b')) ||
        normalized.contains(RegExp(r'\b(taking|take|on)\b'))) {
      return text.trim().isEmpty ? null : text.trim();
    }
    return null;
  }

  List<String> _extractSymptoms(String text) {
    final normalized = normalizeInput(text);
    final inputWords = normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    final detected = <String>{};

    // 1) Exact phrase matching against keyword phrases.
    for (final symptom in triageSymptoms) {
      for (final keyword in symptom.keywords) {
        final normalizedKeyword = normalizeInput(keyword);
        if (normalized.contains(normalizedKeyword)) {
          detected.add(symptom.id);
          break;
        }
      }
    }

    if (detected.isNotEmpty) {
      return detected.toList(growable: false);
    }

    // 2) Fuzzy matching only against symptom id and full keyword phrase.
    for (final symptom in triageSymptoms) {
      final normalizedSymptomId = normalizeInput(
        symptom.id.replaceAll('_', ' '),
      );

      if (_matchesFuzzyFullPhrase(
        normalizedInput: normalized,
        inputWords: inputWords,
        targetPhrase: normalizedSymptomId,
      )) {
        detected.add(symptom.id);
        continue;
      }

      for (final keyword in symptom.keywords) {
        final normalizedKeyword = normalizeInput(keyword);
        if (_matchesFuzzyFullPhrase(
          normalizedInput: normalized,
          inputWords: inputWords,
          targetPhrase: normalizedKeyword,
        )) {
          detected.add(symptom.id);
          break;
        }
      }
    }

    return detected.toList(growable: false);
  }

  bool _matchesFuzzyFullPhrase({
    required String normalizedInput,
    required List<String> inputWords,
    required String targetPhrase,
  }) {
    if (targetPhrase.length < 4) {
      return false;
    }

    final maxDistance = targetPhrase.length <= 4 ? 0 : 2;

    // First compare against whole input for longer phrases only.
    if (targetPhrase.length > 4 &&
        _levenshtein(normalizedInput, targetPhrase) <= maxDistance) {
      return true;
    }

    final targetWords = targetPhrase
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    final windowSize = targetWords.length;
    if (windowSize == 0 || inputWords.length < windowSize) {
      return false;
    }

    for (var i = 0; i <= inputWords.length - windowSize; i++) {
      final candidate = inputWords.sublist(i, i + windowSize).join(' ');
      if (candidate.length < 4) {
        continue;
      }
      if (_levenshtein(candidate, targetPhrase) <= maxDistance) {
        return true;
      }
    }

    return false;
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var previous = List<int>.generate(b.length + 1, (i) => i);

    for (var i = 0; i < a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0);
      current[0] = i + 1;

      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        final insertion = current[j] + 1;
        final deletion = previous[j + 1] + 1;
        final substitution = previous[j] + cost;

        var value = insertion;
        if (deletion < value) value = deletion;
        if (substitution < value) value = substitution;
        current[j + 1] = value;
      }

      previous = current;
    }

    return previous[b.length];
  }

  List<FollowUpQuestion> _buildFollowUps(List<String> symptoms) {
    final followUps = <FollowUpQuestion>[];
    for (final symptom in symptoms) {
      for (final triageSymptom in triageSymptoms) {
        if (triageSymptom.id != symptom) continue;
        for (final followUp in triageSymptom.followUps) {
          followUps.add(followUp);
        }
        break;
      }
    }
    return followUps;
  }

  String _recommendedSpecialtyForSymptoms(List<String> symptoms) {
    if (symptoms.isEmpty) {
      return 'General Physician';
    }

    final countsBySpecialty = <String, int>{};

    for (final symptomId in symptoms) {
      for (final symptom in triageSymptoms) {
        if (symptom.id != symptomId) continue;
        final specialty = symptom.specialty.trim();
        if (specialty.isEmpty) break;
        countsBySpecialty[specialty] = (countsBySpecialty[specialty] ?? 0) + 1;
        break;
      }
    }

    if (countsBySpecialty.isEmpty) {
      return 'General Physician';
    }

    String selectedSpecialty = 'General Physician';
    var highestCount = -1;
    for (final entry in countsBySpecialty.entries) {
      if (entry.value > highestCount) {
        highestCount = entry.value;
        selectedSpecialty = entry.key;
      }
    }

    return selectedSpecialty;
  }

  Map<String, int> _buildCategoryCounts(List<String> symptoms) {
    final countsByCategory = <String, int>{};

    for (final symptomId in symptoms) {
      for (final symptom in triageSymptoms) {
        if (symptom.id != symptomId) continue;
        final category = symptom.category.trim();
        if (category.isEmpty) break;
        countsByCategory[category] = (countsByCategory[category] ?? 0) + 1;
        break;
      }
    }

    return countsByCategory;
  }

  double _recommendationConfidence(
    String conversationId,
    List<String> symptoms,
  ) {
    const baseConfidence = 0.85;

    if (symptoms.length < 2) {
      return baseConfidence;
    }

    final countsByCategory =
        _detectedCategoryCounts[conversationId] ??
        _buildCategoryCounts(symptoms);
    if (countsByCategory.isEmpty) {
      return baseConfidence;
    }

    var strongestCategoryCount = 0;
    for (final count in countsByCategory.values) {
      if (count > strongestCategoryCount) {
        strongestCategoryCount = count;
      }
    }

    if (strongestCategoryCount < 2) {
      return baseConfidence;
    }

    var boosted = baseConfidence + 0.05;
    if (strongestCategoryCount >= 3) {
      boosted += 0.02;
    }

    final strongShare = strongestCategoryCount / symptoms.length;
    if (strongShare >= 0.75) {
      boosted += 0.01;
    }

    if (boosted > 0.95) {
      return 0.95;
    }

    return boosted;
  }

  AIResponse _buildCompletedResponse(IntakeSession session) {
    final severityScore = int.tryParse(
      RegExp(r'\d+').firstMatch(session.severity ?? '')?.group(0) ?? '',
    );
    final triage = (severityScore ?? 0) > 7 ? 'High' : 'Medium';

    final symptomsText = session.symptoms.isEmpty
        ? 'No specific symptoms identified'
        : session.symptoms.join(', ');

    final durationText =
        (session.duration == null || session.duration!.trim().isEmpty)
        ? 'Not provided'
        : session.duration!.trim();
    final medicationsText =
        (session.medications == null || session.medications!.trim().isEmpty)
        ? 'Not provided'
        : session.medications!.trim();
    final severityText =
        (session.severity == null || session.severity!.trim().isEmpty)
        ? 'Not provided'
        : session.severity!.trim();

    final patientName = _patientNames[session.conversationId];
    final displayName = (patientName != null && patientName.trim().isNotEmpty)
        ? patientName
        : 'Patient';
    final hasFeverSymptom = session.symptoms.contains('fever');
    final recommendedSpecialty = _recommendedSpecialtyForSymptoms(
      session.symptoms,
    );
    final durationSentence = durationText == 'Not provided'
        ? null
        : 'It has been going on for $durationText.';
    String? formattedFrequency;
    if (session.frequency != null && session.frequency!.trim().isNotEmpty) {
      final freqValue = session.frequency!.trim();
      formattedFrequency = freqValue.contains('day')
          ? freqValue
          : '$freqValue times per day';
    }
    final outputFrequency = formattedFrequency ?? session.frequency;
    final frequencySentence = formattedFrequency == null
        ? null
        : 'Symptoms occur $formattedFrequency.';
    final medsLower = medicationsText.toLowerCase();
    final medicationsSentence = medicationsText == 'Not provided'
        ? null
        : medsLower == 'no'
        ? 'They are not taking any medications.'
        : medsLower == 'yes'
        ? 'They are taking medications.'
        : 'Medications include $medicationsText.';
    final severitySentence = severityText == 'Not provided'
        ? null
        : 'Severity is $severityText.';
    final temperatureSentence = !hasFeverSymptom
        ? null
        : (session.temperature == null || session.temperature!.trim().isEmpty)
        ? null
        : 'Temperature is ${session.temperature!.trim()}.';
    final clinicalSummaryParts = <String>[
      "$displayName has $symptomsText.",
      if (durationSentence != null) durationSentence,
      if (frequencySentence != null) frequencySentence,
      if (medicationsSentence != null) medicationsSentence,
      if (severitySentence != null) severitySentence,
      if (temperatureSentence != null) temperatureSentence,
    ];
    final clinicalSummary = clinicalSummaryParts.join(' ');

    final rawText = 'Summary generated.';

    return AIResponse(
      rawText: rawText,
      detectedSymptoms: session.symptoms,
      recommendedSpecialty: recommendedSpecialty,
      triageLevel: triage,
      confidence: _recommendationConfidence(
        session.conversationId,
        session.symptoms,
      ),
      generatedAt: DateTime.now(),
      stage: IntakeStage.completed,
      duration: session.duration,
      medications: session.medications,
      severity: session.severity,
      temperature: session.temperature,
      frequency: outputFrequency,
      followUpAnswers: session.followUpAnswers,
      clinicalSummary: clinicalSummary,
    );
  }
}
