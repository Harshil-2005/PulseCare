import 'package:flutter/material.dart';
import 'package:pulsecare/data/datasources/user_datasource.dart';
import 'package:pulsecare/model/user_model.dart';

class UserRepository extends ChangeNotifier {
  UserRepository._privateConstructor(this._dataSource);

  static UserRepository? _instance;

  factory UserRepository([UserDataSource? dataSource]) {
    _instance ??= UserRepository._privateConstructor(
      dataSource ?? LocalUserDataSource(),
    );
    return _instance!;
  }

  final UserDataSource _dataSource;

  Future<User?> getUserById(String userId) async {
    return await _dataSource.getById(userId);
  }

  Stream<User> watchUserById(String userId) {
    return _dataSource.watchUser(userId);
  }

  Future<User> createUser(User user) async {
    final created = await _dataSource.createUser(user);
    notifyListeners();
    return created;
  }

  Future<void> updateUser(String userId, User updatedUser) async {
    if (await _dataSource.getById(userId) != null) {
      _dataSource.update(updatedUser);
      notifyListeners();
    }
  }

  Future<List<User>> getAllUsers() async {
    return await _dataSource.getAll();
  }

  Future<void> deleteUserProfile(String userId) async {
    await _dataSource.deleteUserProfile(userId);
    notifyListeners();
  }
}
