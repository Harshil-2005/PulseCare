import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/user/chat_history_screen.dart';
import 'package:pulsecare/user/doctor_detail_screen.dart';
import 'package:pulsecare/user/new_ai_chat_screen.dart';
import 'package:pulsecare/user/widgets/consultation_chat_widget.dart';

class AiChatScreen extends StatelessWidget {
  final bool showDoctorRecommendations;
  final String? doctorId;
  final String? initialMessage;

  const AiChatScreen({
    super.key,
    this.showDoctorRecommendations = true,
    this.doctorId,
    this.initialMessage,
  });

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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewAiChatScreen(),
                  ),
                );
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
                );
              },
              child: SvgPicture.asset('assets/icons/history.svg', height: 18),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
      body: ConsultationChatWidget(
        conversationId: '',
        userId: '',
        initialMessage: initialMessage,
        showDoctorRecommendations: showDoctorRecommendations,
        doctorId: doctorId,
        onContinueBooking: (selectedDoctorId, summaryId) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorDetailScreen(
                doctorId: selectedDoctorId,
                aiSummaryId: summaryId,
              ),
            ),
          );
        },
      ),
    );
  }
}
