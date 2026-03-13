import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pulsecare/constrains/primary_icon_button.dart';
import 'package:pulsecare/domain/availability_engine.dart';
import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/model/doctor_availability.dart';
import 'package:pulsecare/model/doctor_model.dart';
import 'package:pulsecare/model/rating_model.dart';
import 'package:pulsecare/model/user_model.dart';
import 'package:pulsecare/providers/session_provider.dart';
import '../providers/repository_providers.dart';
import 'package:pulsecare/user/ai_chat_screen.dart';
import 'package:pulsecare/user/app_shell.dart';
import 'package:pulsecare/user/doctor_detail_screen.dart';

final _homeDoctorsProvider = StreamProvider.autoDispose<List<Doctor>>((ref) {
  // Recreate this provider when account/session changes to avoid stale doctor
  // list after logout/login without a full app restart.
  ref.watch(sessionUserIdProvider);

  final doctorRepository = ref.watch(doctorRepositoryProvider);
  return doctorRepository.watchAllDoctors();
});

final _homeDoctorAppointmentsProvider = StreamProvider.autoDispose
    .family<List<Appointment>, String>((ref, doctorId) {
      return ref
          .read(appointmentRepositoryProvider)
          .watchAppointmentsForDoctor(doctorId);
    });

final AvailabilityEngine _availabilityEngine = AvailabilityEngine();

class _DoctorStatusUi {
  const _DoctorStatusUi({required this.text, required this.color});

  final String text;
  final Color color;
}

_DoctorStatusUi _resolveDoctorStatus({
  required Doctor doctor,
  required List<Appointment> appointments,
}) {
  if (!doctor.isAvailableForBooking) {
    return const _DoctorStatusUi(
      text: 'Not Available',
      color: Color(0xffE12D1D),
    );
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final slots = _availabilityEngine.generateSlots(
    doctor: doctor,
    date: today,
    appointments: appointments,
  );

  final hasAvailableToday = slots.any(
    (slot) => slot['status'] == SlotStatus.available,
  );

  if (hasAvailableToday) {
    return const _DoctorStatusUi(
      text: 'Available Today',
      color: Color(0xff059669),
    );
  }

  return const _DoctorStatusUi(
    text: 'Next Available Tomorrow',
    color: Color(0xffF59E0B),
  );
}

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
  String _searchQuery = '';
  String _selectedSpecialization = 'All';

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required String activeSpecialization,
  }) {
    const chatButtonBlue = Color(0xFF3F67FD);
    final isSelected = activeSpecialization == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      checkmarkColor: chatButtonBlue,
      selectedColor: chatButtonBlue.withValues(alpha: 0.15),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      labelStyle: TextStyle(
        color: isSelected ? chatButtonBlue : Colors.grey.shade700,
      ),
      onSelected: (_) {
        setState(() {
          _selectedSpecialization = label;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(sessionUserIdProvider);
    if (userId == null) {
      return const SizedBox.shrink();
    }
    final doctorsAsync = ref.watch(_homeDoctorsProvider);
    final userAsync = ref.watch(_homeUserProvider(userId));
    final doctors = doctorsAsync.valueOrNull ?? const <Doctor>[];
    final specializations =
        doctors.map((doctor) => doctor.speciality).toSet().toList()..sort();
    final chipLabels = ['All', ...specializations];
    final activeSpecialization = chipLabels.contains(_selectedSpecialization)
        ? _selectedSpecialization
        : 'All';
    final filteredDoctors = doctors.where((doctor) {
      final matchesSearch =
          doctor.name.toLowerCase().contains(_searchQuery) ||
          doctor.speciality.toLowerCase().contains(_searchQuery);

      final matchesFilter =
          activeSpecialization == 'All' ||
          doctor.speciality == activeSpecialization;

      return matchesSearch && matchesFilter;
    }).toList();
    final user = userAsync.valueOrNull;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;
    final aiCardHeight = isCompact ? 260.0 : 226.0;

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
            ),
            SliverToBoxAdapter(
              child: Padding(
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
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
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
                                        builder: (context) =>
                                            const AiChatScreen(
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
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverAppBar(
              pinned: true,
              primary: false,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 58,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search doctors or specialization',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(58),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final label in chipLabels)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(
                              context: context,
                              label: label,
                              activeSpecialization: activeSpecialization,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8, top: 12),
                child: Text(
                  'Recommended Doctors',
                  style: TextStyle(fontSize: 20, fontWeight: .w600),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final doctor = filteredDoctors[index];
                return Consumer(
                  builder: (context, ref, _) {
                    final appointmentsAsync = ref.watch(
                      _homeDoctorAppointmentsProvider(doctor.id),
                    );
                    final appointments =
                        appointmentsAsync.valueOrNull ?? const <Appointment>[];
                    final status = _resolveDoctorStatus(
                      doctor: doctor,
                      appointments: appointments,
                    );
                    return doctorCart(
                      doctor,
                      context,
                      status,
                      topPadding: index == 0 ? 0 : 16,
                    );
                  },
                );
              }, childCount: filteredDoctors.length),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
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

Widget doctorCart(
  Doctor doctor,
  BuildContext context,
  _DoctorStatusUi status, {
  double topPadding = 16,
}) {
  return Padding(
    padding: EdgeInsets.only(top: topPadding, left: 16, right: 16),
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
                      height: 126,
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: status.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status.text,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: status.color,
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
                            builder: (context) => AiChatScreen(
                              showDoctorRecommendations: false,
                              doctorId: doctor.id,
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
