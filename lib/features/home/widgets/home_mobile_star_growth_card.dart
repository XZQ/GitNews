import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/repo_growth_chart.dart';
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
          RepaintBoundary(
            child: RepoGrowthChart(
              repos: digest.allRepos,
              days: dataWindow == 'today'
                  ? 1
                  : dataWindow == 'week'
                  ? 7
                  : 30,
              height: 170,
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
}
