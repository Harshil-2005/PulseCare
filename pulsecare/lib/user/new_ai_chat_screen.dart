import 'package:flutter/material.dart';
import 'package:pulsecare/utils/keyboard_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/user/chat_history_screen.dart';
import 'package:pulsecare/user/widgets/consultation_chat_widget.dart';

class NewAiChatScreen extends ConsumerStatefulWidget {
  const NewAiChatScreen({super.key});

  @override
  ConsumerState<NewAiChatScreen> createState() => _NewAiChatScreenState();
}

class _NewAiChatScreenState extends ConsumerState<NewAiChatScreen> {
  static const double _introBottomPadding = 220;
  bool _hasStartedConsultation = false;
  bool _hasAnyUserMessage = false;

  @override
  Widget build(BuildContext context) {
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
          onPressed: () {
            KeyboardUtils.hideKeyboardKeepFocus();
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
                KeyboardUtils.hideKeyboardKeepFocus();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewAiChatScreen(),
                  ),
                );
              },
              child: SvgPicture.asset('assets/icons/new_chat.svg', height: 20),
            ),
            const SizedBox(width: 14),
            InkWell(
              onTap: () {
                KeyboardUtils.hideKeyboardKeepFocus();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatHistoryScreen(),
                  ),
                );
              },
              child: SvgPicture.asset('assets/icons/history.svg', height: 18),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ConsultationChatWidget(
                conversationId: '',
                userId: '',
                showDoctorRecommendations: true,
                showDisclaimer: false,
                hideSeedGreeting: true,
                showIntroUntilConsultationStarts: true,
                showIntro: !_hasStartedConsultation,
                introBuilder: (_) => introContent(),
                introBottomPadding: _introBottomPadding,
                inputBottomPadding: 0,
                trailingBottomSpacer: 30,
                onConsultationStarted: () {
                  if (!_hasStartedConsultation) {
                    setState(() {
                      _hasStartedConsultation = true;
                    });
                  }
                },
                onHasAnyUserMessageChanged: (hasAnyUserMessage) {
                  if (_hasAnyUserMessage != hasAnyUserMessage) {
                    setState(() {
                      _hasAnyUserMessage = hasAnyUserMessage;
                      _hasStartedConsultation =
                          _hasStartedConsultation || hasAnyUserMessage;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
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
}
