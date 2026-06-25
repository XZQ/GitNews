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

/// "项目 / 报告 / 探索" 三栏内容,集中在一个 Tab(对应设计稿"报告.png"和桌面"探索"风格)。
class ProjectPage extends StatelessWidget {
  const ProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('报告')),
      body: ResponsiveLayout(
        compact: (_) => const _Mobile(),
        medium: (_) => const _Desktop(),
        expanded: (_) => const _Desktop(),
      ),
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: const [
        _SummaryMetrics(),
        SizedBox(height: AppSpacing.lg),
        _LanguageDistribution(),
        SizedBox(height: AppSpacing.lg),
        _TrendOverview(),
        SizedBox(height: AppSpacing.lg),
        _PopularRepos(),
        SizedBox(height: AppSpacing.lg),
        _RecentlyUpdated(),
      ],
    );
  }
}

class _Desktop extends StatelessWidget {
  const _Desktop();

  @override
  Widget build(BuildContext context) {
    return CenteredContent(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: const [
          _SummaryMetrics(),
          SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _TrendOverview()),
              SizedBox(width: AppSpacing.lg),
              Expanded(flex: 4, child: _LanguageDistribution()),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          _PopularRepos(),
          SizedBox(height: AppSpacing.lg),
          _RecentlyUpdated(),
        ],
      ),
    );
  }
}

class _SummaryMetrics extends StatelessWidget {
  const _SummaryMetrics();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _MetricBlock(
            label: '本周 Star 增长',
            value: '124',
            delta: '+18.5%',
            color: AppColors.success,
            icon: Icons.star_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricBlock(
            label: '新增仓库',
            value: '2.36K',
            delta: '+7.2%',
            color: Theme.of(context).colorScheme.primary,
            icon: Icons.bookmark_outline,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(
          child: _MetricBlock(
            label: '活跃贡献者',
            value: '156',
            delta: '+12.3%',
            color: AppColors.info,
            icon: Icons.people_outline,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(
          child: _MetricBlock(
            label: '总 Fork 数',
            value: '47.8K',
            delta: '+5.1%',
            color: AppColors.warning,
            icon: Icons.call_split_rounded,
          ),
        ),
      ],
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    required this.delta,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String delta;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            delta,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageDistribution extends StatelessWidget {
  const _LanguageDistribution();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: '语言分布',
            subtitle: '热门仓库的编程语言占比',
          ),
          SizedBox(height: AppSpacing.md),
          _DonutLegend(),
        ],
      ),
    );
  }
}

class _DonutLegend extends StatelessWidget {
  const _DonutLegend();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final l in DemoData.languages.take(6))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(l.color),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(l.name, style: AppTypography.bodyMedium)),
                Text(
                  '${l.percent.toStringAsFixed(1)}%',
                  style: AppTypography.labelMedium,
                ),
                const SizedBox(width: 6),
                Text(
                  '${l.delta >= 0 ? '+' : ''}${l.delta.toStringAsFixed(1)}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: l.delta >= 0 ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TrendOverview extends StatelessWidget {
  const _TrendOverview();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: '趋势对比',
            subtitle: '最近 7 天 vs 上周',
          ),
          SizedBox(height: AppSpacing.md),
        ],
      ).copyChildren([
        StarTrendChart(
          series: [
            ChartSeries(
              values: DemoData.generateStarTrend(42000, 4200),
              color: Theme.of(context).colorScheme.primary,
            ),
            ChartSeries(
              values: DemoData.generateStarTrend(38500, 2800),
              color: AppColors.info,
            ),
          ],
          height: 220,
        ),
      ]),
    );
  }
}

class _PopularRepos extends StatelessWidget {
  const _PopularRepos();

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
              title: '本周热门',
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

class _RecentlyUpdated extends StatelessWidget {
  const _RecentlyUpdated();

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
              title: '最近活跃',
              subtitle: '近期有更新的仓库',
            ),
          ),
          for (var i = 0; i < DemoData.recent.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            RepoTile(
              repo: DemoData.recent[i],
              onTap: () => context.go(
                '/repo_detail/${Uri.encodeComponent(DemoData.recent[i].fullName)}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

extension _ColumnCopy on Column {
  Column copyChildren(List<Widget> extra) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      children: [...children, ...extra],
    );
  }
}
