import 'package:flutter/material.dart';

import 'strings_en_us.dart';
import 'strings_zh_cn.dart';

/* 
*应用本地化字符串集合。
***当前状态**:项目处于单语言阶段,本类只提供"骨架"和少量 key,
*用于:
*1. 在 `app.dart` 注册 `AppLocalizations.delegate`,把英文挂为兜底
*locale,以便未来英文用户至少能看到落地页基本文案。
*2. 后续迁移:把页面里硬编码的中文逐条抽到这里,zh 添 key、en 补译文。
*不引入 `intl` / `easy_localization` 等三方包,避免新增构建依赖。
*如未来字符串爆炸(>200 条)或需要复数/性别变体,再切到 `intl` + ARB。
*/
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    final instance =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    return instance ?? AppLocalizations(fallbackLocale);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // 默认支持的 locale 列表。zh-CN 为主翻译,en-US 为兜底。
  static const supportedLocales = <Locale>[
    Locale('zh', 'CN'),
    Locale('en', 'US'),
  ];

  // 默认 locale:找不到匹配时回落到 en-US。
  static const fallbackLocale = Locale('en', 'US');

  static const Map<String, Map<String, String>> _localizedStrings = {
    'zh': stringsZhCN,
    'en': stringsEnUS,
  };

  String tr(String key) {
    final map = _localizedStrings[locale.languageCode] ?? stringsEnUS;
    return map[key] ?? stringsEnUS[key] ?? key;
  }

  String get appName => tr('app.name');
  String get retry => tr('common.retry');
  String get empty => tr('common.empty');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['zh', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
