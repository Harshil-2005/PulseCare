import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pulsecare/utils/keyboard_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/constrains/app_avatar.dart';
import 'package:pulsecare/model/chat_message.dart';
import 'package:pulsecare/model/doctor_model.dart';
import 'package:pulsecare/model/intake_session_model.dart';
import 'package:pulsecare/repositories/chat_repository.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import 'package:pulsecare/user/doctor_detail_screen.dart';
import 'package:pulsecare/utils/time_utils.dart';
import 'package:pulsecare/data/triage/triage_data.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../providers/repository_providers.dart';
import '../../providers/session_provider.dart';

final _consultationDoctorsProvider = StreamProvider.autoDispose<List<Doctor>>((
  ref,
) {
  // Recreate the stream when account/session changes to avoid stale cache.
  ref.watch(sessionUserIdProvider);
  return ref.read(doctorRepositoryProvider).watchAllDoctors();
});

final _consultationDoctorByIdProvider = FutureProvider.autoDispose
    .family<Doctor?, String>((ref, doctorId) async {
      return ref.read(doctorRepositoryProvider).getDoctorById(doctorId);
    });

class ConsultationChatWidget extends ConsumerStatefulWidget {
  final String conversationId;
  final String userId;
  final bool showDoctorRecommendations;
  final String? doctorId;
  final void Function(String doctorId, String? summaryId)? onContinueBooking;
  final String? initialMessage;
  final bool showDisclaimer;
  final bool hideSeedGreeting;
  final bool showIntroUntilConsultationStarts;
  final bool showIntro;
  final Widget Function(BuildContext context)? introBuilder;
  final double introBottomPadding;
  final double inputBottomPadding;
  final double trailingBottomSpacer;
  final FocusNode? inputFocusNode;
  final VoidCallback? onConsultationStarted;
  final ValueChanged<bool>? onHasAnyUserMessageChanged;

  const ConsultationChatWidget({
    super.key,
    required this.conversationId,
    required this.userId,
    required this.showDoctorRecommendations,
    this.doctorId,
    this.onContinueBooking,
    this.initialMessage,
    this.showDisclaimer = true,
    this.hideSeedGreeting = false,
    this.showIntroUntilConsultationStarts = false,
    this.showIntro = false,
    this.introBuilder,
    this.introBottomPadding = 220,
    this.inputBottomPadding = 20,
    this.trailingBottomSpacer = 0,
    this.inputFocusNode,
    this.onConsultationStarted,
    this.onHasAnyUserMessageChanged,
  });

  @override
  ConsumerState<ConsultationChatWidget> createState() =>
      _ConsultationChatWidgetState();
}

class _ConsultationChatWidgetState extends ConsumerState<ConsultationChatWidget>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  late final FocusNode _inputFocusNode;
  late final ChatRepository _chatRepository;
  final Map<String, GlobalKey> _messageKeys = {};
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _ownsFocusNode = false;
  bool _isInitialized = false;
  bool _isSending = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _didSendInitialMessage = false;
  bool _hasStartedConsultation = false;
  bool _latestIntakeCompleted = false;
  bool _didAutoScrollToBottom = false;

  String _userId = '';
  String _conversationId = '';
  String _currentUserName = '';
  String? _currentUserAvatarPath;
  String? _pendingInitialMessage;
  String? _completedSummaryId;
  String? _recommendedSpecialty;
  String _speechBaseText = '';
  String _micLocaleLabel = '';

  bool _micDialogOpen = false;
  bool _micDialogClosing = false;
  bool _autoRestartListening = false;
  bool _manualStopRequested = false;
  bool _heardSpeech = false;
  bool _wakeWordDetected = false;

  Timer? _micRestartTimer;
  final ValueNotifier<_MicUiState> _micUiState =
      ValueNotifier<_MicUiState>(_MicUiState.initial());

  static const List<String> _wakeWords = <String>[
    'hey pulsecare',
    'hey pulse care',
    'hi pulsecare',
    'hi pulse care',
    'ok pulsecare',
    'ok pulse care',
    'hello pulsecare',
    'hello pulse care',
    'pulsecare',
    'pulse care',
  ];

  List<ChatMessage> _messages = const <ChatMessage>[];
  double _lastKeyboardInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatRepository = ref.read(chatRepositoryProvider);
    _inputFocusNode = widget.inputFocusNode ?? FocusNode();
    _ownsFocusNode = widget.inputFocusNode == null;
    _inputFocusNode.addListener(_handleInputFocusChanged);

    final initial = widget.initialMessage?.trim();
    _pendingInitialMessage = (initial == null || initial.isEmpty)
        ? null
        : initial;

    _initializeConversation();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: _handleSpeechStatus,
        onError: _handleSpeechError,
      );
      if (!mounted) return;
      setState(() {
        _speechAvailable = available;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _speechAvailable = false;
      });
    }
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      if (_isListening) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  void _handleSpeechError(Object error) {
    if (!mounted) return;
    if (_isListening) {
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<bool> _ensureSpeechAvailable() async {
    if (_speechAvailable) return true;
    try {
      final available = await _speech.initialize(
        onStatus: _handleSpeechStatus,
        onError: _handleSpeechError,
      );
      if (!mounted) return false;
      setState(() {
        _speechAvailable = available;
      });
      return available;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleMicTap() async {
    if (_isListening) {
      await _stopListening();
      return;
    }
    await _startListening();
  }

  Future<void> _startListening() async {
    final available = await _ensureSpeechAvailable();
    if (!available) {
      _showSpeechUnavailable();
      return;
    }

    _speechBaseText = _controller.text.trimRight();
    if (mounted) {
      setState(() {
        _isListening = true;
      });
    }

    try {
      await _speech.listen(
        onResult: (result) {
          final recognized = result.recognizedWords.trim();
          if (recognized.isEmpty) return;
          final base = _speechBaseText;
          final updated = base.isEmpty ? recognized : '$base $recognized';
          _controller.value = TextEditingValue(
            text: updated,
            selection: TextSelection.collapsed(offset: updated.length),
          );
          if (result.finalResult) {
            _speechBaseText = updated;
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _stopListening() async {
    if (!_speech.isListening) {
      if (mounted && _isListening) {
        setState(() {
          _isListening = false;
        });
      }
      return;
    }
    await _speech.stop();
    if (!mounted) return;
    setState(() {
      _isListening = false;
    });
  }

  void _showSpeechUnavailable() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Microphone access is required for voice input.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _initializeConversation() async {
    try {
      var resolvedUserId = widget.userId.trim();

      if (resolvedUserId.isEmpty) {
        String? sessionUserId = ref.read(sessionUserIdProvider);
        if (sessionUserId == null || sessionUserId.isEmpty) {
          try {
            sessionUserId = SessionRepository().getCurrentUserId();
          } catch (_) {
            sessionUserId = null;
          }
        }
        if (sessionUserId != null && sessionUserId.isNotEmpty) {
          try {
            final currentUser = await ref
                .read(userRepositoryProvider)
                .getUserById(sessionUserId);
            resolvedUserId = currentUser?.id ?? sessionUserId;
          } catch (_) {
            resolvedUserId = sessionUserId;
          }
        }
      }

      if (resolvedUserId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isInitialized = true;
          _userId = '';
          _conversationId = '';
          _currentUserName = '';
          _currentUserAvatarPath = null;
          _messages = const <ChatMessage>[];
        });
        return;
      }

      String resolvedUserName = '';
      String? resolvedUserAvatarPath;
      try {
        final resolvedUser = await ref
            .read(userRepositoryProvider)
            .getUserById(resolvedUserId);
        resolvedUserName = resolvedUser?.fullName.trim() ?? '';
        resolvedUserAvatarPath = resolvedUser?.avatarPath;
      } catch (_) {
        resolvedUserName = '';
        resolvedUserAvatarPath = null;
      }

      final resolvedConversationId = widget.conversationId.trim().isEmpty
          ? _chatRepository.ensureConversationStarted(resolvedUserId)
          : widget.conversationId.trim();

      List<ChatMessage> initialMessages;
      try {
        initialMessages = await _chatRepository.getMessages(
          resolvedConversationId,
        );
      } catch (_) {
        initialMessages = const <ChatMessage>[];
      }

      if (!mounted) return;

      final hasAnyUserMessage = initialMessages.any(
        (message) => message.isUser,
      );
      final summaryMessage = initialMessages.lastWhere(
        (message) => (message.summarySymptoms?.isNotEmpty ?? false),
        orElse: () => ChatMessage(
          id: '',
          isUser: false,
          message: '',
          sentAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
      final hasSummary = summaryMessage.summarySymptoms?.isNotEmpty ?? false;
      final inferredSpecialty = hasSummary
          ? _inferSpecialtyFromSymptoms(summaryMessage.summarySymptoms!)
          : null;
      setState(() {
        _userId = resolvedUserId;
        _conversationId = resolvedConversationId;
        _currentUserName = resolvedUserName;
        _currentUserAvatarPath = resolvedUserAvatarPath;
        _messages = initialMessages;
        _hasStartedConsultation = hasAnyUserMessage;
        _latestIntakeCompleted = _latestIntakeCompleted || hasSummary;
        if (_recommendedSpecialty == null && inferredSpecialty != null) {
          _recommendedSpecialty = inferredSpecialty;
        }
        _isInitialized = true;
      });

      widget.onHasAnyUserMessageChanged?.call(hasAnyUserMessage);
      if (hasAnyUserMessage) {
        widget.onConsultationStarted?.call();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animated: false);
      });
      if (hasSummary && !_didAutoScrollToBottom) {
        _didAutoScrollToBottom = true;
        _scrollToBottomAfterBuild();
      }

      _triggerInitialMessageIfNeeded();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _refreshMessages() async {
    if (_conversationId.isEmpty) return;
    final updated = await _chatRepository.getMessages(_conversationId);
    if (!mounted) return;

    final hasAnyUserMessage = updated.any((message) => message.isUser);
    final summaryMessage = updated.lastWhere(
      (message) => (message.summarySymptoms?.isNotEmpty ?? false),
      orElse: () => ChatMessage(
        id: '',
        isUser: false,
        message: '',
        sentAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
    final hasSummary = summaryMessage.summarySymptoms?.isNotEmpty ?? false;
    final inferredSpecialty = hasSummary
        ? _inferSpecialtyFromSymptoms(summaryMessage.summarySymptoms!)
        : null;
    setState(() {
      _messages = updated;
      _hasStartedConsultation = _hasStartedConsultation || hasAnyUserMessage;
      _latestIntakeCompleted = _latestIntakeCompleted || hasSummary;
      if (_recommendedSpecialty == null && inferredSpecialty != null) {
        _recommendedSpecialty = inferredSpecialty;
      }
    });
    widget.onHasAnyUserMessageChanged?.call(hasAnyUserMessage);

    _scrollToBottom();
    if (hasSummary && !_didAutoScrollToBottom) {
      _didAutoScrollToBottom = true;
      _scrollToBottomAfterBuild();
    }
  }

  void _triggerInitialMessageIfNeeded() {
    if (_didSendInitialMessage) return;
    final initialMessage = _pendingInitialMessage;
    if (initialMessage == null || initialMessage.isEmpty) return;

    _didSendInitialMessage = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      sendMessage(initialMessage);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputFocusNode.removeListener(_handleInputFocusChanged);
    unawaited(_speech.stop());
    unawaited(_speech.cancel());
    _micRestartTimer?.cancel();
    _micUiState.dispose();
    _controller.dispose();
    _chatScrollController.dispose();
    if (_ownsFocusNode) {
      _inputFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted || !_isInitialized) return;
    final currentInset =
        View.of(context).viewInsets.bottom / View.of(context).devicePixelRatio;
    final keyboardOpened = currentInset > _lastKeyboardInset;
    _lastKeyboardInset = currentInset;

    if (!keyboardOpened || !_inputFocusNode.hasFocus) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: false);
    });
  }

  void _handleInputFocusChanged() {
    if (!_inputFocusNode.hasFocus) return;
  }

  void _scrollToBottomAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: false);
      Future<void>.delayed(const Duration(milliseconds: 40), () {
        if (!mounted) return;
        _scrollToBottom(animated: false);
      });
    });
  }

  String _inferSpecialtyFromSymptoms(List<String> symptoms) {
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

  void _showKeyboardWithFocus() {
    if (!_inputFocusNode.hasFocus) {
      _inputFocusNode.requestFocus();
    }
    FocusScope.of(context).requestFocus(_inputFocusNode);
  }

  void _keepInputFocusWithoutKeyboard() {
    if (!_inputFocusNode.hasFocus) {
      _inputFocusNode.requestFocus();
    }
    FocusScope.of(context).requestFocus(_inputFocusNode);
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  void _hideKeyboardKeepFocus() {
    _keepInputFocusWithoutKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowIntro =
        widget.showIntroUntilConsultationStarts &&
        (widget.showIntro || !_hasStartedConsultation);

    return Column(
      children: [
        if (widget.showDisclaimer && !_hasStartedConsultation)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xffEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Disclaimer: For Informational purposes only. Consult a healthcare professional for medical advice.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        Expanded(
          child: shouldShowIntro
              ? _buildIntroContainer(context)
              : _buildChatContent(context),
        ),
        _ChatInputField(
          controller: _controller,
          focusNode: _inputFocusNode,
          isSending: _isSending,
          isListening: _isListening,
          isSpeechAvailable: _speechAvailable,
          onMicTap: _handleMicTap,
          onSend: sendMessage,
          bottomPadding: widget.inputBottomPadding,
          onTapOutside: _hideKeyboardKeepFocus,
          onInputTap: _showKeyboardWithFocus,
        ),
        if (widget.trailingBottomSpacer > 0)
          SizedBox(height: widget.trailingBottomSpacer),
      ],
    );
  }

  Widget _buildIntroContainer(BuildContext context) {
    final introBuilder = widget.introBuilder;
    if (introBuilder == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        final bottomPadding =
            16.0 + (keyboardOpen ? widget.introBottomPadding : 0.0);

        return SingleChildScrollView(
          physics: keyboardOpen
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: introBuilder(context),
          ),
        );
      },
    );
  }

  Widget _buildChatContent(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final selectedDoctorId = widget.doctorId?.trim();
    final isDoctorSpecificMode =
        selectedDoctorId != null && selectedDoctorId.isNotEmpty;
    final shouldShowRecommendations =
        _latestIntakeCompleted &&
        widget.showDoctorRecommendations &&
        !isDoctorSpecificMode;
    final shouldShowContinueBooking =
        _latestIntakeCompleted && isDoctorSpecificMode;

    final selectedDoctorAsync = isDoctorSpecificMode
        ? ref.watch(_consultationDoctorByIdProvider(selectedDoctorId))
        : null;
    final selectedDoctor = selectedDoctorAsync?.valueOrNull;

    final visibleMessages = widget.hideSeedGreeting
        ? _messages.where((message) => !_isSeedGreeting(message)).toList()
        : _messages;

    final trailingWidgets = <Widget>[];
    if (shouldShowRecommendations) {
      trailingWidgets.add(
        _DoctorRecommendations(
          recommendedSpecialty: _recommendedSpecialty,
          doctorCardBuilder: _doctorSuggestionCard,
        ),
      );
    }
    if (shouldShowContinueBooking) {
      trailingWidgets.add(_buildContinueBookingCard(selectedDoctor));
    }

    return _ChatMessagesList(
      messages: visibleMessages,
      scrollController: _chatScrollController,
      messageKeys: _messageKeys,
      bubbleBuilder: _chatBubble,
      trailingWidgets: trailingWidgets,
      bottomContentPadding:
          widget.inputBottomPadding + widget.trailingBottomSpacer,
      keyboardOpen: keyboardOpen,
    );
  }

  Future<void> sendMessage([String? initialMessage]) async {
    final shouldKeepKeyboardOpen = _inputFocusNode.hasFocus;

    final message = (initialMessage ?? _controller.text).trim();
    if (message.isEmpty || _isSending || _conversationId.isEmpty) return;
    if (_isListening) {
      await _stopListening();
    }

    setState(() {
      _isSending = true;
      _hasStartedConsultation = true;
    });
    widget.onConsultationStarted?.call();

    try {
      final createdMessage = await _chatRepository.addUserMessage(
        _conversationId,
        message,
      );
      if (!mounted) return;

      _controller.clear();
      await _refreshMessages();
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pinMessageNearTop(createdMessage.id);
        _scrollToBottom();
      });

      final aiResponse = await _chatRepository.generateAndStoreAiResponse(
        _conversationId,
        _userId,
      );
      if (!mounted) return;

      final intakeCompleted =
          aiResponse.stage == IntakeStage.completed ||
          aiResponse.summaryId != null;

      await _refreshMessages();
      if (!mounted) return;

      setState(() {
        _recommendedSpecialty = aiResponse.recommendedSpecialty;
        if (aiResponse.summaryId != null) {
          _completedSummaryId = aiResponse.summaryId;
        }
        _latestIntakeCompleted = _latestIntakeCompleted || intakeCompleted;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (shouldKeepKeyboardOpen) {
          _showKeyboardWithFocus();
        }
        _scrollToBottom();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _pinMessageNearTop(String messageId, {bool animated = true}) {
    final key = _messageKeys[messageId];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.08,
      duration: animated ? const Duration(milliseconds: 260) : Duration.zero,
      curve: Curves.easeOut,
    );
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_chatScrollController.hasClients) return;
    final target = _chatScrollController.position.maxScrollExtent;
    if (animated) {
      _chatScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _chatScrollController.jumpTo(target);
    }
  }

  Widget _chatBubble(ChatMessage chat) {
    final isUser = chat.isUser;

    return TweenAnimationBuilder<double>(
      key: ValueKey(chat.id),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              const CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('assets/images/drLara.png'),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(14),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xff3F67FD) : Colors.grey.shade200,
                borderRadius: isUser
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      )
                    : const BorderRadius.only(
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMessageBody(chat, isUser),
                  const SizedBox(height: 4),
                  Text(
                    TimeUtils.formatTime(chat.sentAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isUser)
              AppAvatar(
                radius: 18,
                name: _currentUserName,
                imagePath: _currentUserAvatarPath,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBody(ChatMessage chat, bool isUser) {
    if (!_isFormattedSummary(chat)) {
      return Text(
        chat.message,
        style: TextStyle(color: isUser ? Colors.white : Colors.black),
      );
    }

    final summarySymptoms = chat.summarySymptoms;
    final summaryDuration = chat.summaryDuration;
    final summaryMedications = chat.summaryMedications;
    final summarySeverity = chat.summarySeverity;
    final summaryTemperature = chat.summaryTemperature;
    final summaryFrequency = chat.summaryFrequency;
    final summaryFollowUps = chat.summaryFollowUpAnswers;
    const textStyle = TextStyle(color: Colors.black);

    final symptomsText = summarySymptoms
        ?.map(_formatSymptomLabel)
        .where((value) => value.isNotEmpty)
        .join(', ');
    final durationText = summaryDuration;
    final medicationsText = summaryMedications;
    final severityText = summarySeverity;
    final temperatureText = summaryTemperature;
    final frequencyText = summaryFrequency;
    final followUpsText = summaryFollowUps?.entries
        .map((entry) => '${_followUpLabelFromId(entry.key)}: ${entry.value}')
        .join('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Appointment Summary',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        if (symptomsText != null)
          Text('Symptoms: $symptomsText', style: textStyle),
        if (durationText != null)
          Text('Duration: $durationText', style: textStyle),
        if (frequencyText != null)
          Text('Frequency: $frequencyText', style: textStyle),
        if (medicationsText != null)
          Text('Medications: $medicationsText', style: textStyle),
        if (severityText != null)
          Text('Severity: $severityText', style: textStyle),
        if (temperatureText != null)
          Text('Temperature: $temperatureText', style: textStyle),
        if (followUpsText != null && followUpsText.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Follow-ups:', style: textStyle),
          Text(followUpsText, style: textStyle),
        ],
      ],
    );
  }

  Widget _doctorSuggestionCard(Doctor doctor, String doctorPhone) {
    return InkWell(
      onTap: () {
        KeyboardUtils.hideKeyboardKeepFocus();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDetailScreen(
              doctorId: doctor.id,
              aiSummaryId: _completedSummaryId,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          width: 250,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(
                  255,
                  0,
                  0,
                  0,
                ).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
            color: Colors.white,
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10),
                    ),
                    color: Color(0xff5276FD),
                  ),
                  width: 26,
                  height: 26,
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/vector.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 10),
                    child: Text(
                      doctor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      doctor.speciality,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 10),
                    child: Row(
                      children: [
                        _buildRatingStars(doctor.rating),
                        const SizedBox(width: 6),
                        Text(
                          doctor.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        const Text('|', style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 6),
                        Text(
                          '${doctor.reviews} Reviews',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: SvgPicture.asset('assets/icons/call.svg'),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          doctorPhone.isNotEmpty
                              ? doctorPhone
                              : 'Not Available',
                          style: const TextStyle(fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueBookingCard(Doctor? doctor) {
    if (doctor == null) {
      return const SizedBox.shrink();
    }

    final selectedDoctorId = widget.doctorId?.trim();
    final doctorName = doctor.name.trim().isEmpty ? 'this doctor' : doctor.name;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: InkWell(
        onTap: () {
          if (selectedDoctorId == null || selectedDoctorId.isEmpty) {
            return;
          }
          KeyboardUtils.hideKeyboardKeepFocus();
          final onContinueBooking = widget.onContinueBooking;
          if (onContinueBooking != null) {
            onContinueBooking(selectedDoctorId, _completedSummaryId);
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorDetailScreen(
                doctorId: selectedDoctorId,
                aiSummaryId: _completedSummaryId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xff3F67FD),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Book appointment with\nDr. $doctorName',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    final clamped = rating.clamp(0, 5);
    return Row(
      children: List.generate(5, (index) {
        final filled = index < clamped.floor();
        return Icon(
          filled ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 12,
        );
      }),
    );
  }

  bool _isFormattedSummary(ChatMessage chat) {
    if (chat.isUser) return false;
    if (chat.summarySymptoms != null ||
        chat.summaryFollowUpAnswers != null ||
        chat.summaryFrequency != null) {
      return true;
    }
    return false;
  }

  bool _isSeedGreeting(ChatMessage chat) {
    if (chat.isUser) return false;
    final normalized = chat.message.trim().toLowerCase().replaceAll('’', "'");
    return normalized.startsWith("hello! i'm dr. elara");
  }

  String _followUpLabelFromId(String id) {
    final question = _followUpQuestionById(id);
    if (question != null) {
      return _labelOverride(id) ?? _capitalize(_labelFromQuestion(question));
    }
    var fallback = id.trim();
    for (final symptom in triageSymptoms) {
      final prefix = '${symptom.id}_';
      if (fallback.startsWith(prefix)) {
        fallback = fallback.substring(prefix.length);
        break;
      }
    }
    return _labelOverride(id) ??
        _capitalize(fallback.replaceAll('_', ' ').trim());
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String _formatSymptomLabel(String symptom) {
    final normalized = symptom.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return normalized;
    final words = normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .toList(growable: false);
    return words.join(' ');
  }

  String? _followUpQuestionById(String id) {
    for (final symptom in triageSymptoms) {
      for (final followUp in symptom.followUps) {
        if (followUp.id == id) {
          return followUp.question;
        }
        for (final option in followUp.options) {
          if (option.id == id) {
            return option.label;
          }
        }
      }
    }
    return null;
  }

  String _labelFromQuestion(String question) {
    var label = question.trim();
    label = label.replaceAll('?', '').trim();
    final lower = label.toLowerCase();
    final prefixes = [
      'do you have ',
      'do you ',
      'are you ',
      'have you ',
      'did you ',
      'is your ',
      'is the ',
      'is it ',
      'is ',
      'where is ',
      'where on your body is ',
      'where exactly is ',
      'where exactly is the ',
      'how long have you had ',
      'how long have you been ',
      'how long do ',
      'how long ',
      'how often are ',
      'how often ',
      'how many ',
      'did this ',
      'does it ',
      'does the ',
      'are there ',
      'have you been ',
      'how high has your ',
      'how high has ',
    ];
    for (final prefix in prefixes) {
      if (lower.startsWith(prefix)) {
        label = label.substring(prefix.length);
        break;
      }
    }
    label = label.trimLeft();
    for (final article in ['a ', 'an ', 'the ']) {
      if (label.toLowerCase().startsWith(article)) {
        label = label.substring(article.length);
        break;
      }
    }
    return label.trim();
  }

  String? _labelOverride(String id) {
    const overrides = <String, String>{
      'fever_chills': 'Chills',
      'fever_body_aches': 'Body aches',
      'fever_sore_throat': 'Sore throat',
      'fever_taken_any_medicine_to_reduce_fever': 'Medication to reduce fever',
      'cough_cough_dry': 'Dry cough',
      'cough_wheezing': 'Wheezing',
      'cold_a_runny_nose': 'Runny nose',
      'cold_experiencing_a_sore_throat': 'Sore throat',
      'cold_chills': 'Chills',
      'headache_pain_located': 'Pain location',
      'headache_nausea': 'Nausea',
      'headache_where_is_the_pain_located': 'Pain location',
      'headache_how_severe_is_the_pain': 'Pain severity',
      'chest_pain_pain_sharp': 'Sharp pain',
      'chest_pain_spread_to_arm': 'Pain radiates to arm',
      'chest_pain_worsen_with_exertion': 'Worse with exertion',
      'shortness_of_breath_start_suddenly': 'Sudden onset',
      'shortness_of_breath_short_of_breath_at_rest':
          'Shortness of breath at rest',
      'shortness_of_breath_chest_pain': 'Chest pain',
      'rash_rash': 'Rash location',
      'rash_itchy': 'Itching',
      'rash_recently_use_a_new_soap': 'New soap exposure',
      'stomach_pain_pain_in_abdomen': 'Abdominal pain location',
      'stomach_pain_related_to_meals': 'Related to meals',
      'stomach_pain_pain_constant': 'Constant pain',
      'stomach_pain_how_severe_is_the_pain': 'Pain severity',
      'stomach_pain_is_it_constant_or_cramping': 'Pain pattern',
      'back_pain_pain_in_lower_back': 'Lower back pain',
      'back_pain_did_it_start_after_lifting': 'Started after lifting',
      'back_pain_numbness_in_legs': 'Leg numbness',
      'dizziness_feel_spinning': 'Spinning sensation',
      'dizziness_nausea': 'Nausea',
      'fatigue_fatigue_affecting_daily_activities': 'Affects daily activities',
      'fatigue_weight_change': 'Weight change',
      'sore_throat_swollen_glands': 'Swollen glands',
      'sore_throat_swallowing_painful': 'Painful swallowing',
      'runny_nose_discharge_clear': 'Clear discharge',
      'runny_nose_sinus_pressure': 'Sinus pressure',
      'vomiting_times_have_you_vomited_today': 'Vomiting count (today)',
      'vomiting_able_to_keep_fluids_down': 'Able to keep fluids down',
      'vomiting_abdominal_pain': 'Abdominal pain',
      'diarrhea_there_blood_in_stool': 'Blood in stool',
      'diarrhea_vomiting': 'Vomiting',
      'constipation_abdominal_pain': 'Abdominal pain',
      'constipation_tried_any_laxatives': 'Tried laxatives',
      'joint_pain_affected': 'Affected joints',
      'joint_pain_do_joints_feel_swollen': 'Joint swelling',
      'joint_pain_pain_start_after_injury': 'Started after injury',
      'ear_pain_which_ear_is_affected': 'Affected ear',
      'ear_pain_do_you_have_hearing_loss': 'Hearing loss',
      'ear_pain_do_you_have_discharge': 'Discharge',
      'ear_pain_do_you_have_fever': 'Fever',
      'ear_pain_did_this_start_after_a_cold_or_swimming':
          'Started after cold or swimming',
      'eye_redness_one_eye_affected': 'One eye affected',
      'eye_redness_blurred_vision': 'Blurred vision',
      'eye_redness_been_exposed_to_allergens': 'Allergen exposure',
      'skin_swelling_swelling': 'Swelling location',
      'skin_swelling_area_red': 'Redness',
      'skin_swelling_have_an_injury': 'Injury',
      'palpitations_do_they_occur_at_rest': 'Occurs at rest',
      'palpitations_chest_pain': 'Chest pain',
      'sneezing_sneezing_worse_in_morning': 'Worse in morning',
      'sneezing_a_runny_nose': 'Runny nose',
      'sneezing_recently_had_cold_exposure': 'Cold exposure',
      'nasal_congestion_facial_pressure': 'Facial pressure',
      'nasal_congestion_congestion_affecting_sleep': 'Affects sleep',
      'nausea_vomiting': 'Vomiting',
      'nausea_start_after_eating': 'Started after eating',
      'acid_reflux_do_symptoms_worsen_after_meals': 'Worse after meals',
      'acid_reflux_feel_a_burning_sensation_in_chest': 'Burning in chest',
      'acid_reflux_tried_antacids': 'Tried antacids',
      'itching_itching_most': 'Itching location',
      'itching_a_rash_with_itching': 'Rash with itching',
      'itching_recently_use_a_new_soap': 'New soap exposure',
      'neck_pain_neck_pain_start_after_poor_posture':
          'Started after poor posture',
      'neck_pain_pain_spread_to_shoulder': 'Radiates to shoulder',
      'neck_pain_feel_numbness_in_arms': 'Arm numbness',
      'muscle_pain_painful': 'Painful muscles',
      'muscle_pain_begin_after_exertion': 'Started after exertion',
      'muscle_pain_also_have_weakness': 'Weakness',
      'eye_pain_one_eye_painful': 'One eye painful',
      'eye_pain_redness_in_eye': 'Eye redness',
      'eye_pain_pain_start_after_screen_strain': 'Started after screen strain',
      'anxiety_do_you_feel_anxious': 'Feeling anxious',
      'anxiety_palpitations_during_episodes': 'Palpitations during episodes',
      'anxiety_anxiety_affecting_sleep': 'Affects sleep',
    };
    return overrides[id];
  }
}

class _ChatMessagesList extends StatelessWidget {
  const _ChatMessagesList({
    required this.messages,
    required this.scrollController,
    required this.messageKeys,
    required this.bubbleBuilder,
    required this.trailingWidgets,
    required this.bottomContentPadding,
    required this.keyboardOpen,
  });

  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final Map<String, GlobalKey> messageKeys;
  final Widget Function(ChatMessage chat) bubbleBuilder;
  final List<Widget> trailingWidgets;
  final double bottomContentPadding;
  final bool keyboardOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomContentPadding),
      itemCount: messages.length + trailingWidgets.length,
      itemBuilder: (context, index) {
        if (index < messages.length) {
          final chat = messages[index];
          final messageId = chat.id;
          return KeyedSubtree(
            key: messageKeys.putIfAbsent(messageId, GlobalKey.new),
            child: bubbleBuilder(chat),
          );
        }

        final trailingIndex = index - messages.length;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset((1 - value) * -24, 0),
                child: child,
              ),
            );
          },
          child: trailingWidgets[trailingIndex],
        );
      },
    );
  }
}

class _DoctorRecommendations extends ConsumerWidget {
  const _DoctorRecommendations({
    required this.recommendedSpecialty,
    required this.doctorCardBuilder,
  });

  final String? recommendedSpecialty;
  final Widget Function(Doctor doctor, String phone) doctorCardBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(_consultationDoctorsProvider);
    final doctors = doctorsAsync.valueOrNull ?? const <Doctor>[];
    final specialty = recommendedSpecialty?.trim().toLowerCase();

    var recommended = doctors
        .where((doctor) => doctor.speciality.trim().toLowerCase() == specialty)
        .toList(growable: false);

    if (recommended.isEmpty) {
      recommended = doctors
          .where(
            (doctor) =>
                doctor.speciality.trim().toLowerCase() == 'general physician',
          )
          .toList(growable: false);
    }

    if (recommended.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Text(
          'No doctors available for this specialty yet.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4),
        scrollDirection: Axis.horizontal,
        itemCount: recommended.length,
        itemBuilder: (context, doctorIndex) {
          final doctor = recommended[doctorIndex];
          return Consumer(
            builder: (context, ref, _) {
              final doctorPhone = doctor.phone?.trim() ?? '';
              return doctorCardBuilder(doctor, doctorPhone);
            },
          );
        },
      ),
    );
  }
}

class _ChatInputField extends StatelessWidget {
  const _ChatInputField({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.isListening,
    required this.isSpeechAvailable,
    required this.onMicTap,
    required this.onSend,
    required this.bottomPadding,
    required this.onTapOutside,
    required this.onInputTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool isListening;
  final bool isSpeechAvailable;
  final VoidCallback onMicTap;
  final void Function([String? initialMessage]) onSend;
  final double bottomPadding;
  final VoidCallback onTapOutside;
  final VoidCallback onInputTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: TextFieldTapRegion(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 6,
                  onTap: onInputTap,
                  onTapOutside: (_) {
                    onTapOutside();
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade300,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    suffixIcon: GestureDetector(
                      onTap: onMicTap,
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isListening
                              ? const Color(0xffE6EEFF)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/mick.svg',
                            height: 18,
                            colorFilter: ColorFilter.mode(
                              isListening
                                  ? const Color(0xff3F67FD)
                                  : (isSpeechAvailable
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade400),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                    hintText: 'Ask Dr. Elara Anything...',
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            InkWell(
              onTap: () => onSend(),
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 27,
                backgroundColor: isSending
                    ? const Color(0xff8EA2FF)
                    : const Color(0xff3F67FD),
                child: SvgPicture.asset(
                  'assets/icons/send.svg',
                  height: 25,
                  width: 25,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
