import 'package:pulsecare/model/user_model.dart';

abstract class UserDataSource {
  Future<List<User>> getAll();
  Future<User?> getById(String id);
  Stream<User> watchUser(String userId);
  Future<User> createUser(User user);
  Future<void> update(User user);
  Future<void> deleteUserProfile(String userId);
}

class LocalUserDataSource implements UserDataSource {
  LocalUserDataSource();

  final List<User> _users = [
    User(
      id: 'u1',
      fullName: 'Isha Patel',
      email: 'isha.patel@gmail.com',
      phone: '+91 99999 11111',
      age: 34,
      gender: 'Female',
      avatarPath: null,
    ),
  ];

  @override
  Future<List<User>> getAll() async => List.unmodifiable(_users);

  @override
  Future<User?> getById(String id) async {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<User> watchUser(String userId) async* {
    final user = await getById(userId);
    if (user != null) {
      yield user;
    }
  }

  @override
  Future<User> createUser(User user) async {
    _users.add(user);
    return user;
  }

  @override
  Future<void> update(User user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
    }
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    _users.removeWhere((user) => user.id == userId);
  }
}
