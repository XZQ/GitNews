import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/preferences/server_connection_controller.dart';
import 'package:github_news/features/settings/presentation/self_hosted_server_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/controlled_secure_storage.dart';

const _serverA = 'https://server-a.example';
const _serverB = 'https://server-b.example';
const _secureKey = 'self_hosted_server_connection_v2';

void main() {
  testWidgets('changing the server address requires a new key instead of inheriting the previous key', (tester) async {
    final secure = _storage();
    final container = await _pump(tester, secure);
    final oldDocument = secure.values[_secureKey];
    await _openEditor(tester);
    expect(find.text('Leave blank to keep the current key'), findsOneWidget);

    await tester.enterText(_field('Server URL'), _serverB);
    await tester.pump();
    expect(find.text('Leave blank to keep the current key'), findsNothing);
    await _save(tester);

    expect(find.text('Invalid connection configuration.'), findsOneWidget);
    expect(container.read(serverConnectionControllerProvider).baseUrl, _serverA);
    expect(container.read(serverConnectionControllerProvider).apiKey, 'key-a');
    expect(container.read(sharedPreferencesProvider).getString(serverBaseUrlPreferenceKey), _serverA);
    expect(secure.values[_secureKey], oldDocument);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an equivalent normalized address can keep the key while saving other connection changes', (tester) async {
    final secure = _storage();
    final container = await _pump(tester, secure);
    await _openEditor(tester);
    await tester.enterText(_field('Server URL'), 'https://SERVER-A.example:443/');
    await tester.enterText(_field('Workspace ID'), 'other-workspace');
    await tester.pump();
    expect(find.text('Leave blank to keep the current key'), findsOneWidget);
    await _save(tester);

    final connection = container.read(serverConnectionControllerProvider);
    expect(connection.baseUrl, _serverA);
    expect(connection.workspaceId, 'other-workspace');
    expect(connection.apiKey, 'key-a');
    expect(jsonDecode(secure.values[_secureKey]!), {'base_url': _serverA, 'api_key': 'key-a'});
    expect(find.text('Invalid connection configuration.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a different server can be saved when the user supplies its new key', (tester) async {
    final secure = _storage();
    final container = await _pump(tester, secure);
    await _openEditor(tester);
    await tester.enterText(_field('Server URL'), _serverB);
    await tester.enterText(_field('Master API Key'), 'key-b');
    await _save(tester);

    expect(container.read(serverConnectionControllerProvider).baseUrl, _serverB);
    expect(container.read(serverConnectionControllerProvider).apiKey, 'key-b');
    expect(jsonDecode(secure.values[_secureKey]!), {'base_url': _serverB, 'api_key': 'key-b'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('a storage failure is reported without an uncaught callback error or replacing the connection', (tester) async {
    final secure = _storage();
    final container = await _pump(tester, secure);
    final oldDocument = secure.values[_secureKey];
    secure.failWrite = true;
    await _openEditor(tester);
    await tester.enterText(_field('Server URL'), _serverB);
    await tester.enterText(_field('Master API Key'), 'key-b');
    await _save(tester);

    expect(find.text('Operation failed. Check the URL, key, workspace, and server status.'), findsOneWidget);
    expect(container.read(serverConnectionControllerProvider).baseUrl, _serverA);
    expect(container.read(serverConnectionControllerProvider).apiKey, 'key-a');
    expect(container.read(sharedPreferencesProvider).getString(serverBaseUrlPreferenceKey), _serverA);
    expect(secure.values[_secureKey], oldDocument);
    expect(tester.takeException(), isNull);
  });
}

/* 返回仅包含测试 Key 的内存安全存储。 */
ControlledSecureStorage _storage() => ControlledSecureStorage({
  _secureKey: jsonEncode({'base_url': _serverA, 'api_key': 'key-a'}),
});

/* 在桌面尺寸和英文 locale 下挂载真实连接控制器与编辑页面。 */
Future<ProviderContainer> _pump(WidgetTester tester, ControlledSecureStorage secure) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(1024, 768);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  SharedPreferences.setMockInitialValues({serverBaseUrlPreferenceKey: _serverA});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences), secureStorageProvider.overrideWithValue(secure)]);
  addTearDown(container.dispose);
  await container.read(serverConnectionControllerProvider.notifier).ready;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('en', 'US'),
        localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: SelfHostedServerPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/* 按输入标签定位字段，避免依赖控件排列。 */
Finder _field(String label) => find.byWidgetPredicate((widget) => widget is TextField && widget.decoration?.labelText == label);

/* 打开连接编辑对话框并等待动画完成。 */
Future<void> _openEditor(WidgetTester tester) async {
  await tester.tap(find.text('Edit'));
  await tester.pumpAndSettle();
}

/* 从真实按钮提交并等待持久化和提示完成。 */
Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}
