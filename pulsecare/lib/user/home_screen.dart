import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pulsecare/constrains/primary_icon_button.dart';
import 'package:pulsecare/model/doctor_model.dart';
import 'package:pulsecare/model/rating_model.dart';
import 'package:pulsecare/model/user_model.dart';
import 'package:pulsecare/providers/session_provider.dart';
import '../providers/repository_providers.dart';
import 'package:pulsecare/user/ai_chat_screen.dart';
import 'package:pulsecare/user/app_shell.dart';
import 'package:pulsecare/user/doctor_detail_screen.dart';

final _homeDoctorsProvider = StreamProvider.autoDispose((ref) {
  return ref.read(doctorRepositoryProvider).watchAllDoctors();
});

final _homeUserProvider = StreamProvider.autoDispose.family<User?, String>((
  ref,
  userId,
) {
  return ref.read(userRepositoryProvider).watchUserById(userId);
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(sessionUserIdProvider);
    if (userId == null) {
      return const SizedBox.shrink();
    }
    final doctorsAsync = ref.watch(_homeDoctorsProvider);
    final userAsync = ref.watch(_homeUserProvider(userId));
    final doctors = doctorsAsync.valueOrNull ?? const <Doctor>[];
    final user = userAsync.valueOrNull;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;
    final aiCardHeight = isCompact ? 260.0 : 226.0;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${user?.fullName ?? ''}!',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      'How are you feeling today?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: InkWell(
                  onTap: () {
                    AppShell.of(context)?.switchToTab(3);
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Color.fromARGB(255, 210, 219, 255),
                    child: SvgPicture.asset(
                      'assets/icons/Avatar.svg',
                      width: 28,
                      height: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Container(
              height: aiCardHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(255, 174, 192, 255),
                    Color(0xFF3F67FD),
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      height: 220,
                      width: 209,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: AssetImage('assets/images/c_bg_lines.png'),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16, left: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            color: Colors.white,
                          ),
                          width: 50,
                          height: 50,
                          child: Center(
                            child: Image.asset(
                              'assets/images/msg.png',
                              color: Color(0xff3F67FD),
                              width: 30,
                              height: 30,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'AI Health Assistant',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: .w600,
                                ),
                              ),
                              Text(
                                'Support that\'s always available',
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: .w400,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat with AI Assistant',
                            style: TextStyle(
                              fontWeight: .w600,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Check your symptoms or book an appointment instantly using our advanced AI.',
                            maxLines: isCompact ? 4 : 3,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: .w400,
                            ),
                          ),
                          const Spacer(),
                          Center(
                            child: PrimaryIconButton(
                              text: 'Start Chat with Ai',
                              iconPath: 'assets/icons/s_msg.svg',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AiChatScreen(
                                      showDoctorRecommendations: true,
                                    ),
                                  ),
                                );
                              },
                              width: isCompact ? 240 : 260,
                              height: 50,
                              backgroundColor: Colors.white,
                              textColor: Color(0xff3F67FD),
                              iconColor: Color(0xff3F67FD),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 16, top: 16),
            child: Text(
              'Recommended Doctors',
              style: TextStyle(fontSize: 20, fontWeight: .w600),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: 32),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                return doctorCart(doctors[index], context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget navIcon(String assetPath, bool isSelected) {
  return SvgPicture.asset(
    assetPath,
    width: 26,
    height: 26,
    colorFilter: ColorFilter.mode(
      isSelected ? Color(0xFF3F67FD) : Colors.grey,
      BlendMode.srcIn,
    ),
  );
}

Widget doctorCart(Doctor doctor, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDetailScreen(doctorId: doctor.id),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 92,
                      height: 110,
                      child: Image.asset(doctor.image, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 18, fontWeight: .w700),
                        ),
                        Text(
                          doctor.speciality,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            Text(
                              'Experience:',
                              style: TextStyle(fontSize: 14, fontWeight: .w500),
                            ),
                            Text(
                              '${doctor.experience} Years',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            buildRatingStars(doctor.rating),
                            const SizedBox(width: 5),
                            Text(
                              doctor.rating.toStringAsFixed(1),
                              style: TextStyle(fontWeight: .w500, fontSize: 14),
                            ),
                            const SizedBox(width: 10),
                            const Text('|'),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${doctor.reviews} Reviews',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final buttonWidth = constraints.maxWidth < 290
                      ? constraints.maxWidth
                      : 290.0;
                  return Align(
                    alignment: Alignment.center,
                    child: PrimaryIconButton(
                      text: 'Start Chat With Ai',
                      iconPath: 'assets/images/chat.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AiChatScreen(
                              showDoctorRecommendations: false,
                            ),
                          ),
                        );
                      },
                      width: buttonWidth,
                      height: 50,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget buildRatingStars(double rating) {
  final ratingModel = RatingModel.fromRating(rating);

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ...List.generate(
        ratingModel.fullStars,
        (_) =>
            SvgPicture.asset('assets/icons/star_y.svg', height: 12, width: 12),
      ),
      if (ratingModel.hasHalfStar)
        SvgPicture.asset('assets/icons/star_hy.svg', height: 12, width: 12),
      ...List.generate(
        ratingModel.emptyStars,
        (_) =>
            SvgPicture.asset('assets/icons/star_iy.svg', height: 12, width: 12),
      ),
    ],
  );
}
