import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/preferences/ai_digest_config_controller.dart';
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
  AiDigestConfigState build() => AiDigestConfigState(apiKey: _configured ? 'test-key' : null);

  /* 模拟安全存储异步读取完成后更新配置。 */
  void updateConfigured(bool configured) {
    state = AiDigestConfigState(apiKey: configured ? 'test-key' : null);
  }
}

void main() {
  testWidgets('AI 配置读取完成后自动生成增强内容', (tester) async {
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
    expect(find.text('正在自动生成增强内容…'), findsOneWidget);
    expect(find.text('生成增强内容'), findsNothing);

    completion.complete(result);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(callCount, 1);
    expect(find.text(result.generatedSummary), findsOneWidget);
  });

  testWidgets('未配置 AI 时不自动生成增强内容', (tester) async {
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
    expect(find.text('请先在 AI 解读设置中配置兼容端点、模型和 API Key。'), findsOneWidget);
    expect(find.text('生成增强内容'), findsNothing);
    expect(find.text('去配置 →'), findsOneWidget);

    await tester.tap(find.text('去配置 →'));
    await tester.pumpAndSettle();

    expect(find.text('AI 解读设置'), findsOneWidget);
  });

  testWidgets('自动生成失败后显示重试入口', (tester) async {
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
    expect(find.text('条目增强失败，请检查模型配置后重试。'), findsWidgets);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(callCount, 2);
  });
}

/*
*提供详情增强卡所需的本地化与 Material 上下文。
*/
class _TestApp extends StatelessWidget {
  const _TestApp({required this.item});

  // 当前测试资讯。
  final AiNewsItem item;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: AiNewsEnrichmentCard(item: item)),
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
AiNewsEnrichment _enrichment(String itemId) {
  return AiNewsEnrichment(
    itemId: itemId,
    generatedSummary: '自动生成的增强摘要',
    translatedTitle: '自动增强',
    translatedSummary: '详情页打开后无需点击。',
    importanceScore: 88,
    entities: const AiNewsEntities(),
    model: 'test-model',
    updatedAt: DateTime.utc(2026, 7, 16),
  );
}
