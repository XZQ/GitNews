import 'package:flutter/material.dart';

import '../../core/domain/observed_repo_growth.dart';
import '../../core/domain/repo_entity.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'star_trend_chart.dart';

/// One dated series for the same repository cohort throughout the interval.
class RepoGrowthChart extends StatelessWidget {
  const RepoGrowthChart({required this.repos, this.days = 30, this.height = 180, this.now, super.key});

  final Iterable<RepoEntity> repos;
  final int days;
  final double height;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final growth = ObservedRepoGrowth.fromRepos(repos, days: days, now: now);
    if (growth.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            l10n.tr('growth.empty'),
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      );
    }
    final start = growth.dates.first;
    String dateAt(double offset) => _date(start.add(Duration(days: offset.round())));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n
              .tr('growth.caption')
              .replaceAll('{sample}', '${growth.sampleCount}')
              .replaceAll('{total}', '${growth.totalCount}')
              .replaceAll('{start}', _date(start))
              .replaceAll('{end}', _date(growth.dates.last)),
          style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        RepaintBoundary(
          child: StarTrendChart(
            series: [ChartSeries(values: growth.values, color: colors.primary)],
            xValues: [for (final date in growth.dates) date.difference(start).inDays.toDouble()],
            xLabelBuilder: (offset) => dateAt(offset).substring(5),
            tooltipLabel: (offset, value) => '${dateAt(offset)} UTC\n${value >= 0 ? '+' : ''}${value.round()} Star',
            height: height,
            curveSmoothness: 0,
            showDots: true,
            showArea: false,
          ),
        ),
      ],
    );
  }

  String _date(DateTime date) => date.toIso8601String().substring(0, 10);
}
