import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

import 'app_theme_preset.dart';

/* 
*主题色预设 controller:与 ThemeMode(明暗)正交,仅控制 seed/色相。
*持久化到 SharedPreferences,默认 Slate(冷静工具风设计基线:主色只出现
*在小面积强调元素上,大面积表面保持中性)。
*/
class ThemePresetController extends Notifier<AppThemePreset> {
  static const _kKey = 'app.theme_preset';

  @override
  AppThemePreset build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_kKey);
    if (raw == null) {
      return AppThemePreset.slate;
    }
    return AppThemePreset.byId(raw);
  }

  Future<void> setPreset(AppThemePreset preset) async {
    if (state == preset) {
      return;
    }
    state = preset;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kKey, preset.id);
  }
}

final themePresetControllerProvider = NotifierProvider<ThemePresetController, AppThemePreset>(ThemePresetController.new);
