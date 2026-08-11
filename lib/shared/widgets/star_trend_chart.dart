import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

export 'mini_charts.dart';

/* 
*折线 / 面积图(Star 趋势),支持双系列(当前 vs 昨日)。
*/
class StarTrendChart extends StatelessWidget {
  const StarTrendChart({required this.series, this.height = 180, this.showArea = true, this.showGrid = true, this.showLeftTitles = true, this.curveSmoothness = 0.25, this.xLabels, super.key});

  // 每条系列的颜色 + 数据点。
  final List<ChartSeries> series;
  final double height;
  final bool showArea;
  final bool showGrid;
  final bool showLeftTitles;
  final double curveSmoothness;

  // 自定义 X 轴标签(按数据点 index 取值)。null 时默认显示 `'${i}d'`。
  final List<String>? xLabels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final nonEmptySeries = series.where((item) => item.values.isNotEmpty).toList(growable: false);
    if (nonEmptySeries.isEmpty) {
      return SizedBox(height: height);
    }
    final allValues = nonEmptySeries.expand((item) => item.values).toList(growable: false);
    final rawMin = allValues.reduce((a, b) => a < b ? a : b);
    final rawMax = allValues.reduce((a, b) => a > b ? a : b);
    final yScale = _buildYScale(rawMin, rawMax);
    final pointCount = nonEmptySeries.map((item) => item.values.length).reduce(math.max);
    final maxX = math.max(1, pointCount - 1).toDouble();

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final xLabelStep = _xLabelStep(pointCount, constraints.maxWidth);
          return LineChart(
            LineChartData(
              minY: yScale.minY,
              maxY: yScale.maxY,
              minX: 0,
              maxX: maxX,
              gridData: FlGridData(
                show: showGrid,
                drawVerticalLine: false,
                horizontalInterval: yScale.interval,
                getDrawingHorizontalLine: (_) => FlLine(color: colors.outlineVariant.withValues(alpha: 0.35), strokeWidth: 1, dashArray: [4, 4]),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: showLeftTitles,
                    reservedSize: showLeftTitles ? (constraints.maxWidth < 360 ? 44 : 48) : 0,
                    interval: yScale.interval,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      space: AppSpacing.xs,
                      fitInside: SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: AppSpacing.xxs),
                      child: Text(_shortNumber(value, yScale.interval), maxLines: 1, style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant)),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: xLabelStep.toDouble(),
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      final isInteger = (value - index).abs() < 0.001;
                      final isLastPoint = index == pointCount - 1;
                      if (!isInteger || index < 0 || index >= pointCount || (index % xLabelStep != 0 && !isLastPoint)) {
                        return const SizedBox.shrink();
                      }
                      final label = xLabels != null && index < xLabels!.length ? xLabels![index] : '${index}d';
                      return SideTitleWidget(
                        meta: meta,
                        space: AppSpacing.xs2,
                        fitInside: SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: AppSpacing.xxs),
                        child: Text(label, maxLines: 1, style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant)),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                for (final item in nonEmptySeries)
                  LineChartBarData(
                    spots: [for (var index = 0; index < item.values.length; index++) FlSpot(index.toDouble(), item.values[index])],
                    isCurved: curveSmoothness > 0,
                    curveSmoothness: curveSmoothness,
                    color: item.color,
                    barWidth: 2.2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: showArea,
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [item.color.withValues(alpha: 0.35), item.color.withValues(alpha: 0.0)]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /* 生成对齐到自然刻度的 Y 轴范围，避免边界值和第一档刻度贴在一起。 */
  ({double minY, double maxY, double interval}) _buildYScale(double rawMin, double rawMax) {
    final rawRange = rawMax - rawMin;
    final padding = rawRange == 0 ? math.max(rawMax.abs() * 0.1, 1) : rawRange * 0.08;
    final paddedMin = rawMin - padding;
    final paddedMax = rawMax + padding;
    final interval = _niceInterval((paddedMax - paddedMin) / 4);
    var minY = (paddedMin / interval).floor() * interval;
    var maxY = (paddedMax / interval).ceil() * interval;
    if (minY == maxY) {
      minY -= interval;
      maxY += interval;
    }
    return (minY: minY, maxY: maxY, interval: interval);
  }

  /* 把任意粗略间隔归一为 1、2、2.5、5、10 倍数量级。 */
  double _niceInterval(double roughInterval) {
    if (!roughInterval.isFinite || roughInterval <= 0) {
      return 1;
    }
    final magnitude = math.pow(10, (math.log(roughInterval) / math.ln10).floor()).toDouble();
    final normalized = roughInterval / magnitude;
    final normalizedStep = switch (normalized) {
      <= 1 => 1.0,
      <= 2 => 2.0,
      <= 2.5 => 2.5,
      <= 5 => 5.0,
      _ => 10.0,
    };
    return normalizedStep * magnitude;
  }

  /* 根据可用宽度限制 X 轴标签数量。 */
  int _xLabelStep(int pointCount, double width) {
    if (pointCount <= 1) {
      return 1;
    }
    final targetLabelCount = width < 280
        ? 3
        : width < 420
        ? 4
        : 5;
    return math.max(1, ((pointCount - 1) / (targetLabelCount - 1)).ceil());
  }

  /* 把坐标轴数值压缩成适合窄轴显示的格式。 */
  String _shortNumber(double v, double interval) {
    if (v.abs() < 0.5) {
      return '0';
    }
    final absolute = v.abs();
    final sign = v < 0 ? '-' : '';
    if (absolute >= 1000000) {
      final decimals = interval < 10000
          ? 2
          : interval < 100000
          ? 1
          : 0;
      return '$sign${(absolute / 1000000).toStringAsFixed(decimals)}M';
    }
    if (absolute >= 1000) {
      final decimals = interval < 100
          ? 2
          : interval < 1000
          ? 1
          : 0;
      return '$sign${(absolute / 1000).toStringAsFixed(decimals)}k';
    }
    final decimals = interval < 0.1
        ? 2
        : interval < 1
        ? 1
        : 0;
    return v.toStringAsFixed(decimals);
  }
}

/*
*折线图的一组数值和颜色。
*/
class ChartSeries {
  const ChartSeries({required this.values, required this.color});

  final List<double> values;
  final Color color;
}
