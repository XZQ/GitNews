import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../di/providers.dart';

/*
*应用语言偏好 controller:
*管理用户在设置页选择的 zh-CN / en-US,持久化到 SharedPreferences。
*`MaterialApp.router` 在 `build` 中 `ref.watch` 一次拿到当前 locale,
*切换后整个 MaterialApp 重建,UI 立即反映新语言。
*默认 zh-CN(`AppLocalizations.supportedLocales` 的第一个);无法解析时回退。
*/
class LocaleController extends Notifier<Locale> {
  // SharedPreferences 存储键。格式: `zh_CN` / `en_US`,空表示未设置。
  static const _prefsKey = 'app_locale';

  // 默认语言:简体中文。
  static const _defaultLocale = Locale('zh', 'CN');

  /*
  *Notifier 初始化入口:从 SharedPreferences 读取上一次保存的语言,
  *找不到或格式异常时回退到默认 locale。
  */
  @override
  Locale build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_prefsKey);
    if (raw == null) {
      return _defaultLocale;
    }
    final parsed = _parseRaw(raw);
    if (parsed == null) {
      return _defaultLocale;
    }
    return parsed;
  }

  /*
  *解析 SharedPreferences 中存的 `zh_CN` / `en_US` 字符串为 [Locale]。
  *格式异常或片段缺失时回落到 null,调用方再退到默认 locale。
  */
  Locale? _parseRaw(String raw) {
    final parts = raw.split('_');
    if (parts.length != 2) {
      return null;
    }
    final code = parts[0];
    final country = parts[1];
    if (code.isEmpty || country.isEmpty) {
      return null;
    }
    return Locale(code, country);
  }

  /*
  *切换应用语言并持久化。state 先更新再 await 写盘,UI 重建不卡顿。
  */
  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      '${locale.languageCode}_${locale.countryCode ?? ''}',
    );
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
