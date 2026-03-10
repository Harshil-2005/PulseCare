import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsecare/repositories/session_repository.dart';

final sessionUserIdProvider = StateProvider<String?>((ref) {
  final repo = SessionRepository();
  try {
    return repo.getCurrentUserId();
  } catch (_) {
    return null;
  }
});
