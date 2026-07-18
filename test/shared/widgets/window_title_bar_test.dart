import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/theme/app_colors.dart';
import 'package:github_news/core/theme/app_theme.dart';
import 'package:github_news/shared/widgets/window_title_bar.dart';

const MethodChannel _windowChannel = MethodChannel('github_news/window');
final List<String> _windowMethodCalls = <String>[];

void main() {
  setUp(() {
    _windowMethodCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _windowChannel,
      (call) async {
        _windowMethodCalls.add(call.method);
        return call.method == 'isMaximized' ? false : null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _windowChannel,
      null,
    );
  });

  testWidgets('Windows 应用框架在路由内容上方保留自定义标题栏', (tester) async {
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
        home: DesktopWindowFrame(child: Scaffold(body: Text('route-content'))),
      ),
    );
    await tester.pump();

    expect(find.text('route-content'), findsOneWidget);
    expect(find.byType(WindowTitleBar), Platform.isWindows ? findsOneWidget : findsNothing);
  });

  testWidgets('标题栏窗口控制会转发到 Windows 桥接', (tester) async {
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
        home: DesktopWindowFrame(child: Scaffold(body: Text('route-content'))),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('最小化'));
    await tester.pump();
    await tester.tap(find.byTooltip('最大化'));
    await tester.pump();
    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();

    expect(_windowMethodCalls, contains('minimize'));
    expect(_windowMethodCalls, contains('maximize'));
    expect(_windowMethodCalls, contains('close'));
  });

  testWidgets('浅色标题栏使用不透明主题 surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppTheme.defaultSeed),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh', 'CN'),
        home: const DesktopWindowFrame(child: Scaffold(body: Text('route-content'))),
      ),
    );
    await tester.pump();

    final surface = tester.widget<DecoratedBox>(find.descendant(of: find.byType(WindowTitleBar), matching: find.byType(DecoratedBox)).first);
    final decoration = surface.decoration as BoxDecoration;
    expect(decoration.color, AppColors.surfaceLight);
  });
}
