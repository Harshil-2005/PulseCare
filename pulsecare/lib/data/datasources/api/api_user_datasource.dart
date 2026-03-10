import 'package:pulsecare/data/datasources/user_datasource.dart';
import 'package:pulsecare/model/user_model.dart';

class ApiUserDataSource implements UserDataSource {
  @override
  Future<User> createUser(User user) {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<List<User>> getAll() async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<User?> getById(String id) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Stream<User> watchUser(String userId) {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<void> update(User user) async {
    throw UnimplementedError('API not implemented yet');
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    throw UnimplementedError('API not implemented yet');
  }
}
