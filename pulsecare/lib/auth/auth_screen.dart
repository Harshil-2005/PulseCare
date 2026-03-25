import 'package:flutter/material.dart';
import 'package:pulsecare/utils/keyboard_utils.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsecare/accountsetup/account_setup_flow_screen.dart';
import 'package:pulsecare/constrains/app_toast.dart';
import 'package:pulsecare/constrains/app_text_field.dart';
import 'package:pulsecare/constrains/next_action_button.dart';
import 'package:pulsecare/constrains/toggle_button.dart';
import 'package:pulsecare/doctor/doctor_app_shell.dart';
import 'package:pulsecare/model/user_model.dart';
import 'package:pulsecare/providers/repository_providers.dart';
import 'package:pulsecare/providers/session_provider.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import 'package:pulsecare/user/app_shell.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final bool startWithRegister;

  const AuthScreen({super.key, this.startWithRegister = false});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  static const String _busyActionRegister = 'register';
  static const String _busyActionLogin = 'login';
  static const String _busyActionGoogle = 'google';

  late PageController _pageController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  int currentPage = 0;

  final nameController = TextEditingController();
  final registeremailController = TextEditingController();
  final loginemailController = TextEditingController();
  final registerpasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final loginpasswordController = TextEditingController();
  final _loginEmailFocus = FocusNode();
  final _registerEmailFocus = FocusNode();

  bool isConfirmPasswordVisible = false;
  bool isRegisterPasswordVisible = false;

  bool isLoginPasswordVisible = false;
  bool _loginSubmitted = false;
  bool _registerSubmitted = false;
  bool _loginEmailTouched = false;
  bool _registerEmailTouched = false;
  bool _authBusy = false;
  String? _busyAction;

  @override
  void initState() {
    super.initState();
    currentPage = widget.startWithRegister ? 1 : 0;
    _pageController = PageController(initialPage: currentPage);
    _loginEmailFocus.addListener(() {
      if (!_loginEmailFocus.hasFocus &&
          loginemailController.text.trim().isNotEmpty) {
        setState(() {
          _loginEmailTouched = true;
        });
      }
    });
    _registerEmailFocus.addListener(() {
      if (!_registerEmailFocus.hasFocus &&
          registeremailController.text.trim().isNotEmpty) {
        setState(() {
          _registerEmailTouched = true;
        });
      }
    });
  }

  void goToLogin() {
    setState(() {
      _loginSubmitted = false;
      _registerSubmitted = false;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void goToRegister() {
    setState(() {
      _loginSubmitted = false;
      _registerSubmitted = false;
    });
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleRegisterSubmit() async {
    setState(() {
      _registerSubmitted = true;
    });

    if (!(_registerFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final authRepository = ref.read(authRepositoryProvider);
    if (mounted) {
      setState(() {
        _authBusy = true;
        _busyAction = _busyActionRegister;
      });
    }

    try {
      final uid = await authRepository.register(
        registeremailController.text.trim(),
        registerpasswordController.text.trim(),
      );

      final sessionRepository = SessionRepository();
      await sessionRepository.setCurrentUser(uid);

      if (!mounted) return;
      goToLogin();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Registration failed. Please try again.';
      if (e.code == 'email-already-in-use') {
        message =
            'This email is already registered. Please log in or continue with Google.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address and try again.';
      } else if (e.code == 'weak-password') {
        message =
            'Password is too weak. Use at least 6 characters and try again.';
      }
      showAppToast(context, message, position: AppToastPosition.top);
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        context,
        'Registration failed. Please try again.',
        position: AppToastPosition.top,
      );
    } finally {
      if (mounted) {
        setState(() {
          _authBusy = false;
          _busyAction = null;
        });
      }
    }
  }

  Future<void> _handleLoginSubmit() async {
    setState(() {
      _loginSubmitted = true;
    });

    if (!(_loginFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final authRepository = ref.read(authRepositoryProvider);
    if (mounted) {
      setState(() {
        _authBusy = true;
        _busyAction = _busyActionLogin;
      });
    }

    try {
      final uid = await authRepository.login(
        loginemailController.text.trim(),
        loginpasswordController.text.trim(),
      );

      final sessionRepository = SessionRepository();
      await sessionRepository.setCurrentUser(uid);
      ref.read(sessionUserIdProvider.notifier).state = uid;

      await _navigateAfterLogin(uid);
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        'Login failed. Please check your credentials.',
        position: AppToastPosition.top,
      );
    } finally {
      if (mounted) {
        setState(() {
          _authBusy = false;
          _busyAction = null;
        });
      }
    }
  }

  Future<void> _navigateAfterLogin(String uid) async {
    final userRepository = ref.read(userRepositoryProvider);

    User? existingUser;
    try {
      existingUser = await userRepository.getUserById(uid);
    } catch (_) {
      existingUser = null;
    }

    if (!mounted) return;

    if (existingUser != null) {
      if (existingUser.role == 'doctor') {
        final doctor = await ref
            .read(doctorRepositoryProvider)
            .getDoctorByUserId(uid);
        if (!mounted) return;

        if (doctor != null) {
          final sessionRepository = SessionRepository();
          await sessionRepository.clearSession();
          await sessionRepository.setCurrentUser(uid);
          await sessionRepository.setCurrentDoctor(doctor.id);
          await sessionRepository.setRole('doctor');
          ref.read(sessionUserIdProvider.notifier).state = uid;
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorAppShell(
                doctorId: doctor.id,
                initialSchedule: doctor.schedule,
              ),
            ),
            (route) => false,
          );
          return;
        }
      } else {
        final sessionRepository = SessionRepository();
        await sessionRepository.clearSession();
        await sessionRepository.setCurrentUser(uid);
        await sessionRepository.setRole('patient');
        ref.read(sessionUserIdProvider.notifier).state = uid;
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AppShell()),
          (route) => false,
        );
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AccountSetupFlowScreen()),
    );
  }

  void _autoCapitalizeRegisterName(String value) {
    if (value.isEmpty) return;
    final updated = '${value[0].toUpperCase()}${value.substring(1)}';
    if (updated == value) return;

    nameController.value = nameController.value.copyWith(
      text: updated,
      selection: TextSelection.collapsed(offset: updated.length),
      composing: TextRange.empty,
    );
  }

  String? _validateName(String? value) {
    if (!_registerSubmitted) return null;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Name is required';
    if (text.length < 2) return 'Enter at least 2 characters';
    return null;
  }

  String? _validateLoginEmail(String? value) {
    if (!_loginSubmitted && !_loginEmailTouched) return null;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(text)) return 'Enter a valid email';
    return null;
  }

  String? _validateRegisterEmail(String? value) {
    if (!_registerSubmitted && !_registerEmailTouched) return null;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(text)) return 'Enter a valid email';
    return null;
  }

  String? _validateLoginPassword(String? value) {
    if (!_loginSubmitted) return null;
    final text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < 6) return 'Minimum 6 characters';
    return null;
  }

  String? _validateRegisterPassword(String? value) {
    if (!_registerSubmitted) return null;
    final text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < 6) return 'Minimum 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_registerSubmitted) return null;
    final text = value ?? '';
    if (text.isEmpty) return 'Confirm your password';
    if (text != registerpasswordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  Widget _loginForm() {
    return Form(
      key: _loginFormKey,
      autovalidateMode: AutovalidateMode.always,
      child: Column(
        children: [
          AppTextField(
            controller: loginemailController,
            focusNode: _loginEmailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: _validateLoginEmail,
            hintText: 'Email',
            prefixIconPath: 'assets/icons/email.svg',
            prefixIconColor: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: loginpasswordController,
            hintText: 'Password',

            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            validator: _validateLoginPassword,
            prefixIconPath: 'assets/icons/lock.svg',
            prefixIconColor: Colors.grey.shade400,
            suffixIconColor: Colors.grey.shade400,
            obscureText: !isLoginPasswordVisible,
            suffixIconPath: isLoginPasswordVisible
                ? 'assets/icons/eye_check.svg'
                : 'assets/icons/eye.svg',
            onSuffixTap: () {
              setState(() {
                isLoginPasswordVisible = !isLoginPasswordVisible;
              });
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Forgot password?",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _registerForm() {
    return Form(
      key: _registerFormKey,
      autovalidateMode: AutovalidateMode.always,
      child: Column(
        children: [
          AppTextField(
            controller: nameController,
            hintText: 'Name',
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: _validateName,
            onChanged: _autoCapitalizeRegisterName,
            prefixIconPath: 'assets/icons/person.svg',
            prefixIconColor: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: registeremailController,
            focusNode: _registerEmailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: _validateRegisterEmail,
            hintText: 'Email',
            prefixIconPath: 'assets/icons/email.svg',
            prefixIconColor: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: registerpasswordController,
            hintText: 'Password',
            obscureText: !isRegisterPasswordVisible,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: _validateRegisterPassword,
            prefixIconPath: 'assets/icons/lock.svg',
            prefixIconColor: Colors.grey.shade400,
            suffixIconPath: 'assets/icons/eye.svg',
            suffixIconColor: Colors.grey.shade400,
            onSuffixTap: () {
              setState(() {
                isRegisterPasswordVisible = !isRegisterPasswordVisible;
              });
            },
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: confirmPasswordController,
            hintText: 'Confirm Password',
            obscureText: !isConfirmPasswordVisible,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            validator: _validateConfirmPassword,
            prefixIconPath: 'assets/icons/lock.svg',
            prefixIconColor: Colors.grey.shade400,
            suffixIconPath: !isConfirmPasswordVisible
                ? 'assets/icons/eye_check.svg'
                : 'assets/icons/eye.svg',
            suffixIconColor: Colors.grey.shade400,
            onSuffixTap: () {
              setState(() {
                isConfirmPasswordVisible = !isConfirmPasswordVisible;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _loginEmailFocus.dispose();
    _registerEmailFocus.dispose();
    _pageController.dispose();
    loginemailController.dispose();
    registeremailController.dispose();
    nameController.dispose();
    loginpasswordController.dispose();
    registerpasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isRegister = currentPage == 1;
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      resizeToAvoidBottomInset: true,

      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          KeyboardUtils.hideKeyboardKeepFocus();
        },
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
            child: SizedBox(
              height: media.size.height,
              child: Stack(
                children: [
                  /// 🔵 GRADIENT BACKGROUND (Full Screen)
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7DA2FF), Color(0xFF3F67FD)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  /// 🔤 HEADER TEXT
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, top: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRegister
                                ? "You're almost there!\nLet’s set up your account."
                                : "Go ahead and\nLog in your account",
                            style: const TextStyle(
                              fontFamily: 'Kodchasan',
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// 🧾 WHITE CARD
                  Positioned(
                    top: 210,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: Stack(
                        children: [
                          /// Background image bottom-right
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Image.asset(
                              'assets/images/lines_bg.png',
                              height: 200,
                            ),
                          ),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              final media = MediaQuery.of(context);
                              final isKeyboardOpen =
                                  media.viewInsets.bottom > 0;
                              final isShortCard = constraints.maxHeight < 640;
                              final shouldScrollCard =
                                  isKeyboardOpen || isShortCard;
                              return SingleChildScrollView(
                                physics: shouldScrollCard
                                    ? const BouncingScrollPhysics()
                                    : const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: 40,
                                  bottom: media.viewInsets.bottom + 20,
                                ),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight - 40,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      RegisterLoginToggleButton(
                                        isRegisterSelected: isRegister,
                                        onRegisterTap: goToRegister,
                                        onLoginTap: goToLogin,
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        height: 360,
                                        child: PageView(
                                          controller: _pageController,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          onPageChanged: (index) {
                                            setState(() {
                                              currentPage = index;
                                            });
                                          },
                                          children: [
                                            _loginForm(),
                                            _registerForm(),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      NextActionButton(
                                        text: isRegister ? "Sign Up" : "Login",
                                        isLoading:
                                            _authBusy &&
                                            ((isRegister &&
                                                    _busyAction ==
                                                        _busyActionRegister) ||
                                                (!isRegister &&
                                                    _busyAction ==
                                                        _busyActionLogin)),
                                        loadingText: isRegister
                                            ? 'Signing up...'
                                            : 'Logging in...',
                                        onTap: () {
                                          if (_authBusy) return;
                                          if (isRegister) {
                                            _handleRegisterSubmit();
                                          } else {
                                            _handleLoginSubmit();
                                          }
                                        },
                                      ),
                                      if (!isKeyboardOpen) ...[
                                        const SizedBox(height: 20),
                                        const Text("OR"),
                                        const SizedBox(height: 20),
                                        GestureDetector(
                                          onTap: () async {
                                            if (_authBusy) return;
                                            if (mounted) {
                                              setState(() {
                                                _authBusy = true;
                                                _busyAction = _busyActionGoogle;
                                              });
                                            }
                                            try {
                                              final authRepository = ref.read(
                                                authRepositoryProvider,
                                              );

                                              final uid = await authRepository
                                                  .signInWithGoogle();

                                              final sessionRepository =
                                                  SessionRepository();
                                              await sessionRepository
                                                  .setCurrentUser(uid);
                                              ref
                                                      .read(
                                                        sessionUserIdProvider
                                                            .notifier,
                                                      )
                                                      .state =
                                                  uid;

                                              await _navigateAfterLogin(uid);
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              showAppToast(
                                                context,
                                                'Google sign-in failed. Please try again.',
                                                position: AppToastPosition.top,
                                              );
                                            } finally {
                                              if (mounted) {
                                                setState(() {
                                                  _authBusy = false;
                                                  _busyAction = null;
                                                });
                                              }
                                            }
                                          },
                                          child: Container(
                                            height: 55,
                                            width: double.infinity,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(width: 1.5),
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  height: 30,
                                                  child: Image.asset(
                                                    'assets/images/google.png',
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                const Text(
                                                  "Continue With Google",
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
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
      ),
    );
  }
}



//  body: Column(
//         children: [
//           /// 🔵 HEADER
//           Container(
//             height: 260,
//             width: double.infinity,
//             padding: const EdgeInsets.only(left: 20, top: 90),
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF7DA2FF), Color(0xFF3F67FD)],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   isRegister ? "You're almost there!" : "Go ahead and",
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 Text(
//                   isRegister
//                       ? "Let’s set up your account."
//                       : "Log in your account",
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           /// 🧾 CARD AREA
//           Expanded(
//             child: ClipRRect(
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(40),
//                 topRight: Radius.circular(40),
//               ),
//               child: Container(
//                 decoration: BoxDecoration(color: Colors.white),
//                 child: Stack(
//                   children: [
//                     Positioned(
//                       bottom: 0,
//                       right: 0,
//                       child: Image.asset(
//                         'assets/images/lines_bg.png',
//                         height: 200,
//                       ),
//                     ),
//                     /// 🔹 Main Content
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 50,
//                       ),
//                       child: Column(
//                         children: [
//                           RegisterLoginToggleButton(
//                             isRegisterSelected: isRegister,
//                             onRegisterTap: goToRegister,
//                             onLoginTap: goToLogin,
//                           ),
//                           const SizedBox(height: 24),
//                           Expanded(
//                             child: PageView(
//                               controller: _pageController,
//                               physics: const NeverScrollableScrollPhysics(),
//                               onPageChanged: (index) {
//                                 setState(() {
//                                   currentPage = index;
//                                 });
//                               },
//                               children: [_loginForm(), _registerForm()],
//                             ),
//                           ),
//                           SizedBox(height: 20),
//                           NextActionButton(
//                             text: isRegister ? "Sign Up" : "Login",
//                             onTap: () {
//                               if (isRegister) {
//                                 if (passwordController.text !=
//                                     confirmPasswordController.text) {
//                                   return;
//                                 }
//                                 goToLogin();
//                               }
//                             },
//                           ),
//                           const SizedBox(height: 20),
//                           const Text("OR"),
//                           const SizedBox(height: 20),
//                           Container(
//                             height: 55,
//                             width: double.infinity,
//                             alignment: Alignment.center,
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               border: Border.all(width: 1.5),
//                               borderRadius: BorderRadius.circular(30),
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 SizedBox(
//                                   height: 30,
//                                   child: Center(
//                                     child: Image.asset(
//                                       'assets/images/google.png',
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(width: 20),
//                                 Text("Continue With Google"),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),

  // body: Stack(
      //   children: [
      //     /// 🔵 HEADER
      //     Container(
      //       height: double.infinity,
      //       width: double.infinity,
      //       padding: const EdgeInsets.only(left: 20, top: 90),
      //       decoration: const BoxDecoration(
      //         gradient: LinearGradient(
      //           colors: [Color(0xFF7DA2FF), Color(0xFF3F67FD)],
      //           begin: Alignment.topCenter,
      //           end: Alignment.bottomCenter,
      //         ),
      //       ),
      //       child: Column(
      //         crossAxisAlignment: CrossAxisAlignment.start,
      //         children: [
      //           Text(
      //             isRegister ? "You're almost there!" : "Go ahead and",
      //             style: const TextStyle(
      //               color: Colors.white,
      //               fontSize: 24,
      //               fontWeight: FontWeight.w700,
      //             ),
      //           ),
      //           Text(
      //             isRegister
      //                 ? "Let’s set up your account."
      //                 : "Log in your account",
      //             style: const TextStyle(
      //               color: Colors.white,
      //               fontSize: 24,
      //               fontWeight: FontWeight.w700,
      //             ),
      //           ),
      //         ],
      //       ),
      //     ),
      //     /// 🧾 CARD
      //     Positioned(
      //       top: 240, // 🔥 this creates overlap
      //       left: 0,
      //       right: 0,
      //       bottom: 0,
      //       child: Container(
      //         decoration: BoxDecoration(
      //           color: Colors.white,
      //           borderRadius: const BorderRadius.only(
      //             topLeft: Radius.circular(40),
      //             topRight: Radius.circular(40),
      //           ),
      //         ),
      //         child: Stack(
      //           children: [
      //             Positioned(
      //               bottom: 0,
      //               right: 0,
      //               child: Image.asset(
      //                 'assets/images/lines_bg.png',
      //                 height: 200,
      //               ),
      //             ),
      //             Padding(
      //               padding: const EdgeInsets.symmetric(
      //                 horizontal: 20,
      //                 vertical: 50,
      //               ),
      //               child: Column(
      //                 children: [
      //                   RegisterLoginToggleButton(
      //                     isRegisterSelected: isRegister,
      //                     onRegisterTap: goToRegister,
      //                     onLoginTap: goToLogin,
      //                   ),
      //                   const SizedBox(height: 24),
      //                   Expanded(
      //                     child: PageView(
      //                       controller: _pageController,
      //                       physics: const NeverScrollableScrollPhysics(),
      //                       onPageChanged: (index) {
      //                         setState(() {
      //                           currentPage = index;
      //                         });
      //                       },
      //                       children: [_loginForm(), _registerForm()],
      //                     ),
      //                   ),
      //                   const SizedBox(height: 20),
      //                   NextActionButton(
      //                     text: isRegister ? "Sign Up" : "Login",
      //                     onTap: () {},
      //                   ),
      //                   const SizedBox(height: 20),
      //                   const Text("OR"),
      //                   const SizedBox(height: 20),
      //                   Container(
      //                     height: 55,
      //                     width: double.infinity,
      //                     alignment: Alignment.center,
      //                     decoration: BoxDecoration(
      //                       border: Border.all(width: 1.5),
      //                       borderRadius: BorderRadius.circular(30),
      //                     ),
      //                     child: Row(mainAxisAlignment: MainAxisAlignment.center,
      //                       children: [
      //                         SizedBox(height: 30, child: Center(child: Image.asset('assets/images/google.png'))),
      //                          SizedBox(width: 20,),
      //                          Text("Continue With Google"),
      //                       ],
      //                     ),
      //                   ),
      //                 ],
      //               ),
      //             ),
      //           ],
      //         ),
      //       ),
      //     ),
      //   ],
      // ),   
// import 'package:flutter/material.dart';
// import 'package:pulsecare/utils/keyboard_utils.dart';
// import 'package:pulsecare/auth/loginpage.dart';
// import 'package:pulsecare/auth/registerpage.dart';
// class AuthScreen extends StatefulWidget {
//   final bool startWithRegister;
//   const AuthScreen({super.key, this.startWithRegister = false});
//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }
// class _AuthScreenState extends State<AuthScreen> {
//   late final PageController _pageController;
//   late bool isRegisterSelected;
//   @override
//   void initState() {
//     super.initState();
//     isRegisterSelected = widget.startWithRegister;
//     _pageController = PageController(
//       initialPage: widget.startWithRegister ? 1 : 0,
//     );
//   }
//   void goToRegister() {
//     setState(() => isRegisterSelected = true);
//     _pageController.animateToPage(
//       1,
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//     );
//   }
//   void goToLogin() {
//     setState(() => isRegisterSelected = false);
//     _pageController.animateToPage(
//       0,
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//     );
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: PageView(
//         controller: _pageController,
//         physics: const NeverScrollableScrollPhysics(),
//         onPageChanged: (index) {
//           setState(() {
//             isRegisterSelected = index == 1;
//           });
//         },
//         children: [
//           LoginPage(
//             isRegisterSelected: isRegisterSelected,
//             onRegisterTap: goToRegister,
//           ),
//           RegisterPage(
//             isRegisterSelected: isRegisterSelected,
//             onLoginTap: goToLogin,
//           ),
//         ],
//       ),
//     );
//   }
// }



