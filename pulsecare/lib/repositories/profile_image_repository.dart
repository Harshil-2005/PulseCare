import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pulsecare/services/supabase_storage_service.dart';

class ProfileImageRepository {
  ProfileImageRepository({SupabaseStorageService? storageService})
    : _storageService = storageService ?? SupabaseStorageService();

  final SupabaseStorageService _storageService;

  Future<String> saveUserProfileImage({
    required String userId,
    required String sourcePath,
  }) async {
    return _saveProfileImage(
      folder: 'users',
      entityId: userId,
      sourcePath: sourcePath,
    );
  }

  Future<String> saveDoctorProfileImage({
    required String doctorId,
    required String sourcePath,
  }) async {
    return _saveProfileImage(
      folder: 'doctors',
      entityId: doctorId,
      sourcePath: sourcePath,
    );
  }

  Future<String> _saveProfileImage({
    required String folder,
    required String entityId,
    required String sourcePath,
  }) async {
    if (_isRemotePath(sourcePath)) {
      return sourcePath;
    }

    final localPath = await _copyToLocalProfileDir(
      folder: folder,
      entityId: entityId,
      sourcePath: sourcePath,
    );

    try {
      final downloadUrl = await _storageService.uploadProfileImage(
        File(localPath),
        entityId,
      );
      return downloadUrl;
    } catch (_) {
      return localPath;
    }
  }

  Future<String> _copyToLocalProfileDir({
    required String folder,
    required String entityId,
    required String sourcePath,
  }) async {
    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      return sourcePath;
    }

    final baseDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(
      path.join(baseDir.path, 'profile_images', folder, entityId),
    );
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    final extension = _safeExtension(sourcePath);
    final targetPath = path.join(targetDir.path, 'avatar$extension');
    final copied = await sourceFile.copy(targetPath);
    return copied.path;
  }

  String _safeExtension(String value) {
    final ext = path.extension(value).toLowerCase();
    if (ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.webp') {
      return ext;
    }
    return '.jpg';
  }

  bool _isRemotePath(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }
}
