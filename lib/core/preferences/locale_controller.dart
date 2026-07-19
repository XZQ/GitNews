import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

/*
*应用语言偏好 controller:
*管理用户在设置页选择的 zh-CN / en-US,持久化到 SharedPreferences。
*`MaterialApp.router` 在 `build` 中 `ref.watch` 一次拿到当前 locale,
*切换后整个 MaterialApp 重建,UI 立即反映新语言。
*首次启动跟随系统语言:中文系统使用 zh-CN,其他语言默认 en-US。
*/
class LocaleController extends Notifier<Locale> {
  // SharedPreferences 存储键。格式: `zh_CN` / `en_US`,空表示未设置。
  static const _prefsKey = 'app_locale';

  // 非中文系统或无效配置的默认语言。
  static const _fallbackLocale = Locale('en', 'US');

  /*
  *Notifier 初始化入口:从 SharedPreferences 读取上一次保存的语言,
  *未保存设置时跟随系统语言,格式异常时回退到英文。
  */
  @override
  Locale build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_prefsKey);
    if (raw == null) {
      return _localeForSystem(WidgetsBinding.instance.platformDispatcher.locale);
    }
    final parsed = _parseRaw(raw);
    if (parsed == null) {
      return _fallbackLocale;
    }
    return parsed;
  }

  /* 将系统 locale 归一为应用支持的中文或英文。 */
  Locale _localeForSystem(Locale systemLocale) {
    if (systemLocale.languageCode.toLowerCase() == 'zh') {
      return const Locale('zh', 'CN');
    }
    return _fallbackLocale;
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
    if (code == 'zh' && country == 'CN') {
      return const Locale('zh', 'CN');
    }
    if (code == 'en' && country == 'US') {
      return _fallbackLocale;
    }
    return null;
  }

  /*
  *切换应用语言并持久化。state 先更新再 await 写盘,UI 重建不卡顿。
  */
  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_prefsKey, '${locale.languageCode}_${locale.countryCode ?? ''}');
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);
