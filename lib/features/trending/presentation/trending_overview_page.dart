import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../../project/application/project_providers.dart';

/* 
*二级页 1:Star 增长趋势(全量)。
*/
class TrendingOverviewPage extends ConsumerWidget {
  const TrendingOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectDigestProvider);
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
        compact: (_) => _Body(state: state),
        medium: (_) => CenteredContent(child: _Body(state: state)),
        expanded: (_) => CenteredContent(child: _Body(state: state)),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});

  final AsyncValue<ProjectDigest> state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return state.when(
      data: (digest) => digest.isEmpty
          ? const EmptyView(
              icon: Icons.show_chart_rounded,
              message: '暂无趋势数据',
            )
          : _DigestView(digest: digest),
      loading: () => const _OverviewSkeleton(),
      error: (error, stack) => ErrorView(
        error: error.asAppException(stack),
        onRetry: () => ref.invalidate(projectDigestProvider),
      ),
    );
  }
}

class _DigestView extends StatelessWidget {
  const _DigestView({required this.digest});

  final ProjectDigest digest;

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
                    values: digest.primaryTrend,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  ChartSeries(
                    values: digest.secondaryTrend,
                    color: AppColors.info,
                  ),
                ],
                height: 260,
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _LegendDot(
                    color: Theme.of(context).colorScheme.primary,
                    label: '本周',
                  ),
                  const _LegendDot(color: AppColors.info, label: '上周'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
          width: AppSpacing.sm,
          height: AppSpacing.sm,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.dot),
          ),
        ),
        const SizedBox(width: AppSpacing.xs2),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}

class _WindowStatsTable extends StatelessWidget {
  const _WindowStatsTable();

  @override
  Widget build(BuildContext context) {
    final rows = [
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
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          children: const [
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm2),
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

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

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
        Skeleton(height: 320),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 200),
      ],
    );
  }
}
