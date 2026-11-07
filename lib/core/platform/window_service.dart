import 'package:flutter/services.dart';

import '../utils/app_logger.dart';

/* 
*Windows 平台窗口控制桥接。
*通过 `github_news/window` MethodChannel 调用 native 端实现的
*minimize/maximize/close。在非 Windows 平台调用为 no-op。
*/
class WindowService {
  const WindowService();

  static const MethodChannel _channel = MethodChannel('github_news/window');

  Future<void> minimize() async {
    try {
      await _channel.invokeMethod<void>('minimize');
    } on PlatformException {
      // 非 Windows 平台或 channel 未注册,保持 no-op 但留下可诊断痕迹。
      AppLogger.warn('window.channelFailed', meta: {'op': 'minimize'});
    } on MissingPluginException {
      AppLogger.warn('window.channelFailed', meta: {'op': 'minimize', 'missing': true});
    }
  }

  Future<void> toggleMaximize() async {
    try {
      await _channel.invokeMethod<void>('maximize');
    } on PlatformException {
      AppLogger.warn('window.channelFailed', meta: {'op': 'maximize'});
    } on MissingPluginException {
      AppLogger.warn('window.channelFailed', meta: {'op': 'maximize', 'missing': true});
    }
  }

  Future<void> close() async {
    try {
      await _channel.invokeMethod<void>('close');
    } on PlatformException {
      AppLogger.warn('window.channelFailed', meta: {'op': 'close'});
    } on MissingPluginException {
      AppLogger.warn('window.channelFailed', meta: {'op': 'close', 'missing': true});
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
