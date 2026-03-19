import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulsecare/data/datasources/doctor_review_datasource.dart';
import 'package:pulsecare/model/doctor_review_model.dart';

class FirebaseDoctorReviewDataSource implements DoctorReviewDataSource {
  FirebaseDoctorReviewDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('doctor_reviews');

  @override
  Future<void> add(DoctorReview review) async {
    final appointmentId = review.appointmentId.trim();
    if (appointmentId.isEmpty) {
      throw StateError('missing_review_appointment_id');
    }

    final exists = await _reviewExistsForAppointment(appointmentId);
    if (exists) {
      throw StateError('duplicate_review_for_appointment');
    }

    final docRef = _reviews.doc(appointmentId);
    final appointmentRef = _firestore
        .collection('appointments')
        .doc(appointmentId);
    final toStore = review.copyWith(id: appointmentId);

    final batch = _firestore.batch();
    batch.set(docRef, toStore.toJson());
    batch.update(appointmentRef, {
      'reviewSubmitted': true,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      if (error.code == 'not-found') {
        throw StateError('appointment_not_found');
      }
      throw StateError('review_submission_failed');
    }
  }

  @override
  Future<List<DoctorReview>> getForDoctor(String doctorId) async {
    final snapshot = await _reviews
        .where('doctorId', isEqualTo: doctorId)
        .get();
    return snapshot.docs
        .map((doc) {
          final data = _normalizeMap(doc.data());
          data['id'] = doc.id;
          return DoctorReview.fromJson(data);
        })
        .toList(growable: false);
  }

  Future<bool> _reviewExistsForAppointment(String appointmentId) async {
    final byId = await _reviews.doc(appointmentId).get();
    if (byId.exists) {
      return true;
    }

    // Backward compatibility: old data may use random doc IDs.
    final legacy = await _reviews
        .where('appointmentId', isEqualTo: appointmentId)
        .limit(1)
        .get();
    return legacy.docs.isNotEmpty;
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    map['id'] = (map['id'] ?? '').toString();
    if (map['createdAt'] is Timestamp) {
      map['createdAt'] = (map['createdAt'] as Timestamp)
          .toDate()
          .toIso8601String();
    }
    return map;
  }
}
