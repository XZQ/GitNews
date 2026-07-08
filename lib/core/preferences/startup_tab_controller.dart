import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import '../router/route_specs.dart';

/// 启动 Tab 偏好:决定应用冷启动时落到哪个一级 Tab。
///
/// 存储 [TabSpec.pathSegment](如 'home' / 'discover' / 'profile'),
/// `app_router` 在构造 GoRouter 时 `ref.read` 一次作为 initialLocation,
/// 因此切换后**下次冷启动生效**,不会热重建路由栈、不影响当前导航。
class StartupTabController extends Notifier<String> {
  static const _kKey = 'startup_tab_segment';

  @override
  String build() {
    final segment = ref.read(sharedPreferencesProvider).getString(_kKey);
    if (segment != null && appTabs.any((tab) => tab.pathSegment == segment)) {
      return segment;
    }
    return appTabs.first.pathSegment;
  }

  Future<void> setSegment(String segment) async {
    if (!appTabs.any((tab) => tab.pathSegment == segment)) return;
    state = segment;
    await ref.read(sharedPreferencesProvider).setString(_kKey, segment);
  }
}

final startupTabControllerProvider =
    NotifierProvider<StartupTabController, String>(StartupTabController.new);
