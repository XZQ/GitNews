import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/di/providers.dart';
import '../../core/di/repository_feed_providers.dart';
import '../../core/preferences/config_service.dart';
import '../../core/storage/local_database.dart';
import '../../core/storage/storage_providers.dart';
import '../../features/monitor/application/monitor_settings_controller.dart';
import '../../features/trending/application/trending_providers.dart';
import '../../features/trending/application/trending_repository_feed.dart';

/*
 *应用级的 provider 装配清单。
 *
 *core 只声明契约(`sharedPreferencesProvider` / `appDatabaseProvider` /
 *`repositoryFeedProvider` / `configInvalidationHooksProvider`),具体实现由这里注入。
 *`lib/bootstrap.dart` 因此不需要 import 任何 feature,`lib/core/` 也能保持零 feature 依赖。
 */
List<Override> buildAppOverrides({required SharedPreferences preferences, required LocalDatabase database, required AuthRepository authRepository}) => [
  sharedPreferencesProvider.overrideWithValue(preferences),
  appDatabaseProvider.overrideWithValue(database),
  authRepositoryProvider.overrideWithValue(authRepository),
  // project 需要一份仓库摘要流;具体来源是 trending 的 feed 适配器。
  repositoryFeedProvider.overrideWith((ref) => TrendingRepositoryFeed(ref.watch(trendingRepositoryProvider))),
  // 导入配置后需要连带失效 feature 自己维护的偏好项。
  configInvalidationHooksProvider.overrideWithValue([(ref) => ref.invalidate(monitorSettingsControllerProvider)]),
];
