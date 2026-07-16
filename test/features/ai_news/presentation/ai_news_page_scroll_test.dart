import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/preferences/ai_digest_config_controller.dart';
import 'package:github_news/features/ai_news/application/ai_digest_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_reminder_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/presentation/ai_news_page.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_category_nav.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_page_header.dart';

/*
*测试用静态资讯状态,避免滚动行为测试访问网络和本地数据库。
*/
class _StaticAiNewsItemsNotifier extends AiNewsItemsNotifier {
  _StaticAiNewsItemsNotifier(this._items);

  // 测试列表快照。
  final List<AiNewsItem> _items;

  /* 返回足以滚动的静态资讯列表。 */
  @override
  Future<List<AiNewsItem>> build() async => _items;

  @override
  bool get hasMore => false;

  /* 静态列表不加载下一页。 */
  @override
  Future<void> loadMore() async {}
}

/*
*测试用日报配置,固定为未配置态。
*/
class _StaticAiDigestConfigController extends AiDigestConfigController {
  /* 跳过安全存储读取。 */
  @override
  AiDigestConfigState build() => const AiDigestConfigState();
}

/*
*测试用日报内容,固定为空。
*/
class _StaticAiDigestNotifier extends AiDigestNotifier {
  /* 跳过偏好存储读取。 */
  @override
  Future<String?> build() async => null;
}

void main() {
  testWidgets('AI 页头与分类横条随资讯列表向上滚动', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 7, 16, 12);
    final items = List.generate(
      12,
      (index) => AiNewsItem(
        id: 'scroll-$index',
        category: AiNewsCategory.values[index % AiNewsCategory.values.length],
        title: '第 $index 条独立 AI 资讯主题',
        titleEn: 'Independent AI topic $index',
        summary: '用于验证顶部搜索框和分类横条会随内容一起滚动。',
        source: '测试来源 $index',
        publishedAt: now.subtract(Duration(days: index)),
        score: 60 + index,
        selected: false,
        url: 'https://example.com/$index',
        permalink: 'https://example.com/$index',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiNewsItemsNotifierProvider.overrideWith(() => _StaticAiNewsItemsNotifier(items)),
          aiNewsUnreadReminderCountProvider.overrideWithValue(0),
          aiDigestConfigControllerProvider.overrideWith(_StaticAiDigestConfigController.new),
          aiDigestNotifierProvider.overrideWith(_StaticAiDigestNotifier.new),
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
          home: AiNewsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final headerFinder = find.byType(AiNewsPageHeader, skipOffstage: false);
    final categoryFinder = find.byType(AiNewsCategoryNav, skipOffstage: false);
    final headerTopBefore = tester.getTopLeft(headerFinder).dy;
    final categoryTopBefore = tester.getTopLeft(categoryFinder).dy;

    await tester.drag(find.byType(CustomScrollView).last, const Offset(0, -320));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NestedScrollView), findsOneWidget);
    expect(tester.getTopLeft(headerFinder).dy, lessThan(headerTopBefore));
    expect(tester.getTopLeft(categoryFinder).dy, lessThan(categoryTopBefore));
  });
}
