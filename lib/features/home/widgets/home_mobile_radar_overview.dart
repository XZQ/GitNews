import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../tech_hotspot/application/tech_hotspot_providers.dart';
import '../../tech_hotspot/domain/tech_hotspot_models.dart';
import '../../tech_hotspot/presentation/widgets/tech_hotspot_agent_signal_board.dart';
import '../../tech_hotspot/presentation/widgets/tech_hotspot_heat_chart.dart';
import '../../tech_hotspot/presentation/widgets/tech_hotspot_language_panel.dart';
import '../../tech_hotspot/presentation/widgets/tech_hotspot_tags_cloud.dart';
import '../../tech_hotspot/presentation/widgets/tech_hotspot_topic_card.dart';
import '../../trending/application/trending_providers.dart';
import '../../trending/widgets/trending_topics_panel.dart';

/*
* 移动总览中的 AI 雷达摘要，依次展示标签、观察榜、话题趋势、热度和语言占比。
*/
class HomeMobileRadarOverview extends ConsumerWidget {
  const HomeMobileRadarOverview({super.key});

  /* 构建 AI 雷达摘要及加载、空数据和错误状态。 */
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(techHotspotDigestProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.tr('tech_hotspot.title'),
          meta: l10n.tr('tech_hotspot.subtitle'),
          onTap: () => context.push('/tech_hotspot'),
          showChevron: false,
        ),
        const SizedBox(height: AppSpacing.sm),
        state.when(
          data: (digest) => digest.topics.isEmpty
              ? EmptyView(
                  icon: Icons.radar_rounded,
                  message: l10n.tr('tech_hotspot.empty'),
                )
              : _RadarSummarySections(digest: digest),
          loading: () => const _RadarSummarySkeleton(),
          error: (error, stack) => ErrorView(
            error: error.asAppException(stack),
            onRetry: () => _retry(ref),
          ),
        ),
      ],
    );
  }

  /* 重新请求 AI 雷达聚合数据。 */
  void _retry(WidgetRef ref) {
    ref.invalidate(techHotspotDigestResultProvider);
    ref.invalidate(techHotspotDigestProvider);
  }
}

/*
* 移动总览最底部的 AI 雷达详细主题列表。
*/
class HomeMobileRadarTopicList extends ConsumerWidget {
  const HomeMobileRadarTopicList({super.key});

  /* 构建最多五条主题卡片，并保留进入完整雷达页和详情页的能力。 */
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(techHotspotDigestProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.tr('tech_hotspot.topics'),
          subtitle: l10n.tr('tech_hotspot.subtitle'),
          onTap: () => context.push('/tech_hotspot'),
        ),
        const SizedBox(height: AppSpacing.sm),
        state.when(
          data: (digest) => _RadarTopicCards(topics: digest.topics),
          loading: () => const _RadarTopicsSkeleton(),
          error: (error, stack) => ErrorView(
            error: error.asAppException(stack),
            onRetry: () => _retry(ref),
          ),
        ),
      ],
    );
  }

  /* 重新请求 AI 雷达聚合数据。 */
  void _retry(WidgetRef ref) {
    ref.invalidate(techHotspotDigestResultProvider);
    ref.invalidate(techHotspotDigestProvider);
  }
}

/*
* AI 雷达在移动总览中的五块摘要内容。
*/
class _RadarSummarySections extends ConsumerWidget {
  const _RadarSummarySections({required this.digest});

  // 同一次仓库请求返回的 AI 雷达聚合结果。
  final TechHotspotDigest digest;

  /* 按设计稿顺序构建:雷达标签 → Agent 榜观察 → 话题趋势 → 信号热度 → 语言占比。 */
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 话题趋势取自 GitHub 热榜聚合,与雷达数据不同源;设计稿把它排在
    // Agent 榜观察和信号热度之间,所以在这里跨源取一次,而不是把它留在
    // 热榜区块里破坏版面顺序。
    final trending = ref.watch(trendingDigestProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TechHotspotTagsCloud(
          tags: digest.hotTags,
          compact: true,
          onTagSelected: (tag) {
            ref.read(techHotspotSearchQueryProvider.notifier).state = tag;
            context.push('/tech_hotspot');
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        TechHotspotAgentSignalBoard(topics: digest.topics, compact: true),
        const SizedBox(height: AppSpacing.md),
        if (trending.hasValue)
          TrendingTopicsPanel(
            topics: trending.requireValue.topics,
            onTap: () => context.push('/trending'),
            compact: true,
          )
        else
          const Skeleton(height: 150),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 170,
          child: TechHotspotHeatChart(
            values: digest.heatTrend,
            compact: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // 设计稿的语言占比列到 Top 8,比原先的 5 条多出长尾语言。
        TechHotspotLanguagePanel(
          languages: digest.languages,
          maxItems: 8,
          compact: true,
        ),
      ],
    );
  }
}

/*
* AI 雷达主题列表的五条详情卡片。
*/
class _RadarTopicCards extends StatelessWidget {
  const _RadarTopicCards({required this.topics});

  // 完整雷达主题集合，移动总览只展示前五条。
  final List<TechTopic> topics;

  /* 构建空状态或前五条主题卡片。 */
  @override
  Widget build(BuildContext context) {
    final visibleTopics = topics.take(5).toList(growable: false);
    if (visibleTopics.isEmpty) {
      return EmptyView(
        icon: Icons.search_off_rounded,
        message: AppLocalizations.of(context).tr('tech_hotspot.empty.topics'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < visibleTopics.length; index++) ...[
          if (index != 0) const SizedBox(height: AppSpacing.sm),
          TechHotspotTopicCard(
            topic: visibleTopics[index],
            compact: true,
            onTap: () => context.push(
              '/tech_hotspot/detail/${Uri.encodeComponent(visibleTopics[index].id)}',
            ),
          ),
        ],
      ],
    );
  }
}

/*
* AI 雷达四块摘要加载时的占位内容。
*/
class _RadarSummarySkeleton extends StatelessWidget {
  const _RadarSummarySkeleton();

  /* 构建与四块摘要高度接近的轻量骨架。 */
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Skeleton(height: 120),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 180),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 170),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 250),
      ],
    );
  }
}

/*
* AI 雷达详细列表加载时的占位内容。
*/
class _RadarTopicsSkeleton extends StatelessWidget {
  const _RadarTopicsSkeleton();

  /* 构建五条主题列表的轻量骨架。 */
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Skeleton(height: 72),
        SizedBox(height: AppSpacing.sm),
        Skeleton(height: 72),
        SizedBox(height: AppSpacing.sm),
        Skeleton(height: 72),
      ],
    );
  }
}
