import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import '../../../core/storage/repo_snapshot_history_dao.dart';
import '../domain/trending_repository.dart';
import 'trending_data_source.dart';

/* 
*GitHub REST Search API 数据源。
*GitHub Search 不直接返回 Star 增量,这里的 [RepoEntity.starDelta] 暂用
*search score + stars/forks 生成动量代理值。真实本周趋势需要接入本地快照
*或 GH Archive 后再替换为真实增量。
*/
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
        primaryTrend: _buildTrend(repos, 1.0),
        secondaryTrend: _buildTrend(repos, 0.78),
        tertiaryTrend: _buildTrend(repos, 0.56),
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
      if (query.hasLanguageFilter) 'language:${GitHubApiSupport.quoteSearchValue(query.language)}'
    ];
    return parts.join(' ');
  }

  List<String> _boardSearchParts(TrendingBoard board) {
    return switch (board) {
      TrendingBoard.all => const [],
      TrendingBoard.agent => const ['agent', 'in:name,description,readme'],
      TrendingBoard.mcp => const ['mcp', 'in:name,description,readme'],
      TrendingBoard.aiCoding => const ['coding', 'agent', 'in:name,description,readme'],
      TrendingBoard.newRepos => const []
    };
  }

  // 窗口对应天数:today=1 天,week=7 天,month=30 天。
  Duration _windowDuration(TrendingWindow window) {
    return switch (window) { TrendingWindow.today => const Duration(days: 1), TrendingWindow.week => const Duration(days: 7), TrendingWindow.month => const Duration(days: 30) };
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
    final score = GitHubJson.doubleValue(raw['score']);
    return RepoEntity(
      fullName: fullName,
      description: GitHubJson.nullableString(raw['description']) ?? 'No description',
      language: language,
      starCount: stars,
      starDelta: _momentumScore(stars: stars, forks: forks, score: score, window: query.window),
      forkCount: forks,
      accentArgb: GitHubApiSupport.languageColor(language),
      valueBasis: MetricBasis.observed,
      trendBasis: MetricBasis.estimated,
      trend: _repoTrend(stars, query.window),
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

    final values = _recentObservedValues(trend.values, window);
    return repo.copyWith(starDelta: _observedDelta(values, fallback: repo.starDelta), trend: values, trendBasis: trend.basis);
  }

  List<double> _recentObservedValues(List<double> values, TrendingWindow window) {
    final maxPoints = switch (window) { TrendingWindow.today => 2, TrendingWindow.week => 7, TrendingWindow.month => 30 };
    if (values.length <= maxPoints) {
      return values;
    }
    return values.sublist(values.length - maxPoints);
  }

  int _observedDelta(List<double> values, {required int fallback}) {
    if (values.length < 2) {
      return fallback;
    }
    final delta = values.last - values.first;
    return delta.round().clamp(0, 999999);
  }

  int _momentumScore({required int stars, required int forks, required double score, required TrendingWindow window}) {
    final divisor = switch (window) { TrendingWindow.today => 160, TrendingWindow.week => 90, TrendingWindow.month => 52 };
    final value = (stars / divisor) + (forks / 24) + score;
    return value.clamp(1, 9999).round();
  }

  List<double> _repoTrend(int stars, TrendingWindow window) {
    final base = stars / 120;
    final scale = switch (window) { TrendingWindow.today => 0.8, TrendingWindow.week => 1.0, TrendingWindow.month => 1.22 };
    return List<double>.generate(7, (index) {
      return (base * scale * (0.74 + index * 0.055)).roundToDouble();
    });
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
    return entries.map((entry) {
      final percent = entry.value / total * 100;
      return LanguageEntity(name: entry.key, percent: percent, delta: 0, accentArgb: GitHubApiSupport.languageColor(entry.key), basis: MetricBasis.estimated);
    }).toList(growable: false);
  }

  List<double> _buildTrend(List<RepoEntity> repos, double scale) {
    if (repos.isEmpty) {
      return const [];
    }
    final observed = [
      for (final repo in repos)
        if (repo.trendBasis == MetricBasis.observed && repo.trend != null && repo.trend!.length >= 2) repo.trend!
    ];
    if (observed.isNotEmpty) {
      final pointCount = observed.fold<int>(observed.first.length, (count, trend) => trend.length < count ? trend.length : count);
      return List<double>.generate(pointCount, (index) {
        final sum = observed.fold<double>(0, (total, trend) {
          return total + trend[trend.length - pointCount + index];
        });
        return (sum * scale).roundToDouble();
      });
    }
    final total = repos.fold<int>(0, (sum, repo) => sum + repo.starDelta);
    return List<double>.generate(7, (index) {
      final factor = 0.68 + index * 0.06;
      return (total * scale * factor).roundToDouble();
    });
  }
}
