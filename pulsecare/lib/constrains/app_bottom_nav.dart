import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF3F67FD),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: [
        BottomNavigationBarItem(
          icon: _navIcon('assets/icons/home.svg', currentIndex == 0),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: _navIcon('assets/icons/ex.svg', currentIndex == 1),
          label: 'Appointments',
        ),
        BottomNavigationBarItem(
          icon: _navIcon('assets/icons/report.svg', currentIndex == 2),
          label: 'Report',
        ),
        BottomNavigationBarItem(
          icon: _navIcon('assets/icons/man.svg', currentIndex == 3),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _navIcon(String path, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SvgPicture.asset(
        path,
        width: 24,
        height: 24,
        color: isSelected ?Color(0xFF3F67FD) : Colors.grey,
        ),
      );
    
  }
}
