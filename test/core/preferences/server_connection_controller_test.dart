import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/preferences/server_connection_controller.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/controlled_secure_storage.dart';

const _secureKey = 'self_hosted_server_connection_v2';
const _legacyKey = 'self_hosted_server_api_key';
const _serverA = 'https://sync-a.example.com/api';
const _serverB = 'https://sync-b.example.com/api';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('normalizes an absolute server URL', () {
    expect(normalizeServerBaseUrl(' https://sync.example.com/api/// '), 'https://sync.example.com/api');
    expect(normalizeServerBaseUrl('https://SYNC.Example.com:443/a/../api/'), 'https://sync.example.com/api');
  });

  test('rejects relative and non-http server URLs', () {
    expect(() => normalizeServerBaseUrl('/api'), throwsFormatException);
    expect(() => normalizeServerBaseUrl('file:///tmp/server'), throwsFormatException);
    expect(() => normalizeServerBaseUrl('https://user:password@example.com'), throwsFormatException);
    expect(() => normalizeServerBaseUrl('https://example.com?query=1'), throwsFormatException);
    expect(() => normalizeServerBaseUrl('https://example.com#fragment'), throwsFormatException);
  });

  test('legacy key migrates with its original normalized server and plaintext legacy key is removed', () async {
    final secure = ControlledSecureStorage({_legacyKey: 'key-a'});
    final container = await _container(secure, {serverBaseUrlPreferenceKey: 'https://SYNC-A.example.com:443/api/'});
    final controller = container.read(serverConnectionControllerProvider.notifier);
    await controller.ready;

    final connection = container.read(serverConnectionControllerProvider);
    expect(connection.baseUrl, _serverA);
    expect(connection.apiKey, 'key-a');
    expect(secure.values.containsKey(_legacyKey), isFalse);
    expect(jsonDecode(secure.values[_secureKey]!), {'base_url': _serverA, 'api_key': 'key-a'});
  });

  test('saved key is not loaded for a different server after restart', () async {
    final secure = ControlledSecureStorage({_secureKey: _document(_serverA, 'key-a'), _legacyKey: 'old-unscoped-key'});
    final container = await _container(secure, {serverBaseUrlPreferenceKey: _serverB});
    await container.read(serverConnectionControllerProvider.notifier).ready;

    expect(container.read(serverConnectionControllerProvider).baseUrl, _serverB);
    expect(container.read(serverConnectionControllerProvider).configured, isFalse);
    expect(secure.values.containsKey(_legacyKey), isFalse);
    final credential = jsonDecode(secure.values[_secureKey]!) as Map<String, Object?>;
    expect(credential['base_url'], _serverA);
  });

  test('delayed initialization finishes before save and cannot overwrite the new key', () async {
    final gate = Completer<void>();
    final started = Completer<void>();
    final secure = ControlledSecureStorage({_legacyKey: 'key-a'})
      ..nextReadGate = gate
      ..nextReadStarted = started;
    final container = await _container(secure, {serverBaseUrlPreferenceKey: _serverA});
    final controller = container.read(serverConnectionControllerProvider.notifier);
    await started.future;
    final saving = controller.save(baseUrl: _serverB, workspaceId: 'other', memberId: 'new-device', apiKey: 'key-b');
    gate.complete();
    await saving;

    expect(container.read(serverConnectionControllerProvider).apiKey, 'key-b');
    expect(container.read(serverConnectionControllerProvider).baseUrl, _serverB);
    final credential = jsonDecode(secure.values[_secureKey]!) as Map<String, Object?>;
    expect(credential['api_key'], 'key-b');
  });

  test('secure write failure does not change server preferences or publish a new connection', () async {
    final secure = ControlledSecureStorage({_secureKey: _document(_serverA, 'key-a')});
    final container = await _container(secure, {serverBaseUrlPreferenceKey: _serverA});
    final controller = container.read(serverConnectionControllerProvider.notifier);
    await controller.ready;
    secure.failWrite = true;

    await expectLater(controller.save(baseUrl: _serverB, workspaceId: 'other', memberId: 'new', apiKey: 'key-b'), throwsStateError);

    expect(container.read(sharedPreferencesProvider).getString(serverBaseUrlPreferenceKey), _serverA);
    expect(container.read(serverConnectionControllerProvider).apiKey, 'key-a');
    container.invalidate(serverConnectionControllerProvider);
    await container.read(serverConnectionControllerProvider.notifier).ready;
    expect(container.read(serverConnectionControllerProvider).baseUrl, _serverA);
    expect(container.read(serverConnectionControllerProvider).apiKey, 'key-a');
  });

  test('partial preference write failure restores the original bound connection', () async {
    final secure = ControlledSecureStorage({_secureKey: _document(_serverA, 'key-a')});
    final preferences = _FailingPreferences({serverBaseUrlPreferenceKey: _serverA, serverWorkspacePreferenceKey: 'personal', serverMemberPreferenceKey: 'desktop'});
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences), secureStorageProvider.overrideWithValue(secure)]);
    addTearDown(container.dispose);
    final controller = container.read(serverConnectionControllerProvider.notifier);
    await controller.ready;
    preferences.failKey = serverWorkspacePreferenceKey;

    await expectLater(controller.save(baseUrl: _serverB, workspaceId: 'other', memberId: 'new', apiKey: 'key-b'), throwsStateError);

    expect(preferences.values[serverBaseUrlPreferenceKey], _serverA);
    expect(jsonDecode(secure.values[_secureKey]!), {'base_url': _serverA, 'api_key': 'key-a'});
    container.invalidate(serverConnectionControllerProvider);
    await container.read(serverConnectionControllerProvider.notifier).ready;
    expect(container.read(serverConnectionControllerProvider).baseUrl, _serverA);
    expect(container.read(serverConnectionControllerProvider).apiKey, 'key-a');
  });

  test('new server and key remain unpublished until their secure write completes', () async {
    final secure = ControlledSecureStorage({_secureKey: _document(_serverA, 'key-a')});
    final container = await _container(secure, {serverBaseUrlPreferenceKey: _serverA});
    final controller = container.read(serverConnectionControllerProvider.notifier);
    await controller.ready;
    final gate = Completer<void>();
    final started = Completer<void>();
    secure
      ..nextWriteGate = gate
      ..nextWriteStarted = started;
    final saving = controller.save(baseUrl: _serverB, workspaceId: 'other', memberId: 'new', apiKey: 'key-b');
    await started.future;

    expect(container.read(serverConnectionControllerProvider).baseUrl, _serverA);
    expect(container.read(serverConnectionControllerProvider).apiKey, 'key-a');
    gate.complete();
    await saving;
    expect(container.read(serverConnectionControllerProvider).baseUrl, _serverB);
    expect(container.read(serverConnectionControllerProvider).apiKey, 'key-b');
  });

  test('invalid bound credential cannot configure a connection', () async {
    final secure = ControlledSecureStorage({_secureKey: 'broken-json', _legacyKey: 'legacy-token'});
    final container = await _container(secure, {serverBaseUrlPreferenceKey: _serverA});
    await container.read(serverConnectionControllerProvider.notifier).ready;

    expect(container.read(serverConnectionControllerProvider).configured, isFalse);
    expect(secure.values.containsKey(_legacyKey), isFalse);
  });
}

/* 创建带独立偏好和安全存储的连接测试容器。 */
Future<ProviderContainer> _container(ControlledSecureStorage secure, Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences), secureStorageProvider.overrideWithValue(secure)]);
  addTearDown(container.dispose);
  return container;
}

/* 编码只用于测试的服务器绑定凭据。 */
String _document(String baseUrl, String apiKey) => jsonEncode({'base_url': baseUrl, 'api_key': apiKey});

/*
*可在指定偏好写入时返回失败的替身。
*/
class _FailingPreferences extends Mock implements SharedPreferences {
  _FailingPreferences(this.values) {
    when(() => getString(any())).thenAnswer((invocation) => values[invocation.positionalArguments.first]);
    when(() => setString(any(), any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      if (key == failKey) {
        return false;
      }
      values[key] = invocation.positionalArguments[1] as String;
      return true;
    });
    when(() => remove(any())).thenAnswer((invocation) async {
      values.remove(invocation.positionalArguments.first);
      return true;
    });
  }

  // 模拟普通偏好内容。
  final Map<String, String> values;

  // 指定失败项；其他项仍可写入和回滚。
  String? failKey;
}
