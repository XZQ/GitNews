import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

/* 
*配置导出/导入服务。
*将用户偏好（主题、侧栏宽度、语言等）导出为 JSON 字符串到剪贴板，
*或从剪贴板导入。**不导出 GitHub Token**（安全考虑）。
*/
class ConfigService {
  ConfigService(this._ref);

  final Ref _ref;

  /* 
  *导出当前配置到剪贴板。
  *返回导出的 JSON 字符串。调用方负责展示 SnackBar。
  */
  Future<String> exportConfig() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final keys = prefs.getKeys().where(
          (k) => !k.startsWith('github_personal_access_token'),
        );

    final config = <String, dynamic>{};
    for (final key in keys) {
      config[key] = prefs.get(key);
    }

    final json = const JsonEncoder.withIndent('  ').convert({
      'app': 'github_news',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'preferences': config,
    });

    await Clipboard.setData(ClipboardData(text: json));
    return json;
  }

  /* 
  *从剪贴板导入配置。
  *读取剪贴板内容，解析 JSON，将 preferences 写入 SharedPreferences。
  *返回导入的 key 数量。解析失败抛 [FormatException]。
  */
  Future<int> importConfig() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      throw const FormatException('Clipboard is empty');
    }

    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid config format: expected JSON object',
      );
    }

    final prefs = decoded['preferences'];
    if (prefs is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid config format: missing "preferences"',
      );
    }

    final sp = _ref.read(sharedPreferencesProvider);
    var count = 0;
    for (final entry in prefs.entries) {
      final key = entry.key;
      // 安全过滤:不导入 Token 相关 key
      if (key.startsWith('github_personal_access_token')) {
        continue;
      }

      final value = entry.value;
      if (value is String) {
        await sp.setString(key, value);
        count++;
      } else if (value is int) {
        await sp.setInt(key, value);
        count++;
      } else if (value is double) {
        await sp.setDouble(key, value);
        count++;
      } else if (value is bool) {
        await sp.setBool(key, value);
        count++;
      } else if (value is List) {
        await sp.setStringList(key, value.cast<String>());
        count++;
      }
    }

    return count;
  }
}

final configServiceProvider = Provider<ConfigService>(
  (ref) => ConfigService(ref),
);
