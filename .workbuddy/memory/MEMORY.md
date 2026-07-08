# github_news 项目长期记忆

## 项目概览
- GitHub情报站：Flutter 3.x / Dart 桌面优先（Windows 优先，无后端），本地 SQLite 缓存，离线优先。
- 缓存策略：TTL 5min cache-first + stale-on-failure + seed 兜底。
- 状态/路由：Riverpod + go_router（StatefulShellRoute.indexedStack）。

## 架构规则（AGENTS.md，必须遵守）
- feature-first：`lib/core/{network,storage,theme,router,github,i18n,di,domain}`、`lib/features/<feature>/{data,domain,application,presentation}`、`lib/shared/widgets/`。
- presentation 不得 import feature data 类；跨 feature 只能经 core/domain|config|shared。
- 单 .dart 文件 < 300 行（豁免：i18n maps、generated、机械 codec）。超 300 行须 feature 内拆分到 widgets/ 子目录，保持无 data 类 import。
- 每个 AsyncValue 页面须有 loading/data/error/empty 四态。

## 关键约定
- i18n：新增文案同时改 `lib/core/i18n/strings_zh_cn.dart` 与 `strings_en_us.dart`；无障碍文案用 `a11y.*` 命名空间。
- 无障碍：AppBar 返回按钮一律用 `BackButton(onPressed:)`（自带本地化 tooltip），不要裸 `IconButton(icon: Icon(Icons.arrow_back))`；动作 IconButton 须带 `tooltip:` 且走 i18n。
- 并发：`core/network/parallel.dart` 的 `gatherAll` 适用于"逐项独立拉取、丢一两个不影响整体"的列表聚合（monitor/tech_hotspot/project）；不适用于 enrichment（丢项即丢数据，如 trending/tech_hotspot 的历史合并）。
- schema 迁移：DDL + 迁移链集中在 `core/storage/database_schema.dart`；新增迁移在 `_kMigrations` 末尾追加并自增 `local_database.dart` 的 `_kCurrentVersion`。

## Windows 桌面端运行/构建坑
- `flutter run -d windows` 偶报 MSB3027：WebView2Loader.dll 被旧 github_news.exe 锁定。必须用 PowerShell `Stop-Process -Name github_news -Force` 杀旧实例（禁止 Git Bash `taskkill //F`，// 被 MSYS 吞掉静默失败）。
- release 打包：`flutter build windows --release --obfuscate --split-debug-info=build/symbols`；symbols 目录须保管，崩溃栈用 `flutter symbolize -i <trace> -d build/symbols` 还原。
- 版本号改 `pubspec.yaml` 的 `version:` 即可，CMake 经 FLUTTER_VERSION_* 自动注入 Runner.rc。
- 最低 Win10（runner.exe.manifest supportedOS 仅声明 Win10/11 GUID）。

## 验证基线
- `flutter analyze` = No issues found；`flutter test` = 191 全过（截至 2026-07-08）。

## 仍延期项
- i18n 全量扫荡（~732 处裸中文，主要在 monitor/profile/trending 二级页）。
- 5 主屏 golden 测试；头部去重（PageHeader 配置驱动）。
