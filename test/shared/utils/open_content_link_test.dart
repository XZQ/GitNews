import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/shared/utils/open_content_link.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester, {required String mode, required GoRouter router}) async {
    SharedPreferences.setMockInitialValues({'link_open_mode_migrated_v2': true, 'link_open_mode': mode});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  GoRouter buildRouter(List<String> webviewUrls) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => openContentLink(context: context, ref: ref, uri: Uri.parse('https://example.com/article'), title: '文章标题'),
                  child: const Text('打开链接'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/webview',
          builder: (context, state) {
            webviewUrls.add(state.uri.queryParameters['url'] ?? '');
            return Scaffold(body: Text('WebView:${state.uri.queryParameters['title']}'));
          },
        ),
      ],
    );
  }

  testWidgets('inApp 偏好走应用内 webview 路由并携带 url 与标题', (tester) async {
    final webviewUrls = <String>[];
    await pumpApp(tester, mode: 'inApp', router: buildRouter(webviewUrls));

    await tester.tap(find.text('打开链接'));
    await tester.pumpAndSettle();

    expect(webviewUrls, ['https://example.com/article']);
    expect(find.text('WebView:文章标题'), findsOneWidget);
  });

  testWidgets('external 偏好调用系统浏览器而不是应用内路由', (tester) async {
    final launched = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/url_launcher'), (call) async {
      if (call.method == 'launch') {
        launched.add((call.arguments as Map<Object?, Object?>)['url']! as String);
        return true;
      }
      return false;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/url_launcher'), null));

    final webviewUrls = <String>[];
    await pumpApp(tester, mode: 'external', router: buildRouter(webviewUrls));

    await tester.tap(find.text('打开链接'));
    await tester.pumpAndSettle();

    expect(launched, ['https://example.com/article']);
    expect(webviewUrls, isEmpty);
  });
}
