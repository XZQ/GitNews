import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/theme/app_colors.dart';
import 'package:github_news/core/theme/app_theme.dart';
import 'package:github_news/features/ai_news/application/ai_news_feedback_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_library_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_news_feedback.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item_state.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_article_card.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_event_reports.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_item_list.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final width in [390.0, 1000.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('all reports open independently at width=$width $brightness with large text', (tester) async {
        _viewport(tester, width);
        final router = _router(_reports());
        addTearDown(router.dispose);
        await tester.pumpWidget(_app(router, brightness: brightness, scale: 2));
        await tester.pumpAndSettle();
        expect(find.text('3 篇相关报道 · 2 个来源'), findsOneWidget);
        expect(find.byKey(const ValueKey('ai-news-report-b')), findsNothing);
        await tester.ensureVisible(find.byKey(const ValueKey('ai-news-event-toggle')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('ai-news-event-toggle')));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/ai_news', reason: 'Expanding must not open the primary article');
        expect(find.textContaining('尚未交叉核验'), findsOneWidget);
        for (final id in ['a', 'b', 'c']) {
          await tester.ensureVisible(find.byKey(ValueKey('ai-news-report-$id')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(ValueKey('ai-news-report-$id')));
          await tester.pumpAndSettle();
          expect(find.text('opened:$id'), findsOneWidget);
          router.pop();
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('expanded reports retain their event identity after interest ranking changes', (tester) async {
    _viewport(tester, 1000);
    var profile = AiNewsInterestProfile.empty;
    final router = _router([..._reports(), _report('other', title: 'Robots learn dexterous manipulation')]);
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router, profile: () => profile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ai-news-event-toggle')));
    await tester.pumpAndSettle();
    final stateBefore = tester.state(find.byType(AiNewsEventReports));
    profile = const AiNewsInterestProfile(itemSignals: {'a': AiNewsFeedbackSignal.less, 'other': AiNewsFeedbackSignal.more});
    ProviderScope.containerOf(tester.element(find.byType(AiNewsItemList))).invalidate(aiNewsInterestProfileProvider);
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(AiNewsEventReports)), same(stateBefore));
    expect(find.byKey(const ValueKey('ai-news-report-b')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('ai-news-report-b')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ai-news-report-b')));
    await tester.pumpAndSettle();
    expect(find.text('opened:b'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search keeps similar reports separate and source heat explains its meaning', (tester) async {
    _viewport(tester, 1000);
    final router = _router(_reports(), search: true);
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    expect(find.byType(AiNewsEventReports), findsNothing);
    expect(find.byType(AiNewsArticleCard), findsNWidgets(3));
    expect(find.text('来源热度 90'), findsOneWidget);
    final tooltips = tester.widgetList<Tooltip>(find.byType(Tooltip)).map((tooltip) => tooltip.message ?? '');
    expect(tooltips.any((message) => message.contains('不代表事实')), isTrue);
  });
}

/* 设置逻辑像素视口，避免使用真实窗口。 */
void _viewport(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/* 保留资讯列表所在路由，逐篇访问各自 ID。 */
GoRouter _router(List<AiNewsItem> items, {bool search = false}) => GoRouter(
  initialLocation: '/ai_news',
  routes: [
    GoRoute(
      path: '/ai_news',
      builder: (_, __) => Scaffold(
        body: AiNewsItemList(items: items, category: null, query: '', staticList: true, searchResults: search),
      ),
      routes: [
        GoRoute(
          path: 'detail/:id',
          builder: (_, state) => Scaffold(body: Text('opened:${state.pathParameters['id']}')),
        ),
      ],
    ),
  ],
);

/* 隔离资料库与兴趣依赖，不进行网络访问。 */
Widget _app(GoRouter router, {Brightness brightness = Brightness.light, double scale = 1, AiNewsInterestProfile Function()? profile}) => ProviderScope(
  overrides: [aiNewsInterestProfileProvider.overrideWith((ref) async => profile?.call() ?? AiNewsInterestProfile.empty), aiNewsItemStateProvider.overrideWith((ref, id) async => AiNewsItemState.none)],
  child: MaterialApp.router(
    locale: const Locale('zh', 'CN'),
    localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.fromSeed(brightness, AppColors.brand),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    routerConfig: router,
  ),
);

/* 同一来源的两篇报道不能算作两个独立来源。 */
List<AiNewsItem> _reports() => [_report('a'), _report('b'), _report('c', source: '另一个来源')];

/* 构建足够相似但 ID 不同的标题，并用长来源检验换行。 */
AiNewsItem _report(String id, {String? title, String source = 'Very long research publication source with complete attribution'}) => AiNewsItem(
  id: id,
  category: AiNewsCategory.industry,
  title: title ?? 'Model release improves coding benchmark accuracy $id',
  titleEn: '',
  summary: '研究团队公布了完整的方法和评估结果。',
  source: source,
  url: 'https://example.com/$id',
  permalink: '',
  publishedAt: DateTime.utc(2026, 9, 12, id == 'a' ? 12 : 11),
  score: id == 'a' ? 90 : 10,
  selected: false,
);
