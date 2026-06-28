import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../application/trending_providers.dart';
import '../domain/trending_repository.dart';
import 'trending_language_panel.dart';
import 'trending_page_header.dart';
import 'trending_topics_panel.dart';

/// 桌面:左 8 列(趋势图 + 表格)/ 右 4 列(语言分布 + 主题)。
class TrendingDesktopView extends ConsumerWidget {
  const TrendingDesktopView({required this.digest, super.key});

  final TrendingDigest digest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(trendingLanguageFilterProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TrendingPageHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Star 增长趋势',
                        subtitle: '追踪时间窗内的新增 Star 总量 · 包含所有语言',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      StarTrendChart(
                        series: [
                          ChartSeries(
                            values: digest.primaryTrend,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          ChartSeries(
                            values: digest.secondaryTrend,
                            color: AppColors.info,
                          ),
                          ChartSeries(
                            values: digest.tertiaryTrend,
                            color: AppColors.success,
                          ),
                        ],
                        height: 280,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: (MediaQuery.sizeOf(context).height - 320)
                      .clamp(220.0, 900.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 8,
                        child: _TrendingList(
                          repos: digest.trendingRepos,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              TrendingLanguagePanel(
                                value: lang,
                                onChanged: (v) => ref
                                    .read(trendingLanguageFilterProvider.notifier)
                                    .state = v,
                                languages: digest.languages,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              const TrendingTopicsPanel(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendingList extends StatelessWidget {
  const _TrendingList({required this.repos});

  final List<DemoRepo> repos;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: SectionHeader(
                title: '热门仓库',
                subtitle: '按 Star 增速排序',
              ),
            ),
          ),
          SliverList.builder(
            itemCount: repos.length,
            itemBuilder: (context, i) {
              return Column(
                children: [
                  if (i != 0) const Divider(height: 1),
                  RepoTile(
                    repo: repos[i],
                    onTap: () => context.go(
                      '/repo_detail/${Uri.encodeComponent(repos[i].fullName)}',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
