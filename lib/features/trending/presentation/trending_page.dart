import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../widgets/trending_language_panel.dart';
import '../widgets/trending_metrics.dart';
import '../widgets/trending_topics_panel.dart';

class TrendingPage extends StatelessWidget {
  const TrendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('趋势')),
      body: ResponsiveLayout(
        compact: (_) => const _TrendingMobile(),
        medium: (_) => const _TrendingDesktop(),
        expanded: (_) => const _TrendingDesktop(),
      ),
    );
  }
}

/// 手机:时间窗 / 筛选 + Hero 趋势图 + 列表 + 趋势主题。
class _TrendingMobile extends StatefulWidget {
  const _TrendingMobile();

  @override
  State<_TrendingMobile> createState() => _TrendingMobileState();
}

class _TrendingMobileState extends State<_TrendingMobile> {
  String _window = 'today';
  String _lang = 'all';

  @override
  Widget build(BuildContext context) {
    final windowLabel = const {
      'today': '今日',
      'week': '本周',
      'month': '本月',
    }[_window]!;
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
                    value: _lang,
                    options: const ['all', 'typescript', 'python', 'rust'],
                    optionLabel: (v) => const {
                      'all': '全部语言',
                      'typescript': 'TypeScript',
                      'python': 'Python',
                      'rust': 'Rust',
                    }[v]!,
                    onSelected: (v) => setState(() => _lang = v),
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
                value: _window,
                onChanged: (v) => setState(() => _window = v),
              ),
              const SizedBox(height: AppSpacing.md),
              const TrendingHeroMetrics(),
              const SizedBox(height: AppSpacing.md),
              StarTrendChart(
                series: [
                  ChartSeries(
                    values: DemoData.generateStarTrend(40000, 3200),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  ChartSeries(
                    values: DemoData.generateStarTrend(42000, 3500),
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
                  subtitle: '$windowLabel · ${DemoData.trending.length} 个项目',
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('筛选'),
                  ),
                ),
              ),
              for (var i = 0; i < DemoData.trending.length; i++) ...[
                if (i != 0) const Divider(height: 1),
                RepoTile(
                  repo: DemoData.trending[i],
                  onTap: () => context.go(
                    '/repo_detail/${Uri.encodeComponent(DemoData.trending[i].fullName)}',
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

/// 桌面:左 8 列(趋势图 + 表格)/ 右 4 列(语言分布 + 主题)。
class _TrendingDesktop extends StatefulWidget {
  const _TrendingDesktop();

  @override
  State<_TrendingDesktop> createState() => _TrendingDesktopState();
}

class _TrendingDesktopState extends State<_TrendingDesktop> {
  String _lang = 'all';

  @override
  Widget build(BuildContext context) {
    return CenteredContent(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
                      values: DemoData.generateStarTrend(38000, 4200),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    ChartSeries(
                      values: DemoData.generateStarTrend(35200, 3100),
                      color: AppColors.info,
                    ),
                    ChartSeries(
                      values: DemoData.generateStarTrend(32000, 2800),
                      color: AppColors.success,
                    ),
                  ],
                  height: 280,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 8, child: _TrendingList()),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    TrendingLanguagePanel(
                      value: _lang,
                      onChanged: (v) => setState(() => _lang = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const TrendingTopicsPanel(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendingList extends StatelessWidget {
  const _TrendingList();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const Padding(
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
          for (var i = 0; i < DemoData.trending.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            RepoTile(
              repo: DemoData.trending[i],
              onTap: () => context.go(
                '/repo_detail/${Uri.encodeComponent(DemoData.trending[i].fullName)}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
