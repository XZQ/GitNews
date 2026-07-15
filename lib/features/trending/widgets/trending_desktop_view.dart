import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../application/trending_providers.dart';
import '../domain/trending_repository.dart';
import 'trending_board_selector.dart';
import 'trending_language_panel.dart';
import 'trending_list.dart';
import 'trending_page_header.dart';
import 'trending_topics_panel.dart';

/* 
*桌面:左 8 列(趋势图 + 表格)/ 右 4 列(语言分布 + 主题)。
*/
class TrendingDesktopView extends ConsumerWidget {
  const TrendingDesktopView({required this.digest, this.isReloading = false, super.key});

  final TrendingDigest digest;
  final bool isReloading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(trendingLanguageFilterProvider);
    final board = ref.watch(trendingBoardFilterProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TrendingPageHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrendingBoardSelector(value: board, onChanged: (value) => ref.read(trendingBoardFilterProvider.notifier).state = value),
                      const SizedBox(height: AppSpacing.lg),
                      const SectionHeader(title: 'Star 增长趋势', subtitle: '追踪时间窗内的新增 Star 总量 · 包含所有语言'),
                      const SizedBox(height: AppSpacing.md),
                      RepaintBoundary(
                        child: StarTrendChart(
                          series: [
                            ChartSeries(values: digest.primaryTrend, color: Theme.of(context).colorScheme.primary),
                            ChartSeries(values: digest.secondaryTrend, color: AppColors.info),
                            ChartSeries(values: digest.tertiaryTrend, color: AppColors.success)
                          ],
                          height: 280,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: (MediaQuery.sizeOf(context).height - 320).clamp(220.0, 900.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 8, child: TrendingList(repos: digest.trendingRepos, isLoading: isReloading)),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              TrendingLanguagePanel(value: lang, onChanged: (v) => ref.read(trendingLanguageFilterProvider.notifier).state = v, languages: digest.languages),
                              const SizedBox(height: AppSpacing.lg),
                              const TrendingTopicsPanel()
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}
