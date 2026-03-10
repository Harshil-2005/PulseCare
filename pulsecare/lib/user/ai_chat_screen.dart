import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/model/chat_message.dart';
import 'package:pulsecare/model/doctor_model.dart';
import 'package:pulsecare/model/intake_session_model.dart';
import 'package:pulsecare/repositories/chat_repository.dart';
import 'package:pulsecare/user/chat_history_screen.dart';
import 'package:pulsecare/user/doctor_detail_screen.dart';
import 'package:pulsecare/user/home_screen.dart';
import 'package:pulsecare/user/new_ai_chat_screen.dart';
import 'package:pulsecare/utils/time_utils.dart';
import '../providers/repository_providers.dart';
import '../providers/session_provider.dart';

final _chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((
  ref,
  conversationId,
) async {
  if (conversationId.isEmpty) return const <ChatMessage>[];
  return ref.read(chatRepositoryProvider).getMessages(conversationId);
});

final _chatDoctorsProvider = FutureProvider<List<Doctor>>((ref) async {
  return ref.read(doctorRepositoryProvider).getAllDoctors();
});

final _chatDoctorUserProvider = StreamProvider.autoDispose.family((
  ref,
  String userId,
) {
  return ref.read(userRepositoryProvider).watchUserById(userId);
});

class AiChatScreen extends ConsumerStatefulWidget {
  final bool showDoctorRecommendations;

  const AiChatScreen({super.key, this.showDoctorRecommendations = true});

  @override
  ConsumerState<AiChatScreen> createState() => _NewAiChatScreenState();
}

class _NewAiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  late final ChatRepository _chatRepository;
  String? _completedSummaryId;
  List<String> _detectedSymptoms = const <String>[];
  bool _latestIntakeCompleted = false;
  String _userId = '';
  String _conversationId = '';
  final Map<String, GlobalKey> _messageKeys = {};

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
    setState(() {
      _userId = currentUser?.id ?? userId ?? '';
      _conversationId = _chatRepository.ensureConversationStarted(_userId);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _chatScrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  String _formatSymptomsForBooking() {
    if (_detectedSymptoms.isEmpty) return '';
    return 'Symptoms: ${_detectedSymptoms.join(", ")}';
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowRecommendations = _latestIntakeCompleted;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        titleSpacing: 0,
        toolbarHeight: 85,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        elevation: 0.3,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
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
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dr. Elara',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Your AI Medical Assistant',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                FocusScope.of(context).unfocus();
                Navigator.push(
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
            const SizedBox(width: 13),
            InkWell(
              onTap: () {
                FocusScope.of(context).unfocus();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
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
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
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
            Expanded(child: chatList(shouldShowRecommendations)),
            inputBar(),
          ],
        ),
      ),
    );
  }

  Widget chatList(bool shouldShowRecommendations) {
    final chatsAsync = ref.watch(_chatMessagesProvider(_conversationId));
    final doctorsAsync = ref.watch(_chatDoctorsProvider);

    return chatsAsync.when(
      data: (chats) {
        final doctors = doctorsAsync.valueOrNull ?? const <Doctor>[];
        return ListView.builder(
          controller: _chatScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: chats.length + (shouldShowRecommendations ? 1 : 0),
          itemBuilder: (context, index) {
            if (shouldShowRecommendations && index == chats.length) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset((1 - value) * -36, 0),
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  height: 140,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: doctors.length,
                    itemBuilder: (context, doctorIndex) {
                      final doctor = doctors[doctorIndex];
                      final doctorPhone = doctor.userId.isEmpty
                          ? ''
                          : ref
                                    .watch(
                                      _chatDoctorUserProvider(doctor.userId),
                                    )
                                    .valueOrNull
                                    ?.phone ??
                                '';
                      return doctorSuggestionCard(
                        doctor,
                        context,
                        _completedSummaryId,
                        doctorPhone,
                        _formatSymptomsForBooking(),
                      );
                    },
                  ),
                ),
              );
            }
            final chat = chats[index];
            final messageId = chat.id;
            return KeyedSubtree(
              key: _messageKeys.putIfAbsent(messageId, GlobalKey.new),
              child: chatBubble(chat),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget chatBubble(ChatMessage chat) {
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
                  Text(
                    chat.message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                    ),
                  ),
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
      ),
    );
  }

  Widget inputBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: TextField(
                controller: _controller,
                focusNode: _inputFocusNode,
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                  FocusManager.instance.primaryFocus?.unfocus();
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
                  suffixIcon: SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: SvgPicture.asset('assets/icons/mick.svg'),
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
            onTap: sendMessage,
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: 27,
              backgroundColor: const Color(0xff3F67FD),
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
    );
  }

  Future<void> sendMessage() async {
    FocusScope.of(context).unfocus();

    final message = _controller.text.trim();
    if (message.isEmpty) return;
    late String userMessageId;
    final createdMessage = await _chatRepository.addUserMessage(
      _conversationId,
      message,
    );
    if (!mounted) return;
    userMessageId = createdMessage.id;
    ref.invalidate(_chatMessagesProvider(_conversationId));

    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinMessageNearTop(userMessageId);
    });

    final aiResponse = await _chatRepository.generateAndStoreAiResponse(
      _conversationId,
      _userId,
    );
    if (!mounted) return;
    final intakeCompleted =
        aiResponse.stage == IntakeStage.completed ||
        aiResponse.summaryId != null;
    setState(() {
      // Always capture detected symptoms when intake is completed
      if (intakeCompleted) {
        _detectedSymptoms = aiResponse.detectedSymptoms;
      }
      if (aiResponse.summaryId != null) {
        _completedSummaryId = aiResponse.summaryId;
      }
      _latestIntakeCompleted = intakeCompleted;
    });
    await _chatRepository.saveChatToHistory(
      userId: _userId,
      userMessage: message,
      aiReply: aiResponse.rawText,
    );
    if (!mounted) return;
    ref.invalidate(_chatMessagesProvider(_conversationId));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinMessageNearTop(userMessageId, animated: false);
    });
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
    final target = _chatScrollController.position.maxScrollExtent + 140;
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
}

Widget doctorSuggestionCard(
  Doctor doctor,
  BuildContext context,
  String? aiSummaryId,
  String doctorPhone,
  String prefilledSymptoms,
) {
  return InkWell(
    onTap: () {
      FocusScope.of(context).unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DoctorDetailScreen(
            doctorId: doctor.id,
            aiSummaryId: aiSummaryId,
            prefilledSymptoms: prefilledSymptoms,
          ),
        ),
      ).then((_) {
        if (!context.mounted) return;
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      });
    },
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 250,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.1),
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
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    doctor.speciality,
                    style: TextStyle(
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
                      buildRatingStars(doctor.rating),
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
                        style: TextStyle(fontWeight: FontWeight.w400),
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
