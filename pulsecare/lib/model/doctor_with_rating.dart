import 'package:pulsecare/model/doctor_model.dart';

class DoctorWithRating {
  const DoctorWithRating({
    required this.doctor,
    required this.rating,
    required this.reviewCount,
  });

  final Doctor doctor;
  final double rating;
  final int reviewCount;
}
