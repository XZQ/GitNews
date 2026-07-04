import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

/// 本地 GitHub token 配置状态。
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

  /// 用于隔离 GitHub 热榜缓存,避免匿名状态复用认证请求缓存。
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

/// GitHub Personal Access Token controller。
///
/// 目前作为桌面端开发者配置项保存到 SharedPreferences。后续若引入
/// secure storage 或 OAuth,只需要替换本 controller 的存储实现。
class GitHubTokenController extends Notifier<GitHubTokenState> {
  static const _kKey = 'github_personal_access_token';

  @override
  GitHubTokenState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return GitHubTokenState(token: prefs.getString(_kKey));
  }

  Future<void> setToken(String value) async {
    final token = value.trim();
    if (token.isEmpty) return clear();
    state = GitHubTokenState(token: token);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kKey, token);
  }

  Future<void> clear() async {
    state = const GitHubTokenState();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_kKey);
  }
}

final githubTokenControllerProvider =
    NotifierProvider<GitHubTokenController, GitHubTokenState>(
  GitHubTokenController.new,
);
