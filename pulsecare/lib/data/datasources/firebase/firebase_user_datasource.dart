import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulsecare/data/datasources/user_datasource.dart';
import 'package:pulsecare/model/user_model.dart';

class FirebaseUserDataSource implements UserDataSource {
  FirebaseUserDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<List<User>> getAll() async {
    final snapshot = await _users.get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return User.fromJson(_normalizeMap(data));
        })
        .toList(growable: false);
  }

  @override
  Future<User?> getById(String id) async {
    final snapshot = await _users.doc(id).get();
    if (!snapshot.exists) return null;
    final data = snapshot.data()!;
    data['id'] = snapshot.id;
    return User.fromJson(_normalizeMap(data));
  }

  @override
  Future<User> createUser(User user) async {
    final docId = user.id.isNotEmpty ? user.id : _users.doc().id;
    final created = user.copyWith(id: docId);
    await _users.doc(docId).set(created.toJson());
    return created;
  }

  @override
  Future<void> update(User user) async {
    await _users.doc(user.id).set(user.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    await _users.doc(userId).delete();
  }

  Stream<User> watchUser(String userId) {
    return _users
        .doc(userId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (!doc.exists || data == null) {
            throw StateError('profile_not_found');
          }
          data['id'] = doc.id;
          return User.fromJson(_normalizeMap(data));
        });
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
    if (map['dateOfBirth'] is Timestamp) {
      map['dateOfBirth'] = (map['dateOfBirth'] as Timestamp)
          .toDate()
          .toIso8601String();
    }
    return map;
  }
}
