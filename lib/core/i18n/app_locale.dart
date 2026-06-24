import 'package:flutter/material.dart';

/// 应用支持的语言(默认中文)。
enum AppLocale {
  zh('zh', 'CN', '中文', 'Chinese'),
  en('en', 'US', 'English', 'English');

  const AppLocale(
      this.languageCode, this.countryCode, this.label, this.labelEn);

  final String languageCode;
  final String countryCode;
  final String label;
  final String labelEn;

  Locale get toLocale => Locale(languageCode, countryCode);

  static AppLocale fromCode(String? code) {
    if (code == null) return AppLocale.zh;
    return AppLocale.values.firstWhere(
      (l) => l.name == code,
      orElse: () => AppLocale.zh,
    );
  }
}
