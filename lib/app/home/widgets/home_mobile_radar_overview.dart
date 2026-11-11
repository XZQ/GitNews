import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/tech_hotspot/application/tech_hotspot_providers.dart';
import '../../../features/tech_hotspot/domain/tech_hotspot_models.dart';
import '../../../features/tech_hotspot/presentation/widgets/tech_hotspot_agent_signal_board.dart';
import '../../../features/tech_hotspot/presentation/widgets/tech_hotspot_heat_chart.dart';
import '../../../features/tech_hotspot/presentation/widgets/tech_hotspot_language_panel.dart';
import '../../../features/tech_hotspot/presentation/widgets/tech_hotspot_tags_cloud.dart';
import '../../../features/trending/application/trending_providers.dart';
import '../../../features/trending/widgets/trending_topics_panel.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';

class HomeMobileAgentOverview extends ConsumerWidget {
  const HomeMobileAgentOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(techHotspotDigestProvider);
    return state.when(
      data: (digest) =>
          digest.topics.isEmpty ? EmptyView(icon: Icons.radar_rounded, message: l10n.tr('tech_hotspot.empty.agent_signals')) : TechHotspotAgentSignalBoard(topics: digest.topics, compact: true),
      loading: () => const Skeleton(height: 180),
      error: (error, stack) => ErrorView(
        error: error.asAppException(stack),
        onRetry: () {
          ref.invalidate(techHotspotDigestResultProvider);
          ref.invalidate(techHotspotDigestProvider);
        },
      ),
    );
  }
}

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
        SectionHeader(title: l10n.tr('tech_hotspot.title'), meta: l10n.tr('tech_hotspot.subtitle'), onTap: () => context.push('/tech_hotspot'), showChevron: false),
        const SizedBox(height: AppSpacing.sm),
        state.when(
          data: (digest) => digest.topics.isEmpty ? EmptyView(icon: Icons.radar_rounded, message: l10n.tr('tech_hotspot.empty')) : _RadarSummarySections(digest: digest),
          loading: () => const _RadarSummarySkeleton(),
          error: (error, stack) => ErrorView(error: error.asAppException(stack), onRetry: () => _retry(ref)),
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
    final trending = ref.watch(trendingHomeDigestProvider);
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
        const SizedBox(height: AppSpacing.md),
        // 跨源区块同样要有错误态:失败时只渲染骨架会让用户永远等下去。
        trending.when(
          data: (trendingDigest) => TrendingTopicsPanel(topics: trendingDigest.topics, onTap: () => context.push('/trending'), compact: true),
          loading: () => const Skeleton(height: 150),
          error: (error, stack) => ErrorView(
            error: error.asAppException(stack),
            onRetry: () {
              ref.invalidate(trendingHomeDigestResultProvider);
              ref.invalidate(trendingHomeDigestProvider);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(height: 170, child: TechHotspotHeatChart(values: digest.heatTrend, compact: true)),
        const SizedBox(height: AppSpacing.md),
        // 设计稿的语言占比列到 Top 8,比原先的 5 条多出长尾语言。
        TechHotspotLanguagePanel(languages: digest.languages, maxItems: 8, compact: true),
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
