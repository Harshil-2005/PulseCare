import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/auth/auth_screen.dart';
import 'package:pulsecare/providers/session_provider.dart';

import 'package:pulsecare/user/home_screen.dart';
import 'package:pulsecare/appointment_screens/appointment_screen.dart';
import 'package:pulsecare/user/my_report_screen.dart';
import 'package:pulsecare/user/profile_screen.dart';


class AppShell extends ConsumerStatefulWidget {
 final int initialTab;

const AppShell({super.key, this.initialTab = 0});


  static AppShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<AppShellState>();
  }

  @override
  ConsumerState<AppShell> createState() => AppShellState();
}


class AppShellState extends ConsumerState<AppShell> {
  late int selectedIndex;

@override
void initState() {
  super.initState();
  selectedIndex = widget.initialTab;
}

  List<Widget> get screens => [
  const HomeScreen(),
  const AppointmentScreen(),
  const MyReportScreen(),
  const ProfileScreen(),
];


  void switchToProfile() {
    setState(() {
      selectedIndex = 3;
    });
  }

  void switchToTab(int index) {
  setState(() {
    selectedIndex = index;
  });
}


  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(sessionUserIdProvider, (previous, next) {
      if (next == null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    });

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IndexedStack(
          index: selectedIndex,
          children: screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF3F67FD),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
              icon: _navIcon('assets/icons/home.svg', selectedIndex == 0),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _navIcon('assets/icons/ex.svg', selectedIndex == 1),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: _navIcon('assets/icons/report.svg', selectedIndex == 2),
              label: 'Report',
            ),
            BottomNavigationBarItem(
              icon: _navIcon('assets/icons/man.svg', selectedIndex == 3),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(String assetPath, bool isSelected) {
    return SvgPicture.asset(
      assetPath,
      width: 26,
      height: 26,
      colorFilter: ColorFilter.mode(
        isSelected ? const Color(0xFF3F67FD) : Colors.grey,
        BlendMode.srcIn,
      ),
    );
  }
}


