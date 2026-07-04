import 'package:dio/dio.dart';

import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/json_snapshot_cache_dao.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/entities.dart';
import '../domain/monitor_repository.dart';
import 'local_monitor_repository.dart';

const Duration monitorRemoteCacheTtl = Duration(minutes: 5);

/// 基于 GitHub REST API 的仓库监控数据仓库。
class GithubMonitorRepository implements MonitorRepository {
  const GithubMonitorRepository({
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    String? token,
    DateTime Function()? now,
    MonitorRepository fallback = const LocalMonitorRepository(),
  })  : _dio = dio,
        _cache = cache,
        _token = token,
        _now = now ?? DateTime.now,
        _fallback = fallback;

  final Dio _dio;
  final JsonSnapshotCacheDao _cache;
  final String? _token;
  final DateTime Function() _now;
  final MonitorRepository _fallback;

  static const String _cacheKey = 'monitor:github:default:v1';
  static const List<String> _defaultRepos = [
    'openai/codex',
    'modelcontextprotocol/servers',
    'langchain-ai/langgraph',
    'anthropics/claude-code',
    'ollama/ollama',
    'vllm-project/vllm',
  ];

  @override
  Future<MonitorDigest> getDigest() async {
    final now = _now();
    final cached = await _readCached();
    if (cached != null &&
        await _cache.isFresh(
          key: _cacheKey,
          ttl: monitorRemoteCacheTtl,
          now: now,
        )) {
      return cached;
    }

    try {
      final digest = await _fetchDigest(now);
      await _cache.upsert(
        key: _cacheKey,
        payload: _digestToJson(digest),
        now: now,
      );
      return digest;
    } catch (e) {
      AppLogger.warn(
        'githubMonitorFallback',
        meta: {'error': e.runtimeType.toString()},
      );
      return cached ?? _fallback.getDigest();
    }
  }

  Future<MonitorDigest?> _readCached() async {
    final json = await _cache.read(_cacheKey);
    if (json == null) return null;
    try {
      return _digestFromJson(json);
    } catch (e) {
      AppLogger.warn(
        'githubMonitorCacheParse',
        meta: {'error': e.runtimeType.toString()},
      );
      return null;
    }
  }

  Future<MonitorDigest> _fetchDigest(DateTime now) async {
    final responses = await Future.wait([
      for (final repo in _defaultRepos) _fetchRepo(repo, now),
    ]);
    final repos = responses.map((item) => item.repo).toList(growable: false);
    final alerts = responses
        .expand((item) => _alertsFor(item, now))
        .take(12)
        .toList(growable: false);
    return MonitorDigest(
      monitoredRepos: repos,
      alerts: alerts,
      stats: MonitorStats(
        monitoredCount: repos.length,
        monitoredDelta: 0,
        unreadAlertCount: alerts.length,
        unreadAlertDelta: 0,
        triggeredTodayCount: alerts
            .where((alert) => alert.time == '刚刚' || alert.time.contains('小时'))
            .length,
        triggeredTodayDelta: 0,
        totalAlertCount: alerts.length,
        totalAlertDelta: 0,
      ),
    );
  }

  Future<_RemoteRepoItem> _fetchRepo(String fullName, DateTime now) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        '/repos/$fullName',
        options: Options(headers: _headers()),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(kind: AppExceptionKind.parse);
      }
      return _parseRepo(data, now);
    } on DioException catch (e) {
      throw e.toAppException();
    } on FormatException catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    } on TypeError catch (e, st) {
      throw AppException(kind: AppExceptionKind.parse, cause: e, stack: st);
    }
  }

  Map<String, Object?> _headers() {
    final token = _token?.trim();
    return {
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'GitHubNews/0.1 (Flutter)',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  _RemoteRepoItem _parseRepo(Map<String, Object?> json, DateTime now) {
    final fullName = _string(json['full_name']);
    final language = _nullableString(json['language']) ?? 'Unknown';
    final pushedAt = DateTime.tryParse(_string(json['pushed_at']))?.toUtc();
    final stars = _int(json['stargazers_count']);
    final forks = _int(json['forks_count']);
    final openIssues = _int(json['open_issues_count']);
    return _RemoteRepoItem(
      repo: RepoEntity(
        fullName: fullName,
        description: _nullableString(json['description']) ?? 'No description',
        language: language,
        starCount: stars,
        starDelta: _activityScore(
          stars: stars,
          forks: forks,
          openIssues: openIssues,
          pushedAt: pushedAt,
          now: now,
        ),
        forkCount: forks,
        accentArgb: _languageColor(language),
        trend: _repoTrend(stars),
      ),
      openIssues: openIssues,
      pushedAt: pushedAt,
    );
  }

  List<AlertEntity> _alertsFor(_RemoteRepoItem item, DateTime now) {
    final alerts = <AlertEntity>[
      AlertEntity(
        repoFullName: item.repo.fullName,
        metric: 'Star 总量',
        value: _compactNumber(item.repo.starCount),
        time: _relativeTime(item.pushedAt, now),
        severity: AlertSeverity.success,
      ),
      AlertEntity(
        repoFullName: item.repo.fullName,
        metric: 'Open Issues',
        value: item.openIssues.toString(),
        time: _relativeTime(item.pushedAt, now),
        severity:
            item.openIssues > 500 ? AlertSeverity.warning : AlertSeverity.info,
      ),
    ];
    return alerts;
  }

  int _activityScore({
    required int stars,
    required int forks,
    required int openIssues,
    required DateTime? pushedAt,
    required DateTime now,
  }) {
    final pushedBoost = pushedAt == null
        ? 1
        : (30 - now.toUtc().difference(pushedAt).inDays).clamp(1, 30);
    return ((stars / 180) + (forks / 40) + (openIssues / 12) + pushedBoost)
        .round()
        .clamp(1, 9999);
  }

  List<double> _repoTrend(int stars) {
    final base = stars / 160;
    return List<double>.generate(
      7,
      (index) => (base * (0.72 + index * 0.06)).roundToDouble(),
    );
  }

  String _relativeTime(DateTime? date, DateTime now) {
    if (date == null) return '未知';
    final diff = now.toUtc().difference(date.toUtc());
    if (diff.inMinutes < 10) return '刚刚';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }

  String _compactNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  Map<String, Object?> _digestToJson(MonitorDigest digest) {
    return {
      'repos': digest.monitoredRepos.map(_repoToJson).toList(),
      'alerts': digest.alerts.map(_alertToJson).toList(),
      'stats': _statsToJson(digest.stats),
    };
  }

  MonitorDigest _digestFromJson(Map<String, Object?> json) {
    return MonitorDigest(
      monitoredRepos: _list(json['repos']).map(_repoFromJson).toList(),
      alerts: _list(json['alerts']).map(_alertFromJson).toList(),
      stats: _statsFromJson(_map(json['stats'])),
    );
  }

  Map<String, Object?> _repoToJson(RepoEntity repo) {
    return {
      'fullName': repo.fullName,
      'description': repo.description,
      'language': repo.language,
      'starCount': repo.starCount,
      'starDelta': repo.starDelta,
      'forkCount': repo.forkCount,
      'accentArgb': repo.accentArgb,
      'trend': repo.trend,
    };
  }

  RepoEntity _repoFromJson(Object? raw) {
    final json = _map(raw);
    return RepoEntity(
      fullName: _string(json['fullName']),
      description: _string(json['description']),
      language: _string(json['language']),
      starCount: _int(json['starCount']),
      starDelta: _int(json['starDelta']),
      forkCount: _int(json['forkCount']),
      accentArgb: _int(json['accentArgb']),
      trend: json['trend'] == null ? null : _doubleList(json['trend']),
    );
  }

  Map<String, Object?> _alertToJson(AlertEntity alert) {
    return {
      'repoFullName': alert.repoFullName,
      'metric': alert.metric,
      'value': alert.value,
      'time': alert.time,
      'severity': alert.severity.name,
    };
  }

  AlertEntity _alertFromJson(Object? raw) {
    final json = _map(raw);
    return AlertEntity(
      repoFullName: _string(json['repoFullName']),
      metric: _string(json['metric']),
      value: _string(json['value']),
      time: _string(json['time']),
      severity: AlertSeverity.values.firstWhere(
        (severity) => severity.name == _string(json['severity']),
        orElse: () => AlertSeverity.info,
      ),
    );
  }

  Map<String, Object?> _statsToJson(MonitorStats stats) {
    return {
      'monitoredCount': stats.monitoredCount,
      'monitoredDelta': stats.monitoredDelta,
      'unreadAlertCount': stats.unreadAlertCount,
      'unreadAlertDelta': stats.unreadAlertDelta,
      'triggeredTodayCount': stats.triggeredTodayCount,
      'triggeredTodayDelta': stats.triggeredTodayDelta,
      'totalAlertCount': stats.totalAlertCount,
      'totalAlertDelta': stats.totalAlertDelta,
    };
  }

  MonitorStats _statsFromJson(Map<String, Object?> json) {
    return MonitorStats(
      monitoredCount: _int(json['monitoredCount']),
      monitoredDelta: _int(json['monitoredDelta']),
      unreadAlertCount: _int(json['unreadAlertCount']),
      unreadAlertDelta: _int(json['unreadAlertDelta']),
      triggeredTodayCount: _int(json['triggeredTodayCount']),
      triggeredTodayDelta: _int(json['triggeredTodayDelta']),
      totalAlertCount: _int(json['totalAlertCount']),
      totalAlertDelta: _int(json['totalAlertDelta']),
    );
  }

  List<Object?> _list(Object? raw) {
    if (raw is List<Object?>) return raw;
    throw const FormatException('Expected list');
  }

  Map<String, Object?> _map(Object? raw) {
    if (raw is Map<String, Object?>) return raw;
    throw const FormatException('Expected object');
  }

  List<double> _doubleList(Object? raw) {
    return _list(raw).map(_double).toList(growable: false);
  }

  String _string(Object? raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    throw const FormatException('Expected string');
  }

  String? _nullableString(Object? raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    throw const FormatException('Expected nullable string');
  }

  int _int(Object? raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    throw const FormatException('Expected int');
  }

  double _double(Object? raw) {
    if (raw is num) return raw.toDouble();
    throw const FormatException('Expected double');
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
      _ => 0xFF64748B,
    };
  }
}

class _RemoteRepoItem {
  const _RemoteRepoItem({
    required this.repo,
    required this.openIssues,
    required this.pushedAt,
  });

  final RepoEntity repo;
  final int openIssues;
  final DateTime? pushedAt;
}
