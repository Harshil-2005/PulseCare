import 'package:flutter/material.dart';
import 'upcoming_tab.dart';
import 'past_tab.dart';
import 'cancelled_tab.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final tabIndicatorWidth = (MediaQuery.of(context).size.width - 32) / 3;
    return Scaffold(
       appBar: AppBar(
        toolbarHeight: 85,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        elevation: 0.3,
        title: Center(
          child: Text(
            'My Appointment Bookings',
            style: TextStyle(fontSize: 20, fontWeight: .w600),
          ),
        ),
        shadowColor: Colors.black,
        automaticallyImplyLeading: false,
      ),

      body: SafeArea(
        top: false,
        child: Column(
          children: [
           SizedBox(height: 40),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _tabItem('Upcoming', 0),
              _tabItem('Past', 1),
              _tabItem('Cancelled', 2),
            ],
          ),

           SizedBox(height: 8),

          Stack(
            children: [
              Padding(
                padding:  EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              AnimatedAlign(
                duration:  Duration(milliseconds: 200),
                alignment: Alignment(
                  selectedTab == 0
                      ? -1
                      : selectedTab == 1
                          ? 0
                          : 1,
                  0,
                ),
                child: Padding(
                  padding:  EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: tabIndicatorWidth,
                    height: 5,
                    decoration: BoxDecoration(
                      color:  Color(0xff3F67FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),

           SizedBox(height: 25),

          Expanded(
            child: IndexedStack(
              index: selectedTab,
              children: [
                UpcomingTab(),
                PastTab(),
                CancelledTab(),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(String title, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: selectedTab == index ? Colors.black : Colors.grey,
        ),
      ),
    );
  }
}
