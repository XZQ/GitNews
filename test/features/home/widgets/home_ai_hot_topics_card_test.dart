import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/ai_news/application/ai_news_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_hot_topic.dart';
import 'package:github_news/features/home/widgets/home_ai_hot_topics_card.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('总览热点卡展示前三条并打开总览分支详情', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: HomeAiHotTopicsCard(padding: EdgeInsets.zero)),
          routes: [GoRoute(path: 'webview', name: 'home_hot_topic_webview', builder: (_, state) => Text('opened:${state.uri.queryParameters['title']}'))],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiHotTopicsProvider.overrideWith(
            (ref) async => DataResult(
              data: [
                AiHotTopic(
                  id: 'topic-1',
                  title: '热点一',
                  url: 'https://example.com/source',
                  sourceCount: 4,
                  signalCount: 8,
                  permalink: 'https://example.com/topic',
                  source: 'Example',
                  sourceNames: const ['Example'],
                  latestAt: DateTime(2026, 7, 19),
                ),
              ],
              freshness: DataFreshness.freshCache,
            ),
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('当前热点'), findsOneWidget);
    expect(find.text('热点一'), findsOneWidget);
    expect(find.byType(Tooltip), findsNothing);

    await tester.tap(find.text('热点一'));
    await tester.pumpAndSettle();

    expect(find.text('opened:热点一'), findsOneWidget);
  });
}
