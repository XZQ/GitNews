import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/preferences/github_token_controller.dart';
import '../../../core/preferences/trending_data_source_mode_controller.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/cached_trending_data_source.dart';
import '../data/github_trending_data_source.dart';
import '../data/local_trending_data_source.dart';
import '../data/local_trending_repository.dart';
import '../data/trending_cache_dao.dart';
import '../data/trending_data_source.dart';
import '../data/trending_repository_impl.dart';
import '../domain/entities.dart';
import '../domain/trending_repository.dart';

const Duration trendingGithubCacheTtl = Duration(minutes: 30);

class TrendingDataSourceStatus {
  const TrendingDataSourceStatus({
    required this.mode,
    required this.hasToken,
    required this.cacheTtl,
  });

  final TrendingDataSourceMode mode;
  final bool hasToken;
  final Duration cacheTtl;

  bool get isGithub => mode == TrendingDataSourceMode.github;

  String get label {
    if (!isGithub) return '本地数据';
    final source = hasToken ? 'GitHub Token' : 'GitHub 匿名';
    return '$source · 缓存${cacheTtl.inMinutes}分钟';
  }
}

final trendingDataSourceStatusProvider =
    Provider<TrendingDataSourceStatus>((ref) {
  final mode = ref.watch(trendingDataSourceModeControllerProvider);
  final token = ref.watch(githubTokenControllerProvider);
  return TrendingDataSourceStatus(
    mode: mode,
    hasToken: token.hasToken,
    cacheTtl: trendingGithubCacheTtl,
  );
});

final trendingClockProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

final trendingDataSourceProvider = Provider<TrendingDataSource>((ref) {
  final mode = ref.watch(trendingDataSourceModeControllerProvider);
  return switch (mode) {
    TrendingDataSourceMode.local => const LocalTrendingDataSource(),
    TrendingDataSourceMode.github =>
      ref.watch(githubTrendingDataSourceProvider),
  };
});

final trendingCacheDaoProvider = Provider<TrendingCacheDao>((ref) {
  return TrendingCacheDao(
    ref.watch(appDatabaseProvider).executor,
    ref.watch(cacheMetaDaoProvider),
  );
});

final githubTrendingDataSourceProvider = Provider<TrendingDataSource>((ref) {
  final tokenState = ref.watch(githubTokenControllerProvider);
  return CachedTrendingDataSource(
    remote: GithubTrendingDataSource(
      dio: ref.watch(dioProvider),
      token: tokenState.token,
    ),
    cache: ref.watch(trendingCacheDaoProvider),
    cacheScope: tokenState.cacheScope,
    now: ref.watch(trendingClockProvider),
    ttl: trendingGithubCacheTtl,
  );
});

final trendingRepositoryProvider = Provider<TrendingRepository>((ref) {
  return TrendingRepositoryImpl(
    dataSource: ref.watch(trendingDataSourceProvider),
  );
});

/// 兼容旧测试/外部 override 的本地仓库实例。
final localTrendingRepositoryProvider = Provider<TrendingRepository>((ref) {
  return const LocalTrendingRepository();
});

final trendingDigestProvider = FutureProvider<TrendingDigest>((ref) {
  final query = ref.watch(trendingQueryProvider);
  return ref.watch(trendingRepositoryProvider).getDigest(
        query: query,
      );
});

/// 顶部搜索框关键词。空字符串表示不过滤当前热榜结果。
final trendingSearchQueryProvider = StateProvider<String>((ref) => '');

/// 应用本地搜索后的热榜摘要。
///
/// 搜索只作用于当前已拉取/缓存结果,避免输入关键词触发 GitHub Search 请求。
final filteredTrendingDigestProvider =
    FutureProvider<TrendingDigest>((ref) async {
  final query = ref.watch(trendingSearchQueryProvider);
  final digest = await ref.watch(trendingDigestProvider.future);
  return filterTrendingDigest(digest, query);
});

TrendingDigest filterTrendingDigest(TrendingDigest digest, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) return digest;

  return TrendingDigest(
    trendingRepos: filterTrendingRepos(digest.trendingRepos, keyword),
    recentRepos: filterTrendingRepos(digest.recentRepos, keyword),
    languages: digest.languages,
    primaryTrend: digest.primaryTrend,
    secondaryTrend: digest.secondaryTrend,
    tertiaryTrend: digest.tertiaryTrend,
  );
}

List<RepoEntity> filterTrendingRepos(List<RepoEntity> repos, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) return repos;

  return [
    for (final repo in repos)
      if (_repoSearchText(repo).contains(keyword)) repo,
  ];
}

String _repoSearchText(RepoEntity repo) {
  return [
    repo.fullName,
    repo.description,
    repo.language,
  ].join(' ').toLowerCase();
}

final trendingQueryProvider = Provider<TrendingQuery>((ref) {
  final window = ref.watch(trendingWindowFilterProvider);
  final language = ref.watch(trendingLanguageFilterProvider);
  final board = ref.watch(trendingBoardFilterProvider);
  return TrendingQuery(
    window: TrendingWindow.fromValue(window),
    language: language,
    board: TrendingBoard.fromValue(board),
  );
});

Future<void> refreshTrendingDigest(WidgetRef ref) async {
  final mode = ref.read(trendingDataSourceModeControllerProvider);
  if (mode == TrendingDataSourceMode.github) {
    await ref.read(trendingCacheDaoProvider).deleteSnapshot(
          ref.read(trendingQueryProvider),
          scope: ref.read(githubTokenControllerProvider).cacheScope,
        );
  }
  ref.invalidate(trendingDigestProvider);
}

/// 时间窗筛选:`today` / `week` / `month`。
final trendingWindowFilterProvider = StateProvider<String>((ref) => 'today');

/// 榜单筛选:`all` / `agent` / `mcp` / `ai_coding` / `new_repos`。
final trendingBoardFilterProvider = StateProvider<String>((ref) => 'all');

/// 语言筛选:`all` / `typescript` / `python` / `rust` …
final trendingLanguageFilterProvider = StateProvider<String>((ref) => 'all');
