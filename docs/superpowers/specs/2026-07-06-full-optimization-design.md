# 2026-07-06 全方位优化设计

## 背景

桌面端主链路已进入可用收尾阶段（参考 README "状态" 与最近 20 条 commit）。在继续添加新功能之前，需要在架构、抓取方式、性能、UI 一致性四个维度做一次系统性优化，消除既有的高 ROI 债务，并让后续迭代更轻松。

本设计基于四份调研报告（架构 / 数据层 / 性能 / UI），合并去重后形成。

## 目标

- 抓取层：把 GitHub REST 多次调用 + 0 ETag 的现状改到 ETag 命中 + GraphQL 批量，rate limit 消耗降 50–80%。
- 性能层：消除长列表全量构造与 0 RepaintBoundary，首屏时间与内存同时改善。
- 架构层：把分散的缓存 DAO 收敛到通用实现，TTL/熔断配置化。
- UI 层：补齐 a11y 基线，关闭 A/B/C 旁路与状态完整性缺口。

## 非目标

- 不引入服务端、定时任务、云同步。
- 不替换状态管理（继续 Riverpod）或路由（继续 go_router）。
- 不重构 theme token 系统本身（仅清理残余裸常量）。
- 不补齐 go_router_builder 迁移（按既有 memory 决策继续推迟）。

## 分批与范围

四批按"低风险高收益 → 结构性 → 抓取升级 → 清理"顺序。每批独立可交付、可回滚，互不阻塞。

### 第 1 批：高 ROI 低风险（预计 1-2 天）

#### 1.1 列表虚拟化 + RepaintBoundary

**问题**：30+ 处用 `ListView(children: [...])` 一次性构造全部子项，热榜/监控/详情可达数十项。全仓 0 处 `RepaintBoundary`。

**改造点**（部分高优先文件）：
- `lib/features/trending/presentation/hot_repos_page.dart:75-110`
- `lib/features/trending/presentation/trending_overview_page.dart`（74, 252）
- `lib/features/tech_hotspot/presentation/tech_hotspot_detail_page.dart`（127, 185）
- `lib/features/monitor/presentation/monitor_detail_page.dart`（85, 188）
- `lib/features/repo_detail/presentation/repo_detail_page.dart`（106, 138）
- `lib/features/project/presentation/activity_page.dart`
- `lib/features/home/presentation/home_tablet_body.dart:28`

**做法**：
1. 全量 `ListView(children: [...])` / `Column` 拼列表 → `ListView.builder` 或 `SliverList`。
2. 复杂卡片（含图表、含图片）外包一层 `RepaintBoundary`。
3. 图表窗口选择从页面级 `setState` 下沉到独立 `StatefulWidget` 或 `ValueNotifier`（`home_tablet_body.dart:35`、`home_mobile_body.dart:73`、`devintel_chart_card.dart:79`、`repo_detail_chart.dart:63`）。

**验收**：长列表滚动 60fps；窗口切换不再触发整页 rebuild（DevTools widget rebuild 计数验证）。

#### 1.2 GitHub ETag / If-None-Match

**问题**：全仓 0 处 ETag / If-None-Match / If-Modified-Since。每次刷新都消耗完整 rate limit 配额。

**做法**：
1. `cache_meta` 表用已预留的 `payload_hash` 字段存 ETag（schema 不变，复用列）。
2. `dio_client` 增加 `ETagInterceptor`：请求前从 cache_meta 取 ETag 写入 `If-None-Match`；304 时把缓存标记为命中并刷新 `last_fetched_at`，不向下传播。
3. `GithubApiSupport.headers`（`lib/core/github/github_api_support.dart:15-24`）与所有 GitHub repository 的 `getOrRefresh` 配合读取 ETag。

**验收**：同一资源二次刷新命中 304 不计消耗（GitHub rate_limit 接口验证）；UI 行为不变。

#### 1.3 启动并行化

**问题**：`lib/main.dart:10-22` 串行 await `SharedPreferences.getInstance()` + `LocalDatabase.open()` + FFI 初始化。

**做法**：用 `Future.wait` 并行；非首屏必需的 schema migrate 延后到首帧之后。

**验收**：首帧时间下降（实测对比）。

---

### 第 2 批：架构收敛 + 配置化（预计 2-3 天）

#### 2.1 缓存层抽象

**问题**：`trending_cache_dao.dart`(234 行)、`ai_news_cache_dao.dart`(170 行)、`repo_detail` 历史快照各自写"表 + TTL via CacheMetaDao + JSON 编解码 + cache_key 拼接"，而 `core/storage/json_snapshot_cache_dao.dart`(90 行) 已是通用实现却未被采用。

**做法**：
1. feature 只声明 `CacheKey`（命名空间 + 维度）+ JSON mapper。
2. 全部 feature cache 收敛到 `JsonSnapshotCacheDao`。
3. 写一次性数据迁移：把旧表中最新的 JSON payload 倒进新结构，迁移完删旧表（加版本号 bump）。

**收益**：删 ~300 行；TTL/迁移/容量守卫一处统一。

#### 2.2 TTL 分级 + rate-limit 全局熔断

**问题**：6 处硬编码 `Duration(minutes: 5)`；`AppExceptionKind.rateLimit` 解析了 `retryAfter` 但没人消费。

**做法**：
1. 在 `core/storage` 或 `core/config` 加 `CacheTtlConfig`：列表 5min / repo_detail 30min / monitor 10min / snapshot_history 永久。
2. 新增全局 `RateLimitGate` provider：捕获 `AppExceptionKind.rateLimit` 后，在 `retryAfter` 窗口内短路所有 GitHub 请求直接走 fallback；窗口结束后自动恢复。
3. UI 层展示全局剩余配额状态（复用 `GitHubRateLimitClient` 主动探针）。

#### 2.3 SectionCard 抽象 + 大文件拆分

**问题**：13+ 个 `*_card.dart`、多个 >270 行 build 方法（`github_token_card` 275 行、`profile_settings_card` 270 行、`activity_page` 300 行、`webview_page` 289 行）。

**做法**：
1. 抽 `shared/widgets/section_card.dart`（slots：leading / title / trailing / body / footer）。
2. 13 个 `*_card.dart` 收敛到 `SectionCard` 模板。
3. 4 个大文件按 build 子方法拆为子 widget 文件（每文件 < 200 行）。

**收益**：消除多个 >250 行违规。

---

### 第 3 批：抓取升级 + 功能扩展（预计 3-5 天）

#### 3.1 GraphQL 批量

**问题**：`GithubProjectRepository._fetchContributors`（`lib/features/project/data/github_project_repository.dart:83-101`）对 trending Top4 各发一次 `/contributors`；`GithubRepoDetailRepository._fetchDetail`（`lib/features/repo_detail/data/github_repo_detail_repository.dart:87-102`）对单仓库发 3 次 REST。

**做法**：
1. 引入 `graphql` 包（或继续 dio + POST `/graphql`，避免新依赖，二选一在实现时再拍）。
2. 一次查询合并 `repository(...) { stargazers contributors(first: 20) }`。
3. tech_hotspot 的 N topic 搜索合并为别名批量查询。

**收益**：rate cost 从 7 降到 1。

#### 3.2 AI 资讯 RSS 多源

**问题**：单点依赖 `aihot.virxact.com`（`lib/features/ai_news/data/ai_news_api_client.dart:18`）。

**做法**：
1. 仿 `TrendingDataSource` 抽象，新增 `AiNewsDataSource` 接口与 `RssAiNewsDataSource` 实现。
2. 接入 HN / OpenAI Blog / Anthropic Blog / arXiv cs.AI+cs.CL RSS。
3. 客户端去重：URL 规范化 + 标题 SimHash 近似合并；`ai_news_item.url` 主键化幂等入库。
4. 现有 aihot 源保留为 `AggregatedAiNewsDataSource` 之一。

**收益**：脱离单点、覆盖面扩大、可扩展。

#### 3.3 a11y 基线

**问题**：全仓 1 处 `Semantics`、1 处 `FocusNode`。

**做法**：
1. 为 `HeaderSearchField`、`IconButton`、`AppCard`、`RepoTile`、`SidebarItem` 加 `Semantics(label/container/selected)`。
2. 侧栏与一级页加 `FocusTraversalGroup` + Tab 顺序。
3. `app_theme.dart` 注入 `focusColor` 与自定义 FocusRing InkWell。

**收益**：键盘可达、读屏可用，符合"桌面操作向"定位。

---

### 第 4 批：清理与一致性（预计 0.5-1 天）

- **home 旁路修复**：`lib/features/home/presentation/home_page.dart:20-22` 在 expanded 下应继续走全局 `AppSidebar`，`DevIntelDesktopPage` 改为只渲染 B/C。
- **profile 四态**：`lib/features/profile/presentation/profile_page.dart:24-35` 包 `localContentControllerProvider.when`，加 `ProfileSkeleton`。
- **裸常量清理**：
  - 3 处 `BorderRadius.circular(999)` → `AppRadius.pill`（`ai_news_detail_content.dart:204`、`github_token_card.dart:212,263`）。
  - `devintel_hotspot_list.dart:129-131` 热力梯度提升为 `AppColors.heatHigh/heatMid/heatLow` token。
  - 6 处 `Colors.white/black` 在 hero header 内改 `colorScheme.onPrimary` 等。
- **跨 feature 解耦**：`lib/features/project/domain/project_repository.dart:5-6` re-export `repo_detail/domain` 的 `ContributorEntity`，下沉到 `core/domain`。
- **结构裂缝**：在 AGENTS.md 写"小型展示型 feature 可省略 domain"豁免规则，或为 `home` / `trending` 补齐三层。

---

## 风险与回滚

- 每批独立 commit，回滚粒度 = 单批。
- 第 2 批缓存层抽象涉及旧数据迁移：迁移脚本失败时保留旧表，第二次启动重试。
- 第 3 批 GraphQL 与 RSS 是新依赖、新数据源，先在 feature flag 后面跑（沿用现有 `TrendingDataSourceModeController` 模式），稳定后默认开启。
- 全程不跳过 `dart format` / `flutter analyze` / `flutter test`，桌面影响到的批次额外跑 `flutter build windows --release`。

## 验收标准

每批完成时：
- `rtk dart format .` / `rtk flutter analyze` / `rtk flutter test` 全过。
- 受影响页面手测四态（loading/error/empty/data）。
- 提交时附对比指标（rate limit 消耗、首帧时间、widget rebuild 计数等）。

## 实施顺序

第 1 批内部顺序与编号不同：先做 1.2 ETag，因为它是后续 GraphQL 改造的前置（先把每次请求的 rate cost 降下来，再判断是否仍需切换协议）；再做 1.1 列表虚拟化（局部纯 UI，独立可验证）；最后 1.3 启动并行化。

1. 第 1 批：1.2 ETag → 1.1 虚拟化 → 1.3 启动。
2. 第 2 批：2.1 缓存抽象 → 2.2 TTL+熔断 → 2.3 SectionCard。
3. 第 3 批：3.1 GraphQL → 3.2 RSS → 3.3 a11y。
4. 第 4 批。

每完成一批再决定是否进入下一批，允许中途调整优先级。
