import 'package:flutter/material.dart';
import 'package:pulsecare/utils/keyboard_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pulsecare/doctor/doctor_app_shell.dart';
import 'package:pulsecare/model/day_schedule.dart';
import 'package:pulsecare/user/app_shell.dart';
import 'firebase_options.dart';

import 'package:pulsecare/repositories/session_repository.dart';
import 'package:pulsecare/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final sessionRepository = SessionRepository();

  final restoredUserId = await sessionRepository.restoreUserId();
  if (restoredUserId != null && restoredUserId.isNotEmpty) {
    await sessionRepository.setCurrentUser(restoredUserId);
  }

  final restoredDoctorId = await sessionRepository.restoreDoctorId();
  if (restoredDoctorId != null && restoredDoctorId.isNotEmpty) {
    await sessionRepository.setCurrentDoctor(restoredDoctorId);
  }

  final restoredRole = await sessionRepository.restoreRole();
  if (restoredRole != null && restoredRole.isNotEmpty) {
    await sessionRepository.setRole(restoredRole);
  }

  final role = sessionRepository.getRole();
  final userId = restoredUserId != null && restoredUserId.isNotEmpty
      ? restoredUserId
      : null;
  final doctorId = sessionRepository.getDoctorId();

  Widget home = const SplashScreen();
  if (role == 'doctor' &&
      doctorId != null &&
      doctorId.isNotEmpty &&
      userId != null &&
      userId.isNotEmpty) {
    home = DoctorAppShell(
      doctorId: doctorId,
      initialSchedule: const <DaySchedule>[],
    );
  } else if (role == 'patient' && userId != null && userId.isNotEmpty) {
    home = const AppShell();
  }

  runApp(
    ProviderScope(
      child: MyApp(home: home),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PulseCare',
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus &&
                currentFocus.focusedChild != null) {
              KeyboardUtils.hideKeyboardKeepFocus();
            }
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 255, 255),
        ),
      ),
      home: home,
    );
  }
}


