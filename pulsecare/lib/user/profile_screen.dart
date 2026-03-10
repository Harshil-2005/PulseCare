import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pulsecare/auth/auth_screen.dart';
import 'package:pulsecare/constrains/logout_delete.dart';
import 'package:pulsecare/providers/repository_providers.dart';
import 'package:pulsecare/providers/session_provider.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import 'package:pulsecare/user/edit_age.dart';
import 'package:pulsecare/user/edit_gender.dart';
import 'package:pulsecare/user/edit_phone.dart';
import 'package:pulsecare/user/edit_profile.dart';

final _profileUserProvider = StreamProvider.autoDispose.family((
  ref,
  String userId,
) {
  return ref.read(userRepositoryProvider).watchUserById(userId);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(sessionUserIdProvider);
    if (userId == null) {
      return const SizedBox.shrink();
    }
    final userAsync = ref.watch(_profileUserProvider(userId));

    return userAsync.when(
      data: (user) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 85,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          elevation: 0.3,
          title: Center(
            child: Text(
              'My Profile',
              style: TextStyle(fontSize: 20, fontWeight: .w600),
            ),
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
                      backgroundImage: AssetImage('assets/images/user.jpg'),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: TextStyle(fontWeight: .w600, fontSize: 22),
                        ),
                        SizedBox(height: 7),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontWeight: .w400,
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        SizedBox(height: 7),
                        InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfile(),
                              ),
                            );
                            ref.invalidate(_profileUserProvider(userId));
                          },
                          child: Container(
                            height: 30,
                            width: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Color(0xff3F67FD),
                            ),
                            child: Center(
                              child: Text(
                                'Edit Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: .w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: Offset(3, 3),
                      ),
                    ],
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
                        Text(
                          'Personal Information',
                          style: TextStyle(fontWeight: .w600, fontSize: 18),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 14),
                          child: InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditPhone(),
                                ),
                              );
                              ref.invalidate(_profileUserProvider(userId));
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Color.fromARGB(
                                    255,
                                    196,
                                    209,
                                    255,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icons/call.svg',
                                    width: 22,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Phone',
                                  style: TextStyle(
                                    fontWeight: .w400,
                                    fontSize: 16,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  user.phone,
                                  style: TextStyle(
                                    fontWeight: .w400,
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(width: 10),
                                SvgPicture.asset('assets/icons/right.svg'),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 2, color: Colors.grey.shade300),
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 14),
                          child: InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditAge(),
                                ),
                              );
                              ref.invalidate(_profileUserProvider(userId));
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Color.fromARGB(
                                    255,
                                    196,
                                    209,
                                    255,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icons/cake.svg',
                                    width: 22,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Age',
                                  style: TextStyle(
                                    fontWeight: .w400,
                                    fontSize: 16,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  user.age > 0 ? '${user.age}' : '',
                                  style: TextStyle(
                                    fontWeight: .w400,
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),

                                SizedBox(width: 10),
                                SvgPicture.asset('assets/icons/right.svg'),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 2, color: Colors.grey.shade300),
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 14),
                          child: InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditGender(),
                                ),
                              );
                              ref.invalidate(_profileUserProvider(userId));
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Color.fromARGB(
                                    255,
                                    196,
                                    209,
                                    255,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icons/gender.svg',
                                    width: 22,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'gender',
                                  style: TextStyle(
                                    fontWeight: .w400,
                                    fontSize: 16,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  user.gender,
                                  style: TextStyle(
                                    fontWeight: .w400,
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),

                                SizedBox(width: 10),
                                SvgPicture.asset('assets/icons/right.svg'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 36),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: Offset(3, 3),
                      ),
                    ],
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
                        Text(
                          'Settings',
                          style: TextStyle(fontWeight: .w600, fontSize: 18),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color.fromARGB(
                                  255,
                                  196,
                                  209,
                                  255,
                                ),
                                child: SvgPicture.asset(
                                  'assets/icons/shild.svg',
                                  width: 22,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  fontWeight: .w400,
                                  fontSize: 16,
                                ),
                              ),
                              Spacer(),

                              SvgPicture.asset('assets/icons/right.svg'),
                            ],
                          ),
                        ),
                        Divider(height: 2, color: Colors.grey.shade300),
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color.fromARGB(
                                  255,
                                  196,
                                  209,
                                  255,
                                ),
                                child: SvgPicture.asset(
                                  'assets/icons/help.svg',
                                  width: 22,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Help & Support',
                                style: TextStyle(
                                  fontWeight: .w400,
                                  fontSize: 16,
                                ),
                              ),
                              Spacer(),

                              SvgPicture.asset('assets/icons/right.svg'),
                            ],
                          ),
                        ),
                        Divider(height: 2, color: Colors.grey.shade300),
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 14),
                          child: InkWell(
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
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Color.fromARGB(
                                    255,
                                    196,
                                    209,
                                    255,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icons/log_out.svg',
                                    width: 22,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontWeight: .w400,
                                    fontSize: 16,
                                  ),
                                ),
                                Spacer(),
                                SvgPicture.asset('assets/icons/right.svg'),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 2, color: Colors.grey.shade300),
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 14),
                          child: InkWell(
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
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Color.fromARGB(
                                    255,
                                    196,
                                    209,
                                    255,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icons/delete.svg',
                                    width: 22,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Delete Account',
                                  style: TextStyle(
                                    fontWeight: .w400,
                                    fontSize: 16,
                                  ),
                                ),
                                Spacer(),
                                SvgPicture.asset('assets/icons/right.svg'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}
