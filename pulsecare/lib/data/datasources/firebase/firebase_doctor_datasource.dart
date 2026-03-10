import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulsecare/data/datasources/doctor_datasource.dart';
import 'package:pulsecare/model/doctor_model.dart';

class FirebaseDoctorDataSource implements DoctorDataSource {
  FirebaseDoctorDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _doctors =>
      _firestore.collection('doctors');

  @override
  Future<List<Doctor>> getAll() async {
    final snapshot = await _doctors.get();
    return snapshot.docs
        .map((doc) => Doctor.fromJson(_normalizeMap(doc.data())))
        .toList(growable: false);
  }

  @override
  Future<Doctor?> getById(String id) async {
    final snapshot = await _doctors.doc(id).get();
    if (!snapshot.exists) return null;
    return Doctor.fromJson(_normalizeMap(snapshot.data()!));
  }

  @override
  Future<Doctor?> getByUserId(String userId) async {
    final snapshot = await _doctors.where('userId', isEqualTo: userId).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return Doctor.fromJson(_normalizeMap(snapshot.docs.first.data()));
  }

  @override
  Stream<Doctor?> watchById(String id) {
    return _firestore
        .collection('doctors')
        .doc(id)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (data == null) return null;
          return Doctor.fromJson(_normalizeMap(data));
        });
  }

  @override
  Stream<Doctor?> watchByUserId(String userId) {
    return _firestore
        .collection('doctors')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return Doctor.fromJson(_normalizeMap(snapshot.docs.first.data()));
        });
  }

  @override
  Stream<List<Doctor>> watchAll() {
    return _firestore
        .collection('doctors')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Doctor.fromJson(_normalizeMap(doc.data())))
            .toList(growable: false));
  }

  @override
  Future<Doctor> createDoctor(Doctor doctor) async {
    final docId = doctor.id.isNotEmpty ? doctor.id : _doctors.doc().id;
    final created = doctor.copyWith(id: docId);
    await _doctors.doc(docId).set(created.toJson());
    return created;
  }

  @override
  Future<void> update(Doctor doctor) async {
    await _doctors.doc(doctor.id).set(doctor.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> incrementPatients(String doctorId) async {
    await _doctors.doc(doctorId).set(
      {
        'patients': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> deleteDoctorProfileForUser(String userId) async {
    final query = await _doctors.where('userId', isEqualTo: userId).get();
    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> updateRating({
    required String doctorId,
    required double rating,
    required int reviews,
    required double ratingTotal,
  }) async {
    await _doctors.doc(doctorId).set(
      {
        'rating': rating,
        'reviews': reviews,
        'ratingTotal': ratingTotal,
      },
      SetOptions(merge: true),
    );
  }

  Future<_DoctorRatingStats> getRatingStats(String doctorId) async {
    final snapshot = await _doctors.doc(doctorId).get();
    final data = snapshot.data();
    if (data == null) {
      return const _DoctorRatingStats(rating: 0, reviews: 0, ratingTotal: 0);
    }
    final rating = (data['rating'] as num?)?.toDouble() ?? 0;
    final reviews = data['reviews'] is int
        ? data['reviews'] as int
        : int.tryParse((data['reviews'] ?? '').toString()) ?? 0;
    final ratingTotal =
        (data['ratingTotal'] as num?)?.toDouble() ?? (rating * reviews);
    return _DoctorRatingStats(
      rating: rating,
      reviews: reviews,
      ratingTotal: ratingTotal,
    );
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    map['id'] = (map['id'] ?? '').toString();
    if (map['createdAt'] is Timestamp) {
      map['createdAt'] = (map['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (map['updatedAt'] is Timestamp) {
      map['updatedAt'] = (map['updatedAt'] as Timestamp).toDate().toIso8601String();
    }
    return map;
  }
}

class _DoctorRatingStats {
  const _DoctorRatingStats({
    required this.rating,
    required this.reviews,
    required this.ratingTotal,
  });

  final double rating;
  final int reviews;
  final double ratingTotal;
}
