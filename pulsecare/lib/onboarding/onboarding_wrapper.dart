import 'package:flutter/material.dart';
import 'package:pulsecare/auth/auth_screen.dart';
import 'package:pulsecare/data/onboarding_data.dart';
import 'package:pulsecare/onboarding/onboardingone.dart';

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  final PageController pageController = PageController();
  int currentPage = 0;

  final List<Onboardingdata> data = [
    Onboardingdata(
      image: 'assets/images/onboarding_one.png',
      title: 'Helth Intelligence',
      desc:
          'Empowering you with seamless, secure, and smarter health management.',
    ),
    Onboardingdata(
      image: 'assets/images/onboarding_two.png',
      title: 'Secure Wellness',
      desc:
          'Keep all your medical records secure, organized, and always within reach.',
    ),
    Onboardingdata(
      image: 'assets/images/onboarding_three.png',
      title: 'Ai Assist',
      desc:
          'Get reliable medical support in seconds, whenever you need it.',
    ),
    Onboardingdata(
      image: 'assets/images/onboarding_four.png',
      title: 'Personalize your care',
      desc:
          'Personalized AI care that understands you and guides your health smarter, faster, and better.',
    ),
  ];

  void onImageChange(int index) {
    setState(() {
      currentPage = index;
    });
  }

  void nextPage() {
    if (currentPage < data.length - 1) {
      pageController.nextPage(
        duration: Duration(milliseconds: 400),

        curve: Curves.easeInOut,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen(startWithRegister: true)),
      );
    }
  }

  void skip() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen(startWithRegister: true)),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: OnboardingPage(
        totalPages: data.length,
        data: data,
        controller: pageController,
        currentPage: currentPage,
        onImageChange: onImageChange,
        onNext: nextPage,
        onSkip: skip,
      ),
    );
  }
}

