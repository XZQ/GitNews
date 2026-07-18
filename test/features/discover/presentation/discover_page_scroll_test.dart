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
import 'package:github_news/shared/widgets/mobile_page_header.dart';

/*
*测试用静态仓库列表,避免滚动行为测试访问 GitHub。
*/
class _StaticTrendingReposNotifier extends TrendingReposNotifier {
  _StaticTrendingReposNotifier(this._items, {this.onBuild});

  // 测试仓库快照。
  final List<RepoEntity> _items;

  // 记录下拉刷新触发的重新构建。
  final VoidCallback? onBuild;

  /* 返回足以滚动的静态仓库列表。 */
  @override
  Future<List<RepoEntity>> build() async {
    onBuild?.call();
    return _items;
  }

  @override
  bool get hasMore => false;

  /* 静态列表不加载下一页。 */
  @override
  Future<void> loadMore() async {}

  @override
  Future<void> refresh() async {
    onBuild?.call();
    state = AsyncData(_items);
  }
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
  testWidgets('发现页标题栏不显示数据状态和刷新按钮', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoverReposFreshnessProvider.overrideWith((ref) => DataFreshness.live),
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

    expect(find.text('实时数据'), findsNothing);
    expect(find.byIcon(Icons.refresh_rounded), findsNothing);
    expect(find.byType(HeaderSearchField), findsOneWidget);
    expect(find.text('流行仓库'), findsOneWidget);
    expect(find.text('流行仓库 Top20'), findsNothing);
    expect(tester.getTopLeft(find.byType(HeaderSearchField)).dy, lessThan(tester.getBottomLeft(find.text('发现')).dy));
    expect(find.descendant(of: find.byType(DiscoverSegmented), matching: find.byType(Text)), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('桌面发现页使用单列仓库卡片并隐藏无解释力的趋势口径', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repos = List.generate(
      2,
      (index) => RepoEntity(
        fullName: 'owner/repository-$index',
        description: '用于验证桌面发现页布局的仓库。',
        language: 'Dart',
        starCount: 1000 + index,
        starDelta: 0,
        forkCount: 100 + index,
        accentArgb: 0xFF12B886,
        trendBasis: MetricBasis.estimated,
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

    final first = tester.getTopLeft(find.text('owner/repository-0'));
    final second = tester.getTopLeft(find.text('owner/repository-1'));
    expect(second.dx, first.dx);
    expect(second.dy, greaterThan(first.dy));
    expect(find.text('估算'), findsNothing);
    expect(find.text('—'), findsNothing);
    expect(find.text('流行仓库'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('发现页标题和搜索框固定、分类横条滚动且支持下拉刷新', (tester) async {
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
    var buildCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trendingReposNotifierProvider.overrideWith(
            () => _StaticTrendingReposNotifier(repos, onBuild: () => buildCount++),
          ),
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

    final headerFinder = find.byType(MobilePageHeader, skipOffstage: false);
    final searchFinder = find.byType(HeaderSearchField, skipOffstage: false);
    final segmentedFinder = find.byType(DiscoverSegmented, skipOffstage: false);
    final headerTopBefore = tester.getTopLeft(headerFinder).dy;
    final searchTopBefore = tester.getTopLeft(searchFinder).dy;
    final segmentedTopBefore = tester.getTopLeft(segmentedFinder).dy;
    final verticalListFinder = find.byWidgetPredicate(
      (widget) => widget is ListView && widget.scrollDirection == Axis.vertical,
    );

    expect(find.byType(RefreshIndicator), findsOneWidget);
    await tester.drag(verticalListFinder, const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(buildCount, greaterThan(1));

    await tester.drag(verticalListFinder, const Offset(0, -320));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NestedScrollView), findsOneWidget);
    expect(tester.getTopLeft(headerFinder).dy, headerTopBefore);
    expect(tester.getTopLeft(searchFinder).dy, searchTopBefore);
    expect(tester.getTopLeft(segmentedFinder).dy, lessThan(segmentedTopBefore));
  });
}
