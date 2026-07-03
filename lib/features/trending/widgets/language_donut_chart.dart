import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../domain/entities.dart';

/// 语言占比环形图(中心洞口显示总量)。
class LanguageDonutChart extends StatelessWidget {
  const LanguageDonutChart({
    required this.data,
    required this.holeColor,
    this.centerValue = '2.36M',
    this.centerLabel = '总 Star 增长',
    super.key,
  });

  final List<LanguageEntity> data;
  final Color holeColor;
  final String centerValue;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: CustomPaint(
        painter: _DonutPainter(data: data, holeColor: holeColor),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                centerValue,
                style: AppTypography.displayMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                centerLabel,
                style: AppTypography.labelMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.data, required this.holeColor});
  final List<LanguageEntity> data;
  final Color holeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2 - 12;
    final center = Offset(size.width / 2, size.height / 2);
    var start = -3.14159 / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    for (final l in data) {
      final sweep = (l.percent / 100) * 6.28318;
      paint.color = Color(l.accentArgb);
      final path = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: radius),
          start,
          sweep,
        )
        ..lineTo(center.dx, center.dy)
        ..close();
      canvas.drawPath(path, paint);
      start += sweep;
    }
    paint.color = holeColor;
    canvas.drawCircle(center, radius * 0.62, paint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.data != data || old.holeColor != holeColor;
}
