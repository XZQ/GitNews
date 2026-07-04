# GitHub情报站第一性原理审计

日期: 2026-07-04

## 检查范围

- 代码结构、数据链路、缓存、异常处理、测试与构建。
- 桌面端与移动端响应式布局策略。
- 当前设计系统、搜索框、卡片、导航、信息架构与视觉一致性。

说明: 本轮尝试采集桌面端截图时，系统窗口焦点捕获到了非 App 窗口。误截图片已删除，因此本报告的 UI 判断主要来自代码结构、现有用户截图反馈和组件实现。

## 验证结果

- `dart format --set-exit-if-changed .`: 通过。
- `flutter analyze`: 通过。
- `flutter test --reporter=compact`: 通过，107 个测试。
- `flutter build windows --debug`: 未通过，原因是已打开的 `GitHub情报站 (11764)` 占用 `WebView2Loader.dll`，不是 Dart/Flutter 编译错误。
- `flutter build windows --release`: 通过，产物为 `build/windows/x64/runner/Release/github_news.exe`。

## 当前判断

项目已经不是纯静态 Demo。AI 动态、AI 雷达、仓库监控、深度报告、仓库详情等主链路已经具备 GitHub/API 远端数据、5 分钟本地缓存、失败兜底和本地搜索。GitHub 热榜仍默认本地数据，需要在设置里切到 GitHub 模式，这是为了降低匿名 GitHub Search 限流风险。

整体架构方向正确: Feature-first、Riverpod Provider、Repository 边界、SQLite 缓存 DAO、响应式三档布局都已经搭起来。当前主要问题不是“方向错”，而是“真实数据不断接入后，重复解析、固定高度 UI、数据口径说明和视觉回归测试还没有完全跟上”。

## 高优先级问题

1. README 数据状态已经过期
   - 证据: `README.md:19` 仍写“只有 AI 动态远程接入，其余本地占位”。
   - 事实: `tech_hotspot_providers.dart`、`monitor_providers.dart`、`local_project_repository.dart`、`repo_detail_providers.dart` 都已经默认使用 GitHub 远端仓库或远端聚合。
   - 风险: 后续判断“是否动态数据”会被文档误导，也会影响交付说明。

2. GitHub 数据接入逻辑分散
   - 证据: `github_tech_hotspot_repository.dart`、`github_monitor_repository.dart`、`github_project_repository.dart`、`github_repo_detail_repository.dart` 都各自处理 headers、解析、兜底和缓存。
   - 风险: 新增 Agent 榜、本周趋势、开发者榜时会继续复制逻辑；限流、异常转换、字段解析规则容易不一致。
   - 建议: 抽一个 `core/github/`，放 `GitHubApiClient`、`GitHubHeaders`、`GitHubRepoDto`、`GitHubRateLimitPolicy` 和通用 search/repo parser。

3. 动态数据口径仍不够“诚实”
   - 证据: 多处 `DemoData.generateStarTrend` 仍用于趋势曲线，例如 `home_chart_helpers.dart:111` 起；技术热点增长值也有由 heat 推导的估算逻辑。
   - 风险: 用户会把“估算趋势/本地生成曲线”理解成真实历史增长。
   - 建议: 在数据模型里区分 `observed` / `estimated` / `localFallback`，UI 用轻量状态标签表达，不要让模拟曲线伪装成真实历史。

4. 固定高度 + 动态列表仍是主要 UI 风险
   - 证据: 最近语言占比溢出来自动态语言列表；`tech_hotspot_page.dart` 仍有 360/260 等固定高度区域。
   - 当前缓解: `TechHotspotLanguagePanel` 和 `ProjectLanguageDistribution` 已经改为 bounded 时内部 ListView，未 bounded 时 shrinkWrap。
   - 风险: 其它面板只要真实数据变长，仍可能出现 overflow 或过密。
   - 建议: 给真实页面加 1280x720、1366x768、390x844 三档 widget/layout 测试，专门断言无 overflow。

## 中优先级问题

1. 文件体量超过项目规范
   - `tech_hotspot_page.dart`: 474 行。
   - `github_tech_hotspot_repository.dart`: 374 行。
   - `github_monitor_repository.dart`: 351 行。
   - `developer_options_page.dart`: 347 行。
   - `github_repo_detail_repository.dart`: 344 行。
   - 规范要求单文件超过 300 行必须拆分。建议先拆 UI 页面，再拆 GitHub 数据层。

2. GitHub 热榜默认本地是合理的，但 UI 需要更明确
   - 证据: `TrendingDataSourceModeController` 默认 `local`，状态文案有“本地数据 / GitHub 匿名 / GitHub Token · 缓存5分钟”。
   - 建议: 热榜页顶部保留数据源状态，刷新按钮旁展示当前模式；设置页保留切换入口。

3. Token 存储是本地偏好配置
   - 证据: `github_token_controller.dart` 使用 `SharedPreferences`，设置页文案也已说明。
   - 风险: 桌面开发阶段可接受；正式版本建议换 `flutter_secure_storage` 或 OAuth。

4. UI 视觉已经统一，但还偏“看板堆叠”
   - 优点: `AppCard`、`HeaderSearchField`、主题 token、侧栏、导航已经统一。
   - 风险: 桌面端多个页面都用卡片网格，差异化不够明显。
   - 建议: 让四大模块各有明确信息形态: 新闻是时间流，AI 雷达是主题/信号矩阵，GitHub 热榜是榜单和趋势，深度报告是集合分析和导出。

## 后续推荐顺序

1. 更新 README 和产品数据状态文档，先把“哪些是真实远端、哪些是估算/本地兜底”写准。
2. 抽 `core/github/` 公共数据层，统一 GitHub Search、Repo、Contributors、headers、rate-limit 和解析逻辑。
3. 给真实页面补布局回归测试，重点是 AI 雷达语言面板、深度报告语言面板、热榜列表、首页搜索栏。
4. 把超过 300 行的页面拆成小 widget，把超过 300 行的数据仓库拆成 API client + mapper + repository。
5. 把趋势曲线从 `DemoData.generateStarTrend` 逐步替换成“本地快照历史”，没有历史时明确标成估算。
