import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pulsecare/constrains/app_avatar.dart';
import 'package:pulsecare/constrains/app_page_loader.dart';
import 'package:pulsecare/constrains/primary_icon_button.dart';
import 'package:pulsecare/constrains/skeleton_widgets.dart';
import 'package:pulsecare/domain/availability_engine.dart';
import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/model/doctor_availability.dart';
import 'package:pulsecare/model/doctor_model.dart';
import 'package:pulsecare/model/doctor_with_rating.dart';
import 'package:pulsecare/model/rating_model.dart';
import 'package:pulsecare/model/user_model.dart';
import 'package:pulsecare/providers/session_provider.dart';
import '../providers/repository_providers.dart';
import 'package:pulsecare/user/ai_chat_screen.dart';
import 'package:pulsecare/user/app_shell.dart';
import 'package:pulsecare/user/doctor_detail_screen.dart';

final _homeDoctorsProvider = StreamProvider<List<Doctor>>((ref) {
  // Recreate this provider when account/session changes to avoid stale doctor
  // list after logout/login without a full app restart.
  ref.watch(sessionUserIdProvider.select((userId) => userId));

  final doctorRepository = ref.read(doctorRepositoryProvider);
  return doctorRepository.watchAllDoctors();
});

final _homeDoctorAppointmentsProvider = StreamProvider.autoDispose
    .family<List<Appointment>, String>((ref, doctorId) {
      return ref
          .read(appointmentRepositoryProvider)
          .watchAppointmentsForDoctor(doctorId);
    });

final _homeDoctorWithRatingProvider = StreamProvider.autoDispose
    .family<DoctorWithRating, String>((ref, doctorId) {
      return ref.read(doctorRepositoryProvider).watchDoctorWithRating(doctorId);
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

  const weekdayNames = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  int? parseSlotMinutes(String raw) {
    final match = RegExp(
      r'^(0?[1-9]|1[0-2]):([0-5][0-9])\s?(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (match == null) return null;

    final hour12 = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();

    final baseHour = hour12 == 12 ? 0 : hour12;
    final hour24 = period == 'PM' ? baseHour + 12 : baseHour;
    return hour24 * 60 + minute;
  }

  bool hasAvailableSlots(DateTime date) {
    final slots = _availabilityEngine.generateSlots(
      doctor: doctor,
      date: date,
      appointments: appointments,
    );
    return slots.any((slot) {
      if (slot['status'] != SlotStatus.available) {
        return false;
      }

      final isToday =
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      if (!isToday) {
        return true;
      }

      final rawTime = (slot['time'] ?? '').toString();
      final slotMinutes = parseSlotMinutes(rawTime);
      if (slotMinutes == null) {
        return false;
      }

      final nowMinutes = now.hour * 60 + now.minute;
      return slotMinutes >= nowMinutes;
    });
  }

  DateTime? nextAvailableDate;
  for (var offset = 0; offset <= 60; offset++) {
    final date = today.add(Duration(days: offset));
    if (hasAvailableSlots(date)) {
      nextAvailableDate = date;
      break;
    }
  }

  if (nextAvailableDate == null) {
    return const _DoctorStatusUi(
      text: 'Not Available',
      color: Color(0xffE12D1D),
    );
  }

  final offsetDays = nextAvailableDate.difference(today).inDays;
  if (offsetDays == 0) {
    return const _DoctorStatusUi(
      text: 'Available Today',
      color: Color(0xff059669),
    );
  }

  final nextLabel = offsetDays == 1
      ? 'Tomorrow'
      : (offsetDays <= 7
            ? weekdayNames[nextAvailableDate.weekday - 1]
            : '${nextAvailableDate.day} ${monthNames[nextAvailableDate.month - 1]}');

  return _DoctorStatusUi(
    text: 'Available $nextLabel',
    color: const Color(0xffF59E0B),
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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(sessionUserIdProvider);
    if (userId == null) {
      return const AppPageLoader(message: 'Preparing your dashboard...');
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: HomeHeader(
                userId: userId,
                onAvatarTap: () {
                  AppShell.of(context)?.switchToTab(3);
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Container(
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
                    children: [
                      Positioned(
                        top: 0,
                        right: 0,
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                            const SizedBox(height: 16),
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
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            DoctorListSection(
              searchQuery: _searchQuery,
              selectedSpecialization: _selectedSpecialization,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              onSpecializationChanged: (value) {
                setState(() {
                  _selectedSpecialization = value;
                });
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class HomeHeader extends ConsumerWidget {
  const HomeHeader({
    super.key,
    required this.userId,
    required this.onAvatarTap,
  });

  final String userId;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(_homeUserProvider(userId));
    if (userAsync.isLoading) {
      return const _HomeHeaderSkeleton();
    }
    final user = userAsync.valueOrNull;

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${user?.fullName ?? ''}!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
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
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: InkWell(
            onTap: onAvatarTap,
            child: AppAvatar(
              radius: 28,
              name: user?.fullName,
              imagePath: user?.avatarPath,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeHeaderSkeleton extends StatelessWidget {
  const _HomeHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 150, height: 24, radius: 8),
              SizedBox(height: 10),
              SkeletonBox(width: 190, height: 16, radius: 8),
            ],
          ),
        ),
        Spacer(),
        Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: SkeletonBox(width: 56, height: 56, radius: 28),
        ),
      ],
    );
  }
}

class _DoctorListSectionSkeleton extends StatelessWidget {
  const _DoctorListSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverAppBar(
          pinned: true,
          primary: false,
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 58,
          titleSpacing: 0,
          title: const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: SkeletonBox(height: 52, radius: 30),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(58),
            child: Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
              child: Row(
                children: [
                  Expanded(child: SkeletonBox(height: 34, radius: 30)),
                  SizedBox(width: 8),
                  Expanded(child: SkeletonBox(height: 34, radius: 30)),
                  SizedBox(width: 8),
                  Expanded(child: SkeletonBox(height: 34, radius: 30)),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8, top: 12),
            child: SkeletonBox(width: 190, height: 22, radius: 8),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return DoctorRecommendationCardSkeleton(
              topPadding: index == 0 ? 0 : 16,
            );
          }, childCount: 3),
        ),
      ],
    );
  }
}

class DoctorListSection extends ConsumerWidget {
  const DoctorListSection({
    super.key,
    required this.searchQuery,
    required this.selectedSpecialization,
    required this.onSearchChanged,
    required this.onSpecializationChanged,
  });

  final String searchQuery;
  final String selectedSpecialization;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSpecializationChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(_homeDoctorsProvider);
    return doctorsAsync.when(
      data: (doctors) {
        final specializations =
            doctors.map((doctor) => doctor.speciality).toSet().toList()..sort();
        final chipLabels = ['All', ...specializations];
        final activeSpecialization = chipLabels.contains(selectedSpecialization)
            ? selectedSpecialization
            : 'All';

        final filteredDoctors = doctors.where((doctor) {
          final matchesSearch =
              doctor.name.toLowerCase().contains(searchQuery) ||
              doctor.speciality.toLowerCase().contains(searchQuery);

          final matchesFilter =
              activeSpecialization == 'All' ||
              doctor.speciality == activeSpecialization;

          return matchesSearch && matchesFilter;
        }).toList();

        if (doctors.isEmpty) {
          return SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8, top: 12),
                  child: Text(
                    'Doctors coming soon',
                    style: TextStyle(fontSize: 20, fontWeight: .w600),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No doctors available yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: .w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "We're onboarding doctors. Try AI assistant for help.",
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.35,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: PrimaryIconButton(
                            text: 'Start AI Chat',
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
                            width: 200,
                            height: 46,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final slivers = <Widget>[
          SliverAppBar(
            pinned: true,
            primary: false,
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
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
                  fillColor: Colors.grey.shade300,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: onSearchChanged,
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
                          child: _HomeFilterChip(
                            label: label,
                            activeSpecialization: activeSpecialization,
                            onSelected: onSpecializationChanged,
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
                  final withRatingAsync = ref.watch(
                    _homeDoctorWithRatingProvider(doctor.id),
                  );
                  final appointments =
                      appointmentsAsync.valueOrNull ?? const <Appointment>[];
                  final withRating = withRatingAsync.valueOrNull;
                  final doctorForCard = withRating?.doctor ?? doctor;
                  final rating = withRating?.rating ?? doctor.rating;
                  final reviewCount = withRating?.reviewCount ?? doctor.reviews;
                  final status = _resolveDoctorStatus(
                    doctor: doctorForCard,
                    appointments: appointments,
                  );
                  return _doctorCart(
                    doctorForCard,
                    context,
                    status,
                    rating: rating,
                    reviewCount: reviewCount,
                    topPadding: index == 0 ? 0 : 16,
                  );
                },
              );
            }, childCount: filteredDoctors.length),
          ),
        ];

        return SliverMainAxisGroup(slivers: slivers);
      },
      loading: () => const _DoctorListSectionSkeleton(),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text(e.toString())),
        ),
      ),
    );
  }
}

class _HomeFilterChip extends StatelessWidget {
  const _HomeFilterChip({
    required this.label,
    required this.activeSpecialization,
    required this.onSelected,
  });

  final String label;
  final String activeSpecialization;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const chatButtonBlue = Color(0xFF3F67FD);
    final isSelected = activeSpecialization == label;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      checkmarkColor: chatButtonBlue,
      selectedColor: chatButtonBlue.withValues(alpha: 0.15),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      labelStyle: TextStyle(
        color: isSelected ? chatButtonBlue : Colors.grey.shade700,
      ),
      onSelected: (_) => onSelected(label),
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

Widget _doctorCart(
  Doctor doctor,
  BuildContext context,
  _DoctorStatusUi status, {
  required double rating,
  required int reviewCount,
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
                      child: ColoredBox(
                        color: const Color(0xFFF2F4F7),
                        child: Center(
                          child: AppAvatar(
                            radius: 34,
                            name: doctor.name,
                            imagePath: doctor.image,
                          ),
                        ),
                      ),
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
                            buildRatingStars(rating),
                            const SizedBox(width: 5),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(fontWeight: .w500, fontSize: 14),
                            ),
                            const SizedBox(width: 10),
                            const Text('|'),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                reviewCount == 0
                                    ? 'No reviews'
                                    : '$reviewCount Reviews',
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
