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
    final docRef = review.id.isNotEmpty ? _reviews.doc(review.id) : _reviews.doc();
    final toStore = review.copyWith(id: docRef.id);
    await docRef.set(toStore.toJson());
  }

  @override
  Future<List<DoctorReview>> getForDoctor(String doctorId) async {
    final snapshot = await _reviews.where('doctorId', isEqualTo: doctorId).get();
    return snapshot.docs
        .map((doc) => DoctorReview.fromJson(_normalizeMap(doc.data())))
        .toList(growable: false);
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
