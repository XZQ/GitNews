import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/dio_client.dart';
import '../storage/app_database.dart';

/// 全局 dio 实例(无 token 匿名客户端)。
final dioProvider = Provider((ref) => DioClient.create());

/// 全局数据库。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// SharedPreferences 单例(异步初始化,在 main 中 override)。
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);
