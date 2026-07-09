import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/errors/app_exception.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/shared/widgets/error_view.dart';

void main() {
  group('ErrorView', () {
    testWidgets('network error renders wifi icon and retry button', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh', 'CN'),
          home: Scaffold(
            body: ErrorView(
              error: const AppException(kind: AppExceptionKind.network),
              onRetry: () => retried++,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('网络连接失败,请检查后重试'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '重试'));
      expect(retried, 1);
    });

    testWidgets('rateLimit error shows retry-after seconds', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh', 'CN'),
          home: Scaffold(
            body: ErrorView(
              error: AppException(
                kind: AppExceptionKind.rateLimit,
                meta: {'retryAfter': 30},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);
      expect(find.textContaining('30 秒'), findsOneWidget);
    });

    testWidgets('unauthorized falls back to onRetry when onLogin missing', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh', 'CN'),
          home: Scaffold(
            body: ErrorView(
              error: const AppException(kind: AppExceptionKind.unauthorized),
              onRetry: () => retried++,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('登录已过期,请重新登录'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '重试'));
      expect(retried, 1);
    });

    testWidgets('unknown error renders generic copy', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh', 'CN'),
          home: Scaffold(
            body: ErrorView(
              error: AppException(kind: AppExceptionKind.unknown),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('出错了,请稍后重试'), findsOneWidget);
    });
  });
}
