import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/platform/desktop_integration_service.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

const _windowChannel = MethodChannel('window_manager');
const _trayChannel = MethodChannel('tray_manager');
const _notificationChannel = MethodChannel('local_notifier');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final windowCalls = <MethodCall>[];
  final trayCalls = <MethodCall>[];
  final services = <DesktopIntegrationService>[];
  String? failedTrayMethod;
  bool failPreventClose = false;

  setUp(() {
    failedTrayMethod = null;
    failPreventClose = false;
    windowCalls.clear();
    trayCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_windowChannel, (call) async {
      windowCalls.add(call);
      if (call.method == 'setPreventClose' && (call.arguments as Map)['isPreventClose'] == true && failPreventClose) {
        throw PlatformException(code: 'window_unavailable');
      }
      return call.method.startsWith('is') ? false : null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_trayChannel, (call) async {
      trayCalls.add(call);
      if (call.method == failedTrayMethod) {
        throw PlatformException(code: 'tray_unavailable');
      }
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_notificationChannel, (_) async => true);
  });

  tearDown(() {
    for (final service in services) {
      windowManager.removeListener(service);
      trayManager.removeListener(service);
    }
    services.clear();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_windowChannel, null);
    messenger.setMockMethodCallHandler(_trayChannel, null);
    messenger.setMockMethodCallHandler(_notificationChannel, null);
  });

  for (final failedMethod in ['setIcon', 'setToolTip', 'setContextMenu']) {
    testWidgets('$failedMethod failure leaves native close enabled and never hides an inaccessible window', (tester) async {
      await _withWindowsPlatform(() async {
        failedTrayMethod = failedMethod;
        final service = DesktopIntegrationService.forTesting();
        services.add(service);
        await service.initialize();
        await tester.pump();

        expect(service.active, isFalse);
        expect(_preventCloseValues(windowCalls), [false]);
        expect(trayCalls.map((call) => call.method), contains('destroy'));
        expect(windowManager.listeners, isNot(contains(service)));
        service.onWindowClose();
        await tester.pump();

        expect(windowCalls.map((call) => call.method), isNot(contains('hide')));
      });
    });
  }

  testWidgets('failure to intercept close restores native close and destroys the partial tray', (tester) async {
    await _withWindowsPlatform(() async {
      failPreventClose = true;
      final service = DesktopIntegrationService.forTesting();
      services.add(service);
      await service.initialize();
      await tester.pump();

      expect(service.active, isFalse);
      expect(_preventCloseValues(windowCalls), [true, false]);
      expect(trayCalls.map((call) => call.method), contains('destroy'));
      service.onWindowClose();
      await tester.pump();
      expect(windowCalls.map((call) => call.method), isNot(contains('hide')));
    });
  });

  testWidgets('complete tray setup intercepts close, hides the window, and can restore it', (tester) async {
    await _withWindowsPlatform(() async {
      final service = DesktopIntegrationService.forTesting();
      services.add(service);
      await service.initialize();
      await tester.pump();

      expect(service.active, isTrue);
      expect(_preventCloseValues(windowCalls), [true]);
      expect(windowManager.listeners, contains(service));
      service.onWindowClose();
      await tester.pump();
      expect(windowCalls.map((call) => call.method), contains('hide'));
      windowCalls.clear();
      await service.showWindow();
      expect(windowCalls.map((call) => call.method), containsAll(['show', 'focus', 'setSkipTaskbar']));
    });
  });
}

/* 在测试主体结束前恢复平台覆盖值，包括断言失败路径，满足 Flutter binding 的不变量。 */
Future<void> _withWindowsPlatform(Future<void> Function() body) async {
  final previousPlatform = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = previousPlatform;
  }
}

/* 提取窗口关闭策略，忽略其他启动时窗口调用。 */
List<bool> _preventCloseValues(List<MethodCall> calls) => [
  for (final call in calls)
    if (call.method == 'setPreventClose') (call.arguments as Map)['isPreventClose'] as bool,
];
