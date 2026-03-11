import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pulsecare/auth/auth_screen.dart';
import 'package:pulsecare/constrains/logout_delete.dart';
import 'package:pulsecare/doctor/doctor_full_edit_flow_screen.dart';
import 'package:pulsecare/doctor/screens/edit_about_screen.dart';
import 'package:pulsecare/providers/session_provider.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import '../../providers/repository_providers.dart';

final _doctorProfileDoctorProvider = StreamProvider.autoDispose.family((
  ref,
  String userId,
) {
  return ref.read(doctorRepositoryProvider).watchDoctorByUserId(userId);
});

final _doctorProfileUserProvider = StreamProvider.autoDispose.family((
  ref,
  String userId,
) {
  return ref.read(userRepositoryProvider).watchUserById(userId);
});

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key, required this.doctorId});

  final String doctorId;

  static const List<BoxShadow> profileCardShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.1),
      blurRadius: 10,
      offset: Offset(3, 3),
    ),
  ];

  @override
  ConsumerState<DoctorProfileScreen> createState() =>
      _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  Widget _profileRow({
    required String iconPath,
    required String title,
    String? value,
    VoidCallback? onTap,
    Color? iconColor,
    double iconSize = 22,
    bool emboldenIcon = false,
    bool showDivider = true,
  }) {
    final icon = SvgPicture.asset(
      iconPath,
      width: iconSize,
      height: iconSize,
      fit: BoxFit.contain,
      colorFilter: iconColor == null
          ? null
          : ColorFilter.mode(iconColor, BlendMode.srcIn),
    );

    final row = Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color.fromARGB(255, 196, 209, 255),
          child: emboldenIcon
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    icon,
                    Transform.translate(
                      offset: const Offset(0.35, 0),
                      child: icon,
                    ),
                  ],
                )
              : icon,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 16),
        ),
        const Spacer(),
        if (value != null) ...[
          SizedBox(
            width: 120,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        SvgPicture.asset('assets/icons/right.svg'),
      ],
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 14),
          child: onTap == null ? row : InkWell(onTap: onTap, child: row),
        ),
        if (showDivider) Divider(height: 2, color: Colors.grey.shade300),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(sessionUserIdProvider);
    if (userId == null) {
      return const SizedBox.shrink();
    }
    final doctorAsync = ref.watch(_doctorProfileDoctorProvider(userId));
    return doctorAsync.when(
      data: (doctor) {
        if (doctor == null) {
          return const Scaffold(body: Center(child: Text('Doctor not found')));
        }
        final userAsync = ref.watch(_doctorProfileUserProvider(doctor.userId));
        final user = userAsync.valueOrNull;
        final firstName = user?.firstName.trim() ?? '';
        final lastName = user?.lastName.trim() ?? '';
        final fullName = [
          firstName,
          lastName,
        ].where((part) => part.isNotEmpty).join(' ').trim();
        final fallbackName = doctor.name.trim();
        final displayName = fullName.isNotEmpty
            ? 'Dr. $fullName'
            : (fallbackName.startsWith('Dr.')
                  ? fallbackName
                  : 'Dr. $fallbackName');
        final email = user?.email ?? '';
        final experience = '${doctor.experience} Years';
        final specialization = doctor.speciality;
        final hospital = doctor.address;
        final feeValue = doctor.consultationFee % 1 == 0
            ? doctor.consultationFee.toStringAsFixed(0)
            : doctor.consultationFee.toStringAsFixed(2);
        final fee = '\u20B9$feeValue';
        final slotDuration = '${doctor.slotDuration} minutes';

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 85,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            elevation: 0.3,
            centerTitle: true,
            title: const Text(
              'My Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            shadowColor: Colors.black,
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 34,
                    left: 16,
                    bottom: 30,
                    right: 16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage(doctor.image),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 7),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 7),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const DoctorFullEditFlowScreen(
                                          initialStep: 0,
                                          singleStepMode: false,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                height: 30,
                                width: 90,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: const Color(0xff3F67FD),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 24,
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: DoctorProfileScreen.profileCardShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 20,
                        bottom: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          _profileRow(
                            iconPath: 'assets/icons/call.svg',
                            title: 'Phone',
                            value: user?.phone ?? '',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const DoctorFullEditFlowScreen(
                                        initialStep: 1,
                                        singleStepMode: true,
                                      ),
                                ),
                              );
                            },
                          ),
                          _profileRow(
                            iconPath: 'assets/icons/cake.svg',
                            title: 'Age',
                            value: '${user?.age ?? ''}',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const DoctorFullEditFlowScreen(
                                        initialStep: 2,
                                        singleStepMode: true,
                                      ),
                                ),
                              );
                            },
                          ),
                          _profileRow(
                            iconPath: 'assets/icons/gender.svg',
                            title: 'Gender',
                            value: user?.gender ?? '',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const DoctorFullEditFlowScreen(
                                        initialStep: 3,
                                        singleStepMode: true,
                                      ),
                                ),
                              );
                            },
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 24,
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: DoctorProfileScreen.profileCardShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 20,
                        bottom: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Professional Information',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          _profileRow(
                            iconPath: 'assets/icons/experiance.svg',
                            title: 'Experience',
                            value: experience,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const DoctorFullEditFlowScreen(
                                        initialStep: 4,
                                        singleStepMode: true,
                                      ),
                                ),
                              );
                            },
                            iconColor: const Color(0xff3F67FD),
                          ),
                          _profileRow(
                            iconPath: 'assets/icons/specialization.svg',
                            title: 'Specialization',
                            value: specialization,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const DoctorFullEditFlowScreen(
                                        initialStep: 5,
                                        singleStepMode: true,
                                      ),
                                ),
                              );
                            },
                            iconColor: const Color(0xff3F67FD),
                          ),
                          _profileRow(
                            iconPath: 'assets/icons/location.svg',
                            title: 'Hospital',
                            value: hospital,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const DoctorFullEditFlowScreen(
                                        initialStep: 6,
                                        singleStepMode: true,
                                      ),
                                ),
                              );
                            },
                          ),
                          _profileRow(
                            iconPath: 'assets/icons/about.svg',
                            title: 'About',
                            value: doctor.about,
                            iconSize: 24,
                            iconColor: const Color(0xff3F67FD),
                            emboldenIcon: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditAboutScreen(),
                                ),
                              );
                            },
                          ),
                          _profileRow(
                            iconPath: 'assets/icons/money.svg',
                            title: 'Consultation Fee',
                            value: fee,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const DoctorFullEditFlowScreen(
                                        initialStep: 7,
                                        singleStepMode: true,
                                      ),
                                ),
                              );
                            },
                          ),
                          _profileRow(
                            iconPath: 'assets/icons/round.svg',
                            title: 'Slot Duration',
                            value: slotDuration,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const DoctorFullEditFlowScreen(
                                        initialStep: 8,
                                        singleStepMode: true,
                                      ),
                                ),
                              );
                            },
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 36,
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: DoctorProfileScreen.profileCardShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 20,
                        bottom: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Settings',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          _profileRow(
                            iconPath: 'assets/icons/shild.svg',
                            title: 'Privacy Policy',
                          ),
                          _profileRow(
                            iconPath: 'assets/icons/help.svg',
                            title: 'Help & Support',
                          ),
                          _profileRow(
                            iconPath: 'assets/icons/log_out.svg',
                            title: 'Logout',
                            onTap: () {
                              showConfirmationDialog(
                                context,
                                title: 'Log Out',
                                message: 'Are you sure you want to log out?',
                                iconPath: 'assets/icons/log_out.svg',
                                confirmText: 'Yes, Logout',
                                onConfirm: () {
                                  final authRepository = ref.read(
                                    authRepositoryProvider,
                                  );
                                  authRepository.logout().then((_) {
                                    if (!context.mounted) return;
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AuthScreen(),
                                      ),
                                      (route) => false,
                                    );
                                    SessionRepository().clearSession();
                                    ref
                                            .read(
                                              sessionUserIdProvider.notifier,
                                            )
                                            .state =
                                        null;
                                  });
                                },
                              );
                            },
                          ),
                          _profileRow(
                            iconPath: 'assets/icons/delete.svg',
                            title: 'Delete Account',
                            onTap: () {
                              showConfirmationDialog(
                                context,
                                title: 'Delete Account',
                                message:
                                    'Are you sure you want to delete your account?',
                                iconPath: 'assets/icons/delete.svg',
                                confirmText: 'Yes, Delete',
                                onConfirm: () async {
                                  final loadingContext = context;
                                  showDialog(
                                    context: loadingContext,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                  final sessionRepository = SessionRepository();
                                  final authRepository = ref.read(
                                    authRepositoryProvider,
                                  );
                                  final reportRepository = ref.read(
                                    reportRepositoryProvider,
                                  );
                                  final doctorRepository = ref.read(
                                    doctorRepositoryProvider,
                                  );
                                  final userRepository = ref.read(
                                    userRepositoryProvider,
                                  );
                                  final activeUserId = sessionRepository
                                      .getCurrentUserId();
                                  try {
                                    await authRepository.deleteAccount(
                                      userId: activeUserId,
                                      reportRepository: reportRepository,
                                      doctorRepository: doctorRepository,
                                      userRepository: userRepository,
                                      sessionRepository: sessionRepository,
                                    );
                                    if (!loadingContext.mounted) return;
                                    Navigator.of(loadingContext).pop();
                                    Navigator.of(
                                      loadingContext,
                                    ).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (_) => const AuthScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  } catch (_) {
                                    if (!loadingContext.mounted) return;
                                    Navigator.of(loadingContext).pop();
                                    ScaffoldMessenger.of(
                                      loadingContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Unable to delete account. Please try again.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}
