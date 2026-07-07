import 'package:flutter/material.dart';

/* 
*颜色 token:集中维护,UI 不写裸值。
*/
class AppColors {
  const AppColors._();

  // 品牌主色
  static const Color brand = Color(0xFF0D9488);
  static const Color brandDark = Color(0xFF0F766E);
  static const Color brandLight = Color(0xFFCCFBF1);
  static const Color brandInk = Color(0xFF101828);
  static const Color brandCyan = Color(0xFF22D3EE);
  static const Color brandCyanLight = Color(0xFF67E8F9);

  // 语义色
  static const Color success = Color(0xFF30A46C);
  static const Color warning = Color(0xFFE5A150);
  static const Color danger = Color(0xFFE5464D);
  static const Color info = Color(0xFF4CB5FF);

  // Star / 趋势
  static const Color starGold = Color(0xFFE3B341);
  static const Color trendUp = Color(0xFF30A46C);
  static const Color trendDown = Color(0xFFE5464D);

  // 装饰强调色(图表 / 主题分类)
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentPurple = Color(0xFFA78BFA);

  // 语言(图表分布)
  static const Color langRust = Color(0xFFDEA584);
  static const Color langGo = Color(0xFF00ADD8);
  static const Color langPython = Color(0xFF3572A5);
  static const Color langTypeScript = Color(0xFF3178C6);
  static const Color langJava = Color(0xFFB07219);
  static const Color langSwift = Color(0xFFFA7343);
  static const Color langKotlin = Color(0xFFA97BFF);

  // 语言 ARGB int 值(供 fixture / JSON 序列化使用,与上方 Color 一一对应)
  static const int langRustValue = 0xFFDEA584;
  static const int langGoValue = 0xFF00ADD8;
  static const int langPythonValue = 0xFF3572A5;
  static const int langTypeScriptValue = 0xFF3178C6;
  static const int langJavaValue = 0xFFB07219;
  static const int langSwiftValue = 0xFFFA7343;
  static const int langKotlinValue = 0xFFA97BFF;
  static const int langJavaScriptValue = 0xFFF1E05A;
  static const int langCppValue = 0xFFDEA584; // C++ 复用 Rust 色
  static const int langOtherValue = 0xFF9CA0AC;

  // 语义色 ARGB int 值(供 fixture / 序列化使用,与上方 Color 一一对应)
  static const int brandValue = 0xFF0D9488;
  static const int warningValue = 0xFFE5A150;
  static const int successValue = 0xFF30A46C;
  static const int dangerValue = 0xFFE5464D;
  static const int infoValue = 0xFF4CB5FF;

  // 浅色(默认)
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightAlt = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE8EEF6);
  static const Color textPrimaryLight = Color(0xFF1A1B25);
  static const Color textSecondaryLight = Color(0xFF6B6E7A);
  static const Color textMutedLight = Color(0xFF9CA0AC);

  // 深色
  static const Color bgDark = Color(0xFF0B1120);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color surfaceDarkAlt = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF263244);
  static const Color textPrimaryDark = Color(0xFFE7E7EA);
  static const Color textSecondaryDark = Color(0xFFA1A1A8);
  static const Color textMutedDark = Color(0xFF71717A);
}
