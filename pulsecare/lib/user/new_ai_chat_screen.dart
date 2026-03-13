import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/model/chat_message.dart';
import 'package:pulsecare/model/doctor_model.dart';
import 'package:pulsecare/model/intake_session_model.dart';
import 'package:pulsecare/repositories/chat_repository.dart';
import 'package:pulsecare/user/chat_history_screen.dart';
import 'package:pulsecare/user/doctor_detail_screen.dart';
import 'package:pulsecare/utils/time_utils.dart';
import '../providers/repository_providers.dart';
import '../providers/session_provider.dart';

final _newChatDoctorsProvider = FutureProvider<List<Doctor>>((ref) async {
  return ref.read(doctorRepositoryProvider).getAllDoctors();
});

final _newChatDoctorUserProvider = StreamProvider.autoDispose.family((
  ref,
  String userId,
) {
  return ref.read(userRepositoryProvider).watchUserById(userId);
});

class NewAiChatScreen extends ConsumerStatefulWidget {
  const NewAiChatScreen({super.key});

  @override
  ConsumerState<NewAiChatScreen> createState() => _NewAiChatScreenState();
}

class _NewAiChatScreenState extends ConsumerState<NewAiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  late final ChatRepository _chatRepository;
  static const double _introBottomPadding = 220;
  final Map<String, GlobalKey> _messageKeys = {};
  String _userId = '';
  String _conversationId = '';
  bool _hasStartedConsultation = false;
  bool _isSending = false;
  bool _latestIntakeCompleted = false;
  String? _completedSummaryId;
  String? _recommendedSpecialty;
  List<ChatMessage> _messages = const <ChatMessage>[];

  @override
  void initState() {
    super.initState();
    _chatRepository = ref.read(chatRepositoryProvider);
    _initializeConversation();
  }

  Future<void> _initializeConversation() async {
    final userId = ref.read(sessionUserIdProvider);
    final currentUser = userId == null
        ? null
        : await ref.read(userRepositoryProvider).getUserById(userId);
    if (!mounted) return;
    final resolvedUserId = currentUser?.id ?? userId ?? '';
    final conversationId = _chatRepository.ensureConversationStarted(
      resolvedUserId,
    );
    final initialMessages = await _chatRepository.getMessages(conversationId);
    if (!mounted) return;
    setState(() {
      _userId = resolvedUserId;
      _conversationId = conversationId;
      _messages = initialMessages;
    });
  }

  Future<void> _refreshMessages() async {
    if (_conversationId.isEmpty) return;
    final updated = await _chatRepository.getMessages(_conversationId);
    if (!mounted) return;
    setState(() {
      _messages = updated;
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _chatScrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final initialText = _controller.text.trim();
    if (initialText.isEmpty || _isSending || _conversationId.isEmpty) return;

    setState(() {
      _isSending = true;
      _hasStartedConsultation = true;
    });

    final createdMessage = await _chatRepository.addUserMessage(
      _conversationId,
      initialText,
    );
    _controller.clear();
    await _refreshMessages();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinMessageNearTop(createdMessage.id);
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
      _isSending = false;
      _hasStartedConsultation = _hasStartedConsultation || intakeCompleted;
      if (aiResponse.summaryId != null) {
        _completedSummaryId = aiResponse.summaryId;
      }
      _recommendedSpecialty = aiResponse.recommendedSpecialty;
      _latestIntakeCompleted = _latestIntakeCompleted || intakeCompleted;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (!_chatScrollController.hasClients) return;
    final target = _chatScrollController.position.maxScrollExtent + 120;
    _chatScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  bool get _hasAnyUserMessage => _messages.any((message) => message.isUser);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        titleSpacing: 0,
        toolbarHeight: 85,
        elevation: 0.3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.pop(context);
          },
          icon: SvgPicture.asset(
            'assets/icons/backarrow.svg',
            width: 24,
            height: 20,
          ),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage('assets/images/drLara.png'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dr. Elara',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Your AI Medical Assistant',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                if (!_hasAnyUserMessage) {
                  return;
                }
                FocusScope.of(context).unfocus();
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewAiChatScreen(),
                  ),
                ).then((_) {
                  if (!context.mounted) return;
                  FocusScope.of(context).unfocus();
                  _inputFocusNode.unfocus();
                });
              },
              child: SvgPicture.asset('assets/icons/new_chat.svg', height: 20),
            ),
            const SizedBox(width: 14),
            InkWell(
              onTap: () {
                FocusScope.of(context).unfocus();
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatHistoryScreen(),
                  ),
                ).then((_) {
                  if (!context.mounted) return;
                  FocusScope.of(context).unfocus();
                  _inputFocusNode.unfocus();
                });
              },
              child: SvgPicture.asset('assets/icons/history.svg', height: 18),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Column(
          children: [
            Expanded(
              child: _hasAnyUserMessage
                  ? chatContent()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final keyboardOpen =
                            MediaQuery.of(context).viewInsets.bottom > 0;
                        final bottomPadding =
                            16.0 + (keyboardOpen ? _introBottomPadding : 0.0);
                        return SingleChildScrollView(
                          physics: keyboardOpen
                              ? const ClampingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            bottomPadding,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: introContent(),
                          ),
                        );
                      },
                    ),
            ),
            inputBar(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget chatContent() {
    if (_messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final visibleMessages = _messages
        .where((message) => !_isSeedGreeting(message))
        .toList(growable: false);

    final shouldShowRecommendations = _latestIntakeCompleted;

    return ListView.builder(
      controller: _chatScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: visibleMessages.length + (shouldShowRecommendations ? 1 : 0),
      itemBuilder: (context, index) {
        if (shouldShowRecommendations && index == visibleMessages.length) {
          return _buildDoctorRecommendations();
        }
        final message = visibleMessages[index];
        return KeyedSubtree(
          key: _messageKeys.putIfAbsent(message.id, GlobalKey.new),
          child: _chatBubble(message),
        );
      },
    );
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

  Widget _buildDoctorRecommendations() {
    final doctorsAsync = ref.watch(_newChatDoctorsProvider);

    return doctorsAsync.when(
      data: (doctors) {
        final filteredDoctors = _filterDoctorsBySpecialty(
          doctors,
          _recommendedSpecialty,
        );
        if (filteredDoctors.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filteredDoctors.length,
              itemBuilder: (context, index) {
                final doctor = filteredDoctors[index];
                final doctorPhone = doctor.userId.isEmpty
                    ? ''
                    : ref
                              .watch(_newChatDoctorUserProvider(doctor.userId))
                              .valueOrNull
                              ?.phone ??
                          '';
                return _doctorSuggestionCard(doctor, doctorPhone);
              },
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  List<Doctor> _filterDoctorsBySpecialty(
    List<Doctor> doctors,
    String? specialty,
  ) {
    final normalized = specialty?.trim();
    if (normalized == null || normalized.isEmpty) {
      return doctors;
    }
    final matches = doctors
        .where((doctor) => doctor.speciality == normalized)
        .toList(growable: false);
    return matches.isEmpty ? doctors : matches;
  }

  Widget introContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/robot.png', height: 120),
          const Text(
            'from symptoms to diet advice',
            style: TextStyle(fontSize: 16),
          ),
          const Text(
            'Ask me anything',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'From symptom analysis to detailed diet and lifestyle advice, ask anything and get instant AI support.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget inputBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _inputFocusNode,
              minLines: 1,
              maxLines: 6,
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
                FocusManager.instance.primaryFocus?.unfocus();
              },
              decoration: InputDecoration(
                hintText: 'Ask Dr. Elara Anything...',
                hintStyle: const TextStyle(color: Colors.grey),
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
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset('assets/icons/mick.svg'),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _handleSend,
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: 27,
              backgroundColor: _isSending
                  ? const Color(0xff8EA2FF)
                  : const Color(0xff3F67FD),
              child: SvgPicture.asset(
                'assets/icons/send.svg',
                height: 24,
                width: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatBubble(ChatMessage chat) {
    final isUser = chat.isUser;
    return Padding(
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
            constraints: const BoxConstraints(maxWidth: 260),
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
            const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/images/user.png'),
            ),
        ],
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

    final fields = _parseSummaryFields(chat.message);
    const textStyle = TextStyle(color: Colors.black);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Appointment Summary',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Text('Symptoms: ${fields['symptoms']}', style: textStyle),
        Text('Duration: ${fields['duration']}', style: textStyle),
        Text('Severity: ${fields['severity']}', style: textStyle),
        Text('Temperature: ${fields['temperature']}', style: textStyle),
      ],
    );
  }

  bool _isFormattedSummary(ChatMessage chat) {
    return !chat.isUser &&
        chat.message.trimLeft().toLowerCase().startsWith('summary:');
  }

  bool _isSeedGreeting(ChatMessage chat) {
    if (chat.isUser) return false;
    final normalized = chat.message.trim().toLowerCase().replaceAll('’', "'");
    return normalized.startsWith("hello! i'm dr. elara");
  }

  Map<String, String> _parseSummaryFields(String message) {
    final cleaned = message.replaceFirst(
      RegExp(r'^\s*summary:\s*', caseSensitive: false),
      '',
    );

    String extract(String label, {String? until}) {
      final lookahead = until == null
          ? r'$'
          : '(?=\\s*${until}\\s*:|' + r'$' + ')';
      final pattern = RegExp(
        '$label\\s*:\\s*(.*?)$lookahead',
        caseSensitive: false,
      );
      final value =
          pattern.firstMatch(cleaned)?.group(1)?.trim() ?? 'Not provided';
      return value.replaceAll(RegExp(r'\.+$'), '').trim();
    }

    return {
      'symptoms': extract('Symptoms', until: 'Duration'),
      'duration': extract('Duration', until: 'Medications|Severity'),
      'severity': extract('Severity', until: 'Temperature'),
      'temperature': extract('Temperature'),
    };
  }

  Widget _doctorSuggestionCard(Doctor doctor, String doctorPhone) {
    return InkWell(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDetailScreen(
              doctorId: doctor.id,
              aiSummaryId: _completedSummaryId,
            ),
          ),
        ).then((_) {
          if (!context.mounted) return;
          FocusScope.of(context).unfocus();
          _inputFocusNode.unfocus();
        });
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
                          doctorPhone,
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
}
