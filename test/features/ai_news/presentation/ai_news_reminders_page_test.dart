import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/ai_news/application/ai_news_reminder_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_news_reminder.dart';
import 'package:github_news/features/ai_news/presentation/ai_news_reminders_page.dart';
import 'package:github_news/shared/widgets/app_card.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('AI 资讯提醒使用日报同款卡片背景且移动宽度不溢出', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 7, 16, 12);
    final reminders = [
      AiNewsReminder(
        itemId: 'unread',
        title: '未读提醒使用更明确的标题权重和状态点',
        source: '测试来源',
        publishedAt: now.subtract(const Duration(minutes: 15)),
        createdAt: now,
      ),
      AiNewsReminder(
        itemId: 'read',
        title: '已读提醒仍保留统一卡片表面',
        source: '另一个来源',
        publishedAt: now.subtract(const Duration(hours: 2)),
        createdAt: now,
        readAt: now,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiNewsRemindersProvider.overrideWith((ref) async => reminders),
          aiNewsUnreadReminderCountProvider.overrideWithValue(1),
        ],
        child: const MaterialApp(
          locale: Locale('zh', 'CN'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: AiNewsRemindersPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AppCard), findsNWidgets(2));
    expect(find.byType(ListTile), findsNothing);
    expect(find.byType(Divider), findsNothing);
    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
  });

  testWidgets('提醒页顶部返回和系统返回都明确回到 AI 一级页', (tester) async {
    final router = GoRouter(
      initialLocation: '/ai_news/reminders',
      routes: [
        GoRoute(
          path: '/ai_news',
          builder: (context, state) => const Scaffold(
            body: Text('AI_ROOT'),
            bottomNavigationBar: Text('BOTTOM_NAV'),
          ),
          routes: [
            GoRoute(
              path: 'reminders',
              builder: (context, state) => const AiNewsRemindersPage(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiNewsRemindersProvider.overrideWith((ref) async => const []),
          aiNewsUnreadReminderCountProvider.overrideWithValue(0),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/ai_news');
    expect(find.text('BOTTOM_NAV'), findsOneWidget);

    router.go('/ai_news/reminders');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/ai_news');
    expect(find.text('BOTTOM_NAV'), findsOneWidget);
  });
}
