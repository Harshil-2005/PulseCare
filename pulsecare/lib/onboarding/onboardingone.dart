import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/constrains/next_action_button.dart';
import 'package:pulsecare/data/onboarding_data.dart';

class OnboardingPage extends StatelessWidget {
  final List<Onboardingdata> data;
  final PageController controller;
  final int totalPages;
  final int currentPage;
  final Function(int) onImageChange;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const OnboardingPage({
    super.key,
    required this.totalPages,
    required this.data,
    required this.controller,
    required this.currentPage,
    required this.onImageChange,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final heroWidth = (screenWidth - 32).clamp(280.0, 350.0);

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Image.asset(
              'assets/images/onboarding_up_lines.png',
              height: 255,
            ),
          ),

          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset('assets/images/lines_bg.png', width: 200),
          ),

          Positioned(
            top: 25,
            right: 10,
            child: TextButton(
              onPressed: onSkip,
              child: Text(
                'Skip',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
          ),

          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      width: heroWidth,
                      height: 350,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xff3f67fd), Colors.white],
                        ),
                      ),
                      child: PageView.builder(
                        controller: controller,
                        itemCount: data.length,
                        onPageChanged: (index) {
                          onImageChange(index);
                        },
                        itemBuilder: (context, index) {
                          return Image.asset(
                            data[index].image!,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(data.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: SvgPicture.asset(
                              i == currentPage
                                  ? 'assets/icons/star_active.svg'
                                  : 'assets/icons/star_inactive.svg',
                              width: 20,
                              height: 20,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 44,
                            child: Text(
                              data[currentPage].title!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: const TextStyle(
                                fontFamily: 'Kodchasan',
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 66,
                            child: Text(
                              data[currentPage].desc!,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              style: const TextStyle(fontSize: 18, height: 1.25),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    NextActionButton(
                      text: currentPage == data.length - 1
                          ? "Get Started"
                          : 'Next',
                      onTap: onNext,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
