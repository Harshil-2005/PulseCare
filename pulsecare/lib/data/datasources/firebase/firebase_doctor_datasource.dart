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
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Doctor.fromJson(_normalizeMap(data));
        })
        .toList(growable: false);
  }

  @override
  Future<Doctor?> getById(String id) async {
    final snapshot = await _doctors.doc(id).get();
    if (!snapshot.exists) return null;
    final data = snapshot.data()!;
    data['id'] = snapshot.id;
    return Doctor.fromJson(_normalizeMap(data));
  }

  @override
  Future<Doctor?> getByUserId(String userId) async {
    final snapshot = await _doctors
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final data = doc.data();
    data['id'] = doc.id;
    return Doctor.fromJson(_normalizeMap(data));
  }

  @override
  Stream<Doctor?> watchById(String id) {
    return _firestore.collection('doctors').doc(id).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      data['id'] = doc.id;
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
          final doc = snapshot.docs.first;
          final data = doc.data();
          data['id'] = doc.id;
          return Doctor.fromJson(_normalizeMap(data));
        });
  }

  @override
  Stream<List<Doctor>> watchAll() {
    return _firestore
        .collection('doctors')
        .orderBy('rating', descending: true)
        .orderBy('patients', descending: true)
        .orderBy('experience', descending: true)
        .snapshots()
        .map((snapshot) {
          final doctors = snapshot.docs
              .map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return Doctor.fromJson(_normalizeMap(data));
              })
              .toList(growable: false);
          return List<Doctor>.from(doctors);
        });
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
  Future<void> incrementPatients(String doctorId) async {}

  @override
  Future<void> deleteDoctorProfileForUser(String userId) async {
    final query = await _doctors.where('userId', isEqualTo: userId).get();
    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    map['id'] = (map['id'] ?? '').toString();
    if (map['createdAt'] is Timestamp) {
      map['createdAt'] = (map['createdAt'] as Timestamp)
          .toDate()
          .toIso8601String();
    }
    if (map['updatedAt'] is Timestamp) {
      map['updatedAt'] = (map['updatedAt'] as Timestamp)
          .toDate()
          .toIso8601String();
    }
    return map;
  }
}
