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

/// 监控详情(对应监控页二级稿:实时趋势 + 告警历史)。
class MonitorDetailPage extends StatelessWidget {
  const MonitorDetailPage({required this.repoFullName, super.key});

  final String repoFullName;

  @override
  Widget build(BuildContext context) {
    final repo = [...DemoData.trending, ...DemoData.recent].firstWhere(
      (r) => r.fullName == Uri.decodeComponent(repoFullName),
      orElse: () => DemoData.trending.first,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(repo.fullName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/monitor'),
        ),
      ),
      body: ResponsiveLayout(
        compact: (_) => _Body(repo: repo),
        medium: (_) => CenteredContent(child: _Body(repo: repo)),
        expanded: (_) => CenteredContent(child: _Body(repo: repo)),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.repo});
  final DemoRepo repo;

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
            children: const [
              SectionHeader(
                title: 'Realtime Trends',
                subtitle: 'Star / Fork in the last 24h',
              ),
              SizedBox(height: AppSpacing.md),
            ],
          ).copyChildren([
            StarTrendChart(
              series: [
                ChartSeries(
                  values:
                      DemoData.generateStarTrend(repo.starCount - 5000, 5000),
                  color: AppColors.brand,
                ),
                ChartSeries(
                  values: DemoData.generateStarTrend(repo.forkCount, 800),
                  color: AppColors.info,
                ),
              ],
              height: 220,
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SectionHeader(
                title: 'Alert History',
                subtitle: 'All alerts triggered by this repo',
              ),
              SizedBox(height: AppSpacing.md),
            ],
          ).copyChildren([
            for (final a in DemoData.alerts.take(5)) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.history_rounded, color: AppColors.brand),
                title: Text(a.repo, style: AppTypography.titleSmall),
                subtitle: Text('${a.metric} · ${a.time}'),
                trailing: Text(
                  a.value,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ]),
        ),
      ],
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
