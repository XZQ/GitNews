import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/auth/auth_secure_storage.dart';

void main() {
  test('Supabase session and PKCE verifier use secure storage adapters', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    const sessionStorage = SecureAuthLocalStorage(storage);
    const pkceStorage = SecureAuthPkceStorage(storage);

    await sessionStorage.initialize();
    expect(await sessionStorage.hasAccessToken(), isFalse);

    await sessionStorage.persistSession('{"refresh_token":"secret"}');
    expect(await sessionStorage.hasAccessToken(), isTrue);
    expect(await sessionStorage.accessToken(), '{"refresh_token":"secret"}');

    await pkceStorage.setItem(key: 'verifier', value: 'pkce-secret');
    expect(await pkceStorage.getItem(key: 'verifier'), 'pkce-secret');

    await pkceStorage.removeItem(key: 'verifier');
    await sessionStorage.removePersistedSession();
    expect(await pkceStorage.getItem(key: 'verifier'), isNull);
    expect(await sessionStorage.hasAccessToken(), isFalse);
  });
}
