import 'package:flutter/material.dart';
import 'package:pulsecare/data/datasources/doctor_review_datasource.dart';
import 'package:pulsecare/model/doctor_review_model.dart';

class DoctorReviewRepository extends ChangeNotifier {
  DoctorReviewRepository(this._dataSource);

  final DoctorReviewDataSource _dataSource;

  Future<void> createReview(DoctorReview review) async {
    _validateReview(review);
    final normalized = review.copyWith(id: review.appointmentId);
    await _dataSource.add(normalized);
    // TODO: Move rating aggregation to Cloud Function
    notifyListeners();
  }

  Future<List<DoctorReview>> getDoctorReviews(String doctorId) async {
    return _dataSource.getForDoctor(doctorId);
  }

  Future<double> calculateDoctorRating(String doctorId) async {
    final reviews = await _dataSource.getForDoctor(doctorId);
    if (reviews.isEmpty) return 0;
    final total = reviews.fold<double>(0, (sum, item) => sum + item.rating);
    return total / reviews.length;
  }

  void _validateReview(DoctorReview review) {
    if (review.doctorId.trim().isEmpty ||
        review.userId.trim().isEmpty ||
        review.appointmentId.trim().isEmpty) {
      throw StateError('missing_review_identity');
    }
  }
}
