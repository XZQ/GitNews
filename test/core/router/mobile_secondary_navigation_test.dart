import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/home/presentation/home_mobile_body.dart';
import 'package:github_news/features/home/widgets/home_mobile_radar_overview.dart';
import 'package:github_news/features/tech_hotspot/application/tech_hotspot_providers.dart';
import 'package:github_news/features/tech_hotspot/domain/tech_hotspot_models.dart';
import 'package:github_news/features/tech_hotspot/presentation/widgets/tech_hotspot_topic_card.dart';
import 'package:github_news/features/trending/application/trending_providers.dart';
import 'package:github_news/features/trending/domain/trending_repository.dart';
import 'package:go_router/go_router.dart';

const _radarDigest = TechHotspotDigest(
  languages: [
    LanguageStat(
      name: 'Dart',
      percent: 60,
      delta: 1.2,
      color: 0xFF00B4AB,
      repoCount: 6,
    ),
    LanguageStat(
      name: 'Python',
      percent: 40,
      delta: 0.4,
      color: 0xFF3572A5,
      repoCount: 4,
    ),
  ],
  topics: [
    TechTopic(
      id: 'agent',
      name: 'Agent 框架',
      category: 'Agent',
      heat: 96,
      growth: 12.5,
      mentions: 120,
      relatedRepos: 18,
      summary: 'Agent ecosystem signal',
    ),
    TechTopic(
      id: 'mcp',
      name: 'MCP 协议',
      category: 'Agent',
      heat: 92,
      growth: 11.2,
      mentions: 110,
      relatedRepos: 16,
      summary: 'MCP ecosystem signal',
    ),
    TechTopic(
      id: 'coding',
      name: 'AI Coding 工具',
      category: 'DevTools',
      heat: 88,
      growth: 9.8,
      mentions: 100,
      relatedRepos: 14,
      summary: 'AI coding ecosystem signal',
    ),
    TechTopic(
      id: 'rag',
      name: 'RAG 工程化',
      category: 'Data',
      heat: 82,
      growth: 8.6,
      mentions: 90,
      relatedRepos: 12,
      summary: 'RAG ecosystem signal',
    ),
    TechTopic(
      id: 'local',
      name: '本地推理',
      category: 'Infra',
      heat: 76,
      growth: 7.4,
      mentions: 80,
      relatedRepos: 10,
      summary: 'Local inference ecosystem signal',
    ),
    TechTopic(
      id: 'extra',
      name: '不应出现在总览',
      category: 'Infra',
      heat: 70,
      growth: 6.2,
      mentions: 70,
      relatedRepos: 8,
      summary: 'Only visible on the full Radar page',
    ),
  ],
  heatTrend: [
    TechHeatPoint(label: '周一', value: 70),
    TechHeatPoint(label: '周二', value: 76),
    TechHeatPoint(label: '周三', value: 82),
    TechHeatPoint(label: '周四', value: 88),
    TechHeatPoint(label: '周五', value: 91),
  ],
  hotTags: ['Agent', 'MCP', 'AI Coding'],
);

const _trendingDigest = TrendingDigest(
  trendingRepos: [
    RepoEntity(
      fullName: 'openai/codex',
      description: 'Coding agent',
      language: 'Dart',
      starCount: 12000,
      starDelta: 320,
      forkCount: 800,
      accentArgb: 0xFF00B4AB,
      valueBasis: MetricBasis.observed,
      trendBasis: MetricBasis.estimated,
    ),
  ],
  recentRepos: [],
  languages: [],
  primaryTrend: [12, 18, 24, 30],
  secondaryTrend: [8, 12, 16, 20],
  tertiaryTrend: [],
  topics: [
    TrendingTopicEntity(
      name: 'ai-agents',
      repoCount: 1,
      starCount: 12000,
      basis: MetricBasis.observed,
    ),
  ],
);

void main() {
  testWidgets('雷达整合页展示四块摘要与五个主题并支持导航', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = _buildRouter();
    await tester.pumpWidget(_RouterTestApp(router: router));
    await tester.pumpAndSettle();

    expect(find.textContaining('雷达标签'), findsOneWidget);
    expect(find.text('本周信号热度'), findsOneWidget);
    expect(find.text('语言占比'), findsOneWidget);
    expect(find.byType(TechHotspotTopicCard), findsNWidgets(5));
    expect(find.text('本地推理'), findsWidgets);
    expect(find.text('不应出现在总览'), findsNothing);

    await tester.tap(find.text('AI雷达'));
    await tester.pumpAndSettle();
    expect(find.text('雷达页'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('RAG 工程化'));
    await tester.tap(find.text('RAG 工程化'));
    await tester.pumpAndSettle();
    expect(find.text('雷达详情'), findsOneWidget);
  });

  testWidgets('mobile overview presents eight blocks in reading order', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 5000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/overview-order',
      routes: [
        GoRoute(
          path: '/overview-order',
          builder: (_, __) => const Scaffold(body: HomeMobileBody()),
        ),
      ],
    );
    await tester.pumpWidget(_RouterTestApp(router: router));
    await tester.pumpAndSettle();

    const orderedLabels = ['Agent 榜观察', '热门仓库', 'Star 增长榜', 'AI雷达', '雷达标签', '话题趋势', '本周信号热度', '语言占比'];
    final verticalPositions = [
      for (final label in orderedLabels) tester.getTopLeft(find.textContaining(label).first).dy,
    ];

    for (var index = 1; index < verticalPositions.length; index++) {
      expect(
        verticalPositions[index],
        greaterThan(verticalPositions[index - 1]),
        reason: '${orderedLabels[index]} should follow ${orderedLabels[index - 1]}',
      );
    }
  });
}

/* 构建覆盖总览、AI 雷达和主题详情的测试路由。 */
GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                HomeMobileRadarOverview(),
                SizedBox(height: 16),
                HomeMobileRadarTopicList(),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/tech_hotspot',
        builder: (_, __) => const Scaffold(body: Center(child: Text('雷达页'))),
        routes: [
          GoRoute(
            path: 'detail/:id',
            builder: (_, __) => const Scaffold(body: Text('雷达详情')),
          ),
        ],
      ),
    ],
  );
}

/*
*为移动端 AI 雷达整合测试提供固定数据和中文本地化。
*/
class _RouterTestApp extends StatelessWidget {
  const _RouterTestApp({required this.router});

  // 测试使用的路由实例。
  final GoRouter router;

  /* 构建带 Riverpod 覆盖的路由测试应用。 */
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        techHotspotDigestProvider.overrideWith((ref) async => _radarDigest),
        trendingDigestProvider.overrideWith((ref) async => _trendingDigest),
        trendingHomeDigestProvider.overrideWith((ref) async => _trendingDigest),
      ],
      child: MaterialApp.router(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }
}
