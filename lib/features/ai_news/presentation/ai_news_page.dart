import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/breakpoint.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/ai_news_providers.dart';
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
class AiNewsPage extends ConsumerStatefulWidget {
  const AiNewsPage({super.key});

  @override
  ConsumerState<AiNewsPage> createState() => _AiNewsPageState();
}

class _AiNewsPageState extends ConsumerState<AiNewsPage> {
  AiNewsCategory? _category;
  String _window = '24h';

  @override
  Widget build(BuildContext context) {
    final digest = ref.watch(aiNewsDigestProvider);
    final items = _filtered(digest.items);
    final hero = items.where((e) => e.isHero).firstOrNull;
    final rest = items.where((e) => !e.isHero).toList();
    final formFactor = Breakpoints.of(context);
    final isCompact = formFactor == FormFactor.compact;

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
              padding: EdgeInsets.fromLTRB(
                isCompact ? AppSpacing.lg : AppSpacing.xl,
                AppSpacing.lg,
                isCompact ? AppSpacing.lg : AppSpacing.xl,
                AppSpacing.xxxl,
              ),
              child: _ResponsiveBody(
                main: _MainList(hero: hero, rest: rest),
                sidebar: AiNewsTopicSidebar(
                  hotTopics: digest.hotTopics,
                  topCompanies: digest.topCompanies,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<AiNewsItem> _filtered(List<AiNewsItem> items) {
    if (_category == null) return items;
    return items.where((e) => e.category == _category).toList();
  }
}

class _ResponsiveBody extends StatelessWidget {
  const _ResponsiveBody({required this.main, required this.sidebar});

  final Widget main;
  final Widget sidebar;

  @override
  Widget build(BuildContext context) {
    final formFactor = Breakpoints.of(context);
    if (formFactor == FormFactor.expanded) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 8, child: main),
          const SizedBox(width: AppSpacing.lg),
          Expanded(flex: 4, child: sidebar),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        main,
        const SizedBox(height: AppSpacing.lg),
        sidebar,
      ],
    );
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
