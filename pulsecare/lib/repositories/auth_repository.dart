import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulsecare/data/datasources/auth_datasource.dart';
import 'package:pulsecare/repositories/doctor_repository.dart';
import 'package:pulsecare/repositories/report_repository.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import 'package:pulsecare/repositories/user_repository.dart';

class AuthRepository {
  AuthRepository(this._datasource);

  final AuthDatasource _datasource;

  Future<String> register(String email, String password) {
    return _datasource.register(email, password);
  }

  Future<String> login(String email, String password) {
    return _datasource.login(email, password);
  }

  Future<String> signInWithGoogle() {
    return _datasource.signInWithGoogle();
  }

  Future<void> logout() {
    return _datasource.logout();
  }

  String? getCurrentUserId() {
    return _datasource.getCurrentUserId();
  }

  String? getCurrentUserEmail() {
    return _datasource.getCurrentUserEmail();
  }

  Future<void> deleteAuthAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No authenticated user found for account deletion.',
        );
      }
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        rethrow;
      }
      rethrow;
    }
  }

  Future<void> deleteAccount({
    required String userId,
    required ReportRepository reportRepository,
    required DoctorRepository doctorRepository,
    required UserRepository userRepository,
    required SessionRepository sessionRepository,
  }) async {
    await reportRepository.deleteReportsForUser(userId);
    await doctorRepository.deleteDoctorProfileForUser(userId);
    await userRepository.deleteUserProfile(userId);
    await deleteAuthAccount();
    await sessionRepository.clearSession();
  }
}
