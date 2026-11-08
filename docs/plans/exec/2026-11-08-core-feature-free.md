# core 层去 feature 化：路由与装配归位组合根

状态：Complete

本计划遵循 `.agent/PLANS.md`，执行期间必须保持内容与实际状态一致。
承接 `2026-11-08-architecture-closure.md` 里记入「已知残余边界」的那一条：
`lib/core/di` 与 `lib/core/router` 仍在装配 feature。

## Purpose / Big Picture

上一轮把跨 feature import 收成了 0，但 `lib/core/` 里还有 **39 条**指向 `lib/features/`
的 import，分布在 5 个文件：

| 文件 | 条数 | 性质 |
| --- | --- | --- |
| `core/router/app_route_branches.dart` | 31 | 路由表引用各 feature 页面 |
| `core/di/project_composition.dart` | 5 | 用 trending 的 feed 装配 project 仓库 |
| `core/router/app_router.dart` | 1 | `/webview` 路由引用 webview 页面 |
| `core/preferences/config_service.dart` | 1 | 导入配置后 invalidate monitor 设置 |
| `core/demo_data_mappers.dart` | 1 | 演示告警映射用到 monitor 的 domain |

后三项其实都是「装配」而非「core 能力」，所以 core 成了伪叶子层：任何 feature
改动都会向上污染它。目标是把这 39 条压到 **0**，并把规则写成断言。

观察方式：`grep` 统计 core→features 为 0；结构测试新增「core 不得 import 任何
feature」；`flutter analyze` 零问题、`flutter test` 全绿、CI 双 job success。

## Progress

- [x] (2026-11-08 08:40Z) 复核 39 条明细，确认拆分为「路由装配 32」「仓库装配 5」
      「配置失效钩子 1」「演示数据映射 1」四类。
- [x] (2026-11-08 08:44Z) `core/router/app_router.dart` 与 `app_route_branches.dart`
      迁到 `lib/app/router/`（目录深度相同，`../../features/...` 相对路径无需改写）；
      删除 `app_router` 对 `route_specs` 的再导出，`shared/` 三个组件改为直接依赖
      `core/router/route_specs.dart`。
- [x] (2026-11-08 08:47Z) `core/di/project_composition.dart` 按归属迁回
      `features/project/application/project_composition.dart`；trending 依赖换成
      core 声明的 `repositoryFeedProvider`。
- [x] (2026-11-08 08:49Z) 新增 `core/di/repository_feed_providers.dart`：占位
      provider，缺省抛 `StateError`，由组合根 override（与既有
      `sharedPreferencesProvider` / `appDatabaseProvider` 同一套约定）。
- [x] (2026-11-08 08:51Z) 新增 `lib/app/di/app_overrides.dart`：集中装配
      preferences / database / auth / repositoryFeed / configInvalidationHooks；
      `lib/bootstrap.dart` 改为调用 `buildAppOverrides(...)`，不再 import 任何 feature。
- [x] (2026-11-08 08:53Z) `config_service.dart` 的 monitor invalidate 改为
      `configInvalidationHooksProvider` 钩子；`monitorNotificationCount` 作为
      配置契约常量移入 core（与 `monitorRuleCount` 同处理）。
- [x] (2026-11-08 08:55Z) 删除未使用的演示告警数据与 mapper（`DemoData.alerts`、
      `DemoAlertFixture`、`alertSeverity*`、`DemoAlertFixtureX`），core 不再依赖
      monitor 的 domain。
- [x] (2026-11-08 08:57Z) 结构测试新增 3 条断言：core 不得 import feature、
      组合根必须持有 `router/` 与 `di/`、`core/router/app_router.dart` 不得复现。
- [x] (2026-11-08 08:58Z) `flutter analyze` 修到 `No issues found!`；期间遇到三处真实问题：
      `Override` 要从 `flutter_riverpod/misc.dart` 引入、`config_service` 还用了
      `monitorNotificationCount`（不只 invalidate）、Riverpod 3 异常包装导致契约测试断言失效。
- [x] (2026-11-08 09:00Z) `flutter test`：616 用例全过；`dart format --set-exit-if-changed`
      530 文件 0 changed。
- [x] (2026-11-08 09:01Z) `check_markdown_links` / `check_repository_portability` /
      `git diff --check` 全部通过。
- [x] (2026-11-08 09:14Z) CI run 42432458449（sha `02dbd86`，attempt 1）双 job success：
      `ci-windows` 9/9 步、`server` 9/9 步全 passed。

## Surprises & Discoveries

- Observation: `lib/shared/widgets/` 的三个组件是通过 `app_router.dart` 的
  `export 'route_specs.dart'` 间接拿到 `appTabs` 的，而不是真的需要 router。
  Evidence: 三个文件只用到 `appTabs` / `mobileAppTabs` / `indexOfLocation`。
- Observation: `lib/app/` 本来就没有任何 `features/*/data/` import，所以上一轮那条
  「组合根不得触达 data」的断言不需要放宽，`project_composition` 迁走后依然为 0。
- Observation: `DemoData.alerts` 与 `DemoAlertFixtureX.toEntity()` 全仓库零调用，
  core 对 monitor domain 的唯一依赖其实是死代码。
  Evidence: `grep DemoAlertFixture` 只命中定义自身与其常量。
- Observation: Riverpod 3 把 provider 内部抛出的异常包成 `ProviderException`，
  所以「占位 provider 缺省抛错」的契约测试不能用 `throwsStateError`，要断言
  错误文案。
- Observation: `config_service` 除了 invalidate monitor，还用
  `monitorNotificationCount` 校验导入的 `monitor_notification_settings` 长度；
  这条依赖不是「失效」而是「契约常量」，必须与钩子分开处理。

## Decision Log

- Decision: 路由表迁到 `lib/app/router/`，而不是让每个 feature 自注册 `GoRoute`。
  Rationale: 自注册需要 core 提供可变注册表，会把「路由顺序、shell 分支归属」这类
  全局决策拆散到 13 个 feature 里，且改动面远大于移动两个文件。组合根持有路由是
  go_router 的常规用法。
  Date: 2026-11-08
- Decision: core 需要 feature 能力时用「占位 provider + 组合根 override」。
  Rationale: 仓库里 `sharedPreferencesProvider` / `appDatabaseProvider` 已经是这个
  模式（缺省 `throw StateError('… must be overridden in main()')`），复用同一约定
  比引入 service locator 或回调注册更一致，也让「忘记装配」立刻显性失败。
  Date: 2026-11-08
- Decision: `project_composition.dart` 迁回 project feature，而不是留在 `lib/app/di/`。
  Rationale: 它构造的是 project 自己的 `ProjectRepository`，`project_providers.dart`
  要 re-export 它；若放在 `app/`，feature 就得反向 import 组合根。放在 feature 内、
  用 core 的 `RepositoryFeed` 抽象解耦 trending，依赖方向才是单向的。
  Date: 2026-11-08
- Decision: `monitorNotificationCount` 移入 core 而不是走钩子注册校验器。
  Rationale: 它只是一个长度常量，与已存在的 `monitorRuleCount` 完全同构；为一个
  整数引入一套校验器注册机制不划算。
  Date: 2026-11-08
- Decision: 删除演示告警数据而不是把 `AlertEntity` 搬进 `core/domain/`。
  Rationale: 全仓库零调用，搬运只会让死数据获得更长的生命。
  Date: 2026-11-08

## Outcomes & Retrospective

| 指标 | 前 | 后 |
| --- | --- | --- |
| `lib/core/` → `lib/features/` import | 39（5 文件） | **0** |
| `lib/app/` → `features/*/data/` import | 0 | **0**（未放宽断言） |
| 除 features 自身外装配 feature 的目录 | `core/`、`app/` | **仅 `app/`** |
| `flutter analyze` | — | `No issues found!` |
| `flutter test` | 613 | **616 全过** |
| `dart format --set-exit-if-changed` | — | 530 文件 0 changed |

CI（run [42432458449](https://github.com/XZQ/GitNews/actions/runs/42432458449)，
sha `02dbd86`，attempt 1）：`ci-windows` 与 `server` 均 success，各 9/9 步 passed。

复盘：

- 这一轮把「core 是叶子层」从口号变成了可断言的事实。之前 core 只是**约定上**的
  基础层，实际被 5 个文件拽着 13 个 feature 的历史包袱。
- 39 条里有 32 条是路由，属于「看起来必须耦合、其实只是放错目录」。真正需要设计
  判断的只有 `project → trending` 那一条，解法是既有的占位 provider 约定，没有
  引入新机制。
- 顺带清掉的死演示数据说明一件事：`core` 里的「共享 fixture」很容易变成没人用的
  历史沉积，因为没人会去删 core 里的东西。

## Context and Orientation

- `lib/app/router/`：`app_router.dart`（GoRouter + shell）、`app_route_branches.dart`（13 个分支）。
- `lib/app/di/app_overrides.dart`：core 占位 provider 的唯一实现处。
- `lib/core/router/route_specs.dart`：纯 UI 的 IA 常量（tab 顺序、路径段），不引用 feature。
- `lib/core/di/repository_feed_providers.dart`：`RepositoryFeed` 的注入点。
- `lib/features/project/application/project_composition.dart`：投影仓库装配。
- `lib/core/preferences/config_service.dart`：`configInvalidationHooksProvider` 与
  `monitorNotificationCount` 契约常量。
- `test/core/architecture/layer_imports_test.dart`：四条 0 断言 + 两条结构断言。

## Plan of Work

1. 迁路由到 `lib/app/router/`，修 `shared/` 与 `app.dart` 的 import 与再导出。
2. 迁 `project_composition` 回 project，trending 依赖换成 core 占位 provider。
3. 新增 `app_overrides.dart`，bootstrap 改为调用它。
4. config_service 改钩子 + 契约常量归位；删死演示数据。
5. 结构测试加断言，修被影响的两个测试。
6. 本机门禁 + 文档同步，提交推送，读 CI。

## Concrete Steps

工作目录 `D:\BaiduSyncdisk\workspace\GitNews`；Flutter 在
`C:\Users\24491\AppData\Local\Temp\flutter3449\flutter`。

- `dart format --output=none --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test`（须清空 `HTTP(S)_PROXY` 并设 `NO_PROXY=127.0.0.1,localhost,::1`，
  否则 `flutter_tester` 的 localhost WebSocket 会被代理接管）
- `powershell -File tools/check_markdown_links.ps1 .`
- `powershell -File tools/check_repository_portability.ps1 .`
- `git diff --check`

## Validation and Acceptance

- `grep -c "features/" lib/core/**/*.dart` 全为 0；结构测试 `core must not import any feature` 通过。
- 结构测试 `composition root owns routing and provider wiring` 通过。
- `flutter analyze` 无 error/warning/info；616 用例全绿；格式 0 changed。
- CI `ci-windows` 与 `server` 均 success。

## Idempotence and Recovery

全部为源码内可逆编辑，文件迁移用 `git mv` 保留历史；不删用户数据、不改凭据、
不 force push。占位 provider 缺省抛错，装配遗漏会在启动时立刻暴露而不是静默降级。

## Artifacts and Notes

- 迁移前的 39 条明细见本文件 Purpose 表格；逐条清单可用
  `grep -rnE "import '((\.\./)+|package:github_news/)features/" lib/core` 复现（现为 0）。
- CI：[run 42432458449](https://github.com/XZQ/GitNews/actions/runs/42432458449)，
  被验证的代码状态 `02dbd86`，两个 job 均 success，Harness 证据随 run 上传。
- 提交序列：`0eb047f`（路由迁移）、`06918d0`（core 依赖倒置）、`7213cbf`（删死演示数据）、
  `02dbd86`（结构断言 + 文档）。

## Interfaces and Dependencies

不新增运行时依赖，不改 `pubspec.yaml` / `pubspec.lock`。
新增 provider：`repositoryFeedProvider`（core 占位）、`configInvalidationHooksProvider`（core 钩子）。
新增函数：`buildAppOverrides({preferences, database, authRepository}) -> List<Override>`。
移动类型/文件：`appRouterProvider`、`buildAppRouter`、`buildAppRouteBranches` 迁到 `lib/app/router/`；
`projectRepositoryProvider`、`localProjectRepositoryProvider` 迁到 `features/project/application/`，
`projectRepositoryFeedProvider` 删除（由 `repositoryFeedProvider` 取代）。
`fetchProfileWhitelist` 等上一轮接口不变。
