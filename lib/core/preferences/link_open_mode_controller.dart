import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

/* 
*外链打开方式。
*- [inApp]:应用内 WebView([WebViewPage])打开,保留在 App 内浏览。
*- [external]:系统浏览器打开(`url_launcher.externalApplication`)。
*/
enum LinkOpenMode {
  inApp('profile.link_open.in_app'),
  external('profile.link_open.external');

  const LinkOpenMode(this.label);

  // i18n key for display label.
  final String label;
}

/* 
*链接打开方式 controller:持久化到 SharedPreferences。
*默认 [LinkOpenMode.external]:Windows 端 `flutter_inappwebview` 加载外链
*经常白屏 / 析构时崩进程,先用系统浏览器打开,插件稳定后再切回 inApp。
*/
class LinkOpenModeController extends Notifier<LinkOpenMode> {
  static const _kKey = 'link_open_mode';
  static const _kMigratedKey = 'link_open_mode_migrated_v2';

  @override
  LinkOpenMode build() {
    // 同步读取(main() 已 override sharedPreferencesProvider),避免异步加载
    // 造成首帧渲染 external、随后又被覆盖的闪烁。
    final prefs = ref.read(sharedPreferencesProvider);
    final migrated = prefs.getBool(_kMigratedKey) ?? false;
    if (!migrated) {
      prefs.remove(_kKey);
      prefs.setBool(_kMigratedKey, true);
      return LinkOpenMode.external;
    }
    final raw = prefs.getString(_kKey);
    if (raw == null) {
      return LinkOpenMode.external;
    }
    return LinkOpenMode.values.firstWhere((m) => m.name == raw, orElse: () => LinkOpenMode.external);
  }

  Future<void> setMode(LinkOpenMode mode) async {
    if (state == mode) {
      return;
    }
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kKey, mode.name);
  }
}

final linkOpenModeControllerProvider = NotifierProvider<LinkOpenModeController, LinkOpenMode>(LinkOpenModeController.new);
