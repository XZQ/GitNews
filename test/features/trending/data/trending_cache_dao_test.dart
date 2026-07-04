import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/features/trending/data/cached_trending_data_source.dart';
import 'package:github_news/features/trending/data/trending_cache_dao.dart';
import 'package:github_news/features/trending/data/trending_data_source.dart';
import 'package:github_news/features/trending/domain/trending_repository.dart';

class _FakeRemoteTrendingDataSource implements TrendingDataSource {
  _FakeRemoteTrendingDataSource(this.snapshot);

  TrendingDataSnapshot snapshot;
  Object? error;
  int calls = 0;

  @override
  Future<TrendingDataSnapshot> fetchTrending(TrendingQuery query) async {
    calls++;
    final e = error;
    if (e != null) throw e;
    return snapshot;
  }
}

void main() {
  group('TrendingCacheDao', () {
    late LocalDatabase db;
    late TrendingCacheDao dao;

    setUp(() async {
      db = await LocalDatabase.openInMemory();
      dao = TrendingCacheDao(db.executor, CacheMetaDao(db.executor));
    });

    tearDown(() async => db.close());

    test('readSnapshot should return null when cache is empty', () async {
      expect(await dao.readSnapshot(const TrendingQuery()), isNull);
    });

    test('upsertSnapshot should persist snapshot and meta', () async {
      final now = DateTime.utc(2026, 7, 4, 10);
      await dao.upsertSnapshot(
        query: const TrendingQuery(language: 'Rust'),
        snapshot: _snapshot('rust-lang/rust'),
        now: now,
      );

      final cached = await dao.readSnapshot(
        const TrendingQuery(language: 'Rust'),
      );

      expect(cached, isNotNull);
      expect(cached?.trendingRepos.first.fullName, 'rust-lang/rust');
      expect(
        await dao.isFresh(
          query: const TrendingQuery(language: 'Rust'),
          ttl: const Duration(minutes: 30),
          now: now.add(const Duration(minutes: 10)),
        ),
        isTrue,
      );
    });

    test('isFresh should be false when TTL expired', () async {
      final now = DateTime.utc(2026, 7, 4, 10);
      await dao.upsertSnapshot(
        query: const TrendingQuery(),
        snapshot: _snapshot('openai/codex'),
        now: now,
      );

      expect(
        await dao.isFresh(
          query: const TrendingQuery(),
          ttl: const Duration(minutes: 30),
          now: now.add(const Duration(minutes: 31)),
        ),
        isFalse,
      );
    });

    test('clear should remove trending snapshots', () async {
      await dao.upsertSnapshot(
        query: const TrendingQuery(),
        snapshot: _snapshot('openai/codex'),
        now: DateTime.utc(2026, 7, 4, 10),
      );

      await dao.clear();

      expect(await dao.readSnapshot(const TrendingQuery()), isNull);
    });

    test('deleteSnapshot should remove only the matching query and scope',
        () async {
      const python = TrendingQuery(language: 'Python');
      const rust = TrendingQuery(language: 'Rust');
      final now = DateTime.utc(2026, 7, 4, 10);
      await dao.upsertSnapshot(
        query: python,
        snapshot: _snapshot('python/repo'),
        now: now,
      );
      await dao.upsertSnapshot(
        query: rust,
        snapshot: _snapshot('rust/repo'),
        now: now,
      );
      await dao.upsertSnapshot(
        query: python,
        scope: 'token_1',
        snapshot: _snapshot('token/repo'),
        now: now,
      );

      await dao.deleteSnapshot(python);

      expect(await dao.readSnapshot(python), isNull);
      expect(
        (await dao.readSnapshot(rust))?.trendingRepos.first.fullName,
        'rust/repo',
      );
      expect(
        (await dao.readSnapshot(python, scope: 'token_1'))
            ?.trendingRepos
            .first
            .fullName,
        'token/repo',
      );
      expect(
        await dao.isFresh(
          query: python,
          ttl: const Duration(minutes: 30),
          now: now.add(const Duration(minutes: 1)),
        ),
        isFalse,
      );
    });

    test('cache scope should isolate anonymous and token snapshots', () async {
      const query = TrendingQuery(language: 'Python');
      await dao.upsertSnapshot(
        query: query,
        snapshot: _snapshot('anonymous/repo'),
        now: DateTime.utc(2026, 7, 4, 10),
      );
      await dao.upsertSnapshot(
        query: query,
        scope: 'token_1',
        snapshot: _snapshot('token/repo'),
        now: DateTime.utc(2026, 7, 4, 10),
      );

      final anonymous = await dao.readSnapshot(query);
      final token = await dao.readSnapshot(query, scope: 'token_1');

      expect(anonymous?.trendingRepos.first.fullName, 'anonymous/repo');
      expect(token?.trendingRepos.first.fullName, 'token/repo');
    });
  });

  group('CachedTrendingDataSource', () {
    late LocalDatabase db;
    late TrendingCacheDao dao;
    late DateTime now;

    setUp(() async {
      db = await LocalDatabase.openInMemory();
      dao = TrendingCacheDao(db.executor, CacheMetaDao(db.executor));
      now = DateTime.utc(2026, 7, 4, 10);
    });

    tearDown(() async => db.close());

    test('should return fresh cache without calling remote', () async {
      const query = TrendingQuery(language: 'Python');
      await dao.upsertSnapshot(
        query: query,
        snapshot: _snapshot('cached/repo'),
        now: now,
      );
      final remote = _FakeRemoteTrendingDataSource(_snapshot('remote/repo'));
      final dataSource = CachedTrendingDataSource(
        remote: remote,
        cache: dao,
        now: () => now.add(const Duration(minutes: 10)),
        ttl: const Duration(minutes: 30),
      );

      final snapshot = await dataSource.fetchTrending(query);

      expect(snapshot.trendingRepos.first.fullName, 'cached/repo');
      expect(remote.calls, 0);
    });

    test('should refresh stale cache and store remote snapshot', () async {
      const query = TrendingQuery(language: 'Python');
      await dao.upsertSnapshot(
        query: query,
        snapshot: _snapshot('stale/repo'),
        now: now,
      );
      final remote = _FakeRemoteTrendingDataSource(_snapshot('remote/repo'));
      final dataSource = CachedTrendingDataSource(
        remote: remote,
        cache: dao,
        now: () => now.add(const Duration(minutes: 40)),
        ttl: const Duration(minutes: 30),
      );

      final snapshot = await dataSource.fetchTrending(query);
      final cached = await dao.readSnapshot(query);

      expect(snapshot.trendingRepos.first.fullName, 'remote/repo');
      expect(cached?.trendingRepos.first.fullName, 'remote/repo');
      expect(remote.calls, 1);
    });

    test('should fall back to stale cache when remote fails', () async {
      const query = TrendingQuery(language: 'Python');
      await dao.upsertSnapshot(
        query: query,
        snapshot: _snapshot('stale/repo'),
        now: now,
      );
      final remote = _FakeRemoteTrendingDataSource(_snapshot('remote/repo'))
        ..error = StateError('network down');
      final dataSource = CachedTrendingDataSource(
        remote: remote,
        cache: dao,
        now: () => now.add(const Duration(minutes: 40)),
        ttl: const Duration(minutes: 30),
      );

      final snapshot = await dataSource.fetchTrending(query);

      expect(snapshot.trendingRepos.first.fullName, 'stale/repo');
      expect(remote.calls, 1);
    });
  });
}

TrendingDataSnapshot _snapshot(String fullName) {
  return TrendingDataSnapshot(
    trendingRepos: [
      RepoEntity(
        fullName: fullName,
        description: 'desc',
        language: 'Python',
        starCount: 1200,
        starDelta: 32,
        forkCount: 80,
        accentArgb: 0xFF3572A5,
        trend: const [1, 2, 3],
      ),
    ],
    recentRepos: const [],
    languages: const [
      LanguageEntity(
        name: 'Python',
        percent: 100,
        delta: 0,
        accentArgb: 0xFF3572A5,
      ),
    ],
    primaryTrend: const [1, 2, 3],
    secondaryTrend: const [1, 2, 3],
    tertiaryTrend: const [1, 2, 3],
  );
}
