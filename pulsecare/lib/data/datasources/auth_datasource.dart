abstract class AuthDatasource {
  Future<String> register(String email, String password);
  Future<String> login(String email, String password);
  Future<String> signInWithGoogle();
  Future<void> logout();
  String? getCurrentUserId();
  String? getCurrentUserEmail();
}
