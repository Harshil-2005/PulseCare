import 'package:pulsecare/model/doctor_review_model.dart';

abstract class DoctorReviewDataSource {
  Future<void> add(DoctorReview review);
  Future<List<DoctorReview>> getForDoctor(String doctorId);
}

class LocalDoctorReviewDataSource implements DoctorReviewDataSource {
  LocalDoctorReviewDataSource();

  final List<DoctorReview> _reviews = [];

  @override
  Future<void> add(DoctorReview review) async {
    _reviews.insert(0, review);
  }

  @override
  Future<List<DoctorReview>> getForDoctor(String doctorId) async {
    return _reviews
        .where((review) => review.doctorId == doctorId)
        .toList(growable: false);
  }

}
