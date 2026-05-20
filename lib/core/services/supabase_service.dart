import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static const _bucket = 'rockmeet-images';

  SupabaseClient get _client => Supabase.instance.client;

  Future<String> uploadImage({
    required String path,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    await _client.storage.from(_bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  Future<void> deleteImage(String path) async {
    await _client.storage.from(_bucket).remove([path]);
  }

  String getPublicUrl(String path) {
    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
