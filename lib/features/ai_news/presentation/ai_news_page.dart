import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../data/mock_ai_news.dart';
import '../domain/ai_news_item.dart';
import 'widgets/ai_news_article_card.dart';
import 'widgets/ai_news_category_chips.dart';
import 'widgets/ai_news_hero_banner.dart';
import 'widgets/ai_news_page_header.dart';
import 'widgets/ai_news_topic_sidebar.dart';

/// AI 资讯页(桌面 / Expanded 形态)。
///
/// 结构:
/// - 顶部条 [AiNewsPageHeader]
/// - 分类筛选条 [AiNewsCategoryChips]
/// - 主体:左 8 列 Hero + 列表 / 右 4 列 [AiNewsTopicSidebar]
class AiNewsPage extends StatefulWidget {
  const AiNewsPage({super.key});

  @override
  State<AiNewsPage> createState() => _AiNewsPageState();
}

class _AiNewsPageState extends State<AiNewsPage> {
  AiNewsCategory? _category;
  String _window = '24h';

  @override
  Widget build(BuildContext context) {
    final items = _filtered();
    final hero = items.where((e) => e.isHero).firstOrNull;
    final rest = items.where((e) => !e.isHero).toList();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AiNewsPageHeader(),
          AiNewsCategoryChips(
            selected: _category,
            onSelected: (v) => setState(() => _category = v),
            window: _window,
            onWindowChanged: (v) => setState(() => _window = v),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xxxl,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 8, child: _MainList(hero: hero, rest: rest)),
                  const SizedBox(width: AppSpacing.lg),
                  const Expanded(flex: 4, child: AiNewsTopicSidebar()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<AiNewsItem> _filtered() {
    if (_category == null) return MockAiNews.all;
    return MockAiNews.all.where((e) => e.category == _category).toList();
  }
}

class _MainList extends StatelessWidget {
  const _MainList({required this.hero, required this.rest});

  final AiNewsItem? hero;
  final List<AiNewsItem> rest;

  @override
  Widget build(BuildContext context) {
    if (hero == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in rest) ...[
            AiNewsArticleCard(item: e, onTap: () {}),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AiNewsHeroBanner(
          item: hero!,
          categoryLabel: _label(hero!.category),
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final e in rest) ...[
          AiNewsArticleCard(item: e, onTap: () {}),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  static String _label(AiNewsCategory c) {
    switch (c) {
      case AiNewsCategory.industry:
        return '行业动态';
      case AiNewsCategory.breakthrough:
        return '技术突破';
      case AiNewsCategory.application:
        return '产业应用';
      case AiNewsCategory.funding:
        return '投融资';
    }
  }
}
