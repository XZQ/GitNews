import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/dio_client.dart';

/// 全局 dio 实例(无 token 匿名客户端)。
final dioProvider = Provider((ref) => DioClient.create());

/// SharedPreferences 单例(异步初始化,在 main 中 override)。
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

/// FlutterSecureStorage 单例(桌面端走 Windows DPAPI / macOS Keychain)。
///
/// 用于存储敏感凭据(如 GitHub Token),替代 SharedPreferences 明文存储。
/// 初始化为同步操作(内部走 platform channel),无需在 main 中 override。
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    wOptions: WindowsOptions(),
  ),
);
