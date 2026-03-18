import 'package:shared_preferences/shared_preferences.dart';

class SessionRepository {
  SessionRepository._privateConstructor();

  static final SessionRepository _instance =
      SessionRepository._privateConstructor();

  factory SessionRepository() {
    return _instance;
  }

  String? _currentUserId;
  String? _currentDoctorId;
  String? _currentRole;

  static const String _userIdKey = 'current_user_id';
  static const String _doctorIdKey = 'current_doctor_id';
  static const String _roleKey = 'role';

  String getCurrentUserId() {
    if (_currentUserId == null) {
      throw StateError('No active user session');
    }
    return _currentUserId!;
  }

  String getCurrentDoctorId() {
    if (_currentDoctorId == null) {
      throw StateError('No active doctor session');
    }
    return _currentDoctorId!;
  }

  String? getDoctorId() => _currentDoctorId;

  String? getRole() => _currentRole;

  Future<void> setCurrentUser(String userId) async {
    _currentUserId = userId;
    await persistUserId(userId);
  }

  Future<void> setCurrentDoctor(String doctorId) async {
    _currentDoctorId = doctorId;
    await persistDoctorId(doctorId);
  }

  Future<void> setRole(String role) async {
    _currentRole = role;
    await persistRole(role);
  }

  Future<void> clearSession() async {
    _currentUserId = null;
    _currentDoctorId = null;
    _currentRole = null;
    await _clearPersistedSession();
  }

  Future<void> persistUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, id);
  }

  Future<String?> restoreUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<void> persistDoctorId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_doctorIdKey, id);
  }

  Future<String?> restoreDoctorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_doctorIdKey);
  }

  Future<void> persistRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  Future<String?> restoreRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<void> _clearPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_doctorIdKey);
    await prefs.remove(_roleKey);
  }
}
