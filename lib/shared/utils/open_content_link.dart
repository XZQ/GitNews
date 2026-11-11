import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/preferences/link_open_mode_controller.dart';

/*
 *按用户「链接打开方式」偏好打开内容链接。
 *
 *inApp 走顶层 /webview 路由留在应用内;external 用系统浏览器。
 *认证流(设备登录等)不经过本函数,固定系统浏览器,避免把凭据
 *输入留在应用内 WebView。返回 false 表示外部打开失败,调用方
 *可据此提示;inApp 导航成功返回 true。
 */
Future<bool> openContentLink({required BuildContext context, required WidgetRef ref, required Uri uri, String? title}) async {
  final mode = ref.read(linkOpenModeControllerProvider);
  if (mode == LinkOpenMode.inApp) {
    if (!context.mounted) {
      return false;
    }
    final location = Uri(path: '/webview', queryParameters: {'url': uri.toString(), if (title != null && title.isNotEmpty) 'title': title});
    // push 的 Future 在页面 pop 时才完成;导航发起即视为打开成功。
    unawaited(context.push(location.toString()));
    return true;
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
