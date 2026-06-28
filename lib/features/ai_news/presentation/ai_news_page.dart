import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/breakpoint.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/ai_news_providers.dart';
import '../domain/ai_news_item.dart';
import 'widgets/ai_news_article_card.dart';
import 'widgets/ai_news_category_chips.dart';
import 'widgets/ai_news_hero_banner.dart';
import 'widgets/ai_news_page_header.dart';
import 'widgets/ai_news_topic_sidebar.dart';

/// AI 动态页(桌面 / Expanded 形态)。
///
/// 结构:
/// - 顶部条 [AiNewsPageHeader]
/// - 分类筛选条 [AiNewsCategoryChips]
/// - 主体:左 8 列 Hero + 列表 / 右 4 列 [AiNewsTopicSidebar]
class AiNewsPage extends ConsumerWidget {
  const AiNewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digest = ref.watch(aiNewsDigestProvider);
    final items = ref.watch(aiNewsFilteredItemsProvider);
    final category = ref.watch(aiNewsCategoryFilterProvider);
    final window = ref.watch(aiNewsWindowFilterProvider);
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
            selected: category,
            onSelected: (v) =>
                ref.read(aiNewsCategoryFilterProvider.notifier).state = v,
            window: window,
            onWindowChanged: (v) =>
                ref.read(aiNewsWindowFilterProvider.notifier).state = v,
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
            AiNewsArticleCard(
              item: e,
              onTap: () => context.go('/ai_news/detail/${e.id}'),
            ),
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
          onTap: () => context.go('/ai_news/detail/${hero!.id}'),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final e in rest) ...[
          AiNewsArticleCard(
            item: e,
            onTap: () => context.go('/ai_news/detail/${e.id}'),
          ),
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
