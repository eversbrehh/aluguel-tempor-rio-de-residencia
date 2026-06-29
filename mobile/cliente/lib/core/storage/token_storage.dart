import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persiste o token de acesso do Supabase entre execuções.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'lamd.access_token';
  static const _userIdKey = 'lamd.user_id';
  static const _emailKey = 'lamd.user_email';

  Future<void> save({
    required String accessToken,
    required String userId,
    required String email,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _emailKey, value: email);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> readUserId() => _storage.read(key: _userIdKey);
  Future<String?> readEmail() => _storage.read(key: _emailKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _emailKey);
  }
}
