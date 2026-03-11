import 'package:pulsecare/repositories/auth_repository.dart';

class AuthController {
  AuthController(this._authRepository);

  final AuthRepository _authRepository;

  Future<String> register(String email, String password) {
    return _authRepository.register(email, password);
  }

  Future<String> login(String email, String password) {
    return _authRepository.login(email, password);
  }

  Future<String> signInWithGoogle() {
    return _authRepository.signInWithGoogle();
  }

  Future<void> logout() {
    return _authRepository.logout();
  }

  String? getCurrentUserId() {
    return _authRepository.getCurrentUserId();
  }

  String? getCurrentUserEmail() {
    return _authRepository.getCurrentUserEmail();
  }
}
