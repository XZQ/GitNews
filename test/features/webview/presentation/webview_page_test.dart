import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/webview/presentation/webview_page.dart';

void main() {
  testWidgets('热点详情精简模式只保留应用返回和标题', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh', 'CN'),
        localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: WebViewPage(url: '', title: '热点详情', showPageActions: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('热点详情'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsNothing);
    expect(find.byIcon(Icons.open_in_new_rounded), findsNothing);
    expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
  });
}
