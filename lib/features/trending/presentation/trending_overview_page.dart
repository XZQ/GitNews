import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_trend_chart.dart';

/// 二级页 1:Star 增长趋势(全量)。
class TrendingOverviewPage extends StatelessWidget {
  const TrendingOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Star 增长趋势'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: ResponsiveLayout(
        compact: (_) => const _Body(),
        medium: (_) => CenteredContent(child: const _Body()),
        expanded: (_) => CenteredContent(child: const _Body()),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
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
              const SectionHeader(
                title: '总体 Star 增长趋势',
                subtitle: '最近 30 天 · 所有语言聚合',
              ),
              const SizedBox(height: AppSpacing.md),
              StarTrendChart(
                series: [
                  ChartSeries(
                    values: DemoData.generateStarTrend(42000, 4200),
                    color: AppColors.brand,
                  ),
                  ChartSeries(
                    values: DemoData.generateStarTrend(39500, 3100),
                    color: AppColors.info,
                  ),
                ],
                height: 260,
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: const [
                  _LegendDot(color: AppColors.brand, label: '本周'),
                  _LegendDot(color: AppColors.info, label: '上周'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SectionHeader(
                title: '按时间窗统计',
                subtitle: '不同时段的 Star 增长总量',
              ),
              SizedBox(height: AppSpacing.md),
              _WindowStatsTable(),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}

class _WindowStatsTable extends StatelessWidget {
  const _WindowStatsTable();

  @override
  Widget build(BuildContext context) {
    final rows = const [
      ['今日', '+18.5%', '4,231', '128'],
      ['本周', '+12.4%', '28,420', '1,082'],
      ['本月', '+9.6%', '124,830', '4,210'],
      ['本季', '+15.7%', '372,140', '11,920'],
    ];
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE6E7EE)),
            ),
          ),
          children: [
            _Th('时间窗'),
            _Th('增长率'),
            _Th('新增 Star'),
            _Th('活跃仓库'),
          ],
        ),
        for (final r in rows)
          TableRow(
            children: [
              _Td(r[0]),
              _Td(r[1], color: AppColors.success),
              _Td(r[2]),
              _Td(r[3]),
            ],
          ),
      ],
    );
  }
}

class _Th extends StatelessWidget {
  const _Th(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Td extends StatelessWidget {
  const _Td(this.text, {this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: AppTypography.bodyMedium.copyWith(
          color: color ?? Theme.of(context).colorScheme.onSurface,
          fontWeight: color != null ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
