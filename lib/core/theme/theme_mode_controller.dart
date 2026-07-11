import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

/* 
*主题模式 controller:
*- 由 UI 上的"深色模式"开关控制(且仅在桌面端可切换)。
*- 持久化到 SharedPreferences。
*/
class ThemeModeController extends Notifier<ThemeMode> {
  static const _kKey = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_kKey);
    if (raw == null) {
      return ThemeMode.light;
    }
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.light,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    if (state == mode) {
      return;
    }
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kKey, mode.name);
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }
}

final themeModeControllerProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
