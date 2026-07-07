import 'dart:io' show Platform;

/* 平台差异扩展:UI 通过此类访问,不直接 `Platform.isXxx`。 */
class PlatformInfo {
  const PlatformInfo._();

  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;
  static bool get isTouch => isMobile;
}
