import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../../trending/application/trending_providers.dart';
import '../../trending/domain/trending_repository.dart';
import '../../trending/widgets/trending_metrics.dart';
import '../../trending/widgets/trending_topics_panel.dart';

/*
* 移动总览中的 GitHub 热榜三块内容：Star 增长、热门仓库和话题趋势。
*/
class HomeMobileTrendingOverview extends ConsumerWidget {
  const HomeMobileTrendingOverview({super.key});

  /* 构建 GitHub 热榜三块内容及统一的加载和错误状态。 */
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trendingDigestProvider);
    return state.when(
      data: (digest) => _TrendingSections(digest: digest),
      loading: () => const _TrendingSkeleton(),
      error: (error, stack) => ErrorView(
        error: error.asAppException(stack),
        onRetry: () {
          ref.invalidate(trendingDigestResultProvider);
          ref.invalidate(trendingDigestProvider);
        },
      ),
    );
  }
}

/*
* 移动总览中的三块 GitHub 热榜正文。
*/
class _TrendingSections extends ConsumerWidget {
  const _TrendingSections({required this.digest});

  // 当前时间窗和语言筛选对应的 GitHub 热榜摘要。
  final TrendingDigest digest;

  /* 按 Star 增长、热门仓库、话题趋势的顺序构建内容。 */
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final window = ref.watch(trendingWindowFilterProvider);
    final windowLabel = _windowLabel(l10n, window);
    final repos = digest.trendingRepos.take(3).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tr('trending.mobile.star_growth_rank'),
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.tr('trending.mobile.tracking_subtitle').replaceAll('{window}', windowLabel),
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TrendingWindowSegmented(
                value: window,
                onChanged: (value) => ref.read(trendingWindowFilterProvider.notifier).state = value,
              ),
              const SizedBox(height: AppSpacing.md),
              RepaintBoundary(
                child: StarTrendChart(
                  series: [
                    ChartSeries(
                      values: digest.primaryTrend,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    ChartSeries(
                      values: digest.secondaryTrend,
                      color: AppColors.success,
                    ),
                  ],
                  height: 200,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: l10n.tr('trending.page.repos'),
          subtitle: l10n.tr('trending.mobile.repos_count').replaceAll('{window}', windowLabel).replaceAll('{count}', '${repos.length}'),
          onTap: () => context.push('/trending'),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (repos.isEmpty)
          EmptyView(
            icon: Icons.local_fire_department_outlined,
            message: l10n.tr('trending.hot_repos.empty'),
          )
        else
          for (var index = 0; index < repos.length; index++) ...[
            if (index != 0) const SizedBox(height: AppSpacing.sm),
            RepoTile(
              repo: repos[index],
              rank: index + 1,
              dense: true,
              onTap: () => context.push(
                '/trending/detail/${Uri.encodeComponent(repos[index].fullName)}',
              ),
            ),
          ],
        const SizedBox(height: AppSpacing.lg),
        TrendingTopicsPanel(
          topics: digest.topics,
          onTap: () => context.push('/trending'),
        ),
      ],
    );
  }

  /* 把筛选值转换为移动端显示的时间窗名称。 */
  String _windowLabel(AppLocalizations l10n, String window) {
    return switch (window) {
      'week' => l10n.tr('trending.window.week'),
      'month' => l10n.tr('trending.window.month'),
      _ => l10n.tr('trending.window.today'),
    };
  }
}

/*
* GitHub 热榜三块内容加载时的移动端占位。
*/
class _TrendingSkeleton extends StatelessWidget {
  const _TrendingSkeleton();

  /* 构建 Star 卡片、仓库预览和话题词云的骨架。 */
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Skeleton(height: 320),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 260),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 150),
      ],
    );
  }
}
