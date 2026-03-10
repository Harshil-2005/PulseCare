import 'package:flutter/material.dart';

class NoReportsWidget extends StatelessWidget {
  const NoReportsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/report.png',
          width: 80,
          height: 75,
        ),
        const SizedBox(height: 15),
        const Text(
          'No Report Uploaded Yet',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        const Text(
          'Upload your medical report to get analysis and guidance',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

