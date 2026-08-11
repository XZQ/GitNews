import 'package:flutter/material.dart';

/*
*轻量图表组件:极简热力柱状图与行内面积趋势。
*
*与 `star_trend_chart.dart` 的完整坐标轴折线图不同,这里的组件面向
*  列表行、卡片角落等受限空间,不渲染坐标轴与网格。
*/

/*
*极简热力柱状图(语言分布、活跃度等)。
*/
class MiniBars extends StatelessWidget {
  const MiniBars({required this.values, this.height = 60, super.key});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    final rawMax = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final maxV = rawMax <= 0 ? 1.0 : rawMax;
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
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
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
  const Sparkline({required this.values, this.color, this.width = 64, this.height = 20, super.key});

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
    if (values.length == 1) {
      final y = size.height / 2;
      canvas.drawCircle(Offset(size.width / 2, y), 2, Paint()..color = color);
      return;
    }
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

