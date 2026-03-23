import 'package:pulsecare/model/doctor_review_model.dart';

abstract class DoctorReviewDataSource {
  Future<void> add(DoctorReview review);
  Future<List<DoctorReview>> getForDoctor(String doctorId);
  Stream<List<DoctorReview>> watchForDoctor(String doctorId);
}

class LocalDoctorReviewDataSource implements DoctorReviewDataSource {
  LocalDoctorReviewDataSource();

  final List<DoctorReview> _reviews = [];

  @override
  Future<void> add(DoctorReview review) async {
    final exists = _reviews.any(
      (existing) => existing.appointmentId == review.appointmentId,
    );
    if (exists) {
      throw StateError('duplicate_review_for_appointment');
    }
    _reviews.insert(0, review);
  }

  @override
  Future<List<DoctorReview>> getForDoctor(String doctorId) async {
    return _reviews
        .where((review) => review.doctorId == doctorId)
        .toList(growable: false);
  }

  @override
  Stream<List<DoctorReview>> watchForDoctor(String doctorId) async* {
    yield await getForDoctor(doctorId);
  }
}
