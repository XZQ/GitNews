import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/repo_entity.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../../trending/application/trending_providers.dart';
import '../../trending/domain/trending_repository.dart';
import '../../trending/widgets/trending_metrics.dart';

/*
*移动总览中的 GitHub 热榜正文。
*/
class HomeMobileStarGrowthCard extends ConsumerWidget {
  const HomeMobileStarGrowthCard({required this.digest, required this.dataWindow, super.key});

  final String dataWindow;

  // 当前时间窗和语言筛选对应的 GitHub 热榜摘要。
  final TrendingDigest digest;

  /* 按设计稿顺序构建:热门仓库卡片在前,Star 增长榜图表在后。 */
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final window = ref.watch(trendingWindowFilterProvider);
    final windowLabel = _windowLabel(l10n, dataWindow);
    final repos = digest.trendingRepos.take(3).toList(growable: false);
    final primaryTrend = _tail(digest.primaryTrend, 7);
    final secondaryTrend = _tail(digest.secondaryTrend, 7);
    return AppCard(
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
              TrendingWindowSegmented(value: window, dense: true, onChanged: (value) => ref.read(trendingWindowFilterProvider.notifier).state = value),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.tr('trending.mobile.tracking_subtitle').replaceAll('{window}', windowLabel), style: AppTypography.monoMeta.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          if (repos.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: _ChartLegend(repo: repos.first, color: Theme.of(context).colorScheme.primary),
                ),
                if (repos.length > 1)
                  Expanded(
                    child: _ChartLegend(repo: repos[1], color: AppColors.info, alignEnd: true),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          RepaintBoundary(
            child: StarTrendChart(
              series: [
                ChartSeries(values: primaryTrend, color: Theme.of(context).colorScheme.primary),
                ChartSeries(values: secondaryTrend, color: AppColors.info),
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
        Container(
          width: AppSpacing.sm,
          height: AppSpacing.sm,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
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
