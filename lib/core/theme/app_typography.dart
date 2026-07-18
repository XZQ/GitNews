import 'package:flutter/material.dart';

/*
*字号 token(Material 3 + 业务扩展)。
*
*等宽族:仓库名、Star 数、百分比、日期、来源标识等「机器数据」统一走
*  [mono],与中文正文的比例字体形成对比,呼应设计稿的终端观感。
*  字体资源缺失时由 [monoFallback] 逐级回退到系统等宽字体,不会崩。
*/
class AppTypography {
  const AppTypography._();

  // 等宽字体族名,需与 pubspec.yaml 的 fonts.family 一致。
  static const String monoFamily = 'JetBrainsMono';

  // 等宽回退链:资源未打包时按序回退到各平台自带等宽字体。
  static const List<String> monoFallback = <String>[
    'JetBrains Mono',
    'SFMono-Regular',
    'Cascadia Mono',
    'Consolas',
    'Menlo',
    'DejaVu Sans Mono',
    'monospace',
  ];

  /* 把任意比例字体样式转成等宽版本,字号与字重保持不变。 */
  static TextStyle mono(TextStyle base) {
    return base.copyWith(fontFamily: monoFamily, fontFamilyFallback: monoFallback);
  }

  static const TextStyle displayLarge = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2);
  static const TextStyle displayMedium = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2);
  static const TextStyle headlineLarge = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25);
  static const TextStyle headlineMedium = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);
  static const TextStyle titleLarge = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3);
  static const TextStyle titleMedium = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35);
  static const TextStyle titleSmall = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4);
  static const TextStyle bodyLarge = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.45);
  static const TextStyle labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3);
  static const TextStyle labelMedium = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3);
  static const TextStyle labelSmall = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.3);
  static const TextStyle labelMicro = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.5,
  );

  // 等宽:仓库全名、命令行式标题(如 `$ ai-daily --today`)。
  static final TextStyle monoTitle = mono(titleSmall);

  // 等宽:指标数值(Star 数、增量、百分比),字重加粗以突出。
  static final TextStyle monoMetric = mono(labelLarge).copyWith(fontWeight: FontWeight.w700);

  // 等宽:次要元数据(语言名、日期、来源、Top N 角标)。
  static final TextStyle monoMeta = mono(labelSmall);

  // 等宽:大号统计数字(监控页 4 宫格计数)。
  static final TextStyle monoDisplay = mono(headlineMedium).copyWith(fontWeight: FontWeight.w700);
}
