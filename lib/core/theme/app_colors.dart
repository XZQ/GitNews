import 'package:flutter/material.dart';

/// 颜色 token:集中维护,UI 不写裸值。
class AppColors {
  const AppColors._();

  // 品牌主色
  static const Color brand = Color(0xFF6E56CF);
  static const Color brandDark = Color(0xFF5840B5);
  static const Color brandLight = Color(0xFFEEEAFE);

  // 语义色
  static const Color success = Color(0xFF30A46C);
  static const Color warning = Color(0xFFE5A150);
  static const Color danger = Color(0xFFE5464D);
  static const Color info = Color(0xFF4CB5FF);

  // Star / 趋势
  static const Color starGold = Color(0xFFE3B341);
  static const Color trendUp = Color(0xFF30A46C);
  static const Color trendDown = Color(0xFFE5464D);

  // 语言(图表分布)
  static const Color langRust = Color(0xFFDEA584);
  static const Color langGo = Color(0xFF00ADD8);
  static const Color langPython = Color(0xFF3572A5);
  static const Color langTypeScript = Color(0xFF3178C6);
  static const Color langJava = Color(0xFFB07219);
  static const Color langSwift = Color(0xFFFA7343);
  static const Color langKotlin = Color(0xFFA97BFF);

  // 浅色(默认)
  static const Color bgLight = Color(0xFFF6F7FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightAlt = Color(0xFFFAFBFE);
  static const Color borderLight = Color(0xFFEEF0F4);
  static const Color textPrimaryLight = Color(0xFF1A1B25);
  static const Color textSecondaryLight = Color(0xFF6B6E7A);
  static const Color textMutedLight = Color(0xFF9CA0AC);

  // 深色
  static const Color bgDark = Color(0xFF0F0F12);
  static const Color surfaceDark = Color(0xFF1A1A1F);
  static const Color surfaceDarkAlt = Color(0xFF23232B);
  static const Color borderDark = Color(0xFF242429);
  static const Color textPrimaryDark = Color(0xFFE7E7EA);
  static const Color textSecondaryDark = Color(0xFFA1A1A8);
  static const Color textMutedDark = Color(0xFF71717A);
}
