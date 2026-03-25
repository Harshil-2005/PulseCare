import 'package:flutter/material.dart';
import 'package:pulsecare/user/home_screen.dart';


class NoAppointmentScreen extends StatefulWidget {
  const NoAppointmentScreen({super.key});

  @override
  State<NoAppointmentScreen> createState() => _NoAppointmentScreenState();
}

class _NoAppointmentScreenState extends State<NoAppointmentScreen> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Image.asset(
                'assets/images/phone.png',
                width: 110,
                height: 110,
              ),
            ),
            Center(
              child: Text(
                'No appointments scheduled at the moment',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: .w500),
              ),
            ),
          ],
        ),
      ),

       bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF3F67FD),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: navIcon('assets/icons/home.svg', selectedIndex == 0),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: navIcon('assets/icons/ex.svg', selectedIndex == 1),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: navIcon('assets/icons/report.svg', selectedIndex == 2),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: navIcon('assets/icons/man.svg', selectedIndex == 3),
            label: 'Profile',
          ),
        ],
      ),
    
    );
  }
}

