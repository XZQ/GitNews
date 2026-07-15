import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bootstrap.dart';
import 'core/platform/desktop_integration_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DesktopIntegrationService.instance.initialize();
  // 移动端沉浸式:内容延伸到状态栏/手势条下,系统栏透明。
  // 桌面端此调用是无害 no-op。
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  // 全局崩溃兜底:release 下不显示 Flutter 红屏,而是友好提示。
  ErrorWidget.builder = (details) => Material(
        color: Colors.black87,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_outlined, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  kDebugMode ? details.exceptionAsString() : '应用遇到意外错误,请重启。',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                )
              ],
            ),
          ),
        ),
      );
  runApp(const BootstrapApp());
}
