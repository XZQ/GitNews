import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';
import 'strings.dart';

/// 应用语言控制器:持久化到 SharedPreferences,默认中文。
class LocaleController extends Notifier<AppLocale> {
  static const _kKey = 'app.locale';

  @override
  AppLocale build() {
    _loadFromPrefs();
    return AppLocale.zh;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return;
    state = AppLocale.fromCode(raw);
  }

  Future<void> setLocale(AppLocale locale) async {
    if (state == locale) return;
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, locale.name);
  }

  Future<void> toggle() => setLocale(
        state == AppLocale.zh ? AppLocale.en : AppLocale.zh,
      );
}

final localeControllerProvider =
    NotifierProvider<LocaleController, AppLocale>(LocaleController.new);

/// 当前 locale 下的字符串集合。
final appStringsProvider = Provider<AppStrings>((ref) {
  return AppStrings(ref.watch(localeControllerProvider));
});

/// 当前 locale 的 [Locale] 供 MaterialApp 使用。
final materialLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(localeControllerProvider).toLocale;
});
