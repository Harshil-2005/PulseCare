import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/user/chat_history_screen.dart';

class NewAiChatScreen extends StatelessWidget {
  const NewAiChatScreen({super.key});

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
            InkWell(onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => NewAiChatScreen()));
            },
              child: SvgPicture.asset('assets/icons/new_chat.svg', height: 20)),
            const SizedBox(width: 14),
            InkWell(onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatHistoryScreen()));
            },
              child: SvgPicture.asset('assets/icons/history.svg', height: 18)),
            const SizedBox(width: 10),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: introContent()),
          inputBar(),
          const SizedBox(height: 30),
        ],
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

  Widget inputBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
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
          CircleAvatar(
            radius: 27,
            backgroundColor: const Color(0xff3F67FD),
            child: SvgPicture.asset(
              'assets/icons/send.svg',
              height: 24,
              width: 24,
            ),
          ),
        ],
      ),
    );
  }
}
