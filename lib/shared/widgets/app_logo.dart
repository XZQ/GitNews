import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// GitHub情报站 品牌标识。
///
/// - [mark]: 仅图标(用于左上角、登录、PRO 卡片)
/// - [wordmark]: 纯文字标(图标右侧)
/// - [compact] / [full]: 横排组合,带可选文字
class AppLogo extends StatelessWidget {
  const AppLogo({
    this.size = 32,
    this.showText = true,
    this.brightness,
    super.key,
  });

  final double size;
  final bool showText;

  /// null 表示跟随系统(从 [Theme.of] 推断)。
  final Brightness? brightness;

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark ||
        (brightness == null && Theme.of(context).brightness == Brightness.dark);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoMark(size: size),
        if (showText) ...[
          SizedBox(width: size * 0.32),
          Text(
            'GitHub 情报站',
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              height: 1.0,
            ),
          ),
        ],
      ],
    );
  }
}

/// 自绘品牌图标:圆角方形 + "G" 字 + 上升柱状。
class LogoMark extends StatelessWidget {
  const LogoMark({this.size = 32, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoMarkPainter(),
      ),
    );
  }
}

class _LogoMarkPainter extends CustomPainter {
  static const _grad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B73E5), Color(0xFF5840B5)],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.22;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));

    // 1) 渐变背景
    final bg = Paint()..shader = _grad.createShader(rect);
    canvas.drawRRect(rrect, bg);

    // 2) 内部 "G" 字轮廓(用 Path 模拟,环形 + 内横线)
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width * 0.30;
    final innerR = size.width * 0.20;
    final gPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round;

    final ring = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: (outerR + innerR) / 2),
        -3.6,
        5.6,
      );
    canvas.drawPath(ring, gPaint);

    // 3) G 内部的小横线
    canvas.drawLine(
      Offset(cx, cy + innerR * 0.05),
      Offset(cx + innerR * 0.85, cy + innerR * 0.05),
      Paint()
        ..color = Colors.white
        ..strokeWidth = size.width * 0.085
        ..strokeCap = StrokeCap.round,
    );

    // 4) 上升柱状(情报感)
    final bar = Paint()..color = const Color(0xFF30A46C);
    final bw = size.width * 0.085;
    final baseY = size.height * 0.78;
    final gap = size.width * 0.045;
    final heights = [0.18, 0.30, 0.45];
    for (var i = 0; i < heights.length; i++) {
      final x = size.width * 0.22 + i * (bw + gap);
      final h = size.height * heights[i];
      final rrectBar = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, baseY - h, bw, h),
        Radius.circular(bw * 0.45),
      );
      canvas.drawRRect(rrectBar, bar);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
