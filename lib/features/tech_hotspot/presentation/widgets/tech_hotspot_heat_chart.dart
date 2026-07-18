import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/tech_hotspot_models.dart';

class TechHotspotHeatChart extends StatelessWidget {
  const TechHotspotHeatChart({
    required this.values,
    this.compact = false,
    super.key,
  });

  final List<TechHeatPoint> values;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    if (values.isEmpty) {
      return AppCard(
        child: Center(
          child: Text(
            l10n.tr('common.empty'),
            style: AppTypography.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final rawMin = values.map((point) => point.value).reduce((a, b) => math.min(a, b));
    final rawMax = values.map((point) => point.value).reduce((a, b) => math.max(a, b));
    final range = rawMax - rawMin;
    final padding = math.max(5.0, range * 0.12);
    final minY = math.max(0.0, rawMin - padding);
    final maxY = rawMax + padding;
    final labelIndexes = <int>{
      0,
      if (!compact) ...List.generate(values.length, (index) => index),
      if (compact) values.length ~/ 2,
      values.length - 1,
    }.toList()
      ..sort();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.show_chart_rounded,
                size: 16,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.tr('tech_hotspot.heat_chart.title'),
                  style: AppTypography.titleSmall.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                l10n.tr('tech_hotspot.heat_chart.peak').replaceAll('{v}', rawMax.toStringAsFixed(0)),
                style: AppTypography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: minY,
                maxY: maxY,
                minX: 0,
                maxX: math.max(1, values.length - 1).toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: values.length > 2,
                    curveSmoothness: 0.35,
                    preventCurveOverShooting: true,
                    barWidth: 2.4,
                    color: AppColors.warning,
                    dotData: FlDotData(show: values.length == 1),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.warning.withValues(alpha: 0.16),
                    ),
                    spots: [
                      for (var index = 0; index < values.length; index++) FlSpot(index.toDouble(), values[index].value),
                    ],
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => [
                      for (final spot in spots)
                        LineTooltipItem(
                          '${values[spot.spotIndex].label}\n${spot.y.toStringAsFixed(0)}',
                          AppTypography.labelSmall.copyWith(
                            color: colors.surface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final index in labelIndexes)
                Text(
                  values[index].label,
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
