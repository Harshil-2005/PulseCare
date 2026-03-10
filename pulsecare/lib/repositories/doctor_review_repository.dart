import 'package:flutter/material.dart';
import 'package:pulsecare/data/datasources/doctor_review_datasource.dart';
import 'package:pulsecare/data/datasources/firebase/firebase_doctor_datasource.dart';
import 'package:pulsecare/model/doctor_review_model.dart';

class DoctorReviewRepository extends ChangeNotifier {
  DoctorReviewRepository(
    this._dataSource, {
    FirebaseDoctorDataSource? doctorDataSource,
  }) : _doctorDataSource = doctorDataSource ?? FirebaseDoctorDataSource();

  final DoctorReviewDataSource _dataSource;
  final FirebaseDoctorDataSource _doctorDataSource;

  Future<void> createReview(DoctorReview review) async {
    _validateReview(review);
    await _dataSource.add(review);
    await _updateDoctorRatingStats(review);
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

  Future<void> _updateDoctorRatingStats(DoctorReview review) async {
    final current = await _doctorDataSource.getRatingStats(review.doctorId);
    final newRatingTotal = current.ratingTotal + review.rating;
    final newReviews = current.reviews + 1;
    final newAverage = newReviews == 0 ? 0.0 : newRatingTotal / newReviews;
    await _doctorDataSource.updateRating(
      doctorId: review.doctorId,
      rating: newAverage,
      reviews: newReviews,
      ratingTotal: newRatingTotal,
    );
  }

  void _validateReview(DoctorReview review) {
    if (review.doctorId.trim().isEmpty ||
        review.userId.trim().isEmpty ||
        review.appointmentId.trim().isEmpty) {
      throw StateError('missing_review_identity');
    }
  }
}
