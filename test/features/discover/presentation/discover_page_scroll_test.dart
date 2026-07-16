import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/shared/local_content_controller.dart';
import 'package:github_news/features/discover/application/discover_notifiers.dart';
import 'package:github_news/features/discover/application/discover_providers.dart';
import 'package:github_news/features/discover/presentation/discover_page.dart';
import 'package:github_news/features/discover/presentation/widgets/discover_segmented.dart';
import 'package:github_news/shared/widgets/header_search_field.dart';

/*
*测试用静态仓库列表,避免滚动行为测试访问 GitHub。
*/
class _StaticTrendingReposNotifier extends TrendingReposNotifier {
  _StaticTrendingReposNotifier(this._items);

  // 测试仓库快照。
  final List<RepoEntity> _items;

  /* 返回足以滚动的静态仓库列表。 */
  @override
  Future<List<RepoEntity>> build() async => _items;

  @override
  bool get hasMore => false;

  /* 静态列表不加载下一页。 */
  @override
  Future<void> loadMore() async {}
}

/*
*测试用空本地收藏状态,避免读取 SharedPreferences。
*/
class _StaticLocalContentController extends LocalContentController {
  /* 返回无收藏、无监控的静态状态。 */
  @override
  LocalContentState build() {
    return const LocalContentState(
      bookmarkedRepos: {},
      monitoredRepos: {},
      monitoredSkills: {},
      followedDevelopers: {},
      monitorRules: [false, false, false, false],
      repoSnapshots: {},
      developerSnapshots: {},
    );
  }
}

void main() {
  testWidgets('发现页不显示新鲜缓存状态', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoverReposFreshnessProvider.overrideWith((ref) => DataFreshness.freshCache),
          trendingReposNotifierProvider.overrideWith(() => _StaticTrendingReposNotifier(const [])),
          localContentControllerProvider.overrideWith(_StaticLocalContentController.new),
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
          home: DiscoverHubPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('新鲜缓存'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('发现页搜索框与分类横条随列表滚动且标题栏固定', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repos = List.generate(
      12,
      (index) => RepoEntity(
        fullName: 'owner/repository-$index',
        description: '第 $index 个用于验证发现页滚动行为的仓库。',
        language: index.isEven ? 'Dart' : 'Python',
        starCount: 1000 + index,
        starDelta: 10 + index,
        forkCount: 100 + index,
        accentArgb: 0xFF12B886,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trendingReposNotifierProvider.overrideWith(() => _StaticTrendingReposNotifier(repos)),
          localContentControllerProvider.overrideWith(_StaticLocalContentController.new),
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
          home: DiscoverHubPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final appBarFinder = find.byType(AppBar, skipOffstage: false);
    final searchFinder = find.byType(HeaderSearchField, skipOffstage: false);
    final segmentedFinder = find.byType(DiscoverSegmented, skipOffstage: false);
    final appBarTopBefore = tester.getTopLeft(appBarFinder).dy;
    final searchTopBefore = tester.getTopLeft(searchFinder).dy;
    final segmentedTopBefore = tester.getTopLeft(segmentedFinder).dy;
    final verticalList = tester.widgetList<ListView>(find.byType(ListView)).firstWhere((list) => list.scrollDirection == Axis.vertical);

    await tester.drag(find.byWidget(verticalList), const Offset(0, -320));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NestedScrollView), findsOneWidget);
    expect(tester.getTopLeft(appBarFinder).dy, appBarTopBefore);
    expect(tester.getTopLeft(searchFinder).dy, lessThan(searchTopBefore));
    expect(tester.getTopLeft(segmentedFinder).dy, lessThan(segmentedTopBefore));
  });
}
