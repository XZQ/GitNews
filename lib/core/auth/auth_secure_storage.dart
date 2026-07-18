import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/*
*把 Supabase 完整会话 JSON 存入平台安全存储。
*
*替换 SDK 默认的 SharedPreferences 存储，避免 refresh token 明文落盘。
*/
class SecureAuthLocalStorage extends LocalStorage {
  const SecureAuthLocalStorage(this._storage);

  static const String _sessionKey = 'app_auth_supabase_session_v1';

  // 平台安全存储实例。
  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => (await _storage.read(key: _sessionKey))?.isNotEmpty ?? false;

  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) => _storage.write(key: _sessionKey, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _sessionKey);
}

/*
*把 PKCE code verifier 存入平台安全存储。
*/
class SecureAuthPkceStorage extends GotrueAsyncStorage {
  const SecureAuthPkceStorage(this._storage);

  static const String _keyPrefix = 'app_auth_pkce_v1_';

  // 平台安全存储实例。
  final FlutterSecureStorage _storage;

  @override
  Future<String?> getItem({required String key}) => _storage.read(key: '$_keyPrefix$key');

  @override
  Future<void> setItem({required String key, required String value}) => _storage.write(key: '$_keyPrefix$key', value: value);

  @override
  Future<void> removeItem({required String key}) => _storage.delete(key: '$_keyPrefix$key');
}
