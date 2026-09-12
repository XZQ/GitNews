import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/preferences/ai_digest_config_controller.dart';
import 'package:github_news/core/theme/app_colors.dart';
import 'package:github_news/core/theme/app_theme.dart';
import 'package:github_news/features/ai_news/application/ai_news_enrichment_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_news_enrichment.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_enrichment_card.dart';

/*
*测试用 AI 配置状态,避免读取真实安全存储。
*/
class _StaticAiDigestConfigController extends AiDigestConfigController {
  _StaticAiDigestConfigController(this._configured);

  // 是否模拟已配置 AI。
  final bool _configured;

  /* 返回固定配置状态。 */
  @override
  AiDigestConfigState build() => AiDigestConfigState(serviceUrl: 'https://proxy.example', isAuthenticated: _configured);

  /* 模拟安全存储异步读取完成后更新配置。 */
  void updateConfigured(bool configured) {
    state = AiDigestConfigState(serviceUrl: 'https://proxy.example', isAuthenticated: configured);
  }
}

void main() {
  testWidgets('Agnes 返回有效数据后才显示 AI 摘要与翻译', (tester) async {
    final item = _item();
    final result = _enrichment(item.id);
    final completion = Completer<AiNewsEnrichment?>();
    AiNewsEnrichment? stored;
    late _StaticAiDigestConfigController configController;
    var callCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiDigestConfigControllerProvider.overrideWith(() {
            configController = _StaticAiDigestConfigController(false);
            return configController;
          }),
          aiNewsEnrichmentProvider.overrideWith((ref, id) async => stored),
          aiNewsEnrichmentGeneratorProvider.overrideWith((ref) {
            return (AiNewsItem requested, {bool force = false}) async {
              callCount++;
              expect(requested.id, item.id);
              expect(force, isFalse);
              stored = await completion.future;
              ref.invalidate(aiNewsEnrichmentProvider(requested.id));
              return stored;
            };
          }),
        ],
        child: _TestApp(item: item),
      ),
    );
    await tester.pumpAndSettle();

    expect(callCount, 0);
    configController.updateConfigured(true);
    await tester.pump();
    await tester.pump();

    expect(callCount, 1);
    expect(find.text('AI 摘要与翻译'), findsNothing);

    completion.complete(result);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(callCount, 1);
    expect(find.text(result.generatedSummary), findsOneWidget);
  });

  testWidgets('未配置代理或未登录时隐藏新的 AI 生成', (tester) async {
    final item = _item();
    var callCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiDigestConfigControllerProvider.overrideWith(() => _StaticAiDigestConfigController(false)),
          aiNewsEnrichmentProvider.overrideWith((ref, id) async => null),
          aiNewsEnrichmentGeneratorProvider.overrideWith((ref) {
            return (AiNewsItem requested, {bool force = false}) async {
              callCount++;
              return null;
            };
          }),
        ],
        child: _TestApp(item: item),
      ),
    );
    await tester.pumpAndSettle();

    expect(callCount, 0);
    expect(find.text('AI 摘要与翻译'), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('退出登录后保留缓存阅读并关闭重新生成入口', (tester) async {
    final item = _item();
    final result = _enrichment(item.id);
    late _StaticAiDigestConfigController config;
    var callCount = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiDigestConfigControllerProvider.overrideWith(() => config = _StaticAiDigestConfigController(true)),
          aiNewsEnrichmentProvider.overrideWith((ref, id) async => result),
          aiNewsEnrichmentGeneratorProvider.overrideWith((ref) {
            return (AiNewsItem requested, {bool force = false}) async {
              callCount++;
              return result;
            };
          }),
        ],
        child: _TestApp(item: item),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    config.updateConfigured(false);
    await tester.pumpAndSettle();
    expect(find.text(result.generatedSummary), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsNothing);
    expect(callCount, 0);
  });

  testWidgets('Agnes 请求失败时隐藏 AI 摘要与翻译', (tester) async {
    final item = _item();
    var callCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiDigestConfigControllerProvider.overrideWith(() => _StaticAiDigestConfigController(true)),
          aiNewsEnrichmentProvider.overrideWith((ref, id) async => null),
          aiNewsEnrichmentGeneratorProvider.overrideWith((ref) {
            return (AiNewsItem requested, {bool force = false}) async {
              callCount++;
              throw StateError('generation failed');
            };
          }),
        ],
        child: _TestApp(item: item),
      ),
    );
    await tester.pumpAndSettle();

    expect(callCount, 1);
    expect(find.text('AI 摘要与翻译'), findsNothing);
    expect(find.text('重试'), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets('AI 字段标注准确且长文完整显示 $brightness', (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final item = _item();
      final result = _enrichment(item.id, longContent: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [aiDigestConfigControllerProvider.overrideWith(() => _StaticAiDigestConfigController(false)), aiNewsEnrichmentProvider.overrideWith((ref, id) async => result)],
          child: _TestApp(item: item, brightness: brightness),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('AI 摘要与翻译'), findsOneWidget);
      expect(find.text('生成摘要'), findsOneWidget);
      expect(find.text('摘要中文翻译'), findsOneWidget);
      expect(find.text('识别实体'), findsOneWidget);
      expect(find.textContaining('请核对原文'), findsOneWidget);
      expect(find.text('未识别到实体'), findsOneWidget);
      expect(find.text('核心观点'), findsNothing);
      final body = tester.widget<Text>(find.text(result.translatedSummary));
      expect(body.maxLines, isNull);
      expect(body.overflow, isNot(TextOverflow.ellipsis));
      await tester.ensureVisible(find.text('AI 重要性估计 88/100（非可信度）'));
      await tester.pumpAndSettle();
      expect(find.text('AI 重要性估计 88/100（非可信度）').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

/*
*提供详情增强卡所需的本地化与 Material 上下文。
*/
class _TestApp extends StatelessWidget {
  const _TestApp({required this.item, this.brightness = Brightness.light});

  // 当前测试资讯。
  final AiNewsItem item;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.fromSeed(brightness, AppColors.brand),
      home: Scaffold(
        body: SingleChildScrollView(child: AiNewsEnrichmentCard(item: item)),
      ),
    );
  }
}

/* 创建测试资讯。 */
AiNewsItem _item() {
  return AiNewsItem(
    id: 'auto-enrichment-item',
    category: AiNewsCategory.paper,
    title: 'Automatic enrichment',
    titleEn: 'Automatic enrichment',
    summary: 'Open the detail page and generate automatically.',
    source: 'Test',
    url: 'https://example.com/article',
    permalink: 'https://example.com/article',
    publishedAt: DateTime(2026, 7, 16),
    score: 80,
    selected: true,
  );
}

/* 创建测试增强结果。 */
AiNewsEnrichment _enrichment(String itemId, {bool longContent = false}) {
  return AiNewsEnrichment(
    itemId: itemId,
    generatedSummary: '自动生成的增强摘要',
    translatedTitle: '自动增强',
    translatedSummary: longContent ? List.filled(12, '这是来自文章摘要的中文翻译，应当完整显示并允许核对原文。').join() : '详情页打开后无需点击。',
    importanceScore: 88,
    entities: const AiNewsEntities(),
    model: 'agnes-2.0-flash',
    updatedAt: DateTime.utc(2026, 7, 16),
  );
}
