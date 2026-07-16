import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/shared/widgets/mobile_double_back_exit.dart';

void main() {
  testWidgets('一级页面第一次返回提示、第二次返回退出', (tester) async {
    var exitCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MobileDoubleBackExit(
          onExit: () async => exitCount++,
          child: const Scaffold(body: Text('一级页面')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final guard = tester.state<MobileDoubleBackExitState>(find.byType(MobileDoubleBackExit));
    guard.handleBack();
    await tester.pump(const Duration(milliseconds: 200));

    expect(exitCount, 0);
    expect(find.text('再按一次返回键退出应用'), findsOneWidget);

    guard.handleBack();
    await tester.pump(const Duration(milliseconds: 200));

    expect(exitCount, 1);
  });
}
