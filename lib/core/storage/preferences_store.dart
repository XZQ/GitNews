import 'package:shared_preferences/shared_preferences.dart';

/// 用户偏好键值存储(草稿)。
class PreferencesStore {
  PreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kThemeMode = 'pref.themeMode';

  Future<void> setThemeMode(String mode) => _prefs.setString(_kThemeMode, mode);

  String? getThemeMode() => _prefs.getString(_kThemeMode);
}
