import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'core/storage/cache_meta_dao.dart';
import 'core/storage/local_database.dart';
import 'core/storage/storage_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 全局崩溃兜底:release 下不显示 Flutter 红屏,而是友好提示。
  ErrorWidget.builder = (details) => Material(
        color: Colors.black87,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_outlined,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  kDebugMode
                      ? details.exceptionAsString()
                      : '应用遇到意外错误,请重启。',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
  final results = await Future.wait<dynamic>([
    SharedPreferences.getInstance(),
    LocalDatabase.open(),
  ]);
  final prefs = results[0] as SharedPreferences;
  final database = results[1] as LocalDatabase;
  // 启动时收敛无限增长的 cache_key 元数据(最佳努力,失败不影响启动)。
  await CacheMetaDao(database.executor).pruneStale(
    now: DateTime.now(),
    retainFor: const Duration(days: 2),
  );
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const GitHubNewsApp(),
    ),
  );
}
