# GitHub 情报站产品可信度与本地数据闭环设计

> 历史快照：标题和 `1.3.0+3` 目标版本保留为当时设计记录；相关可信本地闭环已经落地并由 1.4 继续演进。当前中文产品名为“AI资讯”，当前基线与能力请查看 [产品、数据与系统边界](../../plans/product_ia_data_plan.md) 和 [README](../../../README.md)。

日期：2026-07-11
目标版本：`1.3.0+3`

## 背景与第一性原理

GitHub 情报站的核心价值不是展示更多卡片，而是帮助开发者做出可信判断：

1. 当前信息来自哪里，是否新鲜。
2. 用户收藏、关注和监控的对象能否稳定找回。
3. 告警计算是否与文案所说的时间尺度一致。
4. 界面中的登录、活动和通知是否真有对应能力。
5. 发布产物是否不仅能编译，还能实际启动。

当前版本已经具备远端数据、缓存降级、数据来源标识和本地告警，但仍有若干断点：用户集合只保存 ID，部分页面只能从种子数据重建；空监控列表会重新落回默认仓库；跨多日观测被当作单日增长；报告贡献者缓存没有按仓库集合隔离；仓库详情仍展示无来源的样例活动；OAuth Client ID 未配置却仍暴露登录入口；启动前数据库异常没有恢复界面；配置导入缺少完整校验；Windows 发布门禁只验证编译，不验证启动。

## 目标

- 任意远端仓库或开发者被收藏、监控、关注后，都能在本地集合页稳定显示。
- 用户显式清空监控列表后，监控页保持真实空态。
- “单日增长”规则对跨多日采样进行日均化，不制造虚假告警。
- 聚合缓存与实际输入集合、身份作用域严格对应。
- 仓库和报告活动只展示真实 GitHub 数据；无真实数据时展示明确空态。
- OAuth 未配置时不展示必然失败的登录主操作；PAT 仍可作为完整可用路径。
- 启动初始化失败时显示可恢复界面，而不是无窗口退出。
- 配置导入在写入前完成全量校验，失败时不产生部分状态。
- 中英文界面不混杂，关键交互具备语义标签、键盘焦点和布局回归测试。
- Windows Release 必须通过产物完整性检查和真实启动烟测。

## 非目标

- 不新增服务端、后台任务、系统推送或跨设备同步。
- 不新增账号数据库、邮箱密码登录或自有身份系统。
- 不引入 GH Archive、Reddit、X 等新数据源。
- 不重做整体视觉语言，不更换 Riverpod、SQLite 或路由框架。
- 不进行与本次可信度闭环无关的依赖大版本升级。

## 方案选择

采用分层收口方案：保留现有 Feature-first 架构和 SharedPreferences/SQLite 边界，在 Core 增加小型、明确的本地实体快照模型；在现有 Repository 中修正缓存键、活动数据和规则语义；最后补齐 UI 口径、启动恢复与发布门禁。

不采用“只隐藏问题”的表面修补，因为它无法解决用户集合丢失和监控误报。不采用全量数据库重写，因为当前数据规模和单机边界不需要新的 ORM 或复杂迁移框架。

## 1. 本地用户集合

### 数据模型

新增纯 Dart 快照类型：

- `SavedRepoSnapshot`：`fullName`、`description`、`language`、`starCount`、`forkCount`、`accentArgb`、`updatedAt`。
- `SavedDeveloperSnapshot`：`login`、`contributions`、`avatarAccentArgb`、`updatedAt`。

`LocalContentState` 在现有 ID 集合之外维护：

- `Map<String, SavedRepoSnapshot> repoSnapshots`
- `Map<String, SavedDeveloperSnapshot> developerSnapshots`

快照使用 JSON 存入 SharedPreferences。它们属于用户内容元数据，不放入可被“清理缓存”删除的 `json_snapshot_cache`。

### 写入与读取

- 收藏或监控仓库时，调用方同时传入当前 `RepoEntity`，控制器写入 ID 和快照。
- 关注贡献者时，调用方同时传入 `ContributorEntity`。
- 删除收藏时，仅当该仓库既未收藏也未监控时删除仓库快照。
- 删除监控时，仅当该仓库既未监控也未收藏时删除仓库快照。
- 取消关注时删除对应开发者快照。
- 老版本只有 ID、没有快照时，集合页仍创建最小占位实体并显示 `fullName/login`，绝不把用户数据隐藏掉。
- 远端详情再次加载后，用新实体刷新快照。

### 空集合语义

默认监控仓库只在 `_monitorsKey` 从未写入时注入。只要该 key 存在，即使值为空，也必须尊重用户选择。`monitorRepositoryProvider` 不再根据 `Set.isEmpty` 回退默认列表。

## 2. 监控规则语义

### 时间尺度

`MonitorRuleEvaluator` 计算前先得到两个观测所在本地日期之间的自然日差 `elapsedDays`：

- `starDailyDelta = max(0, starDelta) / elapsedDays`
- `forkDailyDelta = max(0, forkDelta) / elapsedDays`
- `starDailyRate = ((currentStars / previousStars)^(1 / elapsedDays) - 1) * 100`
- `issueHeatRatio = (currentOpenIssues + 1) / (previousOpenIssues + 1)`

Issue 热度规则继续表达“自上次观测以来的存量比例变化”，UI 不再称它为单日值。Star 和 Fork 规则明确表达日均变化。

### 去重和历史

- 事件 ID 继续使用 `repo + rule + localDay`，保证同日刷新不重复。
- 观测最多保留 90 个本地日期。
- 跨时区切换仍以每条观测生成时的本地日期为准；测试覆盖连续日、跨多日、同日和负增长。

## 3. 缓存一致性

报告贡献者聚合缓存键由以下内容构成：

- 排序后的仓库 fullName 集合。
- GitHub Token 的非敏感 `cacheScope`。
- 缓存格式版本。

Repository 单资源 ETag 缓存继续按 HTTP 方法、URL 和作用域隔离。聚合贡献者只在输入集合完全相同时复用，避免把上一组仓库的贡献者显示到新报告中。

## 4. 真实活动数据

### 领域模型

新增 `RepoActivityEvent`：仓库、事件类型、标题、参与者、发生时间、目标 URL、`MetricBasis`。

`RepoDetailDigest` 增加 `activities`，`ProjectDigest` 增加聚合 `activities`。活动响应保留 `DataFreshness`，事件自身的 `basis` 固定为 `observed`；本版本不生成估算活动。

### 数据源

- 新增 GitHub `GET /repos/{owner}/{repo}/events?per_page=20` 端点配置。
- 仓库详情读取单仓库事件。
- 深度报告对前四个仓库并发读取事件，按时间倒序合并并限制为 30 条。
- 使用现有 `GitHubResourceCache` 和 ETag。
- 远端失败时可用过期活动缓存；没有缓存时返回空列表，不展示伪造事件。
- Project 活动页和 Repo Detail 活动卡删除硬编码样例，展示真实数据、空态和来源标记。

## 5. GitHub 认证

OAuth Client ID 改为：

```dart
const String.fromEnvironment('GITHUB_OAUTH_CLIENT_ID')
```

- Client ID 非空时，显示“连接 GitHub”并启用 Device Flow。
- Client ID 为空时，不展示可点击但必然失败的登录操作；用户卡显示“未连接 GitHub”，主操作跳转到 Token 配置。
- 登录页在未配置时只解释构建配置要求，不发送请求。
- PAT 继续使用 FlutterSecureStorage；OAuth Token 与 PAT 共用同一安全存储和退出清理路径。
- 文案只承诺读取公开资料和提升 API 配额，不承诺同步、邮箱登录或自有账号。

## 6. 启动恢复与配置导入

### 启动恢复

把 SharedPreferences/SQLite 初始化包装为 `BootstrapResult`：

- 成功时进入应用。
- 数据库打开失败时记录不含敏感数据的错误类型，显示启动恢复页。
- 恢复页提供“重试”和“打开数据目录”两个操作。
- 不自动删除数据库；数据库重置必须是单独、明确确认的危险操作，本版本不实现。
- `ErrorWidget.builder` 继续处理 runApp 之后的构建错误，但不再被误认为能覆盖启动阶段。

### 配置导入

- 导入前验证顶层 `app == github_news`、`version == 1`、`preferences` 类型。
- 仅允许明确白名单中的主题、语言、侧栏、数据源和非敏感本地偏好 key。
- 先把全部值解码成内存中的 `ValidatedPreferences`；任一值非法则零写入。
- 写入完成后刷新相关 Provider，界面立即反映新配置。
- 导出继续排除 Token，并新增单元测试证明 Token、未知 key 和错误列表类型不会进入本地偏好。

## 7. i18n、键盘与可访问性

- 把本次触及页面的硬编码中文迁入中英文字符串表：收藏、关注、监控集合、活动、报告导出、雷达筛选和空态。
- IconButton 必须提供 tooltip；自绘或复合可点击区域提供 `Semantics(button: true, label: ...)`。
- 关键流程覆盖 Tab/Shift+Tab 焦点可达性：侧栏、搜索、刷新、收藏、监控、设置操作。
- 布局测试覆盖 `1366x768`、`1024x768`、`390x844`，断言无 overflow。
- 截图只能支持视觉风险判断；最终不声称完整 WCAG 合规。

## 8. 发布门禁与 CI

新增 GitHub Actions：

- Ubuntu：`dart format --output=none --set-exit-if-changed .`、`flutter analyze`、`flutter test --coverage`。
- Windows：`flutter build windows --release`、产物结构检查、启动烟测。

Windows 启动烟测：

1. 检查 `github_news.exe`、`flutter_windows.dll`、`data/app.so` 和 `data/flutter_assets` 存在。
2. 从 Release 目录启动 exe。
3. 最多等待 15 秒，要求进程未退出且出现非零主窗口句柄。
4. 成功后正常关闭进程；失败时输出退出码和 Application Event Log 摘要。

本地 `tools/windows_release_smoke.ps1` 与 CI 使用同一脚本，避免“CI 有一套、本地有一套”。

## 9. 测试策略

所有行为变更使用测试先行：

- `LocalContentController`：任意远端实体可保存、重建、删除；旧 ID 无快照仍可见；显式空监控保持为空。
- `MonitorRuleEvaluator`：连续日、跨 2/7/30 日、同日、负增长、阈值边界和事件去重。
- `GithubProjectRepository`：仓库集合或作用域变化时不复用错误贡献者聚合。
- 活动解析：Push、Issues、Release、PullRequest 和未知类型；200/304/过期缓存/无缓存失败。
- OAuth：Client ID 空时不发请求且 UI 不显示失效登录主操作。
- Bootstrap：SharedPreferences 或数据库初始化失败时进入恢复状态。
- ConfigService：白名单、版本、类型、Token 排除、零部分写入和 Provider 刷新。
- i18n：新增 key 中英文集合保持一致。
- Widget：集合页真实实体、活动空态、键盘焦点和三档布局。
- 最终运行全量 format、analyze、test、Windows Release build 和启动烟测。

## 10. 数据迁移与兼容

- 不提高 SQLite schema 版本；用户集合快照使用新的 SharedPreferences key。
- 首次读取老版本 ID 集合时，用现有种子实体补齐能匹配的快照，其余生成最小快照。
- 新快照写入失败时保留原 ID 集合，界面至少仍显示最小实体。
- 旧贡献者聚合缓存 key 不再读取，等待现有缓存清理逻辑自然回收。
- OAuth 默认未配置，现有 PAT 不受影响。

## 11. 实施顺序

1. 用户集合快照与真实空监控。
2. 监控日均规则。
3. 报告缓存隔离。
4. 真实活动模型与 API。
5. OAuth 配置和诚实降级。
6. Bootstrap 恢复与配置导入校验。
7. i18n、键盘和布局回归。
8. CI、Windows 启动烟测、版本与文档。

每一阶段形成独立提交并通过受影响测试；最后进行全量验证。

## 验收标准

全部满足才算完成：

1. 任意收藏、监控和关注对象在重启后仍可见。
2. 用户清空监控后保持空态，不恢复默认仓库。
3. 跨多日观测不会制造单日增长误报。
4. 不同仓库集合或 Token 作用域不共享贡献者聚合缓存。
5. 仓库详情和报告不再展示未标明来源的样例活动。
6. OAuth 未配置时没有必然失败的登录主操作。
7. 启动初始化失败时有可恢复界面。
8. 配置导入失败时不产生部分写入，Token 永不导入导出。
9. 本次触及流程在中英文、键盘和三档布局下可用。
10. 版本统一为 `1.3.0+3`，当前文档同步。
11. format、analyze、全量 test、Windows Release build、启动烟测全部通过。
12. `main`、`origin/main` 和 GitHub 实际主分支哈希一致，工作区干净。
