import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulsecare/data/datasources/appointment_datasource.dart';
import 'package:pulsecare/model/appointment_model.dart';

class FirebaseAppointmentDataSource implements AppointmentDataSource {
  FirebaseAppointmentDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _firestore.collection('appointments');

  @override
  Future<List<Appointment>> getAll() async {
    throw UnsupportedError(
      'Unfiltered appointment reads are disabled. Use getForUser/getForDoctor/getForDoctorAt.',
    );
  }

  @override
  Future<List<Appointment>> getForUser(String userId) async {
    final snapshot = await _appointments
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => Appointment.fromJson(_normalizeMap(doc.data())))
        .toList(growable: false);
  }

  @override
  Future<List<Appointment>> getForDoctor(String doctorId) async {
    final snapshot = await _appointments
        .where('doctorId', isEqualTo: doctorId)
        .get();
    return snapshot.docs
        .map((doc) => Appointment.fromJson(_normalizeMap(doc.data())))
        .toList(growable: false);
  }

  @override
  Future<List<Appointment>> getForDoctorAt(
    String doctorId,
    DateTime scheduledAt,
  ) async {
    final snapshot = await _appointments
        .where('doctorId', isEqualTo: doctorId)
        .where('scheduledAt', isEqualTo: scheduledAt.toIso8601String())
        .get();
    return snapshot.docs
        .map((doc) => Appointment.fromJson(_normalizeMap(doc.data())))
        .toList(growable: false);
  }

  @override
  Future<Appointment?> getById(String id) async {
    final snapshot = await _appointments.doc(id).get();
    if (!snapshot.exists) return null;
    return Appointment.fromJson(_normalizeMap(snapshot.data()!));
  }

  @override
  Future<void> add(Appointment appointment) async {
    final docRef = appointment.id.isNotEmpty
        ? _appointments.doc(appointment.id)
        : _appointments.doc();
    final toStore = appointment.copyWith(id: docRef.id);

    await _firestore.runTransaction((transaction) async {
      final duplicateQuery = await _appointments
          .where('doctorId', isEqualTo: toStore.doctorId)
          .where(
            'scheduledAt',
            isEqualTo: toStore.scheduledAt.toIso8601String(),
          )
          .limit(1)
          .get();

      final hasConflict = duplicateQuery.docs.any((doc) {
        final status = (doc.data()['status'] ?? '').toString().toLowerCase();
        return status != 'cancelled';
      });

      if (hasConflict) {
        throw StateError('duplicate_slot');
      }

      transaction.set(docRef, toStore.toJson());
    });
  }

  @override
  Future<void> update(Appointment appointment) async {
    await _appointments
        .doc(appointment.id)
        .set(appointment.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> remove(Appointment appointment) async {
    await _appointments.doc(appointment.id).delete();
  }

  @override
  Stream<List<Appointment>> watchForUser(String userId) {
    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Appointment.fromJson(_normalizeMap(doc.data())))
              .toList(),
        );
  }

  @override
  Stream<List<Appointment>> watchForDoctor(String doctorId) {
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Appointment.fromJson(_normalizeMap(doc.data())))
              .toList(),
        );
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    map['id'] = (map['id'] ?? '').toString();

    if (map['scheduledAt'] is Timestamp) {
      map['scheduledAt'] = (map['scheduledAt'] as Timestamp)
          .toDate()
          .toIso8601String();
    }
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

    final doctor = map['doctor'];
    if (doctor is Map<String, dynamic>) {
      final doctorMap = Map<String, dynamic>.from(doctor);
      if (doctorMap['createdAt'] is Timestamp) {
        doctorMap['createdAt'] = (doctorMap['createdAt'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      if (doctorMap['updatedAt'] is Timestamp) {
        doctorMap['updatedAt'] = (doctorMap['updatedAt'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      map['doctor'] = doctorMap;
    }

    return map;
  }
}
