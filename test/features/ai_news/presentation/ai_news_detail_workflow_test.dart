import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/preferences/ai_digest_config_controller.dart';
import 'package:github_news/core/router/app_route_branches.dart';
import 'package:github_news/core/shared/local_content_controller.dart';
import 'package:github_news/features/ai_news/application/ai_news_enrichment_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_feedback_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_library_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_news_feedback.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item_state.dart';
import 'package:github_news/features/ai_news/presentation/ai_news_detail_page.dart';
import 'package:github_news/features/repo_detail/application/repo_detail_providers.dart';
import 'package:github_news/features/repo_detail/domain/repo_detail_repository.dart';
import 'package:github_news/features/repo_detail/presentation/repo_detail_page.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/*
*复制与路由测试只读缓存，不触发生成服务。
*/
class _Config extends AiDigestConfigController {
  @override
  /* 模拟未配置服务的离线阅读。 */
  AiDigestConfigState build() => const AiDigestConfigState();
}

/*
*隔离已读副作用；仓库订阅仍使用真正的本地控制器和偏好存储。
*/
class _Library extends AiNewsLibraryController {
  _Library(super.ref);

  @override
  /* 本测试不验证资讯已读落库。 */
  Future<void> markRead(AiNewsItem item) async {}
}

void main() {
  for (final content in ['收录的第一段正文。\n\n第二段保留换行。', '']) {
    testWidgets('copy uses saved source body with summary fallback content=${content.isNotEmpty}', (tester) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      final fixture = await _app(_item(content: content));
      await tester.pumpWidget(fixture.app);
      await tester.pumpAndSettle();
      expect(find.byType(SelectionArea), findsOneWidget);
      await tester.tap(find.byTooltip('更多'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('复制收录正文'));
      await tester.pumpAndSettle();
      expect(clipboard, content.isEmpty ? '这是资讯摘要。' : content);
      expect(find.text('已复制收录正文'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('article repository link uses the existing in-shell route and persists a real monitor subscription', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = await _app(_item());
    await tester.pumpWidget(fixture.app);
    await tester.pumpAndSettle();
    final repoLink = find.byKey(const ValueKey('ai-news-repo-example/research'));
    await tester.ensureVisible(repoLink);
    await tester.pumpAndSettle();
    await tester.tap(repoLink);
    await tester.pumpAndSettle();
    expect(find.byType(RepoDetailPage), findsOneWidget);
    expect(find.byKey(const ValueKey('application-shell')), findsOneWidget);
    final route = GoRouterState.of(tester.element(find.byType(RepoDetailPage)));
    expect(route.name, 'ai_news_repo_detail');
    expect(route.pathParameters['fullName'], 'example/research');
    await tester.tap(find.byTooltip('订阅此仓库'));
    await tester.pumpAndSettle();
    expect(fixture.preferences.getStringList('local_content_monitored_repos'), contains('example/research'));
    final restored = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(fixture.preferences)]);
    addTearDown(restored.dispose);
    expect(restored.read(localContentControllerProvider).isMonitored('example/research'), isTrue);
    fixture.router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(AiNewsDetailPage), findsOneWidget);
    expect(find.byKey(const ValueKey('application-shell')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/* 使用实际 AI 分支的子路由及页面，只替换顶部列表和外围壳。 */
Future<({Widget app, GoRouter router, SharedPreferences preferences})> _app(AiNewsItem item) async {
  SharedPreferences.setMockInitialValues({'local_content_monitored_repos': <String>[]});
  final preferences = await SharedPreferences.getInstance();
  final aiBranch = buildAppRouteBranches().singleWhere((branch) => (branch.routes.first as GoRoute).path == '/ai_news');
  final router = GoRouter(
    initialLocation: '/ai_news/detail/${item.id}',
    routes: [
      ShellRoute(
        builder: (_, __, child) => ColoredBox(key: const ValueKey('application-shell'), color: Colors.white, child: child),
        routes: [GoRoute(path: '/ai_news', builder: (_, __) => const Scaffold(), routes: (aiBranch.routes.single as GoRoute).routes)],
      ),
    ],
  );
  addTearDown(router.dispose);
  final app = ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      aiNewsItemDetailProvider.overrideWith((ref, id) async => item),
      aiNewsRelatedItemsProvider.overrideWith((ref, id) async => <AiNewsItem>[]),
      aiNewsItemStateProvider.overrideWith((ref, id) async => AiNewsItemState.none),
      aiNewsInterestProfileProvider.overrideWith((ref) async => AiNewsInterestProfile.empty),
      aiNewsLibraryControllerProvider.overrideWith(_Library.new),
      aiDigestConfigControllerProvider.overrideWith(_Config.new),
      aiNewsEnrichmentProvider.overrideWith((ref, id) async => null),
      repoDetailResultProvider.overrideWith(
        (ref, name) async => const DataResult(
          data: RepoDetailDigest(repo: _repo, contributors: [], relatedRepos: [], primaryTrend: [], compareTrend: [], activities: []),
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
  );
  return (app: app, router: router, preferences: preferences);
}

/* 独立资讯包含一个可以解析的 GitHub 仓库链接。 */
AiNewsItem _item({String content = ''}) => AiNewsItem(
  id: 'workflow',
  category: AiNewsCategory.industry,
  title: '仓库阅读测试',
  titleEn: '',
  summary: '这是资讯摘要。',
  content: content,
  source: 'Example',
  url: 'https://github.com/example/research',
  permalink: '',
  publishedAt: DateTime.utc(2026, 9, 12),
  score: 80,
  selected: false,
);

// 只用于提供订阅按钮的真实实体形状。
const _repo = RepoEntity(
  fullName: 'example/research',
  description: 'Research repository',
  language: 'Dart',
  starCount: 100,
  starDelta: 0,
  forkCount: 10,
  accentArgb: 0,
  valueBasis: MetricBasis.observed,
);
