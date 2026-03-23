import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  SupabaseStorageService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String reportsBucket = 'pulsecare_pdf';
  static const String profilesBucket = 'pulsecare_avatar';

  Future<String> uploadReport(File file, String reportId) async {
    final path = 'reports/$reportId.pdf';
    debugPrint(
      '[SupabaseStorageService] Upload report start bucket=$reportsBucket path=$path file=${file.path}',
    );
    try {
      await _client.storage
          .from(reportsBucket)
          .upload(
            path,
            file,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'application/pdf',
            ),
          );
    } on StorageException catch (error) {
      throw StateError(
        'supabase_storage_rls_blocked: ${error.message} (status ${error.statusCode})',
      );
    }
    final publicUrl = _client.storage.from(reportsBucket).getPublicUrl(path);
    final cacheBustedUrl =
        '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    debugPrint(
      '[SupabaseStorageService] Upload report success bucket=$reportsBucket path=$path',
    );
    return cacheBustedUrl;
  }

  Future<String> uploadProfileImage(File file, String userId) async {
    final path = 'profiles/$userId.jpg';
    await _client.storage
        .from(profilesBucket)
        .upload(
          path,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    final publicUrl = _client.storage.from(profilesBucket).getPublicUrl(path);
    return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }
}
