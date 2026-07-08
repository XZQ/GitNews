# 商业级打磨方案 (Commercial-Grade Polish Plan)

生成于 2026-07-08，基于 4 位专家并行只读评审（架构 / UI-UX / 性能 / 测试）。
基线：`flutter analyze` = No issues；`flutter test` = 187 passing。
已完成项（不再重复）：DataProvenance 5 态、ai_news 种子兜底、monitor 桌面溢出修复、profile 裸圆角、sidebar 背景、repo_tile 致命崩溃修复。

## 优先级总览

### P0 — 正确性 / 信任（Must-fix，高价值低风险）
- A1 Activity 假数据：列表 `activity_page.dart:111-157` 为硬编码假事件，须标注"示例数据"或移除（可信度）。
- A4 跨 feature import 违规：`activity_page.dart:16` 应改为 `core/domain/contributor_entity.dart`。
- B1 repo_detail not_found 误判：`repo_detail_page.dart:77-82` 删除（`relatedRepos/contributors` 为空就显示未找到，误伤真实仓库）。
- A8 数据层 i18n 泄漏：`monitor/data/github_monitor_repository.dart:127` 的 `'刚刚'/'小时'` 移到 domain/presentation 或共享相对时间助手。
- D3 SQLite 迁移往返测试：`local_database.dart` `_kMigrations` 链无测试（数据丢失风险）。

### P1 — 健壮 / 可维护（Must-fix）
- A2 并发超时助手 + 6 处 `Future.wait`（repo_detail:111, tech_hotspot:119/207, monitor:110, project:109, trending:165）：加 `.timeout` + 单失败降级。
- A3 cache_meta 清理：`cache_meta_dao.dart` 增加 `pruneStale(ttlByPrefix)`，启动/写后调用。
- A5/T14 拆分 4 个 >300 行文件：`trending_desktop_view.dart`(329)、`home_chart_helpers.dart`(307)、`activity_page.dart`(302)、`local_database.dart`(311，新增非豁免)。均在 feature 内拆分，无 data 类 import。
- D1 五大桌面主屏 golden（home / trending_desktop / monitor_desktop / repo_detail / profile）。
- D2 monitor 溢出修复回归 golden（`monitor_page.dart:99-146` LayoutBuilder）。
- D4 ai_news `freshCache` 口径断言缺失。
- D5 ai_news 分页 `loadMore/hasMore` 断言缺失。

### P2 — 性能 / UX（Should-fix）
- C2 告警列表 `monitor_alerts_page.dart:81-194` 改为 `ListView.builder` + `RepaintBoundary`。
- C3 AI 资讯时间线 `ai_news_page.dart:171` 加 `RepaintBoundary`。
- C1 WebView 常驻：`webview_page.dart:246/252` 错误态用 `Stack` 叠加 `ErrorView` 而非重建控件；控制器常驻于页 state，关闭时 dispose。
- C5 搜索框双 rebuild：`header_search_field.dart:56-58` 去掉冗余 `setState`。
- B2 profile medium→`_Desktop`：`profile_page.dart:33`。
- B3 i18n 扫荡：主要 presentation 文件硬编码中文迁入 strings map（repo_detail / monitor_alerts / home metrics / ai_news cards / collect / monitor_topics）。
- B4 IconButton tooltip/semantics 无障碍（主要页头/返回按钮）。
- B8 ErrorView 增加返回动作（详情页 deep-link 卡死）。
- A9 全局 `ErrorWidget.builder` 崩溃边界。
- A10 离线/连通性指示（离线优先核心卖点）。

### P3 — 发布加固（Should/Nice）
- A7 release 构建加固：`--obfuscate --split-debug-info`，版本策略。
- A12 EXE 版本资源跟踪 pubspec（`Runner.rc` VERSION_AS_NUMBER）。
- D13 release 冒烟 + 声明 Win10+ 最低版本。
- 头部去重（C6）：二级页统一 `PageHeader` 配置驱动。

## 实施顺序
P0 → P1 → P2 → P3，每阶段结束跑 `flutter analyze` + `flutter test` 校验，最后 `flutter run -d windows` 重开桌面端。
