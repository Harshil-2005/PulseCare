import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulsecare/data/datasources/appointment_datasource.dart';
import 'package:pulsecare/model/appointment_model.dart';

class FirebaseAppointmentDataSource implements AppointmentDataSource {
  FirebaseAppointmentDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _firestore.collection('appointments');

  String _buildSlotAppointmentId(String doctorId, DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    final dateKey = '$y$m$d';
    final timeSlot = '$hh$mm';
    return '${doctorId}_${dateKey}_$timeSlot';
  }

  @override
  Future<List<Appointment>> getAll() async {
    throw UnsupportedError(
      'Unfiltered appointment reads are disabled. Use getForUser/getForDoctor.',
    );
  }

  @override
  Future<List<Appointment>> getForUser(String userId) async {
    final snapshot = await _appointments
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Appointment.fromJson(_normalizeMap(data));
        })
        .toList(growable: false);
  }

  @override
  Future<List<Appointment>> getForDoctor(String doctorId) async {
    final snapshot = await _appointments
        .where('doctorId', isEqualTo: doctorId)
        .get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Appointment.fromJson(_normalizeMap(data));
        })
        .toList(growable: false);
  }

  @override
  Future<Appointment?> getById(String id) async {
    final snapshot = await _appointments.doc(id).get();
    if (!snapshot.exists) return null;
    final data = snapshot.data()!;
    data['id'] = snapshot.id;
    return Appointment.fromJson(_normalizeMap(data));
  }

  @override
  Future<void> add(Appointment appointment) async {
    final resolvedDocId = appointment.id.isNotEmpty
        ? appointment.id
        : _buildSlotAppointmentId(
            appointment.doctorId,
            appointment.scheduledAt,
          );
    final docRef = _appointments.doc(resolvedDocId);
    final toStore = appointment.copyWith(id: docRef.id);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(docRef);
      if (existing.exists) {
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
  Future<void> updateStatusRaw(String appointmentId, String rawStatus) async {
    await _appointments.doc(appointmentId).set({
      'status': rawStatus,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
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
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Appointment.fromJson(_normalizeMap(data));
          }).toList(),
        );
  }

  @override
  Stream<List<Appointment>> watchForDoctor(String doctorId) {
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Appointment.fromJson(_normalizeMap(data));
          }).toList(),
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
