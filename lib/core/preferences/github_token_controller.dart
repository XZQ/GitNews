import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

/* 本地 GitHub token 配置状态。 */
class GitHubTokenState {
  const GitHubTokenState({this.token});

  final String? token;

  bool get hasToken => token != null && token!.trim().isNotEmpty;

  String get maskedToken {
    final raw = token?.trim();
    if (raw == null || raw.isEmpty) return '未配置';
    if (raw.length <= 8) return '已配置';
    return '${raw.substring(0, 4)}...${raw.substring(raw.length - 4)}';
  }

  /* 用于隔离 GitHub 热榜缓存,避免匿名状态复用认证请求缓存。 */
  String get cacheScope {
    final raw = token?.trim();
    if (raw == null || raw.isEmpty) return 'anonymous';
    var hash = 0;
    for (final unit in raw.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return 'token_${raw.length}_$hash';
  }
}

/* GitHub Personal Access Token controller。 */
/*  */
/* Token 通过 [FlutterSecureStorage] 安全存储(Windows DPAPI / macOS Keychain), */
/* 不再明文写入 SharedPreferences。首次启动时自动迁移旧版明文 Token。 */
class GitHubTokenController extends Notifier<GitHubTokenState> {
  static const _kKey = 'github_personal_access_token';
  static const _kLegacyKey = 'github_personal_access_token';

  @override
  GitHubTokenState build() {
    _migrateFromPrefsIfNeeded();
    return const GitHubTokenState();
  }

  /* 异步加载:从 secure storage 读取 Token,同时检查旧版 SharedPreferences 迁移。 */
  Future<void> _migrateFromPrefsIfNeeded() async {
    final secure = ref.read(secureStorageProvider);
    final stored = await secure.read(key: _kKey);
    if (stored != null && stored.isNotEmpty) {
      state = GitHubTokenState(token: stored);
      return;
    }
    // 迁移:如果 secure storage 为空,检查旧版 SharedPreferences
    final prefs = ref.read(sharedPreferencesProvider);
    final legacy = prefs.getString(_kLegacyKey);
    if (legacy != null && legacy.isNotEmpty) {
      await secure.write(key: _kKey, value: legacy);
      await prefs.remove(_kLegacyKey);
      state = GitHubTokenState(token: legacy);
    }
  }

  Future<void> setToken(String value) async {
    final token = value.trim();
    if (token.isEmpty) return clear();
    state = GitHubTokenState(token: token);
    final secure = ref.read(secureStorageProvider);
    await secure.write(key: _kKey, value: token);
  }

  Future<void> clear() async {
    state = const GitHubTokenState();
    final secure = ref.read(secureStorageProvider);
    await secure.delete(key: _kKey);
  }
}

final githubTokenControllerProvider =
    NotifierProvider<GitHubTokenController, GitHubTokenState>(
  GitHubTokenController.new,
);
