import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static const _bucket = 'rockmeet-images';
  static const _defaultsFolder = 'defaults';

  final _random = Random();
  List<String>? _cachedFallbackUrls;

  SupabaseClient get _client => Supabase.instance.client;

  /// Carga (y cachea) las URLs de la carpeta defaults/ del bucket.
  /// Llamar una vez al arrancar la app.
  Future<void> loadFallbackUrls() async {
    try {
      final files = await _client.storage
          .from(_bucket)
          .list(path: _defaultsFolder);
      _cachedFallbackUrls = files
          .where((f) => f.name != '.emptyFolderPlaceholder')
          .map((f) => getPublicUrl('$_defaultsFolder/${f.name}'))
          .toList();
    } catch (_) {
      _cachedFallbackUrls = [];
    }
  }

  /// Devuelve una URL aleatoria de defaults/. Null si no hay ninguna cargada.
  String? get randomFallbackUrl {
    final urls = _cachedFallbackUrls;
    if (urls == null || urls.isEmpty) return null;
    return urls[_random.nextInt(urls.length)];
  }

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
