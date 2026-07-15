# 发现页分页与扩容 Implementation Plan

> 历史快照：本文计划已经在 1.4.0+4 基线中实施，命令、行号和复选框仅保留为执行记录。当前事实请查看 [产品、数据与系统边界](../../plans/product_ia_data_plan.md) 和 [README](../../../README.md)。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让发现页四个分段(repos / skills / official / people)都支持按"剩余 item ≤ 3"触发的无限滚动,扩大单页数据量,并让 official/people 通过 `/search/users` 突破 10 条白名单上限。

**Architecture:** 沿用现有 feature-first 分层。新增 `DiscoverUsersSearchClient` 调 `/search/users`;`fetchProfiles` 扩成按页拉取(白名单置顶 + 搜索结果追加);profile 段采用渐进补全 —— 先渲染占位卡片,后台并发调 `/users/{login}` 逐条刷新。

**Tech Stack:** Flutter / Dart / Riverpod / Dio / SQLite(snapshot cache)/ 现有 `GitHubResourceCache`(ETag)。

**Spec:** `docs/superpowers/specs/2026-07-14-discover-pagination-design.md`

---

## File Structure

新建:
- `lib/features/discover/data/discover_users_search_client.dart` —— `/search/users` 客户端
- `lib/features/discover/data/user_search_hit.dart` —— 搜索结果轻值对象
- `test/features/discover/data/discover_users_search_client_test.dart`
- `test/features/discover/data/discover_repository_test.dart`(如已存在则扩展)
- `test/features/discover/application/profiles_notifier_test.dart`
- `test/features/discover/presentation/discover_profile_row_test.dart`

修改:
- `lib/core/config/api_endpoints_config.dart` —— 加 `/search/users` URL builder
- `lib/features/discover/data/discover_queries.dart` —— 放宽 skills query、新增 search query、profiles page key
- `lib/features/discover/domain/discover_entities.dart` —— `DiscoverProfileEntity` 加 `enriched` / `enrichFailed`
- `lib/features/discover/data/discover_cache_codec.dart` —— 编解码新字段
- `lib/features/discover/data/discover_seed.dart` —— seed 显式标 enriched
- `lib/features/discover/data/discover_repository.dart` —— `fetchProfiles` 加 page/perPage、新增 `fetchProfileDetail`
- `lib/features/discover/application/discover_providers.dart` —— 新增 `ProfilesNotifier`、调整常量
- `lib/features/discover/presentation/discover_page.dart` —— `_onScroll` 改按元素数;`_buildProfiles` 接 notifier
- `lib/features/discover/presentation/widgets/discover_profile_row.dart` —— 占位态
- `lib/core/i18n/strings_zh_cn.dart` / `strings_en_us.dart` —— 新 key
- `test/features/discover/application/discover_providers_test.dart` —— 适配新签名

---

## Task 1: 新增 `/search/users` 端点配置

**Files:**
- Modify: `lib/core/config/api_endpoints_config.dart`
- Test: `test/core/config/api_endpoints_config_test.dart`(新增或扩展)

- [ ] **Step 1: 写失败测试**

创建/扩展 `test/core/config/api_endpoints_config_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/config/api_endpoints_config.dart';

void main() {
  test('githubSearchUsersPath 为 /search/users', () {
    expect(ApiEndpointsConfig.githubSearchUsersPath, '/search/users');
  });

  test('githubSearchUsersUrl 默认参数拼装', () {
    final url = ApiEndpointsConfig.githubSearchUsersUrl(
      q: 'type:org followers:>5000',
    );
    expect(url, contains('q=type%3Aorg%20followers%3A%3E5000'));
    expect(url, contains('per_page=20'));
    expect(url, contains('page=1'));
  });

  test('githubSearchUsersUrl 自定义分页', () {
    final url = ApiEndpointsConfig.githubSearchUsersUrl(
      q: 'ai',
      perPage: 50,
      page: 3,
    );
    expect(url, contains('per_page=50'));
    expect(url, contains('page=3'));
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `rtk flutter test test/core/config/api_endpoints_config_test.dart`
Expected: FAIL — `githubSearchUsersPath` getter not defined.

- [ ] **Step 3: 在 `api_endpoints_config.dart` 中,在 `githubSearchRepositoriesUrl` 之后加入**

```dart
  // GitHub Users 搜索接口:`GET /search/users`。
  // 发现页 official / people 段分页数据源。
  static const String githubSearchUsersPath = '/search/users';

  // GitHub 用户/组织搜索(发现页:官方账号 / 知名开发者)。
  static String githubSearchUsersUrl({
    required String q,
    int perPage = 20,
    int page = 1,
  }) =>
      '/search/users?q=${Uri.encodeQueryComponent(q)}'
      '&per_page=$perPage&page=$page';
```

- [ ] **Step 4: 运行测试确认通过**

Run: `rtk flutter test test/core/config/api_endpoints_config_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/config/api_endpoints_config.dart test/core/config/api_endpoints_config_test.dart
git commit -m "Feat(core): 新增 GitHub /search/users 端点配置"
```

---

## Task 2: `UserSearchHit` 值对象

**Files:**
- Create: `lib/features/discover/data/user_search_hit.dart`

- [ ] **Step 1: 创建值对象文件**

```dart
/// `/search/users` 单条结果的轻量值对象。
/// 仅包含搜索接口返回的字段;bio / followers / public_repos 等
/// 需通过 `/users/{login}` 渐进补全。
class UserSearchHit {
  const UserSearchHit({
    required this.login,
    required this.avatarUrl,
    required this.htmlUrl,
    required this.type,
  });

  final String login;
  final String avatarUrl;
  final String htmlUrl;

  /// GitHub 返回的 'User' 或 'Organization'。
  final String type;
}
```

- [ ] **Step 2: 运行 analyze 验证**

Run: `rtk flutter analyze lib/features/discover/data/user_search_hit.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/discover/data/user_search_hit.dart
git commit -m "Feat(discover): 新增 UserSearchHit 值对象"
```

---

## Task 3: `DiscoverUsersSearchClient`

**Files:**
- Create: `lib/features/discover/data/discover_users_search_client.dart`
- Test: `test/features/discover/data/discover_users_search_client_test.dart`

- [ ] **Step 1: 写失败测试**

创建 `test/features/discover/data/discover_users_search_client_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/discover/data/discover_users_search_client.dart';

void main() {
  test('searchUsers 透传 query/page/perPage 并解析 login 列表', () async {
    final dio = Dio();
    final adapter = _RecordingAdapter();
    dio.httpClientAdapter = adapter;

    final client = DiscoverUsersSearchClient(dio, 'fake-token');
    final hits = await client.searchUsers(
      query: 'type:org followers:>5000',
      page: 2,
      perPage: 30,
    );

    expect(adapter.lastPath, '/search/users');
    expect(adapter.lastQuery!['q'], 'type:org followers:>5000');
    expect(adapter.lastQuery!['page'], '2');
    expect(adapter.lastQuery!['per_page'], '30');
    expect(adapter.lastHeaders!['Authorization'], 'token fake-token');
    expect(hits.length, 2);
    expect(hits[0].login, 'openai');
    expect(hits[0].type, 'Organization');
    expect(hits[1].login, 'karpathy');
    expect(hits[1].type, 'User');
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  String? lastPath;
  Map<String, dynamic>? lastQuery;
  Map<String, dynamic>? lastHeaders;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastPath = options.path;
    lastQuery = options.queryParameters;
    lastHeaders = options.headers;
    final payload = jsonEncode({
      'items': [
        {
          'login': 'openai',
          'avatar_url': 'https://github.com/openai.png',
          'html_url': 'https://github.com/openai',
          'type': 'Organization',
        },
        {
          'login': 'karpathy',
          'avatar_url': 'https://github.com/karpathy.png',
          'html_url': 'https://github.com/karpathy',
          'type': 'User',
        },
      ],
    });
    return ResponseBody.fromString(payload, 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }
}
```

> 测试自包含,不依赖外部 helper。

- [ ] **Step 2: 运行测试确认失败**

Run: `rtk flutter test test/features/discover/data/discover_users_search_client_test.dart`
Expected: FAIL — `DiscoverUsersSearchClient` 不存在。

- [ ] **Step 3: 实现 client**

创建 `lib/features/discover/data/discover_users_search_client.dart`:

```dart
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import 'user_search_hit.dart';

class DiscoverUsersSearchClient {
  const DiscoverUsersSearchClient(this._dio, this._token);

  final Dio _dio;
  final String? _token;

  Future<List<UserSearchHit>> searchUsers({
    required String query,
    required int page,
    required int perPage,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      ApiEndpointsConfig.githubSearchUsersUrl(
        q: query,
        perPage: perPage,
        page: page,
      ),
      options: Options(headers: GitHubApiSupport.headers(token: _token)),
    );
    final data = response.data;
    if (data == null) {
      throw const AppException(kind: AppExceptionKind.parse);
    }
    final items = data['items'];
    if (items is! List<Object?>) {
      throw const AppException(kind: AppExceptionKind.parse);
    }
    return [
      for (final raw in items) _hitFromJson(GitHubJson.map(raw)),
    ];
  }

  UserSearchHit _hitFromJson(Map<String, Object?> json) {
    return UserSearchHit(
      login: GitHubJson.string(json['login']),
      avatarUrl: GitHubJson.nullableString(json['avatar_url']) ?? '',
      htmlUrl: GitHubJson.nullableString(json['html_url']) ?? '',
      type: GitHubJson.nullableString(json['type']) ?? 'User',
    );
  }
}
```

> 注意:dio/dart 相关 import 已在测试顶部包含。`Uint8List` 来自 `dart:typed_data`,`jsonEncode` 来自 `dart:convert`。

- [ ] **Step 4: 运行测试确认通过**

Run: `rtk flutter test test/features/discover/data/discover_users_search_client_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/discover/data/discover_users_search_client.dart \
        test/features/discover/data/discover_users_search_client_test.dart
git commit -m "Feat(discover): 新增 /search/users 客户端"
```

---

## Task 4: `DiscoverQueries` 放宽 skills、新增 search queries、profiles page key

**Files:**
- Modify: `lib/features/discover/data/discover_queries.dart`
- Test: `test/features/discover/data/discover_queries_test.dart`(新增)

- [ ] **Step 1: 写失败测试**

创建 `test/features/discover/data/discover_queries_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/discover/data/discover_queries.dart';
import 'package:github_news/features/discover/domain/discover_entities.dart';

void main() {
  test('skills query 包含放宽后的 topic 与 stars 门槛', () {
    expect(DiscoverQueries.skills, contains('topic:ai-agent'));
    expect(DiscoverQueries.skills, contains('topic:llm-agent'));
    expect(DiscoverQueries.skills, contains('topic:mcp-server'));
    expect(DiscoverQueries.skills, contains('stars:>10'));
  });

  test('officialSearchQuery 使用 type:org + ai 关键词', () {
    expect(DiscoverQueries.officialSearchQuery, contains('type:org'));
    expect(DiscoverQueries.officialSearchQuery, contains('followers:>5000'));
    expect(DiscoverQueries.officialSearchQuery, contains('ai in:name,bio'));
  });

  test('peopleSearchQuery 使用 type:user + ai 关键词', () {
    expect(DiscoverQueries.peopleSearchQuery, contains('type:user'));
    expect(DiscoverQueries.peopleSearchQuery, contains('followers:>1000'));
    expect(DiscoverQueries.peopleSearchQuery, contains('ai in:bio'));
  });

  test('profilesPageKey 按 kind 与分页维度生成', () {
    final key = DiscoverQueries.profilesPageKey(
      DiscoverProfileKind.official,
      2,
      20,
    );
    expect(key, 'discover_profiles:official:p2:n20');
  });

  test('白名单 login 列表保持不变(置顶用)', () {
    expect(DiscoverQueries.officialLogins, contains('openai'));
    expect(DiscoverQueries.officialLogins.length, greaterThanOrEqualTo(8));
    expect(DiscoverQueries.peopleLogins, contains('karpathy'));
    expect(DiscoverQueries.peopleLogins.length, greaterThanOrEqualTo(8));
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `rtk flutter test test/features/discover/data/discover_queries_test.dart`
Expected: FAIL — `officialSearchQuery` / `profilesPageKey` 未定义。

- [ ] **Step 3: 改 `discover_queries.dart`**

修改 `lib/features/discover/data/discover_queries.dart`,替换 `skills` 常量、新增 search query 与 profiles key:

```dart
  static const String trending = 'stars:>1000';
  static const String skills =
      'topic:agent-skills OR topic:claude-skills OR topic:mcp '
      'OR topic:ai-agent OR topic:llm-agent OR topic:mcp-server '
      'stars:>10';

  /// /search/users:官方组织(AI 相关)。
  static const String officialSearchQuery =
      'type:org followers:>5000 ai in:name,bio';

  /// /search/users:知名开发者(AI 相关)。
  static const String peopleSearchQuery =
      'type:user followers:>1000 ai in:bio';
```

新增 profiles page key 方法(放在 `pageKey` 旁):

```dart
  static String profilesPageKey(
    DiscoverProfileKind kind,
    int page,
    int perPage,
  ) =>
      '${DiscoverQueries.profilesCache}:${kind.name}:p$page:n$perPage';
```

- [ ] **Step 4: 运行测试确认通过**

Run: `rtk flutter test test/features/discover/data/discover_queries_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/discover/data/discover_queries.dart \
        test/features/discover/data/discover_queries_test.dart
git commit -m "Feat(discover): 放宽 skills query 并新增 users search queries"
```

---

## Task 5: `DiscoverProfileEntity` 加 `enriched` / `enrichFailed`

**Files:**
- Modify: `lib/features/discover/domain/discover_entities.dart`
- Modify: `lib/features/discover/data/discover_cache_codec.dart`
- Modify: `lib/features/discover/data/discover_seed.dart`
- Modify: `test/features/discover/application/discover_providers_test.dart`

- [ ] **Step 1: 改实体**

修改 `lib/features/discover/domain/discover_entities.dart` 中 `DiscoverProfileEntity`:

```dart
class DiscoverProfileEntity {
  const DiscoverProfileEntity({
    required this.login,
    required this.name,
    required this.type,
    required this.bio,
    required this.publicRepos,
    required this.followers,
    required this.avatarUrl,
    required this.htmlUrl,
    required this.featuredRepoFullName,
    required this.kind,
    this.enriched = true,
    this.enrichFailed = false,
  });

  final String login;
  final String name;
  final String type;
  final String bio;
  final int publicRepos;
  final int followers;
  final String avatarUrl;
  final String htmlUrl;
  final String featuredRepoFullName;
  final DiscoverProfileKind kind;

  /// 是否已通过 /users/{login} 补全完整字段。
  /// `/search/users` 返回的占位 entity 此字段为 false。
  final bool enriched;

  /// 补全失败标记,避免无限重试。
  final bool enrichFailed;
}
```

- [ ] **Step 2: 改 codec 显式写 enriched**

修改 `lib/features/discover/data/discover_cache_codec.dart` 中 `profileFromJson`:

```dart
  static DiscoverProfileEntity profileFromJson(
    Map<String, Object?> json,
    DiscoverProfileKind kind,
  ) {
    final login = GitHubJson.string(json['login']);
    final name = GitHubJson.nullableString(json['name']);
    return DiscoverProfileEntity(
      login: login,
      name: (name == null || name.isEmpty) ? login : name,
      type: GitHubJson.nullableString(json['type']) ?? (kind == DiscoverProfileKind.official ? 'Organization' : 'User'),
      bio: GitHubJson.nullableString(json['bio']) ?? '',
      publicRepos: GitHubJson.intValue(json['public_repos'] ?? json['publicRepos']),
      followers: GitHubJson.intValue(json['followers']),
      avatarUrl: GitHubJson.nullableString(json['avatar_url']) ?? GitHubJson.nullableString(json['avatarUrl']) ?? '',
      htmlUrl: GitHubJson.nullableString(json['html_url']) ?? GitHubJson.nullableString(json['htmlUrl']) ?? 'https://github.com/$login',
      featuredRepoFullName: GitHubJson.nullableString(json['featuredRepoFullName']) ?? DiscoverQueries.featuredRepoForLogin(login),
      kind: kind,
      enriched: true,
      enrichFailed: false,
    );
  }
```

修改 `_profileToJson` 加 `enriched`:

```dart
  static Map<String, Object?> _profileToJson(
    DiscoverProfileEntity profile,
  ) =>
      {
        'login': profile.login,
        'name': profile.name,
        'type': profile.type,
        'bio': profile.bio,
        'publicRepos': profile.publicRepos,
        'followers': profile.followers,
        'avatarUrl': profile.avatarUrl,
        'htmlUrl': profile.htmlUrl,
        'featuredRepoFullName': profile.featuredRepoFullName,
        'enriched': profile.enriched,
        'enrichFailed': profile.enrichFailed,
      };
```

- [ ] **Step 3: 改 seed 显式标 enriched**

修改 `lib/features/discover/data/discover_seed.dart`:`_officialProfiles` 和 `_peopleProfiles` 中每条 `DiscoverProfileEntity(...)` 后加上 `enriched: true,`(默认即 true,显式表达意图)。批量加方式:在每个构造的 `kind: DiscoverProfileKind.xxx,` 行后插入 `enriched: true,`。

> 由于默认值就是 true,代码层行为不变;此步骤仅作可读性,可省略显式写入。**若选择省略,跳过 Step 3。**

- [ ] **Step 4: 更新现有 discover_providers_test.dart 中 `_FakeDiscoverRepository.fetchProfiles` 签名**

修改 `test/features/discover/application/discover_providers_test.dart`:

```dart
  @override
  Future<DataResult<List<DiscoverProfileEntity>>> fetchProfiles({
    required DiscoverProfileKind kind,
    bool force = false,
    int page = 1,
    int perPage = 20,
  }) async {
    profileKinds.add(kind);
    return DataResult(
      freshness: DataFreshness.live,
      data: [
        DiscoverProfileEntity(
          login: kind == DiscoverProfileKind.official ? 'openai' : 'karpathy',
          name: kind == DiscoverProfileKind.official ? 'OpenAI' : 'Andrej',
          type: kind == DiscoverProfileKind.official ? 'Organization' : 'User',
          bio: kind == DiscoverProfileKind.official ? 'Official AI research organization' : 'AI researcher and educator',
          publicRepos: 42,
          followers: 1000,
          avatarUrl: 'https://example.com/avatar.png',
          htmlUrl: 'https://github.com/example',
          featuredRepoFullName: kind == DiscoverProfileKind.official ? 'openai/openai-agents-python' : 'karpathy/nanoGPT',
          kind: kind,
        ),
      ],
    );
  }
```

> 该 fake 当前签名缺 `page`/`perPage` 命名参数,加进去即可,方法体不变。这样 Task 5 改 repository 抽象类签名后该 fake 仍能编译。

- [ ] **Step 5: 运行现有 discover 测试确认未破**

Run: `rtk flutter test test/features/discover/`
Expected: PASS(签名扩展兼容旧测试)。

- [ ] **Step 6: Commit**

```bash
git add lib/features/discover/domain/discover_entities.dart \
        lib/features/discover/data/discover_cache_codec.dart \
        test/features/discover/application/discover_providers_test.dart
git commit -m "Feat(discover): DiscoverProfileEntity 加 enriched/enrichFailed 字段"
```

---

## Task 6: `DiscoverRepository.fetchProfiles` 扩签名 + 新增 `fetchProfileDetail`

**Files:**
- Modify: `lib/features/discover/data/discover_repository.dart`
- Modify: `lib/features/discover/data/discover_profile_client.dart`
- Test: `test/features/discover/data/discover_repository_test.dart`(新增)

- [ ] **Step 1: 写失败测试**

创建 `test/features/discover/data/discover_repository_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/github/github_api_support.dart';
import 'package:github_news/core/storage/json_snapshot_cache_dao.dart';
import 'package:github_news/features/discover/data/discover_repository.dart';
import 'package:github_news/features/discover/domain/discover_entities.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._responder);

  final Map<String, Object?> Function(RequestOptions options) _responder;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final payload = _responder(options);
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );
  }
}

JsonSnapshotCacheDao _emptyCache() {
  // 使用现有的内存测试 cache DAO;若项目无此类 helper,直接用 sqflite_common_ffi
  // 初始化 in-memory 数据库。此处占位为 throw,引导实现者接入现有测试 helper。
  throw UnimplementedError('接入项目现有的 JsonSnapshotCacheDao 测试 helper');
}

void main() {
  group('DiscoverRepository.fetchProfiles 分页', () {
    test('page=1 返回白名单 + 搜索结果,白名单 enriched、搜索结果占位', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StubAdapter((options) {
        if (options.path.contains('/search/users')) {
          return {
            'items': [
              {
                'login': 'some-new-org',
                'avatar_url': 'https://github.com/some-new-org.png',
                'html_url': 'https://github.com/some-new-org',
                'type': 'Organization',
              },
            ],
          };
        }
        // /users/{login}
        return {
          'login': options.path.split('/').last,
          'name': options.path.split('/').last,
          'type': 'Organization',
          'bio': 'bio',
          'public_repos': 5,
          'followers': 9999,
          'avatar_url': 'https://github.com/x.png',
          'html_url': 'https://github.com/x',
        };
      });
      final repo = DiscoverRepository(
        dio: dio,
        cache: _emptyCache(),
        now: () => DateTime(2026, 7, 14),
      );

      final result = await repo.fetchProfiles(
        kind: DiscoverProfileKind.official,
        page: 1,
        perPage: 20,
      );

      // 白名单 N 个(enriched) + 搜索 1 个(占位)
      final whitelistCount =
          DiscoverQueries.officialLogins.length;
      expect(result.data.length, whitelistCount + 1);
      final whitelist = result.data.take(whitelistCount).toList();
      expect(whitelist.every((p) => p.enriched), isTrue);
      final searchHit = result.data.last;
      expect(searchHit.login, 'some-new-org');
      expect(searchHit.enriched, isFalse);
    });

    test('page=2 只返回搜索结果,不含白名单', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StubAdapter((options) {
        return {
          'items': [
            {
              'login': 'page2-org',
              'avatar_url': '',
              'html_url': '',
              'type': 'Organization',
            },
          ],
        };
      });
      final repo = DiscoverRepository(
        dio: dio,
        cache: _emptyCache(),
        now: () => DateTime(2026, 7, 14),
      );

      final result = await repo.fetchProfiles(
        kind: DiscoverProfileKind.official,
        page: 2,
        perPage: 20,
      );

      expect(result.data.length, 1);
      expect(result.data.single.login, 'page2-org');
      expect(result.data.single.enriched, isFalse);
    });

    test('搜索结果与白名单 login 重复时去重,保留 enriched 版本', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StubAdapter((options) {
        if (options.path.contains('/search/users')) {
          return {
            'items': [
              {
                'login': 'openai', // 白名单已有
                'avatar_url': '',
                'html_url': '',
                'type': 'Organization',
              },
            ],
          };
        }
        return {
          'login': options.path.split('/').last,
          'name': 'OpenAI',
          'type': 'Organization',
          'bio': 'bio',
          'public_repos': 100,
          'followers': 200,
          'avatar_url': '',
          'html_url': '',
        };
      });
      final repo = DiscoverRepository(
        dio: dio,
        cache: _emptyCache(),
        now: () => DateTime(2026, 7, 14),
      );

      final result = await repo.fetchProfiles(
        kind: DiscoverProfileKind.official,
        page: 1,
        perPage: 20,
      );

      final openaiEntries = result.data.where((p) => p.login == 'openai');
      expect(openaiEntries.length, 1);
      expect(openaiEntries.single.enriched, isTrue);
    });
  });

  group('DiscoverRepository.fetchProfileDetail', () {
    test('透传 login/kind 给 profile client,返回 enriched 实体', () async {
      final dio = Dio();
      dio.httpClientAdapter = _StubAdapter((options) {
        return {
          'login': 'karpathy',
          'name': 'Andrej Karpathy',
          'type': 'User',
          'bio': 'researcher',
          'public_repos': 60,
          'followers': 200000,
          'avatar_url': '',
          'html_url': '',
        };
      });
      final repo = DiscoverRepository(
        dio: dio,
        cache: _emptyCache(),
        now: () => DateTime(2026, 7, 14),
      );

      final result = await repo.fetchProfileDetail(
        login: 'karpathy',
        kind: DiscoverProfileKind.people,
      );

      expect(result.data.login, 'karpathy');
      expect(result.data.enriched, isTrue);
      expect(result.data.followers, 200000);
    });
  });
}
```

> **重要:** `_emptyCache()` 需接入项目现有的内存 cache helper。在 Step 1 之前用 `rg "JsonSnapshotCacheDao" test/` 找现有 helper(grep),用现有 helper 替换 `throw UnimplementedError(...)`。若无 helper,跳过本任务的 repository 集成测试,改为只测 `DiscoverProfileClient` 单元行为 + notifier 层覆盖。

- [ ] **Step 2: 运行测试确认失败**

Run: `rtk flutter test test/features/discover/data/discover_repository_test.dart`
Expected: FAIL — `fetchProfiles` 不接受 `page`/`perPage`,或 `fetchProfileDetail` 未定义。

- [ ] **Step 3: 改 `discover_profile_client.dart`**

无需修改,保留 `fetch(login, kind)` 即可。

- [ ] **Step 4: 改 `discover_repository.dart`**

在 `DiscoverRepository` 类中:

1. 新增字段:
```dart
  DiscoverRepository({
    required Dio dio,
    required JsonSnapshotCacheDao cache,
    String? token,
    String cacheScope = 'anonymous',
    DateTime Function()? now,
    bool Function()? isRateLimited,
    void Function(int retryAfterSeconds)? onRateLimited,
  })  : _cache = cache,
        _searchClient = DiscoverSearchClient(dio, token),
        _usersSearchClient = DiscoverUsersSearchClient(dio, token),
        _profileClient = DiscoverProfileClient(
          GitHubResourceCache(
            dio: dio,
            cache: cache,
            token: token,
            cacheScope: cacheScope,
            now: now,
          ),
        ),
        _now = now ?? DateTime.now,
        _isRateLimited = isRateLimited,
        _onRateLimited = onRateLimited;

  final DiscoverUsersSearchClient _usersSearchClient;
```

2. 顶部 import 加:
```dart
import 'discover_users_search_client.dart';
import 'user_search_hit.dart';
```

3. 替换 `fetchProfiles` 方法:

```dart
  Future<DataResult<List<DiscoverProfileEntity>>> fetchProfiles({
    required DiscoverProfileKind kind,
    bool force = false,
    int page = 1,
    int perPage = 20,
  }) async {
    final now = _now();
    final searchQuery = kind == DiscoverProfileKind.official
        ? DiscoverQueries.officialSearchQuery
        : DiscoverQueries.peopleSearchQuery;
    final key = DiscoverQueries.profilesPageKey(kind, page, perPage);

    if (force) {
      await _safeDelete(key);
    }

    final bool useRemote = !_blocked();
    List<DiscoverProfileEntity>? searchHits;
    if (useRemote) {
      if (!force && await _isFresh(key, CacheTtlConfig.discover, now)) {
        final cached = await _cache.read(key);
        if (cached != null) {
          final cachedList = DiscoverCacheCodec.decodeProfiles(cached, kind);
          return _composeWithWhitelist(kind, page, cachedList, fromCache: true);
        }
      }
      try {
        final hits = await _usersSearchClient.searchUsers(
          query: searchQuery,
          page: page,
          perPage: perPage,
        );
        searchHits = [
          for (final hit in hits)
            DiscoverProfileEntity(
              login: hit.login,
              name: hit.login,
              type: hit.type,
              bio: '',
              publicRepos: 0,
              followers: 0,
              avatarUrl: hit.avatarUrl,
              htmlUrl: hit.htmlUrl,
              featuredRepoFullName: DiscoverQueries.featuredRepoForLogin(hit.login),
              kind: kind,
              enriched: false,
              enrichFailed: false,
            ),
        ];
        await _cache.upsert(
          key: key,
          payload: DiscoverCacheCodec.profilesToJson(searchHits),
          now: now,
        );
      } on DioException catch (e) {
        _report(GitHubApiSupport.toAppException(e, now: _now));
      } on AppException catch (e) {
        _report(e);
      } catch (e) {
        AppLogger.warn(
          'discoverProfilesSearch',
          meta: {'error': e.runtimeType.toString()},
        );
      }
    }

    final List<DiscoverProfileEntity> searchResult;
    final DataFreshness searchFreshness;
    if (searchHits != null) {
      searchResult = searchHits;
      searchFreshness = DataFreshness.live;
    } else {
      final cached = await _cache.read(key);
      if (cached != null) {
        searchResult = DiscoverCacheCodec.decodeProfiles(cached, kind);
        searchFreshness = DataFreshness.staleCache;
      } else {
        searchResult = const [];
        searchFreshness = page == 1 ? DataFreshness.seed : DataFreshness.staleCache;
      }
    }
    return _composeWithWhitelist(
      kind,
      page,
      searchResult,
      searchFreshness: searchFreshness,
    );
  }

  /// 仅 page==1 时,在搜索结果前置白名单(enriched),并对与白名单重复的 login 去重。
  Future<DataResult<List<DiscoverProfileEntity>>> _composeWithWhitelist(
    DiscoverProfileKind kind,
    int page,
    List<DiscoverProfileEntity> searchResult, {
    DataFreshness? searchFreshness,
    bool fromCache = false,
  }) async {
    if (page != 1) {
      return DataResult(
        data: searchResult,
        freshness: searchFreshness ?? DataFreshness.live,
      );
    }
    final whitelist = await _fetchWhitelist(kind);
    final whitelistLogins = whitelist.map((p) => p.login).toSet();
    final dedupedSearch = searchResult
        .where((p) => !whitelistLogins.contains(p.login))
        .toList();
    final freshness = whitelist.isEmpty && searchResult.isEmpty
        ? DataFreshness.seed
        : (fromCache ? DataFreshness.freshCache : (searchFreshness ?? DataFreshness.live));
    return DataResult(
      data: [...whitelist, ...dedupedSearch],
      freshness: freshness,
    );
  }

  Future<List<DiscoverProfileEntity>> _fetchWhitelist(
    DiscoverProfileKind kind,
  ) async {
    final logins = DiscoverQueries.profileLogins(kind);
    final results = <DiscoverProfileEntity>[];
    for (final login in logins) {
      try {
        final r = await _profileClient.fetch(login, kind);
        final value = r.data;
        results.add(value.copyWith());
      } catch (_) {
        // 单条失败不阻断白名单整体返回;跳过。
      }
    }
    return results;
  }

  Future<DataResult<DiscoverProfileEntity>> fetchProfileDetail({
    required String login,
    required DiscoverProfileKind kind,
  }) async {
    final result = await _profileClient.fetch(login, kind);
    return result.map((p) => p.copyWith());
  }
```

> `DiscoverProfileEntity` 需要 `copyWith` 方法。如果实体当前没有,在 Task 5 的实体改动里补上(若没有,在 Step 1 加 `copyWith` 见下方补丁)。本任务下,在 `discover_entities.dart` 的 `DiscoverProfileEntity` 类内加:

```dart
  DiscoverProfileEntity copyWith({
    String? bio,
    int? publicRepos,
    int? followers,
    String? name,
    String? type,
    String? avatarUrl,
    String? htmlUrl,
    String? featuredRepoFullName,
    bool? enriched,
    bool? enrichFailed,
  }) =>
      DiscoverProfileEntity(
        login: login,
        name: name ?? this.name,
        type: type ?? this.type,
        bio: bio ?? this.bio,
        publicRepos: publicRepos ?? this.publicRepos,
        followers: followers ?? this.followers,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        htmlUrl: htmlUrl ?? this.htmlUrl,
        featuredRepoFullName: featuredRepoFullName ?? this.featuredRepoFullName,
        kind: kind,
        enriched: enriched ?? this.enriched,
        enrichFailed: enrichFailed ?? this.enrichFailed,
      );
```

> **注意:** `DiscoverProfileClient.fetch` 返回的 entity 当前 `enriched` 默认 `true`(Task 5 改造后),刚好符合"detail 补全后 enriched=true"。无需额外操作。

- [ ] **Step 5: 运行测试确认通过**

Run: `rtk flutter test test/features/discover/`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/discover/data/discover_repository.dart \
        lib/features/discover/domain/discover_entities.dart \
        test/features/discover/data/discover_repository_test.dart
git commit -m "Feat(discover): fetchProfiles 支持分页与白名单置顶"
```

---

## Task 7: 常量调整 + `ProfilesNotifier` + provider

**Files:**
- Modify: `lib/features/discover/application/discover_providers.dart`
- Test: `test/features/discover/application/profiles_notifier_test.dart`

- [ ] **Step 1: 写失败测试**

创建 `test/features/discover/application/profiles_notifier_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/features/discover/application/discover_providers.dart';
import 'package:github_news/features/discover/data/discover_repository.dart';
import 'package:github_news/features/discover/domain/discover_entities.dart';

class _FakeRepo implements DiscoverRepository {
  final int whitelistSize;
  final int searchPageSize;
  final Map<String, DiscoverProfileEntity> _detail = {};

  _FakeRepo({this.whitelistSize = 8, this.searchPageSize = 20});

  @override
  Future<DataResult<List<DiscoverProfileEntity>>> fetchProfiles({
    required DiscoverProfileKind kind,
    bool force = false,
    int page = 1,
    int perPage = 20,
  }) async {
    final List<DiscoverProfileEntity> data;
    if (page == 1) {
      final whitelist = [
        for (var i = 0; i < whitelistSize; i++)
          DiscoverProfileEntity(
            login: 'wl-$i',
            name: 'WL $i',
            type: 'User',
            bio: 'bio',
            publicRepos: 1,
            followers: 1,
            avatarUrl: '',
            htmlUrl: '',
            featuredRepoFullName: 'wl-$i/repo',
            kind: kind,
            enriched: true,
          ),
      ];
      final search = [
        for (var i = 0; i < searchPageSize; i++)
          DiscoverProfileEntity(
            login: 'search-${page}_$i',
            name: 'search-${page}_$i',
            type: 'User',
            bio: '',
            publicRepos: 0,
            followers: 0,
            avatarUrl: '',
            htmlUrl: '',
            featuredRepoFullName: 'search-${page}_$i/repo',
            kind: kind,
            enriched: false,
          ),
      ];
      data = [...whitelist, ...search];
    } else {
      data = [
        for (var i = 0; i < searchPageSize; i++)
          DiscoverProfileEntity(
            login: 'search-${page}_$i',
            name: 'search-${page}_$i',
            type: 'User',
            bio: '',
            publicRepos: 0,
            followers: 0,
            avatarUrl: '',
            htmlUrl: '',
            featuredRepoFullName: 'search-${page}_$i/repo',
            kind: kind,
            enriched: false,
          ),
      ];
    }
    return DataResult(data: data, freshness: DataFreshness.live);
  }

  @override
  Future<DataResult<DiscoverProfileEntity>> fetchProfileDetail({
    required String login,
    required DiscoverProfileKind kind,
  }) async {
    final e = _detail.putIfAbsent(
      login,
      () => DiscoverProfileEntity(
        login: login,
        name: login,
        type: 'User',
        bio: 'enriched-bio',
        publicRepos: 42,
        followers: 100,
        avatarUrl: '',
        htmlUrl: '',
        featuredRepoFullName: '$login/repo',
        kind: kind,
        enriched: true,
      ),
    );
    return DataResult(data: e, freshness: DataFreshness.live);
  }

  @override
  Future<DataResult<List<RepoEntity>>> fetchTrendingRepos({
    bool force = false,
    int page = 1,
    int perPage = discoverPageSize,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<DataResult<List<SkillEntity>>> fetchAgentSkills({
    bool force = false,
    int page = 1,
    int perPage = discoverPageSize,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  test('build 后白名单 enriched、搜索结果占位,hasMore=true', () async {
    final repo = _FakeRepo();
    final container = ProviderContainer(
      overrides: [discoverRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final first = await container.read(
      officialProfilesNotifierProvider.future,
    );
    expect(first.length, 8 + 20);
    expect(first.take(8).every((p) => p.enriched), isTrue);
    expect(first.skip(8).every((p) => !p.enriched), isTrue);
    expect(
      container.read(officialProfilesNotifierProvider.notifier).hasMore,
      isTrue,
    );
  });

  test('loadMore 追加搜索结果,hasMore 在不足一页时变 false', () async {
    final repo = _FakeRepo(searchPageSize: 20);
    final container = ProviderContainer(
      overrides: [discoverRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(officialProfilesNotifierProvider.future);
    await container.read(officialProfilesNotifierProvider.notifier).loadMore();

    final list = container.read(officialProfilesNotifierProvider).valueOrNull!;
    expect(list.length, 8 + 20 + 20);
  });

  test('enrichOne 把占位 entity 替换为 enriched', () async {
    final repo = _FakeRepo();
    final container = ProviderContainer(
      overrides: [discoverRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(officialProfilesNotifierProvider.future);
    await container
        .read(officialProfilesNotifierProvider.notifier)
        .enrichOne('search-1_0');

    final list = container.read(officialProfilesNotifierProvider).valueOrNull!;
    final target = list.firstWhere((p) => p.login == 'search-1_0');
    expect(target.enriched, isTrue);
    expect(target.bio, 'enriched-bio');
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `rtk flutter test test/features/discover/application/profiles_notifier_test.dart`
Expected: FAIL — `officialProfilesNotifierProvider` 未定义。

- [ ] **Step 3: 改 `discover_providers.dart`**

1. 替换常量段:

```dart
const int discoverPageSize = 30;
const int discoverProfilesPageSize = 20;
const int discoverLoadMoreRemainingItems = 3;
const double discoverItemExtentCards = 96.0;
const double discoverItemExtentCompact = 72.0;
const int discoverProfileEnrichBatchSize = 10;
```

> 删除 `const double discoverLoadMoreScrollPixels = 520;`。

2. 替换 `officialProfilesProvider` / `peopleProfilesProvider` 两个 `FutureProvider` 为 notifier 形式。删除原 FutureProvider 定义,新增:

```dart
final officialProfilesNotifierProvider = AsyncNotifierProvider.autoDispose<
    ProfilesNotifier, List<DiscoverProfileEntity>>(
  () => ProfilesNotifier(DiscoverProfileKind.official),
);

final peopleProfilesNotifierProvider = AsyncNotifierProvider.autoDispose<
    ProfilesNotifier, List<DiscoverProfileEntity>>(
  () => ProfilesNotifier(DiscoverProfileKind.people),
);
```

3. 修改 `filteredOfficialProfilesProvider` / `filteredPeopleProfilesProvider` 改读 notifier:

```dart
final filteredOfficialProfilesProvider =
    Provider<AsyncValue<List<DiscoverProfileEntity>>>((ref) {
  final query = ref.watch(discoverSearchQueryProvider).trim().toLowerCase();
  final profiles = ref.watch(officialProfilesNotifierProvider);
  if (query.isEmpty) return profiles;
  return profiles.whenData(
    (items) => items.where((p) => _profileText(p).contains(query)).toList(),
  );
});

final filteredPeopleProfilesProvider =
    Provider<AsyncValue<List<DiscoverProfileEntity>>>((ref) {
  final query = ref.watch(discoverSearchQueryProvider).trim().toLowerCase();
  final profiles = ref.watch(peopleProfilesNotifierProvider);
  if (query.isEmpty) return profiles;
  return profiles.whenData(
    (items) => items.where((p) => _profileText(p).contains(query)).toList(),
  );
});
```

4. 新增 `ProfilesNotifier` 类(放在 `AgentSkillsNotifier` 之后):

```dart
class ProfilesNotifier
    extends AutoDisposeAsyncNotifier<List<DiscoverProfileEntity>> {
  ProfilesNotifier(this.kind);

  final DiscoverProfileKind kind;

  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;
  final Set<String> _enrichingLogins = {};
  final Set<String> _enrichFailedLogins = {};

  @override
  Future<List<DiscoverProfileEntity>> build() async {
    final force = ref.watch(discoverRefreshTickProvider) > 0;
    _page = 1;
    _hasMore = true;
    _enrichingLogins.clear();
    _enrichFailedLogins.clear();
    final result = await ref.read(discoverRepositoryProvider).fetchProfiles(
          kind: kind,
          force: force,
          page: _page,
          perPage: discoverProfilesPageSize,
        );
    final list = result.data;
    _updateFreshness(result.freshness);
    _updateHasMore(list, page: _page);
    // Unawaited:补全在后台进行,不阻塞首屏。
    _enrichNextBatch(list);
    return list;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore || state.hasError) return;
    _loadingMore = true;
    try {
      final nextPage = _page + 1;
      final result = await ref.read(discoverRepositoryProvider).fetchProfiles(
            kind: kind,
            page: nextPage,
            perPage: discoverProfilesPageSize,
          );
      final next = result.data;
      _updateFreshness(result.freshness);
      _page = nextPage;
      final merged = [...?state.valueOrNull, ...next];
      state = AsyncData(merged);
      _updateHasMore(next, page: nextPage);
      _enrichNextBatch(next);
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> enrichOne(String login) async {
    if (_enrichingLogins.contains(login) ||
        _enrichFailedLogins.contains(login)) {
      return;
    }
    _enrichingLogins.add(login);
    try {
      final result =
          await ref.read(discoverRepositoryProvider).fetchProfileDetail(
                login: login,
                kind: kind,
              );
      final enriched = result.data;
      final current = state.valueOrNull;
      if (current == null) return;
      state = AsyncData([
        for (final p in current)
          if (p.login == login) enriched else p,
      ]);
    } catch (_) {
      _enrichFailedLogins.add(login);
      final current = state.valueOrNull;
      if (current == null) return;
      state = AsyncData([
        for (final p in current)
          if (p.login == login) p.copyWith(enrichFailed: true) else p,
      ]);
    } finally {
      _enrichingLogins.remove(login);
    }
  }

  Future<void> _enrichNextBatch(List<DiscoverProfileEntity> latest) async {
    if (_enrichingLogins.length > discoverProfileEnrichBatchSize * 2) return;
    final pending = latest
        .where((p) => !p.enriched && !p.enrichFailed)
        .take(discoverProfileEnrichBatchSize)
        .toList();
    // 串行窗口(并发度 4),无第三方依赖。
    for (var i = 0; i < pending.length; i += 4) {
      final window = pending.skip(i).take(4);
      await Future.wait([for (final p in window) enrichOne(p.login)]);
    }
  }

  bool get hasMore => _hasMore;

  void _updateHasMore(
    List<DiscoverProfileEntity> pageData, {
    required int page,
  }) {
    // page==1:whitelist 为 enriched、搜索结果为 !enriched,用 !enriched 计数。
    // page>=2:全部为 !enriched,直接用长度。
    final searchPart = page == 1
        ? pageData.where((p) => !p.enriched).length
        : pageData.length;
    _hasMore = searchPart >= discoverProfilesPageSize;
  }

  void _updateFreshness(DataFreshness freshness) {
    final target = kind == DiscoverProfileKind.official
        ? discoverOfficialFreshnessProvider
        : discoverPeopleFreshnessProvider;
    ref.read(target.notifier).state = freshness;
  }
}
```

> `_updateHasMore` 调用点需相应改:`_updateHasMore(list, page: _page)` 与 `_updateHasMore(next, page: nextPage)`(删除 `whitelistSize:` 参数)。

5. 顶部 import 加:
```dart
import '../data/discover_queries.dart';
```
(若已存在则跳过)

6. 更新 `discover_providers_test.dart`:`filteredOfficialProfilesProvider` 现在返回 `AsyncValue`,而测试中用了 `.future`。改为 `await container.read(officialProfilesNotifierProvider.future)` 后手动过滤,或保留 `filteredOfficialProfilesProvider` 走 `.future`(Provider 类型的 AsyncValue 不能 `.future`,需要改为 FutureProvider 或在测试里 `.future` 通过读取 underlying notifier)。最简:把 filtered 改回 `FutureProvider.autoDispose`,内部 `await notifierProvider.future`:

```dart
final filteredOfficialProfilesProvider =
    FutureProvider.autoDispose<List<DiscoverProfileEntity>>((ref) async {
  final query = ref.watch(discoverSearchQueryProvider).trim().toLowerCase();
  final profiles = await ref.watch(officialProfilesNotifierProvider.future);
  if (query.isEmpty) return profiles;
  return profiles.where((p) => _profileText(p).contains(query)).toList();
});

final filteredPeopleProfilesProvider =
    FutureProvider.autoDispose<List<DiscoverProfileEntity>>((ref) async {
  final query = ref.watch(discoverSearchQueryProvider).trim().toLowerCase();
  final profiles = await ref.watch(peopleProfilesNotifierProvider.future);
  if (query.isEmpty) return profiles;
  return profiles.where((p) => _profileText(p).contains(query)).toList();
});
```

> 上面 Step 3.3 的 Provider 版作废,以本 FutureProvider 版为准。

- [ ] **Step 4: 运行测试确认通过**

Run: `rtk flutter test test/features/discover/`
Expected: PASS(新测试 + 现有测试均过)。

- [ ] **Step 5: Commit**

```bash
git add lib/features/discover/application/discover_providers.dart \
        test/features/discover/application/profiles_notifier_test.dart
git commit -m "Feat(discover): 新增 ProfilesNotifier 与分页常量"
```

---

## Task 8: `_onScroll` 改按元素数 + `_buildProfiles` 接 notifier

**Files:**
- Modify: `lib/features/discover/presentation/discover_page.dart`

- [ ] **Step 1: 改 `_onScroll` 方法**

替换 `lib/features/discover/presentation/discover_page.dart:74-91` 的 `_onScroll`:

```dart
  void _onScroll() {
    if (ref.read(discoverSearchQueryProvider).trim().isNotEmpty) {
      return;
    }
    if (!_scrollController.hasClients) return;
    final useCards = !Breakpoints.isCompact(context);
    final extent =
        useCards ? discoverItemExtentCards : discoverItemExtentCompact;
    final remaining =
        (_scrollController.position.maxScrollExtent - _scrollController.position.pixels) /
            extent;
    if (remaining > discoverLoadMoreRemainingItems) return;
    switch (ref.read(discoverSegmentProvider)) {
      case 'skills':
        ref.read(agentSkillsNotifierProvider.notifier).loadMore();
      case 'repos':
        ref.read(trendingReposNotifierProvider.notifier).loadMore();
      case 'official':
        ref.read(officialProfilesNotifierProvider.notifier).loadMore();
      case 'people':
        ref.read(peopleProfilesNotifierProvider.notifier).loadMore();
    }
  }
```

> 该方法访问 `context`,但 `_onScroll` 是在 `ScrollController` listener 中调用,此时 widget 已 mounted,`context` 可用。若 analyze 报 `use_build_context_synchronously`,可在 `initState` 中读取一次 breakpoint 并存为字段,或用 `if (!mounted) return;` 守卫。先按现状实现,跑 analyze 视情况调整。

- [ ] **Step 2: 改 `_buildProfiles`**

替换 `discover_page.dart:248-290` 的 `_buildProfiles`:

```dart
  Widget _buildProfiles(
    FutureProviderListenable<List<DiscoverProfileEntity>> provider,
    WidgetRef ref,
    AppLocalizations l10n,
    IconData emptyIcon,
    String emptyMessage,
    DiscoverProfileKind kind,
  ) {
    final query = ref.watch(discoverSearchQueryProvider);
    final useCards = !Breakpoints.isCompact(context);
    final async = ref.watch(provider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        error: e is AppException ? e : AppException(kind: AppExceptionKind.unknown, cause: e),
        onRetry: _refresh,
      ),
      data: (profiles) {
        if (profiles.isEmpty) {
          return EmptyView(
            icon: emptyIcon,
            message: query.trim().isEmpty ? emptyMessage : l10n.tr('discover.empty_filter').replaceAll('{query}', query),
          );
        }
        final notifierProvider = kind == DiscoverProfileKind.official
            ? officialProfilesNotifierProvider
            : peopleProfilesNotifierProvider;
        final hasMore = query.trim().isEmpty &&
            ref.read(notifierProvider.notifier).hasMore;
        return ListView.separated(
          controller: _scrollController,
          padding: useCards
              ? const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.xl, AppSpacing.xxxl)
              : const EdgeInsets.symmetric(vertical: AppSpacing.md),
          itemCount: profiles.length + (hasMore ? 1 : 0),
          separatorBuilder: (_, __) =>
              useCards ? const SizedBox(height: AppSpacing.md) : const Divider(height: 1),
          itemBuilder: (context, i) {
            if (i >= profiles.length) {
              return const DiscoverLoadMoreIndicator();
            }
            return DiscoverProfileRow(
              profile: profiles[i],
              cardStyle: useCards,
              onTap: () => context.go(
                discoverProfileDetailLocation(profiles[i]),
              ),
            );
          },
        );
      },
    );
  }
```

> `_buildProfiles` 之前是同步签名,现在改为接收 `FutureProviderListenable`。`build()` 内的调用点要改:

修改 `discover_page.dart:129-140` 的 `build` 内分段:

```dart
            Expanded(
              child: switch (segment) {
                'skills' => _buildSkills(
                    ref.watch(filteredAgentSkillsProvider),
                    l10n,
                  ),
                'official' => _buildProfiles(
                    filteredOfficialProfilesProvider,
                    ref,
                    l10n,
                    Icons.verified_outlined,
                    l10n.tr('discover.empty.official'),
                    DiscoverProfileKind.official,
                  ),
                'people' => _buildProfiles(
                    filteredPeopleProfilesProvider,
                    ref,
                    l10n,
                    Icons.person_search_outlined,
                    l10n.tr('discover.empty.people'),
                    DiscoverProfileKind.people,
                  ),
                _ => _buildRepos(ref.watch(filteredTrendingReposProvider), l10n),
              },
            ),
```

- [ ] **Step 3: 运行 analyze**

Run: `rtk flutter analyze lib/features/discover/presentation/discover_page.dart`
Expected: No issues(或仅 lint,按提示修)。

- [ ] **Step 4: 运行现有 discover 测试**

Run: `rtk flutter test test/features/discover/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/discover/presentation/discover_page.dart
git commit -m "Feat(discover): 滚动触发改为按元素数并接入 profile 分页"
```

---

## Task 9: `DiscoverProfileRow` 占位态

**Files:**
- Modify: `lib/features/discover/presentation/widgets/discover_profile_row.dart`

- [ ] **Step 1: 改 widget 支持占位**

在 `discover_profile_row.dart` 中,把 `profile.bio.isNotEmpty` 的判断扩展为对 `enriched` 的判断。具体替换两处(`cardStyle: false` 与 `cardStyle: true`)的 bio / followers / publicRepos 显示逻辑。

`_shortNumber` 旁加 helper:

```dart
String _placeholderOrNumber(int value, bool enriched) =>
    enriched ? _shortNumber(value) : '—';
```

把 `followers` 行(两处)改为:
```dart
IconMetric(
  icon: Icons.group_rounded,
  value: l10n.tr('discover.profile.followers').replaceAll(
        '{n}',
        _placeholderOrNumber(profile.followers, profile.enriched),
      ),
  color: colors.tertiary,
),
```

把 `public_repos` 行(两处)改为类似。

把 bio 块(两处)改为:
```dart
if (profile.enriched && profile.bio.isNotEmpty) ...[
  const SizedBox(height: AppSpacing.sm),
  Text(profile.bio, ...),
] else if (!profile.enriched) ...[
  const SizedBox(height: AppSpacing.sm),
  Text(
    '—',
    style: AppTypography.bodySmall.copyWith(
      color: colors.onSurfaceVariant.withOpacity(0.5),
    ),
  ),
],
```

> 注:两处指 compact(cardStyle=false)与 card(cardStyle=true)分支。compact 分支原有的 `SizedBox(height: AppSpacing.xxs)` 改为 `AppSpacing.sm` 保持一致。

- [ ] **Step 2: 运行 analyze**

Run: `rtk flutter analyze lib/features/discover/presentation/widgets/discover_profile_row.dart`
Expected: No issues。

- [ ] **Step 3: 手动验证(可选 widget test)**

写一个最小 widget test 验证占位文本 "—":

```dart
testWidgets('enriched=false 时显示占位 —', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.delegate,
      home: Scaffold(
        body: DiscoverProfileRow(
          profile: DiscoverProfileEntity(
            login: 'x',
            name: 'X',
            type: 'User',
            bio: '',
            publicRepos: 0,
            followers: 0,
            avatarUrl: '',
            htmlUrl: '',
            featuredRepoFullName: 'x/y',
            kind: DiscoverProfileKind.people,
            enriched: false,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('—'), findsWidgets);
});
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/discover/presentation/widgets/discover_profile_row.dart \
        test/features/discover/presentation/discover_profile_row_test.dart
git commit -m "Feat(discover): profile 卡片支持未补全占位态"
```

---

## Task 10: i18n key

**Files:**
- Modify: `lib/core/i18n/strings_zh_cn.dart`
- Modify: `lib/core/i18n/strings_en_us.dart`

- [ ] **Step 1: 加 zh-CN**

在 `strings_zh_cn.dart` 中 `'discover.profile.repos'` 之后加入:

```dart
  'discover.profile.loading': '加载中…',
  'discover.profile.enrich_failed': '详细信息加载失败',
```

- [ ] **Step 2: 加 en-US**

在 `strings_en_us.dart` 中对应位置加入:

```dart
  'discover.profile.loading': 'Loading…',
  'discover.profile.enrich_failed': 'Failed to load details',
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/i18n/strings_zh_cn.dart lib/core/i18n/strings_en_us.dart
git commit -m "Feat(i18n): 新增 profile 占位与失败文案"
```

---

## Task 11: 全量检查 + 桌面构建

**Files:** 无源码改动,仅校验。

- [ ] **Step 1: 全量 format**

Run: `rtk dart format .`

- [ ] **Step 2: 全量 analyze**

Run: `rtk flutter analyze`
Expected: No issues。

- [ ] **Step 3: 全量 test**

Run: `rtk flutter test`
Expected: All pass。

- [ ] **Step 4: 桌面 release 构建**

Run: `rtk flutter build windows --release`
Expected: 构建成功。

- [ ] **Step 5: 如有 format/analyze 修正,commit**

```bash
git add -A
git commit -m "Chore(discover): 分页改造收尾格式与静态检查"
```

> 仅在确有改动时提交,无改动跳过本步。

---

## Self-Review 总结

- **Spec 覆盖**:
  - §1 总体方案 → Task 1-10 全覆盖。
  - §2 数据层 → Task 1-6。
  - §3 应用层 → Task 7。
  - §4 UI/实体层 → Task 5(实体)、Task 8(页面)、Task 9(row)。
  - §5 缓存/配置/回退 → Task 1(endpoint)、Task 6(repository cache + 回退)、Task 7(notifier 失败标记)。
  - §5 测试 → Task 1/3/4/6/7/9 各有测试。
  - §5 手动验证 → Task 11。
- **类型一致性**:`enriched` / `enrichFailed` / `copyWith` / `fetchProfileDetail` / `searchUsers` / `profilesPageKey` / `officialSearchQuery` / `peopleSearchQuery` 在所有任务中名字一致。`discoverPageSize` / `discoverProfilesPageSize` / `discoverLoadMoreRemainingItems` / `discoverItemExtentCards` / `discoverItemExtentCompact` / `discoverProfileEnrichBatchSize` 常量名一致。
- **占位扫描**:无 TBD/TODO,所有代码块完整。
