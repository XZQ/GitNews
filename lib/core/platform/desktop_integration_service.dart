import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/*
*桌面生命周期:关闭窗口时隐藏到托盘，托盘可恢复或彻底退出。
*所有插件调用均为最佳努力，初始化失败不会阻断主应用启动。
*/
class DesktopIntegrationService with WindowListener, TrayListener {
  DesktopIntegrationService._();

  static final instance = DesktopIntegrationService._();

  bool _initialized = false;
  bool _quitting = false;
  bool _notificationsReady = false;
  final List<LocalNotification> _activeNotifications = [];

  bool get supported => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  bool get active => supported && _initialized;

  Future<void> initialize() async {
    if (!supported || _initialized) {
      return;
    }
    _initialized = true;
    try {
      await windowManager.ensureInitialized();
      unawaited(
        windowManager.waitUntilReadyToShow(
          const WindowOptions(
            title: 'AI资讯',
            titleBarStyle: TitleBarStyle.hidden,
            windowButtonVisibility: false,
          ),
          () async {
            await windowManager.show();
            await windowManager.focus();
          },
        ),
      );
      await windowManager.setPreventClose(true);
      windowManager.addListener(this);
    } catch (_) {
      // 窗口插件不可用时保留系统默认关闭行为。
    }
    try {
      await trayManager.setIcon(_trayIconPath());
      await trayManager.setToolTip('AI资讯');
      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(key: 'show_window', label: _label(show: true)),
            MenuItem.separator(),
            MenuItem(key: 'exit_app', label: _label(show: false)),
          ],
        ),
      );
      trayManager.addListener(this);
    } catch (_) {
      // 托盘不可用时应用仍可正常以前台窗口运行。
    }
    try {
      await localNotifier.setup(
        appName: 'AI资讯',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
      _notificationsReady = true;
    } catch (_) {
      _notificationsReady = false;
    }
  }

  Future<void> showWindow() async {
    if (!supported) {
      return;
    }
    try {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setSkipTaskbar(false);
    } catch (_) {
      // no-op
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (!_notificationsReady) {
      return;
    }
    try {
      final notification = LocalNotification(title: title, body: body)..onClick = showWindow;
      _activeNotifications.add(notification);
      if (_activeNotifications.length > 20) {
        final oldest = _activeNotifications.removeAt(0);
        await oldest.destroy();
      }
      await notification.show();
    } catch (_) {
      // 系统通知失败不影响应用内提醒落库。
    }
  }

  @override
  void onWindowClose() {
    if (_quitting) {
      return;
    }
    windowManager.hide();
  }

  @override
  void onTrayIconMouseDown() {
    showWindow();
  }

  @override
  void onTrayIconRightMouseUp() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        showWindow();
      case 'exit_app':
        _quit();
    }
  }

  Future<void> _quit() async {
    _quitting = true;
    try {
      await windowManager.setPreventClose(false);
      await trayManager.destroy();
      await windowManager.destroy();
    } catch (_) {
      exit(0);
    }
  }

  String _trayIconPath() {
    final relative = p.join(
      'windows',
      'runner',
      'resources',
      'app_icon.ico',
    );
    final bundled = p.join(
      File(Platform.resolvedExecutable).parent.path,
      'data',
      'flutter_assets',
      relative,
    );
    return File(bundled).existsSync() ? bundled : p.join(Directory.current.path, relative);
  }

  String _label({required bool show}) {
    final chinese = Platform.localeName.toLowerCase().startsWith('zh');
    if (show) {
      return chinese ? '打开 AI资讯' : 'Open AI News';
    }
    return chinese ? '退出' : 'Quit';
  }
}
