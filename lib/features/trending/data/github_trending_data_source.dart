import 'package:dio/dio.dart';

import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/trending_repository.dart';
import 'trending_data_source.dart';

/// GitHub REST Search API 数据源。
///
/// GitHub Search 不直接返回 Star 增量,这里的 [RepoEntity.starDelta] 暂用
/// search score + stars/forks 生成动量代理值。真实本周趋势需要接入本地快照
/// 或 GH Archive 后再替换为真实增量。
class GithubTrendingDataSource implements TrendingDataSource {
  GithubTrendingDataSource({
    required Dio dio,
    String? token,
    DateTime Function()? now,
  })  : _dio = dio,
        _token = token?.trim(),
        _now = now ?? DateTime.now;

  final Dio _dio;
  final String? _token;
  final DateTime Function() _now;

  static const int _perPage = 20;
  static const Map<String, Object?> _headers = {
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'User-Agent': 'GitHubNews/0.1 (Flutter)',
  };

  @override
  Future<TrendingDataSnapshot> fetchTrending(TrendingQuery query) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        '/search/repositories',
        queryParameters: <String, Object?>{
          'q': _buildSearchQuery(query),
          'sort': 'stars',
          'order': 'desc',
          'per_page': _perPage,
        },
        options: Options(headers: _headersWithAuth()),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      final repos = _parseRepos(data, query);
      return TrendingDataSnapshot(
        trendingRepos: repos.take(12).toList(growable: false),
        recentRepos: repos.skip(12).take(8).toList(growable: false),
        languages: _buildLanguages(repos),
        primaryTrend: _buildTrend(repos, 1.0),
        secondaryTrend: _buildTrend(repos, 0.78),
        tertiaryTrend: _buildTrend(repos, 0.56),
      );
    } on DioException catch (e) {
      throw _toAppException(e);
    } on FormatException catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    } on TypeError catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    }
  }

  Map<String, Object?> _headersWithAuth() {
    final token = _token;
    return {
      ..._headers,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  String _buildSearchQuery(TrendingQuery query) {
    final cutoff = _now().toUtc().subtract(_windowDuration(query.window));
    final parts = <String>[
      'stars:>50',
      if (query.board == TrendingBoard.newRepos)
        'created:>=${_formatDate(cutoff)}'
      else
        'pushed:>=${_formatDate(cutoff)}',
      'archived:false',
      ..._boardSearchParts(query.board),
      if (query.hasLanguageFilter) 'language:${_quoteIfNeeded(query.language)}',
    ];
    return parts.join(' ');
  }

  List<String> _boardSearchParts(TrendingBoard board) {
    return switch (board) {
      TrendingBoard.all => const [],
      TrendingBoard.agent => const [
          'agent',
          'in:name,description,readme',
        ],
      TrendingBoard.mcp => const [
          'mcp',
          'in:name,description,readme',
        ],
      TrendingBoard.aiCoding => const [
          'coding',
          'agent',
          'in:name,description,readme',
        ],
      TrendingBoard.newRepos => const [],
    };
  }

  Duration _windowDuration(TrendingWindow window) {
    return switch (window) {
      TrendingWindow.today => const Duration(days: 1),
      TrendingWindow.week => const Duration(days: 7),
      TrendingWindow.month => const Duration(days: 30),
    };
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _quoteIfNeeded(String value) {
    final trimmed = value.trim();
    if (!trimmed.contains(' ')) return trimmed;
    return '"$trimmed"';
  }

  List<RepoEntity> _parseRepos(
    Map<String, Object?> data,
    TrendingQuery query,
  ) {
    final rawItems = data['items'];
    if (rawItems is! List<Object?>) {
      throw const FormatException('GitHub search response missing items');
    }
    return rawItems
        .map((raw) => _parseRepo(raw, query))
        .toList(growable: false);
  }

  RepoEntity _parseRepo(Object? raw, TrendingQuery query) {
    if (raw is! Map<String, Object?>) {
      throw const FormatException('GitHub repository item is not an object');
    }
    final fullName = _string(raw['full_name']);
    final language = _nullableString(raw['language']) ?? 'Unknown';
    final stars = _int(raw['stargazers_count']);
    final forks = _int(raw['forks_count']);
    final score = _double(raw['score']);
    return RepoEntity(
      fullName: fullName,
      description: _nullableString(raw['description']) ?? 'No description',
      language: language,
      starCount: stars,
      starDelta: _momentumScore(
        stars: stars,
        forks: forks,
        score: score,
        window: query.window,
      ),
      forkCount: forks,
      accentArgb: _languageColor(language),
      trend: _repoTrend(stars, query.window),
    );
  }

  String _string(Object? value) {
    if (value is String && value.isNotEmpty) return value;
    throw const FormatException('Expected non-empty string');
  }

  String? _nullableString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    throw const FormatException('Expected nullable string');
  }

  int _int(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    throw const FormatException('Expected integer');
  }

  double _double(Object? value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  int _momentumScore({
    required int stars,
    required int forks,
    required double score,
    required TrendingWindow window,
  }) {
    final divisor = switch (window) {
      TrendingWindow.today => 160,
      TrendingWindow.week => 90,
      TrendingWindow.month => 52,
    };
    final value = (stars / divisor) + (forks / 24) + score;
    return value.clamp(1, 9999).round();
  }

  List<double> _repoTrend(int stars, TrendingWindow window) {
    final base = stars / 120;
    final scale = switch (window) {
      TrendingWindow.today => 0.8,
      TrendingWindow.week => 1.0,
      TrendingWindow.month => 1.22,
    };
    return List<double>.generate(7, (index) {
      return (base * scale * (0.74 + index * 0.055)).roundToDouble();
    });
  }

  List<LanguageEntity> _buildLanguages(List<RepoEntity> repos) {
    if (repos.isEmpty) return const [];
    final counts = <String, int>{};
    for (final repo in repos) {
      counts.update(repo.language, (value) => value + 1, ifAbsent: () => 1);
    }
    final total = repos.length;
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((entry) {
      final percent = entry.value / total * 100;
      return LanguageEntity(
        name: entry.key,
        percent: percent,
        delta: 0,
        accentArgb: _languageColor(entry.key),
      );
    }).toList(growable: false);
  }

  List<double> _buildTrend(List<RepoEntity> repos, double scale) {
    if (repos.isEmpty) return const [];
    final total = repos.fold<int>(0, (sum, repo) => sum + repo.starDelta);
    return List<double>.generate(7, (index) {
      final factor = 0.68 + index * 0.06;
      return (total * scale * factor).roundToDouble();
    });
  }

  int _languageColor(String language) {
    return switch (language.toLowerCase()) {
      'typescript' => 0xFF3178C6,
      'javascript' => 0xFFF1E05A,
      'python' => 0xFF3572A5,
      'rust' => 0xFFDEA584,
      'go' => 0xFF00ADD8,
      'dart' => 0xFF00B4AB,
      'kotlin' => 0xFFA97BFF,
      'swift' => 0xFFFA7343,
      'java' => 0xFFB07219,
      'c++' => 0xFFF34B7D,
      'c#' => 0xFF178600,
      _ => 0xFF64748B,
    };
  }

  AppException _toAppException(DioException e) {
    final response = e.response;
    final statusCode = response?.statusCode ?? 0;
    final isGitHubRateLimit = statusCode == 403 &&
        response?.headers.value('x-ratelimit-remaining') == '0';
    if (isGitHubRateLimit) {
      final reset = int.tryParse(
        response?.headers.value('x-ratelimit-reset') ?? '',
      );
      final retryAfter = reset == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(reset * 1000)
              .difference(_now())
              .inSeconds
              .clamp(0, 3600);
      return AppException(
        kind: AppExceptionKind.rateLimit,
        cause: e,
        meta: {'retryAfter': retryAfter},
      );
    }
    return e.toAppException();
  }
}
