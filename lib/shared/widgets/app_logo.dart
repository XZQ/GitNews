import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/theme/app_colors.dart';

/* 
*GitHub情报站 品牌标识。
*- [mark]: 仅图标(用于左上角、登录)
*- [wordmark]: 纯文字标(图标右侧)
*- [compact] / [full]: 横排组合,带可选文字
*/
class AppLogo extends StatelessWidget {
  const AppLogo({
    this.size = 32,
    this.showText = true,
    this.brightness,
    super.key,
  });

  final double size;
  final bool showText;

  // null 表示跟随系统(从 [Theme.of] 推断)。
  final Brightness? brightness;

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark || (brightness == null && Theme.of(context).brightness == Brightness.dark);
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoMark(size: size),
        if (showText) ...[
          SizedBox(width: size * 0.32),
          Text(
            l10n.tr('app.name'),
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              height: 1.0,
            ),
          )
        ]
      ],
    );
  }
}

/* 
*自绘品牌图标:深色情报雷达 + 趋势轨迹 + 星标节点。
*/
class LogoMark extends StatelessWidget {
  const LogoMark({this.size = 32, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _LogoMarkPainter()));
  }
}

class _LogoMarkPainter extends CustomPainter {
  static const _grad = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brandInk, AppColors.brandDark]);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.24;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));

    // 1) 深色渐变背景。
    final bg = Paint()..shader = _grad.createShader(rect);
    canvas.drawRRect(rrect, bg);

    final clipPath = Path()..addRRect(rrect);
    canvas.save();
    canvas.clipPath(clipPath);

    // 2) 低对比雷达环,增强情报感但不抢主体。
    final radarPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035;
    final radarCenter = Offset(size.width * 0.34, size.height * 0.68);
    for (final scale in const [0.34, 0.56, 0.78]) {
      canvas.drawArc(
        Rect.fromCircle(center: radarCenter, radius: size.width * scale),
        -1.05,
        1.55,
        false,
        radarPaint,
      );
    }

    // 3) 主趋势轨迹。
    final path = Path()
      ..moveTo(size.width * 0.20, size.height * 0.68)
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.52,
        size.width * 0.46,
        size.height * 0.62,
        size.width * 0.58,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.28,
        size.width * 0.78,
        size.height * 0.33,
        size.width * 0.84,
        size.height * 0.22,
      );
    final glowPaint = Paint()
      ..color = AppColors.brandCyan.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.17
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glowPaint);

    final linePaint = Paint()
      ..color = AppColors.brandCyanLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // 4) 节点与星标。
    final nodePaint = Paint()..color = Colors.white;
    for (final node in [Offset(size.width * 0.20, size.height * 0.68), Offset(size.width * 0.58, size.height * 0.42)]) {
      canvas.drawCircle(node, size.width * 0.075, Paint()..color = AppColors.brandCyan.withValues(alpha: 0.28));
      canvas.drawCircle(node, size.width * 0.038, nodePaint);
    }

    final star = Path();
    final starCenter = Offset(size.width * 0.82, size.height * 0.22);
    final outer = size.width * 0.12;
    final inner = size.width * 0.044;
    for (var i = 0; i < 8; i++) {
      final angle = -1.5708 + i * 0.7854;
      final radius = i.isEven ? outer : inner;
      final p = Offset(starCenter.dx + radius * math.cos(angle), starCenter.dy + radius * math.sin(angle));
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(star, Paint()..color = Colors.white);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
