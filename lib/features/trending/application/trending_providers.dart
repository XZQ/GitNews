import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/cache_ttl_config.dart';
import '../../../core/di/providers.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/github/rate_limit_gate.dart';
import '../../../core/i18n/app_localizations.dart';
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

const Duration trendingGithubCacheTtl = CacheTtlConfig.trending;

class TrendingDataSourceStatus {
  const TrendingDataSourceStatus({required this.mode, required this.hasToken, required this.cacheTtl});

  final TrendingDataSourceMode mode;
  final bool hasToken;
  final Duration cacheTtl;

  bool get isGithub => mode == TrendingDataSourceMode.github;

  String label(AppLocalizations l10n) {
    if (!isGithub) {
      return l10n.tr('trending.source.local');
    }
    final source = hasToken ? l10n.tr('trending.source.github_token') : l10n.tr('trending.source.github_anonymous');
    return source + l10n.tr('trending.source.cache_suffix').replaceAll('{minutes}', cacheTtl.inMinutes.toString());
  }
}

final trendingDataSourceStatusProvider = Provider<TrendingDataSourceStatus>((ref) {
  final mode = ref.watch(trendingDataSourceModeControllerProvider);
  final token = ref.watch(githubTokenControllerProvider);
  return TrendingDataSourceStatus(mode: mode, hasToken: token.hasToken, cacheTtl: trendingGithubCacheTtl);
});

final trendingClockProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

final trendingDataSourceProvider = Provider<TrendingDataSource>((ref) {
  final mode = ref.watch(trendingDataSourceModeControllerProvider);
  return switch (mode) { TrendingDataSourceMode.local => const LocalTrendingDataSource(), TrendingDataSourceMode.github => ref.watch(githubTrendingDataSourceProvider) };
});

final trendingCacheDaoProvider = Provider<TrendingCacheDao>((ref) {
  return TrendingCacheDao(ref.watch(appDatabaseProvider).executor, ref.watch(cacheMetaDaoProvider));
});

final githubTrendingDataSourceProvider = Provider<TrendingDataSource>((ref) {
  final tokenState = ref.watch(githubTokenControllerProvider);
  final gate = ref.watch(rateLimitGateProvider);
  final gateController = ref.watch(rateLimitGateProvider.notifier);
  return CachedTrendingDataSource(
    remote: GithubTrendingDataSource(dio: ref.watch(dioProvider), token: tokenState.token, snapshotHistory: ref.watch(repoSnapshotHistoryDaoProvider)),
    cache: ref.watch(trendingCacheDaoProvider),
    cacheScope: tokenState.cacheScope,
    now: ref.watch(trendingClockProvider),
    ttl: trendingGithubCacheTtl,
    isRateLimited: () => gate.isBlocked,
    onRateLimited: gateController.trigger,
  );
});

final trendingRepositoryProvider = Provider<TrendingRepository>((ref) {
  return TrendingRepositoryImpl(dataSource: ref.watch(trendingDataSourceProvider));
});

// 兼容旧测试/外部 override 的本地仓库实例。
final localTrendingRepositoryProvider = Provider<TrendingRepository>((ref) {
  return const LocalTrendingRepository();
});

final trendingDigestResultProvider = FutureProvider<DataResult<TrendingDigest>>((ref) {
  final query = ref.watch(trendingQueryProvider);
  return ref.watch(trendingRepositoryProvider).getDigest(query: query);
});

final trendingDigestProvider = FutureProvider<TrendingDigest>((ref) async {
  return (await ref.watch(trendingDigestResultProvider.future)).data;
});

final trendingFreshnessProvider = Provider<AsyncValue<DataFreshness>>((ref) {
  return ref.watch(trendingDigestResultProvider).whenData((result) => result.freshness);
});

// 顶部搜索框关键词。空字符串表示不过滤当前热榜结果。
final trendingSearchQueryProvider = StateProvider<String>((ref) => '');

// 应用本地搜索后的热榜摘要。
// 搜索只作用于当前已拉取/缓存结果,避免输入关键词触发 GitHub Search 请求。
final filteredTrendingDigestProvider = FutureProvider<TrendingDigest>((ref) async {
  final query = ref.watch(trendingSearchQueryProvider);
  final digest = await ref.watch(trendingDigestProvider.future);
  return filterTrendingDigest(digest, query);
});

TrendingDigest filterTrendingDigest(TrendingDigest digest, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) {
    return digest;
  }

  return TrendingDigest(
    trendingRepos: filterTrendingRepos(digest.trendingRepos, keyword),
    recentRepos: filterTrendingRepos(digest.recentRepos, keyword),
    languages: digest.languages,
    primaryTrend: digest.primaryTrend,
    secondaryTrend: digest.secondaryTrend,
    tertiaryTrend: digest.tertiaryTrend,
    topics: digest.topics,
  );
}

List<RepoEntity> filterTrendingRepos(List<RepoEntity> repos, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) {
    return repos;
  }

  return [
    for (final repo in repos)
      if (_repoSearchText(repo).contains(keyword)) repo
  ];
}

String _repoSearchText(RepoEntity repo) {
  return [repo.fullName, repo.description, repo.language].join(' ').toLowerCase();
}

final trendingQueryProvider = Provider<TrendingQuery>((ref) {
  final window = ref.watch(trendingWindowFilterProvider);
  final language = ref.watch(trendingLanguageFilterProvider);
  final board = ref.watch(trendingBoardFilterProvider);
  return TrendingQuery(window: TrendingWindow.fromValue(window), language: language, board: TrendingBoard.fromValue(board));
});

Future<void> refreshTrendingDigest(WidgetRef ref) async {
  final mode = ref.read(trendingDataSourceModeControllerProvider);
  if (mode == TrendingDataSourceMode.github) {
    await ref.read(trendingCacheDaoProvider).deleteSnapshot(ref.read(trendingQueryProvider), scope: ref.read(githubTokenControllerProvider).cacheScope);
  }
  ref.invalidate(trendingDigestProvider);
  ref.invalidate(trendingDigestResultProvider);
}

// 时间窗筛选:`today` / `week` / `month`。
final trendingWindowFilterProvider = StateProvider<String>((ref) => 'today');

// 榜单筛选:`all` / `agent` / `mcp` / `ai_coding` / `new_repos`。
final trendingBoardFilterProvider = StateProvider<String>((ref) => 'all');

// 语言筛选:`all` / `typescript` / `python` / `rust` …
final trendingLanguageFilterProvider = StateProvider<String>((ref) => 'all');
