import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
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
    sessionRepository.setCurrentUser(restoredUserId);
  }

  final restoredDoctorId = await sessionRepository.restoreDoctorId();
  if (restoredDoctorId != null && restoredDoctorId.isNotEmpty) {
    sessionRepository.setCurrentDoctor(restoredDoctorId);
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PulseCare',
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 255, 255),
        ),
      ),
      home: SplashScreen(),
    );
  }
}