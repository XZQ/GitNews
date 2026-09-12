import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/repo_check_status.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/shared/widgets/repo_check_status_view.dart';

void main() {
  final now = DateTime.utc(2026, 9, 12, 12);

  for (final brightness in Brightness.values) {
    for (final locale in [const Locale('zh', 'CN'), const Locale('en', 'US')]) {
      testWidgets('failed check remains readable at 260 px with large text in $brightness $locale', (tester) async {
        tester.view.physicalSize = const Size(260, 240);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _app(
            locale: locale,
            brightness: brightness,
            child: RepoCheckStatusView(
              now: now,
              check: RepoCheckStatus(attemptedAt: now, validatedAt: now.subtract(const Duration(hours: 2)), failure: RepoCheckFailure.notFound),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(locale.languageCode == 'zh' ? '仓库不存在或不可见' : 'Repository missing or not visible'), findsOneWidget);
        expect(find.textContaining(locale.languageCode == 'zh' ? '最近成功' : 'Last success'), findsOneWidget);
        expect(find.text('正常'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('unknown timestamp stays pending and expired success needs an update', (tester) async {
    await tester.pumpWidget(_app(child: RepoCheckStatusView(now: now)));
    await tester.pumpAndSettle();
    expect(find.text('尚未检查'), findsOneWidget);
    expect(find.textContaining('最近成功'), findsNothing);
    await tester.pumpWidget(
      _app(
        child: RepoCheckStatusView(
          now: now,
          check: RepoCheckStatus(validatedAt: now.subtract(const Duration(hours: 1))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('待更新'), findsOneWidget);
  });
}

/* 用真实中英文资源与大字号验证检查结果的换行。 */
Widget _app({required Widget child, Locale locale = const Locale('zh', 'CN'), Brightness brightness = Brightness.light}) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
  theme: ThemeData(brightness: brightness),
  builder: (context, content) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.5)),
    child: content!,
  ),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);
