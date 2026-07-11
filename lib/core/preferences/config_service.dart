import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/monitor/application/monitor_settings_controller.dart';
import '../di/providers.dart';
import '../router/route_specs.dart';
import '../shared/local_content_controller.dart';
import '../theme/app_theme_preset.dart';
import '../theme/theme_mode_controller.dart';
import '../theme/theme_preset_controller.dart';
import 'link_open_mode_controller.dart';
import 'locale_controller.dart';
import 'startup_tab_controller.dart';
import 'trending_data_source_mode_controller.dart';

abstract interface class ConfigPreferenceStore {
  Set<String> getKeys();

  Object? get(String key);

  Future<bool> setValue(String key, Object value);

  Future<bool> remove(String key);
}

class SharedPreferencesConfigStore implements ConfigPreferenceStore {
  const SharedPreferencesConfigStore(this._preferences);

  final SharedPreferences _preferences;

  @override
  Object? get(String key) => _preferences.get(key);

  @override
  Set<String> getKeys() => _preferences.getKeys();

  @override
  Future<bool> remove(String key) => _preferences.remove(key);

  @override
  Future<bool> setValue(String key, Object value) {
    return switch (value) {
      final String value => _preferences.setString(key, value),
      final int value => _preferences.setInt(key, value),
      final double value => _preferences.setDouble(key, value),
      final bool value => _preferences.setBool(key, value),
      final List<String> value => _preferences.setStringList(key, value),
      _ => throw ArgumentError.value(value, key, 'Unsupported preference type'),
    };
  }
}

final configPreferenceStoreProvider = Provider<ConfigPreferenceStore>((ref) {
  return SharedPreferencesConfigStore(ref.watch(sharedPreferencesProvider));
});

class ConfigService {
  ConfigService(this._ref);

  static const supportedKeys = <String>{
    'app_locale',
    'theme_mode',
    'app.theme_preset',
    'startup_tab_segment',
    'trending_data_source_mode',
    'link_open_mode',
    'local_content_monitor_rules',
    'monitor_notification_settings',
  };

  final Ref _ref;

  Future<String> exportText() async {
    final store = _ref.read(configPreferenceStoreProvider);
    final preferences = <String, Object>{};
    for (final key in supportedKeys) {
      final value = store.get(key);
      if (value != null) {
        preferences[key] = value;
      }
    }
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'github_news',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'preferences': preferences,
    });
  }

  Future<String> exportConfig() async {
    final text = await exportText();
    await Clipboard.setData(ClipboardData(text: text));
    return text;
  }

  Future<int> importConfig() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      throw const FormatException('Clipboard is empty');
    }
    return importText(text);
  }

  Future<int> importText(String text) async {
    final preferences = _decodeAndValidate(text);
    final store = _ref.read(configPreferenceStoreProvider);
    final oldValues = <String, Object?>{
      for (final key in preferences.keys) key: store.get(key),
    };

    try {
      for (final entry in preferences.entries) {
        final written = await store.setValue(entry.key, entry.value);
        if (!written) {
          throw StateError('Failed to write preference: ${entry.key}');
        }
      }
    } catch (_) {
      await _rollback(store, oldValues);
      rethrow;
    }

    _refreshPreferenceProviders();
    return preferences.length;
  }

  Map<String, Object> _decodeAndValidate(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Invalid JSON: $error');
    }
    if (decoded is! Map<String, dynamic> || decoded['app'] != 'github_news' || decoded['version'] != 1) {
      throw const FormatException('Unsupported config envelope');
    }
    final raw = decoded['preferences'];
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Missing preferences object');
    }

    final result = <String, Object>{};
    for (final entry in raw.entries) {
      if (!supportedKeys.contains(entry.key)) {
        throw FormatException('Unsupported preference key: ${entry.key}');
      }
      result[entry.key] = _validateValue(entry.key, entry.value);
    }
    return result;
  }

  Object _validateValue(String key, Object? value) {
    final validStringValues = switch (key) {
      'app_locale' => const {'zh_CN', 'en_US'},
      'theme_mode' => ThemeMode.values.map((mode) => mode.name).toSet(),
      'app.theme_preset' => AppThemePreset.values.map((preset) => preset.id).toSet(),
      'startup_tab_segment' => appTabs.map((tab) => tab.pathSegment).toSet(),
      'trending_data_source_mode' => TrendingDataSourceMode.values.map((mode) => mode.name).toSet(),
      'link_open_mode' => LinkOpenMode.values.map((mode) => mode.name).toSet(),
      _ => null,
    };
    if (validStringValues != null) {
      if (value is! String || !validStringValues.contains(value)) {
        throw FormatException('Invalid value for $key');
      }
      return value;
    }

    final expectedLength = switch (key) {
      'local_content_monitor_rules' => monitorRuleCount,
      'monitor_notification_settings' => monitorNotificationCount,
      _ => throw FormatException('Unsupported preference key: $key'),
    };
    if (value is! List || value.length != expectedLength) {
      throw FormatException('Invalid value for $key');
    }
    const accepted = {'0', '1', 'true', 'false'};
    final normalized = <String>[];
    for (final item in value) {
      if (item is! String || !accepted.contains(item)) {
        throw FormatException('Invalid value for $key');
      }
      normalized.add(item);
    }
    return normalized;
  }

  Future<void> _rollback(
    ConfigPreferenceStore store,
    Map<String, Object?> oldValues,
  ) async {
    for (final entry in oldValues.entries) {
      try {
        final oldValue = entry.value;
        if (oldValue == null) {
          await store.remove(entry.key);
        } else {
          await store.setValue(entry.key, oldValue);
        }
      } catch (_) {
        // 尽最大努力恢复；保留最初的写入错误给调用方。
      }
    }
  }

  void _refreshPreferenceProviders() {
    _ref
      ..invalidate(localeControllerProvider)
      ..invalidate(themeModeControllerProvider)
      ..invalidate(themePresetControllerProvider)
      ..invalidate(startupTabControllerProvider)
      ..invalidate(trendingDataSourceModeControllerProvider)
      ..invalidate(linkOpenModeControllerProvider)
      ..invalidate(localContentControllerProvider)
      ..invalidate(monitorSettingsControllerProvider);
  }
}

final configServiceProvider = Provider<ConfigService>(ConfigService.new);
