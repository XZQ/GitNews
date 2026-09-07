import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/observed_repo_growth.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/storage/repo_snapshot_history_dao.dart';
import '../domain/trending_repository.dart';
import 'trending_data_source.dart';

/// GitHub snapshots plus dated local observations; Search itself has no Star delta.
class GithubTrendingDataSource implements TrendingDataSource {
  GithubTrendingDataSource({required Dio dio, String? token, DateTime Function()? now, RepoSnapshotHistoryDao? snapshotHistory})
    : _dio = dio,
      _token = token?.trim(),
      _now = now ?? DateTime.now,
      _snapshotHistory = snapshotHistory;

  final Dio _dio;
  final String? _token;
  final DateTime Function() _now;
  final RepoSnapshotHistoryDao? _snapshotHistory;

  static const int _perPage = 20;

  @override
  Future<TrendingDataSnapshot> fetchTrending(TrendingQuery query) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        ApiEndpointsConfig.githubSearchRepositoriesPath,
        queryParameters: <String, Object?>{'q': _buildSearchQuery(query), 'sort': 'stars', 'order': 'desc', 'per_page': _perPage},
        options: Options(headers: GitHubApiSupport.headers(token: _token)),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      final repos = await _withObservedHistory(_parseRepos(data, query), query);
      return TrendingDataSnapshot(
        trendingRepos: repos.take(12).toList(growable: false),
        recentRepos: repos.skip(12).take(8).toList(growable: false),
        languages: _buildLanguages(repos),
        primaryTrend: ObservedRepoGrowth.fromRepos(repos, days: _windowDuration(query.window).inDays, now: _now()).values,
        secondaryTrend: const [],
        tertiaryTrend: const [],
        topics: _buildTopics(data),
      );
    } on DioException catch (e) {
      throw GitHubApiSupport.toAppException(e, now: _now);
    } on FormatException catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    } on TypeError catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    }
  }

  String _buildSearchQuery(TrendingQuery query) {
    final cutoff = _now().toUtc().subtract(_windowDuration(query.window));
    final parts = <String>[
      'stars:>50',
      if (query.board == TrendingBoard.newRepos) 'created:>=${GitHubApiSupport.formatDate(cutoff)}' else 'pushed:>=${GitHubApiSupport.formatDate(cutoff)}',
      'archived:false',
      ..._boardSearchParts(query.board),
      if (query.hasLanguageFilter) 'language:${GitHubApiSupport.quoteSearchValue(query.language)}',
    ];
    return parts.join(' ');
  }

  List<String> _boardSearchParts(TrendingBoard board) {
    return switch (board) {
      TrendingBoard.all => const [],
      TrendingBoard.agent => const ['agent', 'in:name,description,readme'],
      TrendingBoard.mcp => const ['mcp', 'in:name,description,readme'],
      TrendingBoard.aiCoding => const ['coding', 'agent', 'in:name,description,readme'],
      TrendingBoard.newRepos => const [],
    };
  }

  // 窗口对应天数:today=1 天,week=7 天,month=30 天。
  Duration _windowDuration(TrendingWindow window) {
    return switch (window) {
      TrendingWindow.today => const Duration(days: 1),
      TrendingWindow.week => const Duration(days: 7),
      TrendingWindow.month => const Duration(days: 30),
    };
  }

  List<RepoEntity> _parseRepos(Map<String, Object?> data, TrendingQuery query) {
    final rawItems = data['items'];
    if (rawItems is! List<Object?>) {
      throw const FormatException('GitHub search response missing items');
    }
    return rawItems.map((raw) => _parseRepo(raw, query)).toList(growable: false);
  }

  RepoEntity _parseRepo(Object? raw, TrendingQuery query) {
    if (raw is! Map<String, Object?>) {
      throw const FormatException('GitHub repository item is not an object');
    }
    final fullName = GitHubJson.string(raw['full_name']);
    final language = GitHubJson.nullableString(raw['language']) ?? 'Unknown';
    final stars = GitHubJson.intValue(raw['stargazers_count']);
    final forks = GitHubJson.intValue(raw['forks_count']);
    return RepoEntity(
      fullName: fullName,
      description: GitHubJson.nullableString(raw['description']) ?? 'No description',
      language: language,
      starCount: stars,
      starDelta: 0,
      starDeltaDays: _windowDuration(query.window).inDays,
      forkCount: forks,
      accentArgb: GitHubApiSupport.languageColor(language),
      valueBasis: MetricBasis.observed,
      trendBasis: MetricBasis.unavailable,
      trend: const [],
    );
  }

  Future<List<RepoEntity>> _withObservedHistory(List<RepoEntity> repos, TrendingQuery query) async {
    final history = _snapshotHistory;
    if (history == null || repos.isEmpty) {
      return repos;
    }

    final capturedAt = _now();
    return Future.wait([for (final repo in repos) _withRepoHistory(repo, query.window, history, capturedAt)]);
  }

  Future<RepoEntity> _withRepoHistory(RepoEntity repo, TrendingWindow window, RepoSnapshotHistoryDao history, DateTime capturedAt) async {
    await history.record(fullName: repo.fullName, stars: repo.starCount, forks: repo.forkCount, capturedAt: capturedAt);
    final trend = await history.starTrend(repo.fullName);
    if (trend == null) {
      return repo;
    }

    final observed = repo.copyWith(trend: trend.values, trendDates: trend.dates, trendBasis: trend.basis);
    final growth = ObservedRepoGrowth.fromRepos([observed], days: _windowDuration(window).inDays, now: capturedAt);
    return observed.copyWith(starDelta: growth.netChange ?? 0, starDeltaDays: _windowDuration(window).inDays);
  }

  List<LanguageEntity> _buildLanguages(List<RepoEntity> repos) {
    if (repos.isEmpty) {
      return const [];
    }
    final counts = <String, int>{};
    for (final repo in repos) {
      counts.update(repo.language, (value) => value + 1, ifAbsent: () => 1);
    }
    final total = repos.length;
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map((entry) {
          final percent = entry.value / total * 100;
          return LanguageEntity(name: entry.key, percent: percent, delta: 0, accentArgb: GitHubApiSupport.languageColor(entry.key), basis: MetricBasis.estimated);
        })
        .toList(growable: false);
  }

  /* 聚合 GitHub Search 返回仓库的 repository topics。 */
  List<TrendingTopicEntity> _buildTopics(Map<String, Object?> data) {
    final rawItems = data['items'];
    if (rawItems is! List<Object?>) {
      return const [];
    }
    final counts = <String, int>{};
    final stars = <String, int>{};
    for (final raw in rawItems) {
      if (raw is! Map<String, Object?>) {
        continue;
      }
      final repoStars = GitHubJson.intValue(raw['stargazers_count']);
      final rawTopics = raw['topics'];
      if (rawTopics is! List<Object?>) {
        continue;
      }
      for (final rawTopic in rawTopics) {
        if (rawTopic is! String) {
          continue;
        }
        final topic = rawTopic.trim().toLowerCase();
        if (topic.isEmpty) {
          continue;
        }
        counts.update(topic, (value) => value + 1, ifAbsent: () => 1);
        stars.update(topic, (value) => value + repoStars, ifAbsent: () => repoStars);
      }
    }
    final names = counts.keys.toList()
      ..sort((left, right) {
        final countOrder = counts[right]!.compareTo(counts[left]!);
        if (countOrder != 0) {
          return countOrder;
        }
        final starOrder = stars[right]!.compareTo(stars[left]!);
        return starOrder != 0 ? starOrder : left.compareTo(right);
      });
    return [for (final name in names.take(10)) TrendingTopicEntity(name: name, repoCount: counts[name]!, starCount: stars[name]!, basis: MetricBasis.observed)];
  }
}
