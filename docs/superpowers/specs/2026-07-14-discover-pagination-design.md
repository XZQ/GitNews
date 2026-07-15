# 发现页分页与扩容设计

> 历史快照：本文的分页设计已经在 1.4.0+4 基线中实现，保留作为设计与实现依据，不再是“待实现”的当前任务。当前事实请查看 [产品、数据与系统边界](../../plans/product_ia_data_plan.md) 和 [README](../../../README.md)。

日期:2026-07-14
状态:历史设计,已实现

## 背景与动机

发现页(Discover)当前 4 个分段(`repos` / `skills` / `official` / `people`)每段只展示约 20 条,且:

- `repos` / `skills` 已有分页骨架(`loadMore` / `hasMore` / `DiscoverLoadMoreIndicator`),但每页 20 条偏少,且滚动触发阈值是 520 像素,语义不清晰。
- `skills` 查询条件过窄(`stars:>50` + 严格 topic 白名单),翻几页就空。
- `official` / `people` 使用硬编码 10 个 login 白名单,逐个 `/users/{login}` 拉 profile,本质无分页,内容上限就是 10。

用户需求:四个段都加"滑动距离底部 3 个元素时自动加载"的分页;扩大数据获取量(例如 Top 100 热门仓库);让官方账号/名人也能持续滚动加载。

## 目标

1. 四个分段统一支持无限滚动,按"剩余可见 item ≤ 3"触发 `loadMore`。
2. `repos` / `skills` 每页 30;`official` / `people` 每页 20。
3. `official` / `people` 改为"白名单 10 个置顶 + `/search/users` 搜索结果追加"模式,可无限翻页(受 GitHub 配额约束)。
4. profile 段采用渐进补全:先用 `/search/users` 的最小字段渲染占位卡片,后台并发补全 `/users/{login}` 的完整字段,逐条刷新。

## 非目标

- 不引入 GraphQL 或新 HTTP 客户端。
- 不改其他 feature(trending / monitoring 等)。
- 不动 mobile 布局,仅复用现有 `Breakpoints.isCompact` 判断。
- 不引入新的后端服务或定时任务。

## 总体方案

四个分段数据来源与首屏构成:

| 段 | 数据源 | 首屏构成 | 每页 |
|---|---|---|---|
| repos | `/search/repositories` `q=stars:>1000 sort=stars`(现有) | 搜索首页 | 30 |
| skills | `/search/repositories` 放宽 query(见下) | 搜索首页 | 30 |
| official | 白名单 10 个置顶 + `/search/users` `type:org followers:>5000 ai in:name,bio sort:followers` | 白名单 + 搜索第 1 页 | 20 |
| people | 白名单 10 个置顶 + `/search/users` `type:user followers:>1000 ai in:bio sort:followers` | 白名单 + 搜索第 1 页 | 20 |

`/search/users` 仅返回 `login / avatar_url / html_url / type`,不返回 `bio / followers / public_repos`。因此 profile 段采用渐进补全:

1. `/search/users` 拿到 login 列表 → 立即构造占位 `DiscoverProfileEntity`(`enriched: false`)→ 渲染卡片(bio/followers/repos 显示 "—")。
2. 后台并发(并发度 4)调 `/users/{login}` 补全 → 逐条把占位替换为完整 entity(`enriched: true`),触发 UI 刷新。
3. 失败的 login 标 `enrichFailed: true`,不重试,占位卡片保留。

白名单 10 个 login 始终置顶,首屏即用现有 `/users/{login}` 拉完整数据(不占位),作为"精选"区。

## 数据层

### 新增 `lib/features/discover/data/discover_users_search_client.dart`

- `searchUsers({required String query, required int page, required int perPage})` → `List<UserSearchHit>`。
- `UserSearchHit` 轻值对象:`login / avatarUrl / htmlUrl / type`。
- 调 `ApiEndpointsConfig.githubSearchUsersUrl(...)`。
- 复用 `GitHubApiSupport.headers(token: ...)`。
- 错误处理与 `DiscoverSearchClient` 一致(DioException → AppException)。

### 改动 `lib/features/discover/data/discover_queries.dart`

- 新增:
  - `static const String officialSearchQuery = 'type:org followers:>5000 ai in:name,bio sort:followers';`
  - `static const String peopleSearchQuery = 'type:user followers:>1000 ai in:bio sort:followers';`
- 放宽 skills:
  - `static const String skills = 'topic:agent-skills OR topic:claude-skills OR topic:mcp OR topic:ai-agent OR topic:llm-agent OR topic:mcp-server stars:>10';`
- 保留 `officialLogins` / `peopleLogins`(白名单置顶用)。
- profiles 分页 cache key:
  - `static String profilesPageKey(DiscoverProfileKind kind, int page, int perPage) => 'discover_profiles:${kind.name}:p$page:n$perPage';`
- 现有 `pageKey(base, page, perPage)` 复用给 repos / skills。

### 改动 `lib/features/discover/data/discover_profile_client.dart`

- 保留 `fetch(login, kind)`,作为单条补全入口。

### 改动 `lib/features/discover/data/discover_repository.dart`

`fetchProfiles` 签名扩展:

```
Future<DataResult<List<DiscoverProfileEntity>>> fetchProfiles({
  required DiscoverProfileKind kind,
  bool force = false,
  int page = 1,
  int perPage = 20,
})
```

行为:

- `page == 1`:
  1. 并发拉白名单 10 个 `/users/{login}`(完整数据,`enriched: true`)。
  2. 拉 `/search/users` 第 1 页 20 条 → 构造占位 entity(`enriched: false`)。
  3. 合并返回 30 条。任一远端失败走 cache / seed(白名单 `DiscoverSeed.seedProfiles(kind)` 作为 seed)。
- `page >= 2`:
  - 只拉 `/search/users` 对应页 → 占位 entity。
- 缓存按页存(`profilesPageKey`),fresh / stale / seed 三级回退保留;seed 仅 page=1 时返回白名单。
- `hasMore` 判定由 provider 层完成:比较 `fetchProfiles` 返回的 `result.data.length < perPage`(page=1 时需先扣掉白名单 10 条再比较搜索部分)。repository 不透出额外字段。
- 限流门控 `_blocked()` 触发时跳过远端,走 cache / seed。

`fetchTrendingRepos` / `fetchAgentSkills` 现有实现保留,仅 `perPage` 参数由 provider 层传入新值。

### 新增 repository 方法 `fetchProfileDetail`

```
Future<DataResult<DiscoverProfileEntity>> fetchProfileDetail({
  required String login,
  required DiscoverProfileKind kind,
})
```

走现有 `DiscoverProfileClient.fetch`,供 provider 层渐进补全用。命中 `GitHubResourceCache` 的 ETag/TTL。

## 应用层

### 改动 `lib/features/discover/application/discover_providers.dart`

常量:

- `const int discoverPageSize = 30;`(repos / skills)
- `const int discoverProfilesPageSize = 20;`(official / people)
- 删除 `discoverLoadMoreScrollPixels`。
- 新增:
  - `const int discoverLoadMoreRemainingItems = 3;`
  - `const double discoverItemExtentCards = 96.0;`
  - `const double discoverItemExtentCompact = 72.0;`
  - `const int discoverProfileEnrichBatchSize = 10;`(build / loadMore 后单批补全项数)

新增 `ProfilesNotifier extends AutoDisposeAsyncNotifier<List<DiscoverProfileEntity>>`:

- 字段:`_page`、`_hasMore`、`_loadingMore`、`_enrichingLogins`(Set<String>)、`_enrichFailedLogins`(Set<String>)。
- `build(kind)`:
  1. `_page = 1`。
  2. `fetchProfiles(kind, page: 1, perPage: 20)` → 30 条(白名单 10 enriched + 搜索 20 占位)。
  3. 立即返回列表。
  4. 触发后台补全:对 `enriched == false` 的前 `discoverProfileEnrichBatchSize = 10` 项调 `_enrichOne(login)`。常量固定为 10(覆盖桌面端可见视口),不做动态估算。
- `loadMore()`:
  - `_page++`,`fetchProfiles(kind, page: _page, perPage: 20)` → append 占位。
  - 触发新追加项的前 10 个补全。
  - 若搜索返回 < perPage,`_hasMore = false`。
- `_enrichOne(login)`:
  - 已在 `_enrichingLogins` 或 `_enrichFailedLogins` → 跳过。
  - 加入 `_enrichingLogins`,调 `fetchProfileDetail`。
  - 成功:`state = state.map((p) => p.login == login ? enriched : p).toList()`。
  - 失败:把对应项 `enrichFailed: true`,加入 `_enrichFailedLogins`。
  - finally:从 `_enrichingLogins` 移除。
- `_enrichBatch(logins, concurrency: 4)`:
  - 简单串行窗口并发(无第三方依赖)。
  - 背压:若 `_enrichingLogins.length > 20`,本轮跳过。
- `bool get hasMore => _hasMore;`

新增 provider:

- `officialProfilesNotifierProvider = AsyncNotifierProvider.autoDispose<ProfilesNotifier, List<DiscoverProfileEntity>>(...)` 注入 `kind = official`。
- `peopleProfilesNotifierProvider` 同理。
- 保留 `filteredOfficialProfilesProvider` / `filteredPeopleProfilesProvider` 改读 notifier 版本,本地搜索过滤逻辑不变。
- `discoverOfficialFreshnessProvider` / `discoverPeopleFreshnessProvider` 仍由 notifier 在 build/loadMore 时更新。

`TrendingReposNotifier` / `AgentSkillsNotifier` 保留,仅构造时 `perPage: discoverPageSize`(已是 20 → 改 30)。

`refresh` 流程:`discoverRefreshTickProvider` 自增 → notifier 监听到后重置 `_page = 1`、`_enrichingLogins` 清空、force=true 重拉首页。

## UI 层

### 改动 `lib/features/discover/domain/discover_entities.dart`

`DiscoverProfileEntity` 新增:

- `final bool enriched;`(默认 false)
- `final bool enrichFailed;`(默认 false)

现有 codec / seed 构造点显式补字段:

- `DiscoverCacheCodec.profileFromJson`:`enriched: true, enrichFailed: false`(从缓存读出的视为已补全)。
- `DiscoverSeed._officialProfiles` / `_peopleProfiles`:`enriched: true, enrichFailed: false`。

### 改动 `lib/features/discover/presentation/widgets/discover_profile_row.dart`

- `enriched == false`:
  - `bio` 区显示一行占位灰色 "—"。
  - `followers` / `publicRepos` 显示 "—"。
- `enrichFailed == true`:
  - 保持 "—" 不变(失败与未补全视觉一致,避免噪音),可选在右下角加一个 12px 的 `Icons.error_outline` 灰色图标。
- 不引入新依赖,用 `AnimatedSwitcher` 或直接 `Text` 替换。

### 改动 `lib/features/discover/presentation/discover_page.dart`

`_onScroll`:

```
final extent = useCards
    ? discoverItemExtentCards
    : discoverItemExtentCompact;
final remaining = (_scrollController.position.maxScrollExtent - _scrollController.position.pixels) / extent;
if (remaining > discoverLoadMoreRemainingItems) return;
switch (ref.read(discoverSegmentProvider)) {
  case 'skills': agentSkillsNotifier.loadMore();
  case 'repos': trendingReposNotifier.loadMore();
  case 'official': officialProfilesNotifier.loadMore();
  case 'people': peopleProfilesNotifier.loadMore();
}
```

`useCards` 由 `!Breakpoints.isCompact(context)` 推导,传入判断。

`_buildProfiles`:

- 改读 notifier 版本 provider。
- `ListView.separated` 的 `itemCount = profiles.length + (hasMore ? 1 : 0)`。
- 末尾 `DiscoverLoadMoreIndicator`。
- `hasMore` 读取对应 notifier。

## 缓存与配置

- repos / skills:按页存,Key `discover_trending_repos:p$n:n$m` / `discover_agent_skills:p$n:n$m`。TTL 走 `CacheTtlConfig.discover` / `.skills`。
- profiles 新增按页 Key `discover_profiles:${kind}:p$page:n$perPage`。TTL `CacheTtlConfig.discover`。
- 渐进补全的 `/users/{login}` 走现有 `GitHubResourceCache`(已带 ETag + TTL),不新增缓存。

`lib/core/config/api_endpoints_config.dart` 新增:

- `static const String githubSearchUsersPath = '/search/users';`
- `static String githubSearchUsersUrl({required String q, int perPage = 20, int page = 1})` —— 返回完整 query path(与现有 `githubSearchRepositoriesUrl` 风格一致)。

## 错误处理与降级

- `/search/users` 整体失败:走 cache → cache 无 → 只返回白名单 10 条(seed freshness)。
- 单条 `/users/{login}` 补全失败:标 `enrichFailed: true`,列表保留占位,不阻断其他项。
- 限流门控 `rateLimitGate.isBlocked` 触发时整体跳过远端,走 cache / seed(复用现有 `_blocked()` 逻辑)。
- `/search/users` 返回的 login 与白名单重复时,白名单优先(去重 by login,保留 enriched 版本)。

## i18n

新增 key:

- `discover.profile.loading`:"加载中…"(占位"—"的语义化文案,供屏幕阅读器 `Semantics`)。
- `discover.profile.enrich_failed`:"详细信息加载失败"。

占位视觉仍用 "—" 字符,无需新文案。

## 测试

新增 / 扩展:

- `test/features/discover/data/discover_users_search_client_test.dart`:mock dio,验证 query / headers / 解析 login 列表 / 错误转换。
- `test/features/discover/data/discover_repository_test.dart` 扩展:
  - profiles 首页 = 白名单 10 + 搜索 20。
  - 搜索失败时首页只剩白名单 10 条。
  - profiles page=2 只含搜索结果,不含白名单。
  - `hasMore` 在搜索返回 < perPage 时为 false。
  - login 与白名单重复时去重。
- `test/features/discover/application/profiles_notifier_test.dart`(新增):
  - build 后首屏 30 条(10 enriched + 20 占位)。
  - `_enrichOne` 成功后 state 对应项变为 enriched。
  - `_enrichOne` 失败后对应项 `enrichFailed: true`,不重试。
  - 并发补全不重复(同一 login 不会进两次 `_enrichingLogins`)。
  - loadMore 追加占位,触发补全。
- 现有 widget 测试扩展:验证"剩余 ≤ 3 触发 loadMore"(mock scroll position)。

## 手动验证

- `rtk dart format .`
- `rtk flutter analyze`
- `rtk flutter test`
- `rtk flutter build windows --release`
- 运行桌面端,切到 4 段分别验证:
  - 滚动加载(剩 3 项触发)。
  - profile 段占位 → 补全的视觉切换。
  - 搜索框过滤(激活时不触发 loadMore)。
  - 限流回退(手动触发 `/rate_limit` 阻塞后,走 cache / seed)。

## 实现顺序建议

1. `ApiEndpointsConfig` 新增 + `DiscoverUsersSearchClient` + 单测。
2. `discover_queries.dart` 放宽 skills query、新增 official/people search query、profiles page key。
3. `DiscoverProfileEntity` 加字段 + codec / seed 补字段。
4. `DiscoverRepository.fetchProfiles` 改签名 + 新增 `fetchProfileDetail` + repository 测试。
5. `ProfilesNotifier` + provider + notifier 测试。
6. UI:实体 row 占位态、`_onScroll` 按元素数、`_buildProfiles` 接 notifier、常量调整。
7. i18n key。
8. 全量检查 + 桌面构建。
