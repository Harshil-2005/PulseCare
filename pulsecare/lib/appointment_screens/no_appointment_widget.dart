import 'package:flutter/material.dart';

class NoAppointmentWidget extends StatelessWidget {
  const NoAppointmentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/phone.png',
          width: 110,
          height: 110,
        ),
        const SizedBox(height: 12),
        const Text(
          'No appointments scheduled\nat the moment',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

