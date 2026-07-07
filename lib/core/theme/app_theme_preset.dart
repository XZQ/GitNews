import 'package:flutter/material.dart';

/* 主题色预设:10 种 seed,色相与明暗(ThemeMode)正交。 */
/*  */
/* UI 通过 `themePresetControllerProvider` 选当前预设; */
/* `AppTheme.fromSeed` 用 preset.seed 派生整套 Material 3 ColorScheme。 */
enum AppThemePreset {
  slate('slate', '灰白', Color(0xFF64748B)),
  teal('teal', '青绿', Color(0xFF0D9488)),
  blue('blue', '宝蓝', Color(0xFF1E88E5)),
  indigo('indigo', '靛蓝', Color(0xFF4F46E5)),
  violet('violet', '紫罗兰', Color(0xFF7C3AED)),
  purple('purple', '暗紫', Color(0xFF6E56CF)),
  emerald('emerald', '翡翠', Color(0xFF10B981)),
  amber('amber', '琥珀', Color(0xFFF59E0B)),
  orange('orange', '橙红', Color(0xFFF97316)),
  rose('rose', '玫红', Color(0xFFF43F5E));

  const AppThemePreset(this.id, this.name, this.seed);

  final String id;
  final String name;
  final Color seed;

  static AppThemePreset byId(String id) {
    for (final p in AppThemePreset.values) {
      if (p.id == id) return p;
    }
    return AppThemePreset.teal;
  }
}
