import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulsecare/accountsetup/account_setup_flow_screen.dart';
import 'package:pulsecare/auth/auth_screen.dart';
import 'package:pulsecare/doctor/doctor_app_shell.dart';
import 'package:pulsecare/doctor/doctor_onboarding_screen.dart';
import 'package:pulsecare/model/day_schedule.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import 'package:pulsecare/user/app_shell.dart';
import 'package:pulsecare/onboarding/onboarding_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> _navigate() async {
    final user = FirebaseAuth.instance.currentUser;
    final sessionRepository = SessionRepository();

    final prefs = await SharedPreferences.getInstance();
    final isOnboardingDone = prefs.getBool('onboarding_done') ?? false;

    if (!mounted) return;

    if (user != null) {
      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;
      await sessionRepository.clearSession();
      await sessionRepository.setCurrentUser(uid);

      final userDoc = await firestore.collection('users').doc(uid).get();
      if (!mounted) return;

      if (!userDoc.exists || userDoc.data() == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountSetupFlowScreen()),
        );
        return;
      }

      final role = (userDoc.data()!['role'] ?? '').toString().toLowerCase();
      if (role == 'doctor') {
        await sessionRepository.setRole('doctor');
        final doctorQuery = await firestore
            .collection('doctors')
            .where('userId', isEqualTo: uid)
            .limit(1)
            .get();
        if (!mounted) return;

        if (doctorQuery.docs.isEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DoctorOnboardingScreen()),
          );
          return;
        }

        final doctorId = doctorQuery.docs.first.id;
        await sessionRepository.setCurrentDoctor(doctorId);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorAppShell(
              doctorId: doctorId,
              initialSchedule: const <DaySchedule>[],
            ),
          ),
        );
        return;
      }

      await sessionRepository.setRole('patient');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } else {
      if (isOnboardingDone) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AuthScreen(startWithRegister: false),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingWrapper()),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), _navigate);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Image.asset(
                'assets/images/lines_bg_up.png',
                width: 230,
                height: 230,
              ),
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 150,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'PulseCare',
                    style: TextStyle(
                      fontFamily: 'Kodchasan',
                      fontSize: 35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                'assets/images/wave.png',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
