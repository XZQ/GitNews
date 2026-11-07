# 架构边界收口与残余重构落地

状态：Complete

本计划遵循 `.agent/PLANS.md`，执行期间必须保持内容与实际状态一致。
用户明确要求：把上一轮标记为「未做 / 剩余边界」的整改项全部做完，然后 commit and push。

## Purpose / Big Picture

上一轮把 5 项重构记入 Decision Log 暂缓，理由是「本机无 Flutter，无编译反馈时风险高于收益」。
本计划先消除这个前提：在沙箱内安装与 CI 完全一致的 Flutter 3.44.9 / Dart 3.12.2，
使 `flutter analyze` 与 `flutter test` 可在本机执行，然后把暂缓项一次性落地：

1. 47 处 feature→feature import 全量归零（home 收敛为组合根，残余 2 处按数据归属归位）；
2. 302 行 `ai_news_detail_components.dart` 拆分；
3. `github_token_card` 的异步业务状态改 provider；
4. `discover` 部分成功的 freshness 语义修正；
5. 删除真正零引用的死代码。

观察方式：`flutter analyze` 零问题、`flutter test` 全绿、结构测试把跨 feature 断言从
「≤9 基线」升级为「必须为 0」、CI 两个 job 均 success。

## Progress

- [x] (2026-11-08 05:42Z) 下载 Flutter 3.44.9 Windows SDK（与 CI 同版本，内含 Dart 3.12.2）到本机临时目录。
- [x] (2026-11-08 05:47Z) 复核「47 处」口径：全部跨 feature 相对 import = 47，其中跨展示层 9 处；
      47 处集中在 `home`（44）与 `project→repo_detail`、`trending→project`（各 1）。
- [x] (2026-11-08 05:48Z) `lib/features/home/**` 迁到 `lib/app/home/**`（26 文件），
      `lib/app.dart` 迁到 `lib/app/app.dart`；因目录深度相同，非跨 feature 的相对 import 无需改写，
      仅重写 17 个文件的跨 feature 引用。
- [x] (2026-11-08 05:50Z) 删除 `repo_detail/domain/entities.dart`（只转发 core 的 1 行 barrel），
      6 处引用改为直接依赖 `core/domain/contributor_entity.dart`。
- [x] (2026-11-08 05:51Z) `TrendingOverviewPage` 归位为 `features/project/presentation/star_growth_page.dart`
      的 `StarGrowthPage`，路由 `/trending/overview` 改为 `/project/growth`，
      i18n 键 `trending.overview.*` → `project.star_growth.*`（zh/en 各 13 个）。
- [x] (2026-11-08 05:52Z) 结构测试重写：跨 feature 断言改为 0，新增「组合根不得触达 feature data」
      与「首页必须位于 `lib/app/home/`」，并把 `package:github_news/**` 纳入解析。
- [x] (2026-11-08 05:53Z) 拆分 `ai_news_detail_components.dart` 为 tokens / section_title / pills /
      cards / page_frame 五个文件，5 个引用方改为精确 import。
- [x] (2026-11-08 05:54Z) 新增 `githubRateLimitCheckProvider`，Token 卡不再持有配额 `setState`；
      保存/清除 token 后重置旧配额结果。
- [x] (2026-11-08 05:55Z) `DataFreshness.partial` + 白名单失败计数 + zh/en provenance 与 feed 文案 + 回归测试。
- [x] (2026-11-08 05:56Z) 删除 4 个零引用文件（含一个制造 7 条 core→features 依赖的死 barrel）。
- [x] (2026-11-08 06:02Z) `flutter pub get --enforce-lockfile` 成功解析依赖（`Got dependencies!`，
      `pubspec.lock` 未变）；末尾因 Windows 未开开发者模式而报 symlink 警告并返回 1，不影响后续门禁。
- [x] (2026-11-08 06:12Z) `flutter analyze` 第一轮 56 issues 全部修完（`../` 前缀、残留 barrel import、
      注释内 `/**` 触发嵌套注释、24 个文件 `directives_ordering`），复跑 `No issues found!`（19.3s）。
- [x] (2026-11-08 06:16Z) `flutter test` 全绿：`All tests passed!`，612 个用例，exit 0。
- [x] (2026-11-08 06:18Z) `dart format --output=none --set-exit-if-changed lib test`：527 文件 0 changed，exit 0。
- [x] (2026-11-08 06:19Z) `check_markdown_links` / `check_repository_portability` / `git diff --check` 全部通过。
- [x] (2026-11-08 06:23Z) 分 6 个提交推送 `origin/main`（`db19646..6b14bf8`）；
      CI run 42419798846 在第 1 次尝试即双 job success（`ci-windows` 8 步、
      `server` 13 步全 passed）。

## Surprises & Discoveries

- Observation: 上一轮记录为「47 处跨 feature import」与结构测试基线 9 并不矛盾：47 是全部跨 feature
  相对 import，9 只是「跨展示层」那部分；其余 38 处是首页引用各 feature 的 application/domain。
  Evidence: 按测试同口径重算得 47 / 9，与 `test/core/architecture/layer_imports_test.dart` 基线一致。
- Observation: `home` 只有 `presentation/` 与 `widgets/`，且全仓库只有 `app_route_branches.dart`
  一处 import 它——它本来就是组合页，不是业务 feature。
  Evidence: `find lib/features/home -name '*.dart'` 与 import 反查。
- Observation: `lib/features/home/*` 与 `lib/app/home/*` 相对 `lib` 的深度相同，
  因此 `../../../core/...`、`../../../../shared/...` 全部保持有效，迁移只需处理跨 feature 引用。
  Evidence: 迁移后未改写的相对 import 全部仍可解析，`flutter analyze` 无路径错误。
- Observation: `repo_detail/domain/entities.dart` 内容只有一行 `export ../../../core/domain/contributor_entity.dart`，
  却是 `project`、`core/demo_data_mappers.dart` 与首页的跨 feature 依赖跳板。
  Evidence: `wc -l` 为 1，删除后 6 处引用改为直接依赖 core。
- Observation: `lib/core/di/feature_providers.dart` 是一个零引用的 DI barrel，本身制造 7 条 `core → features` 边。
  Evidence: 全仓库 import 反查为空；删除后 core→features 边由 46 降到 39。
- Observation: `TrendingOverviewPage` 的副标题写「最近 30 天 · 当前项目样本」，数据来自
  `projectDigestProvider`，i18n 前缀却是 `trending.overview.*`——键名与归属不一致。
  Evidence: `strings_zh_cn.dart` 原文与页面 `ref.watch(projectDigestProvider)`。
- Observation: 沙箱内 `Expand-Archive` 解压 1.77GB SDK 会停滞（8 分钟无新文件），
  改用 `C:\Windows\System32\tar.exe`（bsdtar 3.8.9）正常推进。
  Evidence: `find -newermt '-2 minutes'` 计数为 0；bsdtar 解压后文件数持续增长。
- Observation: `flutter test` 首次运行在加载阶段全数失败，报
  `Unable to connect to flutter_tester process: WebSocketException: Invalid WebSocket upgrade request`，
  并非代码问题——沙箱设置了 `HTTP(S)_PROXY=http://127.0.0.1:56311` 且 `NO_PROXY` 为空，
  连 `flutter_tester` 在 localhost 上的 VM service WebSocket 也被代理接管。
  Evidence: 去掉 `*_proxy` 并设 `NO_PROXY=127.0.0.1,localhost,::1` 后同一命令全绿。
- Observation: `package:sqlite3` 的 native-assets build hook 会从 `github.com` 下载预编译
  `sqlite3.x64.windows.dll`（沙箱对 `github.com` 的 CONNECT 返回 502），但 `api.github.com` 可达。
  Evidence: 经 Git Data / Releases API 取回 1,710,592 字节后按
  `lib/src/hook/asset_hashes.dart` 的 SHA-256（`e6ebc264…278a`）校验通过，
  并落入 hook 的 `out_dir_shared`（`.dart_tool/hooks_runner/shared/sqlite3/build/download-e6ebc264/`）
  后测试不再触发网络。

## Decision Log

- Decision: 在沙箱安装与 CI 同版本的 Flutter SDK，而不是继续「盲改 + 靠 CI 反馈」。
  Rationale: 本轮 5 项都是跨文件重构，没有编译器与测试反馈时无法判断是否破坏调用方；
  1.77GB 下载与解压成本远低于多轮 CI 往返（每轮约 12 分钟且失败信息有限）。
  Date: 2026-11-08
- Decision: 首页整体迁到 `lib/app/`，并把「组合根可以装配 feature」写进 AGENTS.md 与结构测试，
  而不是把 27 个 provider、11 个 domain 模型搬进 `lib/core/`。
  Rationale: 首页天然要组合多个 feature；把它们的状态与实体搬进 core 会造出 god-module，
  且需要改动数百处 import。组合根是公认模式，规则从「基线 9」收紧为「features 之间必须为 0」，
  比原来更严格。
  Date: 2026-11-08
- Decision: `repo_detail/domain/entities.dart` 直接删除而不是保留为 feature 内 barrel。
  Rationale: 它不聚合本 feature 的类型，只转发 `core/domain/contributor_entity.dart`，
  是纯粹的间接层，且是跨 feature 依赖的跳板。
  Date: 2026-11-08
- Decision: `TrendingOverviewPage` 迁到 project 并改名为 `StarGrowthPage`，路由改为 `/project/growth`。
  Rationale: 页面展示 `ProjectDigest`（当前项目样本）的 Star 增长，数据归属 project；
  原路径从未被任何 UI 链接引用（`grep '/trending/overview'` 为空），迁移不影响可达性。
  Date: 2026-11-08
- Decision: `DataFreshness` 新增 `partial`，只在结果本来会是 `live` 时降级。
  Rationale: 缓存与种子口径已有独立语义，不应该被「部分失败」覆盖；只有「宣称实时但不完整」
  才是需要修正的错误陈述。
  Date: 2026-11-08
- Decision: 死代码以「整文件未被任何 lib/test 文件 import」为口径，不使用符号名启发式。
  Rationale: Dart 允许类型名被推断省略，符号名计数会把大量在用类型误判为零引用；
  文件级口径可机械复核且无假阳性。
  Date: 2026-11-08
- Decision: 删除 `ai_news_grouping.dart`、`feature_providers.dart`、`platform_extensions.dart`、
  `home_alerts_panel.dart` 四个零引用文件。
  Rationale: 均为零引用；其中 `platform_extensions.dart` 的 `PlatformInfo` 抽象已被各处
  直接 `Platform.isXxx` 绕过，保留只会误导后续实现。
  Date: 2026-11-08

## Outcomes & Retrospective

上一轮 5 项「未做 / 剩余边界」全部落地，且不再依赖「本机无 Flutter」这条暂缓理由。

结果：

- 跨 feature import：47 → **0**，`test/core/architecture/layer_imports_test.dart` 由「≤9 基线」
  改为硬性 `isEmpty`，另加「组合根不得触达 feature data」「首页必须在 `lib/app/home/`」两条断言。
- `ai_news_detail_components.dart`（302 行）→ 5 个文件，最大 147 行。
- Token 卡：`setState` 业务状态归零，配额检查迁入 `githubRateLimitCheckProvider`；
  「保存清空输入 / 失败保留输入 / 卸载后完成不碰 disposed controller」三条既有回归保持通过。
- `discover` 白名单部分失败不再宣称 `live`，降级为新增的 `DataFreshness.partial`，
  zh/en 文案、provenance badge、feed status、`MetricBasis.fromLegacyName` 全部同步。
- 删除 4 个零引用文件，其中 `core/di/feature_providers.dart` 顺带消除 7 条 `core → features` 边。

本机门禁（Flutter 3.44.9 / Dart 3.12.2，与 CI 同版本）：

| 门禁 | 结果 |
| --- | --- |
| `flutter analyze` | `No issues found!`（19.3s，exit 0） |
| `flutter test` | `All tests passed!` 612 用例，exit 0 |
| `dart format --set-exit-if-changed lib test` | 527 文件 0 changed，exit 0 |
| `check_markdown_links.ps1 .` | passed |
| `check_repository_portability.ps1 .` | passed |
| `git diff --check` | clean |

CI（run [42419798846](https://github.com/XZQ/GitNews/actions/runs/42419798846)，sha `6b14bf8`，attempt 1）：

| job | 结论 | 步骤 |
| --- | --- | --- |
| `Flutter and Windows release build`（`ci-windows`） | success | 8/8 passed（含 `Run Windows build harness` 与 `Upload harness evidence`） |
| `Self-hosted server`（`server`） | success | 13/13 passed |

复盘：

- 「无编译反馈就先不做重构」是对的直觉，但代价评估错了——装一个与 CI 同版本的 SDK
  只花了约 20 分钟，而盲改一轮 CI 往返就要 12 分钟且信息量小得多。以后跨文件重构应先把
  本地门禁跑通，再谈风险。
- 47 与 9 两个数字的口径差异值得记住：定量指标必须写清统计口径，否则「已归零」和
  「基线 9」会看起来互相矛盾。
- 两处卡点都不在代码：SQLite 预编译产物的下载被代理阻断、`flutter_tester` 的 localhost
  WebSocket 被代理接管。排查时先看「是不是环境」比先看「是不是我改错了」更省时间。

已知残余边界（本轮未动，属于独立课题）：

- `lib/core/di`、`lib/core/router` 仍在装配 feature（路由表必须引用各页面），
  它们不在本轮断言范围内，但也未收敛为「core 不认识 feature」。
- 真实账号认证、外部推送网关送达、公网部署三项依赖外部环境，沙箱内无法验证。

## Context and Orientation

- `lib/app/`：应用组合根（`app.dart` 根 widget，`home/` 首页）。
- `lib/features/<feature>/`：业务特性，互不引用；共享走 `lib/core/domain`、`lib/core/config`、`lib/shared`。
- `lib/core/di`、`lib/core/router`：装配与路由，仍引用 feature（本轮未迁，属已知残余边界）。
- `test/core/architecture/layer_imports_test.dart`：机械约束上述规则。
- `lib/core/domain/data_freshness.dart`：`DataFreshness` / `MetricBasis` / `DataResult`。
- `lib/features/discover/data/discover_profile_composition.dart`：白名单抓取与 freshness 合成。
- `lib/features/profile/application/github_rate_limit_check_controller.dart`：配额检查状态。
- `docs/harness/README.md`、`docs/harness/quality_scorecard.md`、`AGENTS.md`：本轮同步的规范文本。

## Plan of Work

1. 安装 Flutter 3.44.9（与 CI 同版本）到本机临时目录，`flutter pub get --enforce-lockfile`。
2. home 迁移 + 组合根规则 + 结构测试升级 + 残余 2 处跨 feature 归位。
3. 拆分 302 行组件；Token 卡改 provider；discover 增加 partial 语义。
4. 删除零引用文件。
5. 本机跑 `dart format --set-exit-if-changed`、`flutter analyze`、`flutter test`，修到全绿。
6. 更新 AGENTS.md / CHANGELOG / Harness 文档，提交推送，读取 CI 结论。

## Concrete Steps

工作目录 `D:\BaiduSyncdisk\workspace\GitNews`；Flutter 在 `C:\Users\24491\AppData\Local\Temp\flutter3449\flutter`。

- `flutter --version`（预期 3.44.9 / Dart 3.12.2）
- `flutter pub get --enforce-lockfile`（预期不修改 `pubspec.lock`）
- `dart format --output=none --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/check_markdown_links.ps1 .`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/check_repository_portability.ps1 .`
- `git diff --check`

## Validation and Acceptance

- 结构测试断言：feature 之间互相 import == 0；展示层与组合根不得触达 feature `data/`；首页在 `lib/app/home/`。
- `flutter analyze` 无 error / warning / info；`flutter test` 全绿（含新增 partial 回归与 Token 卡既有三条回归）。
- `dart format --set-exit-if-changed lib test` 为 0 changed。
- CI `ci-windows` 与 `server` 两个 job 均 success；本地 HEAD 与 `origin/main` 一致。

## Idempotence and Recovery

全部改动为源码内可逆编辑；不删用户数据、不改凭据、不 force push。
文件迁移用 `git mv` 保留历史，可按提交粒度 revert。
Flutter SDK 装在系统临时目录，不进入仓库、不进入 `PATH` 持久配置。

## Artifacts and Notes

- Flutter SDK：`C:\Users\24491\AppData\Local\Temp\flutter3449\flutter`（不入库）。
- CI：[run 42419798846](https://github.com/XZQ/GitNews/actions/runs/42419798846)，
  被验证的代码状态 `6b14bf8`，两个 job 均 success，Harness 证据随 run 上传。
- 提交序列：`1ba75f1`（组合根 + import 归零）、`851ee0d`（组件拆分）、
  `ba54c07`（配额 provider）、`6d25726`（partial 语义）、`75037f2`（死代码）、
  `6b14bf8`（文档同步）。

## Interfaces and Dependencies

不新增运行时依赖，不改 `pubspec.yaml` / `pubspec.lock`。
`DataFreshness` 增加枚举值 `partial`（穷尽 switch 处同步补齐）。
`fetchProfileWhitelist` 返回类型由 `List<DiscoverProfileEntity>` 改为 `DiscoverProfileWhitelist`
（唯一调用方在同文件内）。
新增 `githubRateLimitCheckProvider`（`NotifierProvider<GitHubRateLimitCheckController, AsyncValue<GitHubRateLimitSnapshot>?>`）。
`TrendingOverviewPage` 重命名为 `StarGrowthPage`，路由 `/trending/overview` → `/project/growth`。
