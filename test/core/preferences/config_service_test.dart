import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/di/providers.dart';
import 'package:github_news/core/preferences/ai_news_reminder_preferences.dart';
import 'package:github_news/core/preferences/ai_news_source_controller.dart';
import 'package:github_news/core/preferences/config_service.dart';
import 'package:github_news/core/preferences/link_open_mode_controller.dart';
import 'package:github_news/core/preferences/locale_controller.dart';
import 'package:github_news/core/preferences/startup_tab_controller.dart';
import 'package:github_news/core/preferences/trending_data_source_mode_controller.dart';
import 'package:github_news/core/shared/local_content_controller.dart';
import 'package:github_news/core/theme/app_theme_preset.dart';
import 'package:github_news/core/theme/theme_mode_controller.dart';
import 'package:github_news/core/theme/theme_preset_controller.dart';
import 'package:github_news/features/monitor/application/monitor_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('export includes only supported non-secret preferences', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark', 'github_personal_access_token': 'secret', 'unrelated_cache': 'internal'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);

    final text = await container.read(configServiceProvider).exportText();
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    final exported = decoded['preferences'] as Map<String, dynamic>;

    expect(exported, {'theme_mode': 'dark'});
  });

  test('unknown and secret keys are rejected before any write', () async {
    final store = _MemoryConfigPreferenceStore({'theme_mode': 'light'});
    final container = ProviderContainer(overrides: [configPreferenceStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);

    await expectLater(container.read(configServiceProvider).importText(_config({'theme_mode': 'dark', 'github_personal_access_token': 'x'})), throwsFormatException);

    expect(store.values, {'theme_mode': 'light'});
  });

  test('invalid values are rejected before any write', () async {
    final store = _MemoryConfigPreferenceStore({'theme_mode': 'light'});
    final container = ProviderContainer(overrides: [configPreferenceStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);

    await expectLater(container.read(configServiceProvider).importText(_config({'theme_mode': 'ultraviolet'})), throwsFormatException);

    expect(store.values, {'theme_mode': 'light'});
  });

  test('write failure rolls back all preferences', () async {
    final store = _MemoryConfigPreferenceStore({'theme_mode': 'light', 'app_locale': 'zh_CN'}, failKey: 'app_locale');
    final container = ProviderContainer(overrides: [configPreferenceStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);

    await expectLater(container.read(configServiceProvider).importText(_config({'theme_mode': 'dark', 'app_locale': 'en_US'})), throwsStateError);

    expect(store.values, {'theme_mode': 'light', 'app_locale': 'zh_CN'});
  });

  test('successful import refreshes all preference providers', () async {
    SharedPreferences.setMockInitialValues({'link_open_mode_migrated_v2': true});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);

    expect(container.read(themeModeControllerProvider), ThemeMode.light);
    expect(container.read(themePresetControllerProvider), AppThemePreset.teal);
    expect(container.read(localeControllerProvider), const Locale('zh', 'CN'));
    expect(container.read(startupTabControllerProvider), 'home');
    expect(container.read(trendingDataSourceModeControllerProvider), TrendingDataSourceMode.local);
    expect(container.read(linkOpenModeControllerProvider), LinkOpenMode.external);
    expect(container.read(aiNewsSourceControllerProvider).entries.any((entry) => entry.isCustom), isFalse);
    expect(container.read(aiNewsReminderPreferencesProvider), isTrue);
    container.read(localContentControllerProvider);
    container.read(monitorSettingsControllerProvider);

    final count = await container.read(configServiceProvider).importText(
          _config({
            'app_locale': 'en_US',
            'theme_mode': 'dark',
            'app.theme_preset': 'violet',
            'startup_tab_segment': 'project',
            'trending_data_source_mode': 'github',
            'link_open_mode': 'inApp',
            aiNewsSourcesPreferenceKey: jsonEncode([
              {'id': 'custom_example', 'name': 'Example AI', 'feedUrl': 'https://example.com/feed.xml', 'categoryCode': 'industry', 'enabled': true, 'isCustom': true}
            ]),
            aiNewsRemindersEnabledPreferenceKey: false,
            'local_content_monitor_rules': ['0', '1', '1', '0'],
            'monitor_notification_settings': ['0']
          }),
        );

    expect(count, 10);
    expect(container.read(themeModeControllerProvider), ThemeMode.dark);
    expect(container.read(themePresetControllerProvider), AppThemePreset.violet);
    expect(container.read(localeControllerProvider), const Locale('en', 'US'));
    expect(container.read(startupTabControllerProvider), 'project');
    expect(container.read(trendingDataSourceModeControllerProvider), TrendingDataSourceMode.github);
    expect(container.read(linkOpenModeControllerProvider), LinkOpenMode.inApp);
    expect(
      container.read(aiNewsSourceControllerProvider).entries.any((entry) => entry.config.id == 'custom_example'),
      isTrue,
    );
    expect(container.read(aiNewsReminderPreferencesProvider), isFalse);
    expect(container.read(localContentControllerProvider).monitorRules, [false, true, true, false]);
    expect(container.read(monitorSettingsControllerProvider), [false]);
  });
}

String _config(Map<String, dynamic> preferences) => jsonEncode({'app': 'github_news', 'version': 1, 'preferences': preferences});

class _MemoryConfigPreferenceStore implements ConfigPreferenceStore {
  _MemoryConfigPreferenceStore(Map<String, Object> values, {this.failKey}) : values = {...values};

  final Map<String, Object> values;
  final String? failKey;

  @override
  Object? get(String key) => values[key];

  @override
  Set<String> getKeys() => values.keys.toSet();

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }

  @override
  Future<bool> setValue(String key, Object value) async {
    if (key == failKey) {
      return false;
    }
    values[key] = value;
    return true;
  }
}
