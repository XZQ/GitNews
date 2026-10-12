import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../di/providers.dart';
import '../utils/app_logger.dart';

/* 
*本地 GitHub token 配置状态。
*/
class GitHubTokenState {
  const GitHubTokenState({this.token});

  final String? token;

  bool get hasToken => token != null && token!.trim().isNotEmpty;

  String get maskedToken {
    final raw = token?.trim();
    if (raw == null || raw.isEmpty) {
      return '未配置';
    }
    if (raw.length <= 8) {
      return '已配置';
    }
    return '${raw.substring(0, 4)}...${raw.substring(raw.length - 4)}';
  }

  /* 
  *用于隔离 GitHub 热榜缓存,避免匿名状态复用认证请求缓存。
  */
  String get cacheScope {
    final raw = token?.trim();
    if (raw == null || raw.isEmpty) {
      return 'anonymous';
    }
    var hash = 0;
    for (final unit in raw.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return 'token_${raw.length}_$hash';
  }
}

/* 
*GitHub Personal Access Token controller。
*Token 通过 [FlutterSecureStorage] 安全存储(Windows DPAPI / macOS Keychain),
*不再明文写入 SharedPreferences。首次启动时自动迁移旧版明文 Token。
*/
class GitHubTokenController extends Notifier<GitHubTokenState> {
  static const _kKey = 'github_personal_access_token';
  static const _kLegacyKey = 'github_personal_access_token';

  // 在一次控制器生命周期内依次完成初始化、设置和清除。
  Future<void> _pending = Future<void>.value();

  // 异步操作在开始前捕获存储，不在 await 后读取可能已经销毁的 Ref。
  late FlutterSecureStorage _secure;
  late SharedPreferences _preferences;

  @override
  GitHubTokenState build() {
    _secure = ref.read(secureStorageProvider);
    _preferences = ref.read(sharedPreferencesProvider);
    unawaited(
      _enqueue(_migrateFromPrefsIfNeeded).catchError((Object error) {
        AppLogger.warn('githubTokenLoad', meta: {'error': error.runtimeType.toString()});
      }),
    );
    return const GitHubTokenState();
  }

  /* 等待当前已经排入队列的凭据操作。 */
  Future<void> get ready => _pending;

  /* 
  *异步加载:从 secure storage 读取 Token,同时检查旧版 SharedPreferences 迁移。
  */
  Future<void> _migrateFromPrefsIfNeeded() async {
    final stored = await _secure.read(key: _kKey);
    if (stored != null && stored.isNotEmpty) {
      await _removeLegacyToken();
      _publish(GitHubTokenState(token: stored));
      return;
    }
    // 迁移:如果 secure storage 为空,检查旧版 SharedPreferences
    final legacy = _preferences.getString(_kLegacyKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _secure.write(key: _kKey, value: legacy);
      await _removeLegacyToken();
      _publish(GitHubTokenState(token: legacy));
    }
  }

  /* 串行保存 Token；只有安全存储完成后才更新可用状态。 */
  Future<void> setToken(String value) {
    final token = value.trim();
    if (token.isEmpty) {
      return clear();
    }
    return _enqueue(() async {
      await _removeLegacyToken();
      await _secure.write(key: _kKey, value: token);
      _publish(GitHubTokenState(token: token));
    });
  }

  /* 先清理旧明文，再删除安全存储，避免重启后重新迁移被清除的 Token。 */
  Future<void> clear() {
    return _enqueue(() async {
      await _removeLegacyToken();
      await _secure.delete(key: _kKey);
      _publish(const GitHubTokenState());
    });
  }

  /* 清理旧版明文项，并把持久化失败交给调用方。 */
  Future<void> _removeLegacyToken() async {
    if (_preferences.containsKey(_kLegacyKey) && !await _preferences.remove(_kLegacyKey)) {
      throw StateError('Failed to remove legacy GitHub credential');
    }
  }

  /* 操作失败不会阻断后续重试；每位调用者仍收到自己的失败。 */
  Future<void> _enqueue(Future<void> Function() action) {
    final operation = _pending.then((_) => action());
    _pending = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  /* 已销毁的控制器只完成持久化，不继续发布界面状态。 */
  void _publish(GitHubTokenState next) {
    if (ref.mounted) {
      state = next;
    }
  }
}

final githubTokenControllerProvider = NotifierProvider<GitHubTokenController, GitHubTokenState>(GitHubTokenController.new);
