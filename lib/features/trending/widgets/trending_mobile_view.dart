import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../application/trending_providers.dart';
import '../domain/trending_repository.dart';
import 'trending_metrics.dart';
import 'trending_topics_panel.dart';

/* 手机:时间窗 / 筛选 + Hero 趋势图 + 列表 + 趋势主题。 */
class TrendingMobileView extends ConsumerWidget {
  const TrendingMobileView({required this.digest, super.key});

  final TrendingDigest digest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(trendingWindowFilterProvider);
    final lang = ref.watch(trendingLanguageFilterProvider);
    final windowLabel = const {
      'today': '今日',
      'week': '本周',
      'month': '本月',
    }[window]!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Star 增长榜', style: AppTypography.titleLarge),
                  ),
                  TrendingPopupMenu(
                    value: lang,
                    options: const ['all', 'typescript', 'python', 'rust'],
                    optionLabel: (v) => const {
                      'all': '全部语言',
                      'typescript': 'TypeScript',
                      'python': 'Python',
                      'rust': 'Rust',
                    }[v]!,
                    onSelected: (v) => ref
                        .read(trendingLanguageFilterProvider.notifier)
                        .state = v,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '追踪 $windowLabel · Star 增速排名',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TrendingWindowSegmented(
                value: window,
                onChanged: (v) =>
                    ref.read(trendingWindowFilterProvider.notifier).state = v,
              ),
              const SizedBox(height: AppSpacing.md),
              const TrendingHeroMetrics(),
              const SizedBox(height: AppSpacing.md),
              StarTrendChart(
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
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: SectionHeader(
                  title: '热门仓库',
                  subtitle: '$windowLabel · ${digest.trendingRepos.length} 个项目',
                  trailing: TextButton(
                    onPressed: () => _showFilterSheet(context, ref),
                    child: const Text('筛选'),
                  ),
                ),
              ),
              for (var i = 0; i < digest.trendingRepos.length; i++) ...[
                if (i != 0) const Divider(height: 1),
                RepoTile(
                  repo: digest.trendingRepos[i],
                  onTap: () => context.go(
                    '/trending/detail/${Uri.encodeComponent(digest.trendingRepos[i].fullName)}',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const TrendingTopicsPanel(),
      ],
    );
  }
}

const _windowOptions = {'today': '今日', 'week': '本周', 'month': '本月'};

const _languageOptions = {
  'all': '全部语言',
  'dart': 'Dart',
  'typescript': 'TypeScript',
  'python': 'Python',
  'rust': 'Rust',
  'go': 'Go',
};

Future<void> _showFilterSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetCtx) => StatefulBuilder(
      builder: (sheetCtx, setSheetState) {
        final window = ref.read(trendingWindowFilterProvider);
        final lang = ref.read(trendingLanguageFilterProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('时间窗', style: AppTypography.titleMedium),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final entry in _windowOptions.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: window == entry.key,
                        onSelected: (_) {
                          ref
                              .read(trendingWindowFilterProvider.notifier)
                              .state = entry.key;
                          setSheetState(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('语言', style: AppTypography.titleMedium),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final entry in _languageOptions.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: lang == entry.key,
                        onSelected: (_) {
                          ref
                              .read(trendingLanguageFilterProvider.notifier)
                              .state = entry.key;
                          setSheetState(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                    child: const Text('完成'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
