import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../../trending/application/trending_providers.dart';
import '../../trending/domain/trending_repository.dart';
import '../../trending/widgets/trending_metrics.dart';

/*
* 移动总览中的 GitHub 热榜区块：热门仓库榜单卡片 + Star 增长榜图表。
*
* 话题趋势同属热榜数据，但设计稿把它排在 AI 雷达之后，因此由
*   `HomeMobileRadarOverview` 渲染，不在本区块内。
*/
class HomeMobileTrendingOverview extends ConsumerWidget {
  const HomeMobileTrendingOverview({super.key});

  /* 构建热榜两块内容及统一的加载和错误状态。 */
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
* 移动总览中的 GitHub 热榜正文。
*/
class _TrendingSections extends ConsumerWidget {
  const _TrendingSections({required this.digest});

  // 当前时间窗和语言筛选对应的 GitHub 热榜摘要。
  final TrendingDigest digest;

  /* 按设计稿顺序构建:热门仓库卡片在前,Star 增长榜图表在后。 */
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final window = ref.watch(trendingWindowFilterProvider);
    final windowLabel = _windowLabel(l10n, window);
    final repos = digest.trendingRepos.take(3).toList(growable: false);
    final primaryTrend = _tail(digest.primaryTrend, 7);
    final secondaryTrend = _tail(digest.secondaryTrend, 7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HotReposCard(
          repos: repos,
          meta: l10n.tr('trending.mobile.repos_count').replaceAll('{window}', windowLabel).replaceAll('{count}', '${repos.length}'),
          title: l10n.tr('trending.page.repos'),
          emptyMessage: l10n.tr('trending.hot_repos.empty'),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题与时间窗切换同处一行:设计稿把切换器视作标题的一部分,
              // 而不是占满整行的独立控件,腾出的纵向空间留给折线图。
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.tr('trending.mobile.star_growth_rank'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TrendingWindowSegmented(
                    value: window,
                    dense: true,
                    onChanged: (value) => ref.read(trendingWindowFilterProvider.notifier).state = value,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.tr('trending.mobile.tracking_subtitle').replaceAll('{window}', windowLabel),
                style: AppTypography.monoMeta.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (repos.isNotEmpty)
                Row(
                  children: [
                    Expanded(child: _ChartLegend(repo: repos.first, color: Theme.of(context).colorScheme.primary)),
                    if (repos.length > 1) Expanded(child: _ChartLegend(repo: repos[1], color: AppColors.info, alignEnd: true)),
                  ],
                ),
              const SizedBox(height: AppSpacing.sm),
              RepaintBoundary(
                child: StarTrendChart(
                  series: [
                    ChartSeries(
                      values: primaryTrend,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    ChartSeries(
                      values: secondaryTrend,
                      color: AppColors.info,
                    ),
                  ],
                  height: 170,
                  showGrid: false,
                  showLeftTitles: false,
                  curveSmoothness: 0,
                  xLabels: [for (var index = 0; index < primaryTrend.length; index++) '${index}d'],
                ),
              ),
            ],
          ),
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

  /* 只取设计稿移动图表所需的最近七个数据点。 */
  List<double> _tail(List<double> values, int count) {
    if (values.length <= count) {
      return values;
    }
    return values.sublist(values.length - count);
  }
}

/*
*热门仓库 — 单卡内嵌三行榜单。
*
*设计稿把前三名收在一张卡里、行间用细分隔线,而不是三张各自带边框的
*  卡片:窄屏上连续的独立卡片会产生三条外框 + 三段留白,视觉噪声压过
*  内容本身。行内用 `card: false` 的 [RepoTile] 复用统一的仓库行结构。
*/
class _HotReposCard extends StatelessWidget {
  const _HotReposCard({required this.repos, required this.title, required this.meta, required this.emptyMessage});

  // 榜单前三名;为空时整卡退化为空状态。
  final List<RepoEntity> repos;

  // 卡片标题(如「热门仓库」)。
  final String title;

  // 标题右侧的等宽口径说明(如「今日 · 3 个项目」)。
  final String meta;

  // 无数据时展示的文案。
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: AppTypography.titleMedium.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700))),
            Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.monoMeta.copyWith(color: colors.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: repos.isEmpty
              ? EmptyView(icon: Icons.local_fire_department_outlined, message: emptyMessage)
              : Column(
                  children: [
                    for (var index = 0; index < repos.length; index++) ...[
                      if (index != 0) Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg, color: colors.outlineVariant),
                      _HotRepoRow(
                        repo: repos[index],
                        rank: index + 1,
                        onTap: () => context.push('/trending/detail/${Uri.encodeComponent(repos[index].fullName)}'),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/*
* GitHub 热榜区块加载时的移动端占位。
*/
/* 热门仓库分组卡片中的紧凑排行榜行。 */
class _HotRepoRow extends StatelessWidget {
  const _HotRepoRow({required this.repo, required this.rank, required this.onTap});

  final RepoEntity repo;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = Color(repo.accentArgb);
    final repoName = repo.fullName.split('/').last;
    final initial = repoName.isEmpty ? '?' : repoName.characters.first.toUpperCase();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: AppSpacing.lg,
              child: Text('$rank', style: AppTypography.monoMeta.copyWith(color: rank == 1 ? AppColors.warning : colors.onSurfaceVariant, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xxl,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.md)),
              alignment: Alignment.center,
              child: Text(initial, style: AppTypography.titleSmall.copyWith(color: accent, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(repo.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.monoTitle.copyWith(color: colors.onSurface)),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Container(width: AppSpacing.xs2, height: AppSpacing.xs2, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                      const SizedBox(width: AppSpacing.xs2),
                      Flexible(child: Text(repo.language, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.monoMeta.copyWith(color: colors.onSurfaceVariant))),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(Icons.star_rounded, size: 13, color: AppColors.starGold),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(_shortNumber(repo.starCount), style: AppTypography.monoMeta.copyWith(color: AppColors.starGold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${repo.starDelta > 0 ? '+' : ''}${_shortNumber(repo.starDelta)}',
              style: AppTypography.monoMetric.copyWith(color: repo.starDelta >= 0 ? AppColors.trendUp : AppColors.trendDown),
            ),
          ],
        ),
      ),
    );
  }
}

/* Star 增长图例，复用当前仓库名称与真实指标。 */
class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.repo, required this.color, this.alignEnd = false});

  final RepoEntity repo;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final repoName = repo.fullName.split('/').last;
    return Row(
      mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(width: AppSpacing.sm, height: AppSpacing.sm, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            '$repoName ${_shortNumber(repo.starCount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.monoMeta.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/* 把仓库指标压缩为移动端短数字。 */
String _shortNumber(int value) {
  final absolute = value.abs();
  final sign = value < 0 ? '-' : '';
  if (absolute >= 1000000) {
    return '$sign${(absolute / 1000000).toStringAsFixed(1)}M';
  }
  if (absolute >= 1000) {
    return '$sign${(absolute / 1000).toStringAsFixed(1)}k';
  }
  return '$value';
}

class _TrendingSkeleton extends StatelessWidget {
  const _TrendingSkeleton();

  /* 构建热门仓库卡片与 Star 增长榜图表的骨架,高度与实际版面接近。 */
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Skeleton(height: 260),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 320),
      ],
    );
  }
}
