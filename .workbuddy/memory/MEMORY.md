# github_news 项目长期记忆

## 项目概览
- GitHub情报站：Flutter 3.x / Dart 桌面优先（Windows 优先，无后端），本地 SQLite 缓存，离线优先。
- 缓存策略：TTL 5min cache-first + stale-on-failure + seed 兜底。
- 状态/路由：Riverpod + go_router（StatefulShellRoute.indexedStack）。

## 架构规则（AGENTS.md，必须遵守）
- feature-first：`lib/core/{network,storage,theme,router,github,i18n,di,domain,shared,config,preferences}`、`lib/features/<feature>/{data,domain,application,presentation}`、`lib/shared/widgets/`。
- presentation 不得 import feature data 类；跨 feature 只能经 core/domain|config|shared。
- 单 .dart 文件 < 300 行（豁免：i18n maps、generated、机械 codec）。超 300 行须 feature 内拆分到 widgets/ 子目录，保持无 data 类 import。
- 每个 AsyncValue 页面须有 loading/data/error/empty 四态。

## 关键约定
- i18n：新增文案同时改 `lib/core/i18n/strings_zh_cn.dart` 与 `strings_en_us.dart`；无障碍文案用 `a11y.*` 命名空间。
- 无障碍：AppBar 返回按钮一律用 `BackButton(onPressed:)`（自带本地化 tooltip），不要裸 `IconButton(icon: Icon(Icons.arrow_back))`；动作 IconButton 须带 `tooltip:` 且走 i18n。
- 并发：`core/network/parallel.dart` 的 `gatherAll` 适用于"逐项独立拉取、丢一两个不影响整体"的列表聚合（monitor/tech_hotspot/project）；不适用于 enrichment（丢项即丢数据，如 trending/tech_hotspot 的历史合并）。
- schema 迁移：DDL + 迁移链集中在 `core/storage/database_schema.dart`；新增迁移在 `_kMigrations` 末尾追加并自增 `local_database.dart` 的 `_kCurrentVersion`。
- 监控闭环：`localContentControllerProvider`（core/shared）的 `monitoredRepos` 是发现页↔监控页的唯一真实监控集合；monitorRepositoryProvider 读它（空则回退 githubMonitorDefaultRepos），cacheKey 按内容哈希隔离。discover 行尾开关直接 add/removeMonitor。
- 发现页（discover，第 8 个 Tab，profile 前）：流行仓库 Top20 = GitHub Search `stars:>1000 sort:stars`；Agent Skills 榜 = `topic:agent-skills OR topic:claude-skills OR topic:mcp stars:>50`。三级回退 live→freshCache→staleCache→seed。注意 discover 页类名用 `DiscoverHubPage`（避 project/discover_page.dart 的 `DiscoverPage` 冲突）。
- GitHub Device Flow 登录（core/github/github_device_flow_controller.dart）：桌面端无回调 URL 的方案。端点在 github.com（非 api.github.com），form-urlencoded。需在 `ApiEndpointsConfig.githubOAuthClientId` 填真实 OAuth App client_id 才可用；占位时 UI 短路 error:not_configured。成功后 token 写 secure storage(githubTokenController)、用户信息回填 localContentController.cachedUser。

## Windows 桌面端运行/构建坑
- `flutter run -d windows` 偶报 MSB3027：WebView2Loader.dll 被旧 github_news.exe 锁定。必须用 PowerShell `Stop-Process -Name github_news -Force` 杀旧实例（禁止 Git Bash `taskkill //F`，// 被 MSYS 吞掉静默失败）。
- 首次构建卡死根因（2026-07-08 排查）：`flutter_inappwebview_windows` 的 PreBuildEvent 调 chocolatey 的 `nuget.exe` 下载 3 个依赖包（Microsoft.Web.WebView2 / Windows.ImplementationLibrary / nlohmann.json）到 `build/windows/x64/packages`。nuget 读 `HTTP_PROXY`；代理 `127.0.0.1:9098` 偶发 502 或清空后直连 Azure blob 不通 → 卡死在 'Building Windows application...' 无限重试。诊断：`flutter build windows --verbose` 看 PreBuildEvent 是否停在 nuget install；查 `packages` 目录是否有这 3 个文件夹（有则已下好）。解决：用可用代理重跑（`flutter run -d windows`），包已存在则 nuget 秒跳过，MSBuild 编译 C++ ~28s 后 `√ Built github_news.exe` 启动。停卡死构建用 TaskStop 工具（pkill / Stop-Process -Name 含 msbuild/nuget/cmake 会被安全策略 LOLBin 拦截）。
- release 打包：`flutter build windows --release --obfuscate --split-debug-info=build/symbols`；symbols 目录须保管，崩溃栈用 `flutter symbolize -i <trace> -d build/symbols` 还原。
- 版本号改 `pubspec.yaml` 的 `version:` 即可，CMake 经 FLUTTER_VERSION_* 自动注入 Runner.rc。
- 最低 Win10（runner.exe.manifest supportedOS 仅声明 Win10/11 GUID）。

## 验证基线
- `flutter analyze` = No issues found；`flutter test` = 196 全过（截至 2026-07-08 第二阶段）。

## 仍延期项
- i18n 全量扫荡（~732 处裸中文，主要在 monitor/profile/trending 二级页）。
- Device Flow 实际可用：需注册 GitHub OAuth App 并替换 `ApiEndpointsConfig.githubOAuthClientId` 占位值。
- Agent Skills 第三方排行榜数据源（jaychempan 路径已 404），待确认可靠源后接入 discover enrichment。

## 启动 Tab 偏好（已补完）
- `StartupTabController`（core/preferences）持久化启动 Tab pathSegment；`app_router.buildAppRouter` 同步 `ref.read` 作为 initialLocation（不 watch，避免热重建路由栈，下次冷启动生效）；设置页 launch_theme 行接 Dropdown 选 8 个一级 Tab。
- 坑：appRouter 现急切读 sharedPreferencesProvider，冒烟测试 widget_test 需 override 该 provider（与 main 一致），否则 StateError。
