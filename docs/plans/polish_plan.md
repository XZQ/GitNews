# GitHub 情报站 · 多专家打磨方案

> 历史快照（2026-07-08）：标题沿用当时的产品名，本文保留当时审计证据，不是当前待办或验收结果。当前中文产品名为“AI资讯”，基线为 `1.4.0+4` 加 `Unreleased` 改动；请以 [产品、数据与系统边界](product_ia_data_plan.md)、[README](../../README.md)、[CHANGELOG](../../CHANGELOG.md) 和实际代码为准。

> 由 4 位专家子代理并行评审（架构/系统设计、UI/UX、性能与包体积、测试与稳定性）后汇总。
> 评审基线：`flutter analyze` → **0 错误 / 0 警告**；`flutter test` → **全部通过，0 失败**。
> 结论：项目健康度高，本方案聚焦**健壮性、一致性、性能与测试盲点**的打磨，而非修 Bug。

## 一、高优先级（先修，影响正确性与架构合规）

1. ✅ **presentation 违规依赖 data 类**（已修复 2026-07-08）
   - `lib/features/profile/presentation/widgets/github_token_card.dart:13` 直接 import `data/github_rate_limit_client.dart`，`:24` 持有 `GitHubRateLimitSnapshot` DTO。
   - 修复：新建 `lib/features/profile/domain/github_rate_limit.dart` 存放 `GitHubRateLimitSnapshot/Bucket`；data client 改为 import domain；widget 由依赖 data 改为依赖 domain。`flutter analyze` 0 问题、`flutter test` 182 全过。

2. ✅ **feature 间直接依赖**（已修复 2026-07-08，含 home/devintel 共 2 处）
   - `lib/features/repo_detail/presentation/detail/repo_detail_sidebar.dart:11` import `features/project/application/project_providers.dart`，`:73` `ref.read(projectSearchQueryProvider.notifier)`。另 `home/widgets/devintel/devintel_top_header.dart:11` 也跨 feature 引用了 `projectSearchQueryProvider`。
   - 修复：新建 `lib/shared/providers/app_search_query_provider.dart` 存放 `projectSearchQueryProvider`；从 `project_providers` 移除定义并改为 import+export；repo_detail 与 home/devintel 改从 shared 引入。project 内部文件经 re-export 保持不变。

3. **数据来源可信度模型过粗且展示不全**
   - `lib/core/domain/data_provenance.dart:6` 仅 `observed/estimated/localFallback` 三态，把"实时/有效缓存/过期缓存"全并入 `observed`，过期缓存会被误标为真实观测。
   - 仅在 `repo_detail`（`repo_detail_chart.dart:31/41`）与 `monitor_detail_page.dart:127` 展示；`ai_news/trending/project/home` 未暴露来源。
   - 改法：扩展为 5 态（live / freshCache / staleCache / estimated / seed），并在全部数据 feature 显示来源 badge。

4. **ai_news 缺种子数据兜底**
   - `lib/features/ai_news/data/remote_ai_news_repository.dart` 远端失败且缓存缺失时仅报错，无最后 seed 兜底（其他 feature 复用 `core/demo_data`）。
   - 改法：补 `DemoData`/seed 与 stale→seed 回退链路，统一"cache-first + stale-on-failure"。

5. **回退链路与缓存编解码缺测试（稳定性盲点）**
   - `repo_detail/data/github_repo_detail_repository.dart:83`、`tech_hotspot/data/github_tech_hotspot_repository.dart:83` 的"过期缓存→种子"回退在 `catch` 内且未再包裹，本地兜底抛异常会冒泡为未捕获 AsyncError。
   - `github_repo_entity_codec.dart`、`github_tech_hotspot_cache_codec.dart`、`github_repo_detail_cache_codec.dart` 均无往返单测。
   - 改法：补"有效缓存→过期回退→远端失败回退种子"三态单测 + codec 序列化往返与脏数据容错测试。

## 二、中优先级（一致性、性能、体验）

6. **超 300 行非例外文件**（应拆分）
   - `trending/widgets/trending_desktop_view.dart:326`、`home/presentation/home_chart_helpers.dart:307`、`project/presentation/activity_page.dart:302`。

7. **monitor 桌面双栏溢出/塌缩**
   - `monitor/presentation/monitor_page.dart:111-114` 用 `(MediaQuery.sizeOf-280).clamp(220,900)` 固定像素高度，窗口变矮时溢出并出现双层滚动。
   - 改法：`Expanded`+`flex` 或 `LayoutBuilder` 设最小高度，去掉内层 `SingleChildScrollView`。

8. **i18n 不一致（裸写中文而非 l10n.tr）**
   - `monitor/widgets/monitor_page_header.dart:24-26`、`trending/widgets/trending_page_header.dart:39`（`'今日 +124'` 魔法数字）、`tech_hotspot/presentation/tech_hotspot_page.dart:143`、`profile/presentation/followed_developers_page.dart:21`、`collect_page.dart:22`、`monitor/presentation/monitor_alerts_page.dart:101-104`。
   - 改法：统一走 `l10n.tr`，魔法数字提取为常量。

9. **移动端趋势列表非惰性**
   - `trending/widgets/trending_mobile_view.dart:119` 用 `for` 循环在 `ListView.children` 一次性构建全部 `RepoTile`。
   - 改法：`ListView.builder` 懒构建。

10. **热点趋势重复计算**
    - `shared/widgets/repo_tile.dart:30-31` `repo.trend ?? DemoData.generateStarTrend(...)` 在 build 中生成，滚动/筛选重建时每个 tile 重算。
    - 改法：预计算进 `RepoEntity` 或 memoize。

11. **缺 RepaintBoundary 隔离**
    - 全库仅 `hot_repos_page.dart` 1 处。`trending_desktop_view.dart:67` 的 `StarTrendChart`（fl_chart）在过滤变化时整段重建重绘。
    - 改法：给图表与列表卡片加 `RepaintBoundary`。

12. **死依赖 `cached_network_image`**
    - `pubspec.yaml:37` 声明，但 `lib/` 内无任何 `CachedNetworkImage(` 或 import（`RepoTile` 用字母头像）。
    - 改法：删除该依赖。

13. **缓存容量守卫触发面过窄**
    - `enforceCap()` 仅在 `ai_news_providers.dart:247` 落盘后调用；只浏览 trending/monitor 不进 ai_news 时，快照表永不触发 1GB 上限清理（`local_database.dart:235`）。
    - 改法：各列表写盘后统一触发，或启动/定时触发。

14. **离线回退不一致**
    - ai_news 有"过期但有缓存则不报错"逻辑（`ai_news_providers.dart:235`）；trending/monitor 在 TTL 过期后离线是否回退 stale 缓存需确认。
    - 改法：统一 cache-first + stale-on-failure。

15. **测试覆盖缺口**
    - `github_tech_hotspot_repository_test.dart` 仅 2 例，未覆盖 `Future.wait` 扇出（`:119`）、限流门控（`:65`）、历史趋势合并（`:201`）；repo_detail 仅测 provider 未测 data 层；`ai_news_item_dto.dart` 仅靠 api_client 间接覆盖；`app_router.dart` 无测试（`:68/135/181/214` 用 `pathParameters['fullName']!` 空断言、`queryParameters['url'] ?? ''` 可能传空 URL 给 WebView）。

16. **repo_detail 空态与裸写文案**
    - `repo_detail_page.dart:77` empty 条件 `relatedRepos.isEmpty && contributors.isEmpty` 过弱，找不到的仓库显示零值而非 not_found；`:52/:69` tooltip/snackbar 裸写中文。

## 三、低优先级（打磨细节）

17. **profile 中等屏布局**：`profile_page.dart:33` medium 复用 `_Mobile` 单列，未做 tablet 布局，留白浪费。
18. **裸写圆角/颜色**：`trending_desktop_view.dart:290` `BorderRadius.circular(999)`→`AppRadius.pill`；`profile_user_card.dart:54` `AppRadius.xs + 2` 混用；`repo_detail_header.dart:40`/`monitor_detail_page.dart:115` `Colors.white.withValues` 横幅文字建议用主题语义色。
19. **侧栏/页头背景与 Divider 厚度不一致**：`app_sidebar.dart:38` `surface.withValues(alpha:0.98)` vs `page_header.dart:90` 不透明 `surface`；Divider 0.5 vs 应用级 0.6/1。
20. **`cache_meta` 无失效清理**：只 upsert 不删，过期 `cache_key` 行累积。
21. **并发无超时/降级**：`github_tech_hotspot_repository.dart:119` `_fetchDigest` 多路并发无超时；`getById`/`allTopics`（`:96-102`）直接 `await getDigest()`，异常未降级。
22. **release 构建建议**：`flutter build windows --release --split-debug-info=... --obfuscate`；评估 `--tree-shake-icons`。
23. **`flutter_inappwebview` 常驻**：仅"应用内打开"使用，可考虑默认外部浏览器减少常驻。
24. **重复头**：`ai_news_api_client.dart:26` 与 `ai_news_providers.dart:25` 重复 `'Accept':'application/json'`（可接受，去重即可）。
25. **`setState` 使用**：`profile_data_card`、`webview_page` 等均为本地瞬时 UI 态，合规。

## 四、建议实施顺序

1. 高优先级 1–2（架构合规，影响后续所有改动）。
2. 高优先级 3–4（数据来源准确性 + 离线兜底，统一 cache-first）。
3. 中优先级 7–8（monitor 溢出、i18n 一致性，肉眼可见体验）。
4. 中优先级 9–11、13–14（性能：惰性列表、预计算、RepaintBoundary、容量守卫、离线回退）。
5. 高优先级 5 + 中优先级 15（补回退/codec 单测，锁住正确性）。
6. 低优先级逐项清理（依赖、裸常量、响应式、构建参数）。

> 每项改动后运行：`dart format .` → `flutter analyze` → `flutter test`（桌面相关加 `flutter build windows --release`）。
