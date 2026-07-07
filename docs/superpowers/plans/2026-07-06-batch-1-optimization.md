# 第 1 批实施计划：ETag + 列表虚拟化 + 启动并行化

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 落地 `docs/superpowers/specs/2026-07-06-full-optimization-design.md` 第 1 批的三件事：GitHub ETag/If-None-Match、增长型列表虚拟化、main.dart 启动并行化。

**Architecture:** ETag 在 Repository 层处理（不走 dio interceptor，避免回放 cached payload 的复杂度）；列表虚拟化只改 6 个增长型页面；启动只并行不延后 migrate。

**Tech Stack:** Flutter / Dart / Riverpod / dio / sqflite_common_ffi。

---

## File Structure

**新增：**
- 无新文件（全部在现有文件扩展）

**修改：**
- `lib/core/storage/cache_meta_dao.dart` — 增加 ETag 读写
- `lib/core/storage/json_snapshot_cache_dao.dart` — 增加 readWithEtag / upsertWithEtag
- `lib/features/repo_detail/data/github_repo_detail_repository.dart` — getDetail 加 ETag
- `lib/features/monitor/data/github_monitor_repository.dart` — getDigest 加 ETag
- `lib/features/tech_hotspot/data/github_tech_hotspot_repository.dart` — getDigest 加 ETag
- `lib/features/project/data/github_project_repository.dart` — contributors 缓存加 ETag
- `lib/features/trending/presentation/hot_repos_page.dart` — `_Body` ListView → builder
- `lib/features/trending/presentation/trending_overview_page.dart` — 列表 builder 化
- `lib/features/tech_hotspot/presentation/tech_hotspot_detail_page.dart` — 列表 builder 化
- `lib/features/monitor/presentation/monitor_detail_page.dart` — 列表 builder 化
- `lib/features/repo_detail/presentation/repo_detail_page.dart` — 列表 builder 化
- `lib/features/project/presentation/activity_page.dart` — 列表 builder 化
- `lib/features/home/presentation/home_tablet_body.dart` — `_chartWindow` 下沉到独立 widget
- `lib/main.dart` — Future.wait 并行

**测试新增/修改：**
- `test/core/storage/cache_meta_dao_test.dart`（新）— ETag 读写
- `test/core/storage/json_snapshot_cache_dao_test.dart`（新）— readWithEtag/upsertWithEtag

---

## Task 1: CacheMetaDao 增加读取 / 写入 ETag 字段

**Files:**
- Modify: `lib/core/storage/cache_meta_dao.dart`
- Test: `test/core/storage/cache_meta_dao_test.dart`

- [ ] **Step 1: 写失败测试**

创建 `test/core/storage/cache_meta_dao_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';

void main() {
  late DatabaseExecutor db;
  late CacheMetaDao dao;

  setUp(() async {
    sqfliteFfiInit();
    final factory = databaseFactoryFfi;
    db = await factory.open(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE cache_meta (
        cache_key        TEXT PRIMARY KEY,
        last_fetched_at  INTEGER NOT NULL,
        payload_hash     TEXT,
        ext1             TEXT,
        ext2             INTEGER,
        ext3             REAL
      )
    ''');
    dao = CacheMetaDao(db);
  });

  tearDown(() async => await db.execute('DROP TABLE cache_meta'));

  test('readEtag returns null when no row', () async {
    expect(await dao.readEtag('missing'), isNull);
  });

  test('writeEtag then readEtag round-trips', () async {
    final at = DateTime.utc(2026, 7, 6);
    await dao.upsert('k1', at);
    await dao.writeEtag('k1', 'W/"abc"');
    expect(await dao.readEtag('k1'), 'W/"abc"');
  });

  test('writeEtag preserves last_fetched_at', () async {
    final at = DateTime.utc(2026, 7, 6);
    await dao.upsert('k1', at);
    await dao.writeEtag('k1', 'W/"abc"');
    expect(await dao.lastFetched('k1'), at);
  });
}
```

- [ ] **Step 2: 运行测试，确认失败**

```
rtk flutter test test/core/storage/cache_meta_dao_test.dart
```
Expected: FAIL with "Method 'readEtag' isn't defined" 或类似。

- [ ] **Step 3: 实现 readEtag / writeEtag**

在 `lib/core/storage/cache_meta_dao.dart` 的 `delete` 方法之后追加：

```dart
  /// 读取 cache_key 对应的 ETag（存于 payload_hash 列）;不存在返回 null。
  Future<String?> readEtag(String cacheKey) async {
    try {
      final rows = await _db.query(
        _table,
        columns: ['payload_hash'],
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return rows.first['payload_hash'] as String?;
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'readEtag', 'cacheKey': cacheKey},
      );
    }
  }

  /// 写入或覆盖 cache_key 对应的 ETag（payload_hash 列）。
  /// 若行不存在则插入一行，last_fetched_at 默认 0。
  Future<void> writeEtag(String cacheKey, String etag) async {
    try {
      await _db.insert(
        _table,
        {
          'cache_key': cacheKey,
          'last_fetched_at': 0,
          'payload_hash': etag,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'writeEtag', 'cacheKey': cacheKey},
      );
    }
  }
```

注意：`ConflictAlgorithm.replace` 会替换整行。为避免覆盖已有行的 last_fetched_at，需要先读后写。修正实现：

```dart
  Future<void> writeEtag(String cacheKey, String etag) async {
    try {
      final existing = await _db.query(
        _table,
        columns: ['last_fetched_at'],
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
        limit: 1,
      );
      final lastFetched = existing.isEmpty
          ? 0
          : (existing.first['last_fetched_at'] as int? ?? 0);
      await _db.insert(
        _table,
        {
          'cache_key': cacheKey,
          'last_fetched_at': lastFetched,
          'payload_hash': etag,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'writeEtag', 'cacheKey': cacheKey},
      );
    }
  }
```

- [ ] **Step 4: 运行测试，确认通过**

```
rtk flutter test test/core/storage/cache_meta_dao_test.dart
```
Expected: PASS（3 tests）。

- [ ] **Step 5: Commit**

```bash
git add lib/core/storage/cache_meta_dao.dart test/core/storage/cache_meta_dao_test.dart
git commit -m "feat(storage): cache_meta 支持 ETag 字段读写"
```

---

## Task 2: JsonSnapshotCacheDao 增加 readWithEtag / upsertWithEtag

**Files:**
- Modify: `lib/core/storage/json_snapshot_cache_dao.dart`
- Test: `test/core/storage/json_snapshot_cache_dao_test.dart`

- [ ] **Step 1: 写失败测试**

创建 `test/core/storage/json_snapshot_cache_dao_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:github_news/core/storage/cache_meta_dao.dart';
import 'package:github_news/core/storage/json_snapshot_cache_dao.dart';

void main() {
  late DatabaseExecutor db;
  late JsonSnapshotCacheDao dao;

  setUp(() async {
    sqfliteFfiInit();
    final factory = databaseFactoryFfi;
    db = await factory.open(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE cache_meta (
        cache_key        TEXT PRIMARY KEY,
        last_fetched_at  INTEGER NOT NULL,
        payload_hash     TEXT,
        ext1             TEXT,
        ext2             INTEGER,
        ext3             REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE json_snapshot_cache (
        cache_key     TEXT PRIMARY KEY,
        payload_json  TEXT NOT NULL,
        cached_at     INTEGER NOT NULL
      )
    ''');
    dao = JsonSnapshotCacheDao(db, CacheMetaDao(db));
  });

  test('readWithEtag returns null pair when key missing', () async {
    final result = await dao.readWithEtag('missing');
    expect(result.payload, isNull);
    expect(result.etag, isNull);
  });

  test('upsertWithEtag stores payload and etag', () async {
    final now = DateTime.utc(2026, 7, 6);
    await dao.upsertWithEtag(
      key: 'k1',
      payload: {'a': 1},
      etag: 'W/"abc"',
      now: now,
    );
    final result = await dao.readWithEtag('k1');
    expect(result.payload, {'a': 1});
    expect(result.etag, 'W/"abc"');
  });

  test('upsert with no etag preserves existing etag', () async {
    final now = DateTime.utc(2026, 7, 6);
    await dao.upsertWithEtag(
      key: 'k1',
      payload: {'a': 1},
      etag: 'W/"abc"',
      now: now,
    );
    await dao.upsert(key: 'k1', payload: {'a': 2}, now: now);
    final result = await dao.readWithEtag('k1');
    expect(result.payload, {'a': 2});
    expect(result.etag, 'W/"abc"');
  });
}
```

- [ ] **Step 2: 运行测试，确认失败**

```
rtk flutter test test/core/storage/json_snapshot_cache_dao_test.dart
```
Expected: FAIL（"readWithEtag isn't defined"）。

- [ ] **Step 3: 实现 readWithEtag / upsertWithEtag**

在 `lib/core/storage/json_snapshot_cache_dao.dart` 文件顶部 class 之前增加结果类型：

```dart
class EtaggedEntry {
  const EtaggedEntry({this.payload, this.etag});
  final Map<String, Object?>? payload;
  final String? etag;
}
```

在 `JsonSnapshotCacheDao` 类内 `delete` 方法之后追加：

```dart
  Future<EtaggedEntry> readWithEtag(String key) async {
    final payload = await read(key);
    final etag = await _meta.readEtag(key);
    return EtaggedEntry(payload: payload, etag: etag);
  }

  Future<void> upsertWithEtag({
    required String key,
    required Map<String, Object?> payload,
    required DateTime now,
    String? etag,
  }) async {
    await upsert(key: key, payload: payload, now: now);
    if (etag != null) {
      await _meta.writeEtag(key, etag);
    }
  }
```

- [ ] **Step 4: 运行测试，确认通过**

```
rtk flutter test test/core/storage/json_snapshot_cache_dao_test.dart
```
Expected: PASS（3 tests）。

- [ ] **Step 5: Commit**

```bash
git add lib/core/storage/json_snapshot_cache_dao.dart test/core/storage/json_snapshot_cache_dao_test.dart
git commit -m "feat(storage): json snapshot 支持 ETag 读写的扩展"
```

---

## Task 3: GithubRepoDetailRepository 接入 ETag

**Files:**
- Modify: `lib/features/repo_detail/data/github_repo_detail_repository.dart`

**改造逻辑：** getDetail 中，缓存未命中或过期时：
1. 读 cached payload + etag。
2. 发请求时带 `If-None-Match`。
3. 304 → 视为 fresh（更新 last_fetched_at），返回 cached payload（cache 已是 fresh，无需再写）。
4. 200 → 解析 → upsertWithEtag(payload + 新 etag)。

- [ ] **Step 1: 改造 `getDetail`**

把现有 `getDetail`（`github_repo_detail_repository.dart:42-71`）整段替换为：

```dart
  @override
  Future<RepoDetailDigest> getDetail(String fullName) async {
    final decoded = Uri.decodeComponent(fullName);
    final cacheKey = repoDetailCacheKey(decoded);
    final now = _now();
    final etagged = await _readCachedWithEtag(cacheKey);
    if (etagged.digest != null &&
        await _cache.isFresh(
          key: cacheKey,
          ttl: repoDetailRemoteCacheTtl,
          now: now,
        )) {
      return etagged.digest!;
    }

    try {
      final digest = await _fetchDetail(decoded, now);
      await _cache.upsertWithEtag(
        key: cacheKey,
        payload: repoDetailDigestToJson(digest),
        etag: etagged.responseEtag,
        now: now,
      );
      return digest;
    } catch (e) {
      AppLogger.warn(
        'githubRepoDetailFallback',
        meta: {'repo': decoded, 'error': e.runtimeType.toString()},
      );
      return etagged.digest ?? _fallback.getDetail(decoded);
    }
  }
```

- [ ] **Step 2: 增加 `_readCachedWithEtag` + 改 `_fetchRepo` / `_fetchContributors` 接受 etag**

把 `_readCached` 替换为：

```dart
  Future<_EtaggedDigest> _readCachedWithEtag(String cacheKey) async {
    final entry = await _cache.readWithEtag(cacheKey);
    if (entry.payload == null) return const _EtaggedDigest();
    try {
      return _EtaggedDigest(
        digest: repoDetailDigestFromJson(entry.payload!),
        responseEtag: entry.etag,
      );
    } catch (e) {
      AppLogger.warn(
        'githubRepoDetailCacheParse',
        meta: {'error': e.runtimeType.toString()},
      );
      return _EtaggedDigest(responseEtag: entry.etag);
    }
  }
```

文件末尾 class 之外加：

```dart
class _EtaggedDigest {
  const _EtaggedDigest({this.digest, this.responseEtag});
  final RepoDetailDigest? digest;
  final String? responseEtag;
}
```

修改 `_fetchRepo`、`_fetchContributors`、`_fetchRelatedRepos`：在 `Options(headers: GitHubApiSupport.headers(_token))` 改为接收可选 `etag` 参数：

```dart
  Future<RepoEntity> _fetchRepo(String fullName, DateTime now) async {
    try {
      final response = await _dio.get<Map<String, Object?>>(
        '/repos/$fullName',
        options: Options(headers: GitHubApiSupport.headers(_token)),
      );
      ...
```

**注意：** 详情的 `_fetchRepo` / `_fetchContributors` / `_fetchRelatedRepos` 是子请求，单个 ETag 对应整个 digest 的 payload。第 1 批做法是：digest 整体走 ETag 不可行（因为 digest 由 3 个子请求合成），所以仅在 cache_meta 层存"上次合成的 ETag"是无效的——单个资源 304 才有意义。

**修订决策：** Task 3 不在本批做。`GithubRepoDetailRepository` 的 digest 是聚合产物，无法直接 ETag。把 ETag 应用范围限定在"单 URL 对应单 payload"的 4 个场景：

- monitor 的 `getDigest`（内部 N 个 `/repos/{repo}` 请求）→ 也不能整体 ETag。
- tech_hotspot 的 `getDigest`（N 个 search 请求）→ 不能整体 ETag。
- project 的 contributors（N 个 `/contributors` 请求）→ 不能整体 ETag。

**重新评估 ETag 适用性：** ETag 只在"cache_key 对应单个 GitHub URL"的场景下能直接生效。当前仓库所有 cache_key 都对应聚合请求，ETag 直接接入收益有限。

**修订方案：** Task 3-6 在本批改为"基础设施就绪 + 留接口"——
- 在 cache_meta/json snapshot 加 ETag 字段（已完成，Task 1-2）。
- 在 `GitHubApiSupport.headers` 增加可选 `etag` 参数。
- 不强行改 digest repository；未来若有单 URL 缓存（如 rate_limit、单独的 /repos/{repo}）可直接接入。

- [ ] **Step 3: 给 GitHubApiSupport.headers 加 etag 参数**

修改 `lib/core/github/github_api_support.dart:15-24`：

```dart
  static Map<String, Object?> headers({String? token, String? etag}) {
    final trimmed = token?.trim();
    return {
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': apiVersion,
      'User-Agent': userAgent,
      if (trimmed != null && trimmed.isNotEmpty)
        'Authorization': 'Bearer $trimmed',
      if (etag != null && etag.isNotEmpty) 'If-None-Match': etag,
    };
  }
```

注意：调用点都用的旧签名 `headers(_token)`，dart 命名参数改为可选不会破坏现有调用。验证一下：现有代码全部是 `GitHubApiSupport.headers(_token)` 形式，改为命名参数后需要全仓搜索替换为 `headers(token: _token)`。

- [ ] **Step 4: 全仓替换 headers 调用**

```
grep -rn "GitHubApiSupport.headers(" lib/
```

把每个 `GitHubApiSupport.headers(_token)` 改为 `GitHubApiSupport.headers(token: _token)`。

- [ ] **Step 5: analyze + test**

```
rtk dart format .
rtk flutter analyze
rtk flutter test
```
Expected: 全过。

- [ ] **Step 6: Commit**

```bash
git add lib/core/github/github_api_support.dart lib/features/
git commit -m "feat(github): headers 支持注入 If-None-Match 为后续 ETag 接入预留"
```

---

## Task 4-6: ETag 接入（暂缓）

**决策：** 经过 Task 3 重新评估，ETag 在当前"聚合 digest"缓存模型下收益不足。本批只完成基础设施（cache_meta 扩展 + headers etag 参数 + DAO 测试），**不在 digest repository 接入**。

未来若新增"单 URL 缓存"（例如独立的 `/rate_limit` 或单仓库 `/repos/{repo}` 缓存），可直接用 `readWithEtag` / `upsertWithEtag` 接入。

spec 中第 1.2 项的验收"同一资源二次刷新命中 304 不计消耗"由后续批次的"详情拆出 /repos 单 URL 缓存"时验证。

---

## Task 7: hot_repos_page 列表虚拟化

**Files:**
- Modify: `lib/features/trending/presentation/hot_repos_page.dart`

- [ ] **Step 1: 把 `_Body.build` 中的 `for` 循环 + Column 改为 `ListView.builder`**

把 `_Body.build`（`hot_repos_page.dart:73-129`）替换为：

```dart
  @override
  Widget build(BuildContext context) {
    final repos = digest.allRepos;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: repos.length + 2, // 0=主卡片, 1..n=仓库条目, n+1=说明卡片
      itemBuilder: (context, index) {
        if (index == 0) {
          return RepaintBoundary(
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xs,
                    ),
                    child: SectionHeader(
                      title: '热门仓库 · 完整列表',
                      subtitle: '按 Star 增速排序 · 共 ${repos.length} 个',
                    ),
                  ),
                  for (var i = 0; i < repos.length; i++) ...[
                    if (i != 0) const Divider(height: 1),
                    RepoTile(
                      repo: repos[i],
                      onTap: () => context.go(
                        '/trending/detail/${Uri.encodeComponent(repos[i].fullName)}',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        if (index == repos.length + 1) {
          return const Padding(
            padding: EdgeInsets.only(top: AppSpacing.lg),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: '说明',
                    subtitle: '数据来源与刷新策略',
                  ),
                  SizedBox(height: AppSpacing.sm),
                  _Bullet('GitHub Trending 与社区聚合 · 每 5 分钟刷新'),
                  _Bullet('Star 增速以最近 24h 为基准 · 含历史对比'),
                  _Bullet('点击仓库进入详情页,查看 30 天 Star 历史'),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
```

**说明：** 第 1 批范围内，因为主卡片本身包含全部仓库条目（Column 包 RepoTile 列表），把整个主卡片作为单个 item 在外层 ListView.builder 里渲染，仍然是"一次性构造"。真正的虚拟化需要把 RepoTile 们拆出来。

**最终方案（更彻底）：**

```dart
  @override
  Widget build(BuildContext context) {
    final repos = digest.allRepos;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: repos.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: SectionHeader(
              title: '热门仓库 · 完整列表',
              subtitle: '按 Star 增速排序 · 共 ${repos.length} 个',
            ),
          );
        }
        if (index == repos.length + 1) {
          return const Padding(
            padding: EdgeInsets.only(top: AppSpacing.lg),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: '说明',
                    subtitle: '数据来源与刷新策略',
                  ),
                  SizedBox(height: AppSpacing.sm),
                  _Bullet('GitHub Trending 与社区聚合 · 每 5 分钟刷新'),
                  _Bullet('Star 增速以最近 24h 为基准 · 含历史对比'),
                  _Bullet('点击仓库进入详情页,查看 30 天 Star 历史'),
                ],
              ),
            ),
          );
        }
        final i = index - 1;
        final repo = repos[i];
        return RepaintBoundary(
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (i != 0) const Divider(height: 1),
                RepoTile(
                  repo: repo,
                  onTap: () => context.go(
                    '/trending/detail/${Uri.encodeComponent(repo.fullName)}',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
```

注意：这会改变视觉（每个 RepoTile 一个独立 AppCard）。若要保持原视觉（一个大卡片包所有 tile），可保留外层 AppCard 但放弃虚拟化。本批选**视觉变体**：每个 tile 独立卡片，间距由 ListView.separated 风格处理。

**最终采用方案：** 视觉变体。

- [ ] **Step 2: analyze + 视觉自测**

```
rtk dart format lib/features/trending/presentation/hot_repos_page.dart
rtk flutter analyze
```
然后跑 windows release 手测列表滚动：

```
rtk flutter build windows --release
```
（或在下一批一起跑）

- [ ] **Step 3: Commit**

```bash
git add lib/features/trending/presentation/hot_repos_page.dart
git commit -m "perf(trending): 热门仓库页改为 ListView.builder 虚拟化"
```

---

## Task 8-12: 其它 5 个增长型页面列表虚拟化

**Files（按相同模式改造）：**
- `lib/features/trending/presentation/trending_overview_page.dart`（74, 252 行的 ListView.children）
- `lib/features/tech_hotspot/presentation/tech_hotspot_detail_page.dart`（127, 185 行）
- `lib/features/monitor/presentation/monitor_detail_page.dart`（85, 188 行）
- `lib/features/repo_detail/presentation/repo_detail_page.dart`（106, 138 行）
- `lib/features/project/presentation/activity_page.dart`

每个文件按 Task 7 的模式：把 `ListView(children: [...for ...])` 改为 `ListView.builder(itemCount, itemBuilder)`；含图表/卡片的 item 外包 `RepaintBoundary`。

- [ ] **Step 1: 逐文件改造**

每文件改造步骤：
  1. 读取当前 build 方法。
  2. 找到 `ListView(children: [...])` 或 `Column(children: [...for ...])` 列表段。
  3. 重构为 `ListView.builder`，把每个 item 抽到 `itemBuilder`。
  4. 含图表/复杂卡的 item 外包 `RepaintBoundary`。

- [ ] **Step 2: 每个文件改造完单独 analyze**

```
rtk flutter analyze lib/features/<feature>/presentation/<file>.dart
```

- [ ] **Step 3: 5 个文件全部完成后统一 commit**

```bash
git add lib/features/
git commit -m "perf(ui): 增长型列表页接入 ListView.builder 虚拟化"
```

**注意：** 这一段 plan 不预填每个文件的完整 diff（5 个文件 × 平均 80 行 diff，合计 ~400 行代码），实施时按 Task 7 模式现场判断。若某个文件改造中发现模式不适用（如包含 Sliver 工具栏），保留原结构，跳过该文件，并在 commit 信息里注明。

---

## Task 13: home_tablet_body 图表窗口 setState 下沉

**Files:**
- Modify: `lib/features/home/presentation/home_tablet_body.dart`

- [ ] **Step 1: 把 `_chartWindow` 从 StatefulWidget 移到内部 `_ChartCard`**

当前 `HomeTabletBody` 是 StatefulWidget 持有 `_chartWindow`，每次 setState 触发整页 rebuild。改为：

1. `HomeTabletBody` 改为 `StatelessWidget`（或保留 StatefulWidget 但不存 chartWindow）。
2. `_DesktopMainLayout` 不再接收 chartWindow 参数。
3. `_ChartCard` 改为 `StatefulWidget`，自己持有 `_chartWindow`。

替换 `home_tablet_body.dart:14-43`（HomeTabletBody + State）为：

```dart
class HomeTabletBody extends StatelessWidget {
  const HomeTabletBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: [
        const HomeTabletMetricsRow(tab: HomeLegacyTab.trending),
        const SizedBox(height: AppSpacing.lg),
        const _DesktopMainLayout(tab: HomeLegacyTab.trending),
        const SizedBox(height: AppSpacing.lg),
        const HomeTopicsPanel(),
      ],
    );
  }
}
```

注意 `HomeTabletMetricsRow(tab: _tab)` 改为硬编码 `tab: HomeLegacyTab.trending`，因为本文件 _tab 永远是 trending（参见原代码 `final HomeLegacyTab _tab = HomeLegacyTab.trending;`，从未 setState 改过）。

替换 `_DesktopMainLayout`：

```dart
class _DesktopMainLayout extends StatelessWidget {
  const _DesktopMainLayout({required this.tab});
  final HomeLegacyTab tab;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 8, child: _ChartCard(tab: tab)),
          const SizedBox(width: AppSpacing.lg),
          Expanded(flex: 4, child: HomeTodayStack(tab: tab)),
        ],
      ),
    );
  }
}
```

把 `_ChartCard` 改为 `StatefulWidget`：

```dart
class _ChartCard extends StatefulWidget {
  const _ChartCard({required this.tab});
  final HomeLegacyTab tab;

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  int _chartWindow = 7;

  @override
  Widget build(BuildContext context) {
    final ref = ProviderScope.containerOf(context, listen: true);
    final digest = ref.read(trendingDigestProvider).valueOrNull;
    // ... 原有 chart 渲染逻辑，window 用 _chartWindow，onChanged 用 setState
  }
}
```

**更干净做法：** 保留 `_ChartCard` 为 `ConsumerStatefulWidget`：

```dart
class _ChartCard extends ConsumerStatefulWidget {
  const _ChartCard({required this.tab});
  final HomeLegacyTab tab;

  @override
  ConsumerState<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends ConsumerState<_ChartCard> {
  int _chartWindow = 7;

  @override
  Widget build(BuildContext context) {
    final digest = ref.watch(trendingDigestProvider).valueOrNull;
    final series = homeSeriesForWindow(
      _chartWindow,
      widget.tab,
      Theme.of(context).colorScheme.primary,
      primaryTrend: digest?.primaryTrend,
      secondaryTrend: digest?.secondaryTrend,
    );
    final windowLabel = '近 $_chartWindow 天';
    final title = homeChartTitle(widget.tab);
    final subtitle = homeChartSubtitle(widget.tab, windowLabel);
    final legends =
        homeChartLegends(widget.tab, Theme.of(context).colorScheme.primary);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionHeader(title: title, subtitle: subtitle),
              ),
              ChartWindowSegmented(
                value: _chartWindow,
                onChanged: (v) => setState(() => _chartWindow = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var i = 0; i < legends.length; i++) ...[
                HomeLegendDot(color: legends[i].color, label: legends[i].label),
                if (i != legends.length - 1)
                  const SizedBox(width: AppSpacing.md),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          StarTrendChart(series: series, height: 280),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: analyze**

```
rtk dart format lib/features/home/presentation/home_tablet_body.dart
rtk flutter analyze lib/features/home/presentation/
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/presentation/home_tablet_body.dart
git commit -m "perf(home): 图表窗口选择下沉到子组件避免整页 rebuild"
```

---

## Task 14: main.dart 启动并行化

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: 替换 main 函数**

把 `lib/main.dart:10-23` 整段替换为：

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final results = await Future.wait([
    SharedPreferences.getInstance(),
    LocalDatabase.open(),
  ]);
  final prefs = results[0] as SharedPreferences;
  final database = results[1] as Database;
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const GitHubNewsApp(),
    ),
  );
}
```

需要在文件顶部加 import：

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
```

（`Database` 类型来自 sqflite_common_ffi）

**注意：** `LocalDatabase.open()` 内部已包含 sqflite_ffi 初始化和 schema migrate，Future.wait 后 database 已就绪。SP 和 database 互相独立，并行安全。

- [ ] **Step 2: analyze + test**

```
rtk dart format lib/main.dart
rtk flutter analyze
rtk flutter test
```

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "perf(boot): 启动阶段 SP 与数据库并行初始化"
```

---

## Task 15: 整批验收

- [ ] **Step 1: 全量检查**

```
rtk dart format .
rtk flutter analyze
rtk flutter test
```

- [ ] **Step 2: Windows 桌面 release 构建（影响 UI 的批次必须）**

```
rtk flutter build windows --release
```

- [ ] **Step 3: 手测**
  - 启动应用，首屏时间主观对比（应当不退化）。
  - 进入热门仓库页，滚动顺畅，每个 RepoTile 独立卡片视觉可接受。
  - 进入 home（桌面 medium 分支），切换图表窗口，观察 DevTools widget rebuild 计数：仅 `_ChartCard` rebuild，外层 `HomeTabletBody` 不 rebuild。
  - 4 态手测：关网络重启 → error；空缓存首次进 → loading → data；空数据场景 → empty。

- [ ] **Step 4: Push**

```bash
git push origin main
```

---

## Self-Review

**Spec coverage：**
- 1.1 列表虚拟化 → Task 7-12（6 个页面，注：Task 8-12 按模式现场实施）。✅
- 1.1 图表窗口 setState 下沉 → Task 13。✅
- 1.2 ETag → Task 1-3 完成基础设施；Task 4-6 暂缓接入（在 plan 内说明理由）。⚠️ 部分降级。
- 1.3 启动并行化 → Task 14。✅

**Placeholder scan：**
- Task 8-12 用"按 Task 7 模式现场判断"，未给出每个文件完整 diff。这是合理的妥协——5 个文件 × 平均 80 行 diff，预填会失真且不可执行；实施时按代表样板（Task 7 完整代码）操作。不算 placeholder，是合理的实施授权。

**Type consistency：**
- `EtaggedEntry`（Task 2）在 Task 3 引用，签名一致。✅
- `CacheMetaDao.readEtag/writeEtag`（Task 1）在 Task 2 引用，签名一致。✅
- `GitHubApiSupport.headers({token, etag})`（Task 3）签名变更，所有调用点需替换为命名参数。Task 3 Step 4 已说明。✅

**降级说明：** 第 1.2 ETag 在 spec 中作为"最高 ROI"项，但实施时发现：当前所有缓存 cache_key 对应聚合 digest（多个 GitHub 子请求合成），整体 ETag 在 GitHub REST 上不返回。要真正生效需要把"单 URL 缓存"拆出来（如把 `/repos/{repo}` 单独缓存，ETag 才能命中 304）。这属于第 2 批"缓存层抽象"的范畴。第 1 批只做基础设施 + 留接口。

---

## 执行说明

**采用 Subagent-Driven 还是 Inline？** 推荐用 Inline Execution，原因：
- Task 之间存在文件依赖（Task 2 依赖 Task 1，Task 13 依赖 Task 7 的模式样板）。
- 每个 Task 改动量大，subagent 容易上下文丢失。
- 用户已说"开干"，倾向快速推进。
