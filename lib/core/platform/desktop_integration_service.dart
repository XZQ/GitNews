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

  /* 创建独立生命周期实例，测试不会污染生产单例。 */
  @visibleForTesting
  DesktopIntegrationService.forTesting();

  static final instance = DesktopIntegrationService._();

  bool _initialized = false;
  bool _quitting = false;
  bool _notificationsReady = false;

  // 只有窗口插件和完整托盘入口都可用时，关闭才可以隐藏窗口。
  bool _hideOnClose = false;
  final List<LocalNotification> _activeNotifications = [];

  bool get supported => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  bool get active => supported && _hideOnClose;

  /* 先建立可恢复的托盘入口，再接管窗口关闭；失败时保留默认关闭。 */
  Future<void> initialize() async {
    if (!supported || _initialized) {
      return;
    }
    _initialized = true;
    var windowReady = false;
    try {
      await windowManager.ensureInitialized();
      windowReady = true;
      unawaited(_showInitialWindow());
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
      if (windowReady) {
        await windowManager.setPreventClose(true);
        windowManager.addListener(this);
        _hideOnClose = true;
      }
    } catch (_) {
      _hideOnClose = false;
      windowManager.removeListener(this);
      trayManager.removeListener(this);
      try {
        await trayManager.destroy();
      } catch (_) {
        // 尽力移除不完整的托盘入口。
      }
      if (windowReady) {
        try {
          await windowManager.setPreventClose(false);
        } catch (_) {
          // 没有注册关闭监听，不会主动隐藏仍可见的窗口。
        }
      }
    }
    try {
      await localNotifier.setup(appName: 'AI资讯', shortcutPolicy: ShortcutPolicy.requireCreate);
      _notificationsReady = true;
    } catch (_) {
      _notificationsReady = false;
    }
  }

  /* 保持首帧前的非阻塞窗口展示，并在插件异步失败时保留可见窗口。 */
  Future<void> _showInitialWindow() async {
    try {
      await windowManager.waitUntilReadyToShow(const WindowOptions(title: 'AI资讯', titleBarStyle: TitleBarStyle.hidden, windowButtonVisibility: false), () {
        unawaited(showWindow());
      });
    } catch (_) {
      // Flutter Runner 仍负责首帧窗口展示。
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

  Future<void> showNotification({required String title, required String body}) async {
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
    if (_quitting || !_hideOnClose) {
      return;
    }
    unawaited(windowManager.hide().catchError((Object _) {}));
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(showWindow());
  }

  @override
  void onTrayIconRightMouseUp() {
    unawaited(trayManager.popUpContextMenu().catchError((Object _) {}));
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        unawaited(showWindow());
      case 'exit_app':
        unawaited(_quit());
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
    final relative = p.join('windows', 'runner', 'resources', 'app_icon.ico');
    final bundled = p.join(File(Platform.resolvedExecutable).parent.path, 'data', 'flutter_assets', relative);
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
