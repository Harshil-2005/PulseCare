import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pulsecare/constrains/app_avatar.dart';

enum AppointmentCardStatus { confirmed, pending, cancelled, completed }

class AppointmentCard extends StatelessWidget {
  final AppointmentCardStatus status;
  final String doctorName;
  final String speciality;
  final String image;
  final String date;
  final String time;
  final Widget bottomAction;

  const AppointmentCard({
    super.key,
    required this.status,
    required this.doctorName,
    required this.speciality,
    required this.image,
    required this.date,
    required this.time,
    required this.bottomAction,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = _statusUI();

    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 10),
                  child: _doctorImage(image, doctorName),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 10, top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _statusBadge(statusConfig),
                        const SizedBox(height: 10),
                        Text(
                          doctorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          speciality,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return SizedBox(
                              width: constraints.maxWidth,
                              child: FittedBox(
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/date.svg',
                                      width: 16,
                                      height: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(date, maxLines: 1),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '|',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(width: 8),
                                    SvgPicture.asset(
                                      'assets/icons/round.svg',
                                      width: 16,
                                      height: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(time, maxLines: 1),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: 10,
              ),
              child: bottomAction,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _statusUI() {
    switch (status) {
      case AppointmentCardStatus.confirmed:
        return {
          'text': 'Confirmed',
          'color': const Color(0xff3F67FD),
          'bg': const Color(0xffE4E9FC),
        };
      case AppointmentCardStatus.pending:
        return {
          'text': 'Pending',
          'color': const Color(0xffF59E0B),
          'bg': const Color(0xffFFE2AF),
        };
      case AppointmentCardStatus.completed:
        return {
          'text': 'Completed',
          'color': const Color(0xff059669),
          'bg': const Color.fromARGB(255, 203, 248, 233),
        };
      case AppointmentCardStatus.cancelled:
        return {
          'text': 'Cancelled',
          'color': const Color(0xffE12D1D),
          'bg': const Color(0xffFFDFDC),
        };
    }
  }

  Widget _statusBadge(Map<String, dynamic> config) {
    return Container(
      height: 25,
      width: 95,
      decoration: BoxDecoration(
        color: config['bg'],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: config['color'],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            config['text'],
            style: TextStyle(
              color: config['color'],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _doctorImage(String value, String doctorName) {
    final imagePath = value.trim();
    final hasNetwork =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    final isAbsolutePath =
        imagePath.startsWith('/') ||
        RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(imagePath);

    if (hasNetwork) {
      return Image.network(
        imagePath,
        width: 92,
        height: 112,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _doctorImageFallback(doctorName),
      );
    }

    if (isAbsolutePath) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(file, width: 92, height: 112, fit: BoxFit.cover);
      }
      return _doctorImageFallback(doctorName);
    }
    return _doctorImageFallback(doctorName);
  }

  Widget _doctorImageFallback(String doctorName) {
    return Container(
      width: 92,
      height: 112,
      color: const Color(0xFFF2F4F7),
      alignment: Alignment.center,
      child: AppAvatar(radius: 34, name: doctorName),
    );
  }
}
