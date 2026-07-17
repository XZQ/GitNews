import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/storage/cache_meta_dao.dart';
import '../domain/trending_repository.dart';
import 'trending_data_source.dart';

/* 
*GitHub 热榜快照缓存 DAO。
*表结构由 `LocalDatabase` 创建;TTL 元信息复用全局 [CacheMetaDao]。
*/
class TrendingCacheDao {
  TrendingCacheDao(this._db, this._meta);

  final DatabaseExecutor _db;
  final CacheMetaDao _meta;

  static const String _table = 'trending_snapshot_cache';

  /* 
  *cache_key 构造规则:模块名:数据源:时间窗:榜单:语言。
  */
  static String cacheKey(TrendingQuery query, {String scope = 'anonymous'}) {
    final language = query.hasLanguageFilter ? query.language.trim().toLowerCase() : 'all';
    return 'trending:github:$scope:window=${query.window.name}:board=${query.board.value}:language=$language';
  }

  Future<TrendingDataSnapshot?> readSnapshot(TrendingQuery query, {String scope = 'anonymous'}) async {
    try {
      final rows = await _db.query(
        _table,
        columns: ['payload_json'],
        where: 'cache_key = ?',
        whereArgs: [cacheKey(query, scope: scope)],
        limit: 1,
      );
      if (rows.isEmpty) {
        return null;
      }
      final payload = rows.first['payload_json'] as String;
      final json = jsonDecode(payload) as Map<String, Object?>;
      return _snapshotFromJson(json);
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'trending.readSnapshot'},
      );
    }
  }

  Future<void> upsertSnapshot({
    required TrendingQuery query,
    String scope = 'anonymous',
    required TrendingDataSnapshot snapshot,
    required DateTime now,
  }) async {
    final key = cacheKey(query, scope: scope);
    final cachedAt = now.millisecondsSinceEpoch;
    try {
      await _db.insert(
        _table,
        {'cache_key': key, 'payload_json': jsonEncode(_snapshotToJson(snapshot)), 'cached_at': cachedAt},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _meta.upsert(key, now);
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'trending.upsertSnapshot'},
      );
    }
  }

  Future<bool> isFresh({
    required TrendingQuery query,
    String scope = 'anonymous',
    required Duration ttl,
    required DateTime now,
  }) async {
    final last = await _meta.lastFetched(cacheKey(query, scope: scope));
    if (last == null) {
      return false;
    }
    return now.difference(last) < ttl;
  }

  Future<void> clear() async {
    try {
      await _db.delete(_table);
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'trending.clear'},
      );
    }
  }

  Future<void> deleteSnapshot(TrendingQuery query, {String scope = 'anonymous'}) async {
    final key = cacheKey(query, scope: scope);
    try {
      await _db.delete(_table, where: 'cache_key = ?', whereArgs: [key]);
      await _meta.delete(key);
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'trending.deleteSnapshot'},
      );
    }
  }

  Map<String, Object?> _snapshotToJson(TrendingDataSnapshot snapshot) {
    return {
      'trendingRepos': snapshot.trendingRepos.map(_repoToJson).toList(),
      'recentRepos': snapshot.recentRepos.map(_repoToJson).toList(),
      'languages': snapshot.languages.map(_languageToJson).toList(),
      'primaryTrend': snapshot.primaryTrend,
      'secondaryTrend': snapshot.secondaryTrend,
      'tertiaryTrend': snapshot.tertiaryTrend,
      'topics': snapshot.topics.map(_topicToJson).toList(),
    };
  }

  TrendingDataSnapshot _snapshotFromJson(Map<String, Object?> json) {
    return TrendingDataSnapshot(
      trendingRepos: _list(json['trendingRepos']).map(_repoFromJson).toList(),
      recentRepos: _list(json['recentRepos']).map(_repoFromJson).toList(),
      languages: _list(json['languages']).map(_languageFromJson).toList(),
      primaryTrend: _doubleList(json['primaryTrend']),
      secondaryTrend: _doubleList(json['secondaryTrend']),
      tertiaryTrend: _doubleList(json['tertiaryTrend']),
      topics: json['topics'] == null ? const [] : _list(json['topics']).map(_topicFromJson).toList(),
    );
  }

  /* 把热榜主题统计编码为缓存 JSON。 */
  Map<String, Object?> _topicToJson(TrendingTopicEntity topic) {
    return {
      'name': topic.name,
      'repoCount': topic.repoCount,
      'starCount': topic.starCount,
      'basis': topic.basis.name,
    };
  }

  /* 从缓存 JSON 恢复热榜主题统计。 */
  TrendingTopicEntity _topicFromJson(Object? raw) {
    final json = _map(raw);
    return TrendingTopicEntity(
      name: _string(json['name']),
      repoCount: _int(json['repoCount']),
      starCount: _int(json['starCount']),
      basis: _basisFromJson(json, 'basis', 'provenance'),
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
      'valueBasis': repo.valueBasis.name,
      'trendBasis': repo.trendBasis.name,
      'trend': repo.trend
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
      valueBasis: _basisFromJson(json, 'valueBasis', 'valueProvenance'),
      trendBasis: _basisFromJson(json, 'trendBasis', 'trendProvenance'),
      trend: json['trend'] == null ? null : _doubleList(json['trend']),
    );
  }

  Map<String, Object?> _languageToJson(LanguageEntity language) {
    return {'name': language.name, 'percent': language.percent, 'delta': language.delta, 'accentArgb': language.accentArgb, 'basis': language.basis.name};
  }

  LanguageEntity _languageFromJson(Object? raw) {
    final json = _map(raw);
    return LanguageEntity(
      name: _string(json['name']),
      percent: _double(json['percent']),
      delta: _double(json['delta']),
      accentArgb: _int(json['accentArgb']),
      basis: _basisFromJson(json, 'basis', 'provenance'),
    );
  }

  List<Object?> _list(Object? raw) {
    if (raw is List<Object?>) {
      return raw;
    }
    throw const FormatException('Expected list');
  }

  Map<String, Object?> _map(Object? raw) {
    if (raw is Map<String, Object?>) {
      return raw;
    }
    throw const FormatException('Expected object');
  }

  List<double> _doubleList(Object? raw) {
    return _list(raw).map(_double).toList(growable: false);
  }

  String _string(Object? raw) {
    if (raw is String) {
      return raw;
    }
    throw const FormatException('Expected string');
  }

  int _int(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is double) {
      return raw.round();
    }
    throw const FormatException('Expected int');
  }

  double _double(Object? raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    throw const FormatException('Expected double');
  }

  MetricBasis _basisFromJson(Map<String, Object?> json, String key, String legacyKey) {
    final name = json[key] as String?;
    return name == null ? MetricBasis.fromLegacyName(json[legacyKey] as String?) : MetricBasis.fromName(name);
  }
}
