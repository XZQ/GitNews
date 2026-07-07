import 'package:flutter/services.dart';

/* Windows 平台窗口控制桥接。 */
/*  */ /* 通过 `github_news/window` MethodChannel 调用 native 端实现的 */
/* minimize/maximize/close。在非 Windows 平台调用为 no-op。 */
class WindowService {
  const WindowService();

  static const MethodChannel _channel = MethodChannel('github_news/window');

  Future<void> minimize() async {
    try {
      await _channel.invokeMethod<void>('minimize');
    } on PlatformException {
      // 非 Windows 平台或 channel 未注册,静默忽略。
    } on MissingPluginException {
      // 同上。
    }
  }

  Future<void> toggleMaximize() async {
    try {
      await _channel.invokeMethod<void>('maximize');
    } on PlatformException {
      // ignore
    } on MissingPluginException {
      // ignore
    }
  }

  Future<void> close() async {
    try {
      await _channel.invokeMethod<void>('close');
    } on PlatformException {
      // ignore
    } on MissingPluginException {
      // ignore
    }
  }

  Future<bool> isMaximized() async {
    try {
      final result = await _channel.invokeMethod<bool>('isMaximized');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
