import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/* 
*折线 / 面积图(Star 趋势),支持双系列(当前 vs 昨日)。
*/
class StarTrendChart extends StatelessWidget {
  const StarTrendChart({
    required this.series,
    this.height = 180,
    this.showArea = true,
    this.xLabels,
    super.key,
  });

  // 每条系列的颜色 + 数据点。
  final List<ChartSeries> series;
  final double height;
  final bool showArea;

  // 自定义 X 轴标签(按数据点 index 取值)。null 时默认显示 `'${i}d'`。
  final List<String>? xLabels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (series.isEmpty) {
      return SizedBox(height: height);
    }
    final allValues = series.expand((s) => s.values).toList();
    final minY = (allValues.reduce((a, b) => a < b ? a : b)) - 50;
    final maxY = (allValues.reduce((a, b) => a > b ? a : b)) + 50;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          minX: 0,
          maxX: (series.first.values.length - 1).toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: colors.outlineVariant.withValues(alpha: 0.35),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, _) => Text(
                  _shortNumber(value),
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: (series.first.values.length / 5).clamp(1, 30),
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  final label = (xLabels != null && i < xLabels!.length) ? xLabels![i] : '${i}d';
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs2),
                    child: Text(
                      label,
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            for (final s in series)
              LineChartBarData(
                spots: [
                  for (var i = 0; i < s.values.length; i++) FlSpot(i.toDouble(), s.values[i]),
                ],
                isCurved: true,
                curveSmoothness: 0.25,
                color: s.color,
                barWidth: 2.2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: showArea,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      s.color.withValues(alpha: 0.35),
                      s.color.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _shortNumber(double v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}k';
    }
    return v.toStringAsFixed(0);
  }
}

class ChartSeries {
  const ChartSeries({required this.values, required this.color});

  final List<double> values;
  final Color color;
}

/* 
*极简热力柱状图(语言分布、活跃度等)。
*/
class MiniBars extends StatelessWidget {
  const MiniBars({required this.values, this.height = 60, super.key});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxV = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final v in values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: FractionallySizedBox(
                  heightFactor: (v / maxV).clamp(0.05, 1.0),
                  widthFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.6),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/* 
*极简面积趋势(行内用,无坐标轴)。
*/
class Sparkline extends StatelessWidget {
  const Sparkline({
    required this.values,
    this.color,
    this.width = 64,
    this.height = 20,
    super.key,
  });

  final List<double> values;
  final Color? color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.tertiary;
    if (values.isEmpty) {
      return SizedBox(width: width, height: height);
    }
    return CustomPaint(
      size: Size(width, height),
      painter: _SparklinePainter(values: values, color: resolved),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    final stepX = size.width / (values.length - 1);

    final path = Path()..moveTo(0, size.height);
    for (var i = 0; i < values.length; i++) {
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        path.lineTo(0, y);
      } else {
        path.lineTo(i * stepX, y);
      }
    }
    path.lineTo(size.width, size.height);
    path.close();

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final linePath = Path();
    for (var i = 0; i < values.length; i++) {
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        linePath.moveTo(0, y);
      } else {
        linePath.lineTo(i * stepX, y);
      }
    }
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.values != values || old.color != color;
}
