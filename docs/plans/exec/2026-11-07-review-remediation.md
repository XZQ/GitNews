# 全项目审查发现的分批整改与验证

状态：Active

本计划遵循 `.agent/PLANS.md`，执行期间必须保持内容与实际状态一致。
用户明确要求：逐个确认发现、完善修复、提交并推送到 `origin/main`。

## Purpose / Big Picture

把 2026-11-07 全项目梳理确认的真实缺陷修掉，让降级路径不再覆盖用户数据、
限流与服务端时间语义一致、Device Flow 与 README 承诺一致、关键失败可观测，
并用结构与回归测试卡住增量。观察方式：新增回归测试通过、CI 的
`ci-windows` 与 `server` 两个 job 均 success、远端 SHA 与本地一致。

## Progress

- [x] (2026-11-07 02:30Z) 逐条复核梳理结论；确认两处为刻意设计、不修改行为。
- [x] (2026-11-07 02:30Z) 探测本机工具链：flutter / dart / uv / pytest 均不可用。
- [x] (2026-11-07 03:10Z) 批次 A：快照与观测历史的「降级读 → 全量写回」数据丢失，含 5 个回归。
- [x] (2026-11-07 03:10Z) 批次 B：趋势限流回退种子、服务端 feed 时间兜底改为 0，含 3 个回归。
- [x] (2026-11-07 03:10Z) 批次 C：Device Flow 按 `githubOAuthConfigured` 接入登录页，README 表述对齐。
- [x] (2026-11-07 03:10Z) 批次 D：桌面/窗口/认证/后台刷新/发现/路由补日志，导出失败文案与 i18n。
- [x] (2026-11-07 03:10Z) 批次 E：缓存表清单改名、自托管路径与请求头集中、3 处乱码注释修复、跨层 import 基线测试。
- [x] (2026-11-07 03:10Z) 本机静态校验：`git diff --check`、Python `py_compile`、相对 import 存在性、import 排序、i18n 双边一致、行宽均通过。
- [x] (2026-11-07 02:55Z) 6 个分项提交并 push 至 `origin/main`(`33cd916`)，本地与远端 SHA 一致。
- [x] (2026-11-07 02:56Z) 首轮 CI：`server` job success；`ci-windows` 在
  `flutter.changed-format-check` 失败(5 个 Dart 文件)，后续 analyze/test/build 未执行。
- [x] (2026-11-07 03:08Z) 下载与 CI 同版本的 Dart 3.12.2 SDK，精确复现格式判定后格式化
  这 5 个文件，本地复检 25 个改动文件 `0 changed`。
- [x] (2026-11-07 03:05Z) 第二轮 CI：`server` 全绿(ruff / pytest / live-smoke)；
  `ci-windows` 的格式、链接、可移植性均通过，`flutter.analyze` 报 6 个 error。
- [x] (2026-11-07 03:12Z) 修复 6 个 error(泛型 const 3 处、RegExp 非 const 构造、
  可空 apiKey 类型)，本地 Dart 3.12.2 复检 25 文件 `0 changed`。
- [x] (2026-11-07 03:13Z) 第三轮 CI：`server` 全绿；`ci-windows` 的 analyzer 仅剩
  1 个 `use_super_parameters` info，但门禁仍判失败。已局部抑制并写明父类私有形参原因。
- [x] (2026-11-07 03:14Z) 推送 lint 修复 `b2f6143`，本地与远端 SHA 一致。
- [x] (2026-11-07 03:20Z) 第四轮 CI：`server` 6/6 通过；`ci-windows` 停在
  `flutter.changed-format-check`，失败与 Dart 代码格式无关，是 Harness 单文件边界 bug。
- [x] (2026-11-07 03:35Z) 本机用 Dart 3.12.2 精确复现 `No file or directory found at "t"`
  与 `/System Volume Information\*`；定位为 `if` 表达式把单元素数组 unwrap 成标量，
  `@formatTargets` splat 标量后按字符传参。
- [x] (2026-11-07 03:40Z) 修脚本为 `[string[]]$formatTargets`，新增契约与 Windows
  行为回归测试；本机两种单文件场景均 `passed for 1 file(s)`，Harness `-List` 与
  `docs -DryRun` 通过。
- [ ] 推送本轮 Harness 修复，读取第五轮 CI 完整结论并把本计划标记为 Complete。

## Surprises & Discoveries

- Observation: 本机没有 Flutter / Dart SDK，`flutter`、`dart`、`uv` 均不在 PATH，
  工作区也没有 `.dart_tool/` 或 `build/`；`python` 3.13 可用但无 pytest。
  Evidence: `flutter --version` / `dart --version` / `uv --version` 均 command not found；
  PowerShell 全盘 depth-5 搜索 `flutter.bat` 无结果。
- Observation: `local_database.clearAll()` 只清 4 张表是刻意设计，不是漏维护。
  Evidence: `database_schema.dart:54-56,143` 明确把 ai_news_state / ai_news_reminder
  标为用户数据；monitor_alert_event、ai_news_feedback 亦为用户数据；
  ai_news_enrichment 是「结果按条目和模型持久缓存」的离线内容。仅改命名与注释。
- Observation: Device Flow controller 已完整实现（写安全存储 token、拉 /user 回填），
  UI 186 行也完整，只是零引用。因此接线优于删链。
  Evidence: `github_device_flow_controller.dart:146-162`；`device_flow_content.dart`。
- Observation: 服务端 FCM/APNs/WNS 只入 outbox 是刻意留给外部网关，非桩实现。
  Evidence: `server/README.md:60` 与 `routers/push.py` 的 /outbox/ack 接口。
- Observation: 初步梳理把 `enforceCap()` 与 `homeSeriesForWindow` 判为「零引用死代码」，
  复核发现二者均有测试引用，因此本轮不删除任何被认为零引用的文件。
  Evidence: `test/core/storage/local_database_test.dart:49,53`、
  `test/features/home/home_providers_test.dart:147-198`。
- Observation: `lib/shared/widgets/mobile_page_header.dart:25` 与
  `lib/features/trending/application/trending_providers.dart:97-98` 存在 UTF-8 被误按
  GBK 解码的乱码注释，已按语义重写。原始字节已不可精确还原(含替换字符)。
  Evidence: Python 还原脚本对三段文本均无法 encode('gbk')。
- Observation: 本机虽无 Flutter，但可从 Google Storage 单独下载 Dart SDK(214 MB)；
  临时屏蔽 `analysis_options.yaml` 中因缺少 package_config 而无法解析的 include 后，
  `dart format` 即可精确复现 CI 判定(同样 25 文件 / 5 changed)，无需完整 Flutter 或 VS。
  Evidence: 首轮 artifact 里 `03-flutter.changed-format-check.log`，与本地 Dart 3.12.2
  输出逐文件一致；临时改动用 try/finally 即时还原，未进入提交。
- Observation: 首轮 CI 的 `server` job 已 success，说明 `feeds.py` 改动与新增测试
  通过了 Ruff 与 pytest；Flutter 侧当时尚未执行到 analyze/test。
  Evidence: run 42331315470 的 jobs 结论。
- Observation: Dart 3.12 不允许 const 构造使用类型参数作为类型实参
  (`const_with_type_parameters`)，且 `RegExp` 构造函数并非 const；纯静态检查
  无法发现，由 CI 的 `flutter.analyze` 暴露。
  Evidence: run 42332010580 的 `04-flutter.analyze.log`，6 个 error 全部有明确行号。
- Observation: `ServerConnectionState.apiKey` 是 `String?`；把请求头集中到 support
  类时必须接收可空值，并避免生成看似有效的 `Bearer` 头。
  Evidence: `lib/core/preferences/server_connection_controller.dart:28`。
- Observation: 第四轮 `flutter.changed-format-check` 失败与 Dart 代码格式无关。
  PowerShell 的 `if` 表达式赋值会把单元素数组 unwrap 成 `System.String`；
  `@formatTargets` 对标量 splatting 给原生 exe 时按字符逐个传参，`dart format`
  因此收到 `t`/`e`/`s`/`t`/... 并把根目录字符参数展开到 `/System Volume Information\*`。
  Evidence: run 42333112096 的逐步日志；`git diff 6bf1b5d...HEAD -- lib test` 仅 1 个
  Dart 文件；本机用独立 Dart 3.12.2 SDK 复现得到逐字一致的报错。
- Observation: 修复后用 CI 等价行宽（`analysis_options.yaml` 临时屏蔽无法解析的
  include，try/finally 字节级还原）在本机验证：真实仓库 `Formatted 1 file (0 changed)`
  与临时仓库单文件场景均返回 `passed for 1 file(s)`。
  Evidence: 本机 PowerShell + Dart SDK 执行输出；`harness.ps1 -List` 与
  `-Suite docs -DryRun` 均退出 0。

## Decision Log

- Decision: 不本机运行 Flutter/Harness 门禁，改由 GitHub Actions 作为完整验证门，
  push 后读取 CI 结论；本机只执行可做的静态校验（Python 语法编译、Dart import
  路径与括号/JSON 结构检查、git diff --check）。
  Rationale: 仓库既有先例（2026-10-12 计划同样因本机缺 Visual Studio 靠 CI 验证）。
  Date: 2026-11-07
- Decision: 批次 A 采用「损坏标志 + 禁止覆盖写回」，不改 LocalContentState 公开 API。
  Rationale: 保留 UI 可用性与现有测试构造，改动最小且可逆。
  Date: 2026-11-07
- Decision: 限流无缓存时不打远端，抛 AppException(rateLimit) 交给上层统一降级。
  Rationale: 与其余 6 个仓库的 gate.isBlocked 语义一致。
  Date: 2026-11-07
- Decision: Device Flow 在登录页按 githubOAuthConfigured 条件渲染卡片，不新建路由。
  Rationale: 编译期常量决定可用性，登录页本就是 ListView；避免改动路由表。
  Date: 2026-11-07
- Decision: 47 处 feature→feature import 本轮只加基线结构测试卡增量，不做全量搬迁。
  Rationale: 属重构级改动，在无编译反馈的环境下全量搬迁风险不可控；home 聚合页
  本就需要组合各 feature 卡片，收益低于风险。
  Date: 2026-11-07
- Decision: 服务端时间解析失败返回 0（epoch）而非当前时间。
  Rationale: 旧文章排到末尾、不会被 since 反复当新文章；保持返回 int 的签名不变。
  Date: 2026-11-07
- Decision: 本轮不删除零引用文件、不拆 302 行组件、不把 github_token_card 改 provider、
  不做 47 处跨 feature import 全量搬迁，也不改 `discover` 部分成功时的 freshness 语义。
  Rationale: 均属重构或语义变更，在本机无编译反馈的前提下风险高于收益；
  用新增结构测试先卡住增量，后续有 Flutter SDK 时按专题处理。
  Date: 2026-11-07
- Decision: 修复 `tools/check_changed_dart_format.ps1` 这一窄组件，不改 CI 清单、
  不跳过该步骤、不把改动检查降级为全量基线，并把边界固化为契约与行为回归测试。
  Rationale: 遵循 `docs/harness/README.md`「把重复失败提升为测试」；根因可精确复现，
  修复面只有一处显式数组类型声明，绕开只会掩盖真实边界缺陷。
  Date: 2026-11-07

## Outcomes & Retrospective

代码与本机可执行的静态校验已全部完成；本机**没有**执行 Flutter / uv / pytest
门禁，仅用独立 Dart 3.12.2 SDK 执行过 `dart format` 与改动文件格式检查，
完整验证交由 GitHub Actions。本计划在读取 CI 结论、补录证据前保持 Active。

已确认排除的两类误报：`clearAll` 只清 4 张可再生存量表是刻意设计(仅改名与注释)；
服务端 FCM/APNs/WNS 只入 outbox 是留给外部网关的设计。

本轮未处理的重构项见 Decision Log，均已在交付说明中列出。剩余风险：
本机已能用独立 Dart 3.12.2 SDK 精确执行 `dart format --set-exit-if-changed`，
但仍无法执行 `flutter analyze`、`flutter test` 与 Release 构建；编译、全量测试与
Windows 构建只能由 CI 暴露后修复。新增的行为回归测试也只能在 Windows CI 上
真正执行（本机无 `flutter test`）。

## Context and Orientation

- `lib/core/shared/`：收藏/监控/关注实体的本地快照（`local_content_snapshots.dart`
  编解码、`local_content_defaults.dart` 默认值补齐、`local_content_controller.dart`
  Riverpod Notifier 与持久化）。
- `lib/features/monitor/data/monitor_observation_dao.dart`：每日 Star/Fork 观测，
  读写 `json_snapshot_cache`。
- `lib/features/trending/data/cached_trending_data_source.dart`：热榜缓存 + 限流门。
- `lib/features/profile/presentation/login_page.dart` 与 `widgets/`：应用账号登录。
- `server/app/feeds.py`：RSS/Atom 解析，`_parse_time` 产出毫秒时间戳。
- `lib/core/utils/app_logger.dart`：唯一日志门面，`warn(tag, meta: {...})`。
- 测试位于 `test/` 与 `server/tests/`；门禁定义在 `tools/harness.json`，
  CI 在 `.github/workflows/harness.yml`（ci-windows + server 两个 job）。

## Plan of Work

1. 批次 A：`decode*Snapshots` 返回损坏标志；controller 持有标志，`_persist*` 在
   损坏时跳过写回并 warn；`MonitorObservationDao` 增加 `readWithStatus`，
   `record()` 在损坏时跳过写入以保住原历史。补 4 个回归。
2. 批次 B：限流分支抛 `AppException`；`_parse_time` 兜底改为 0 并记录；补回归。
3. 批次 C：登录页条件渲染 Device Flow 卡片；修正 README 表述。
4. 批次 D：桌面集成、窗口服务、认证初始化、后台刷新、discover 白名单、
   profile 导出文案等静默 catch 补日志或修正文案。
5. 批次 E：`_kBusinessTables` 改名并写清甄别标准；自托管路径集中；
   删除零引用死代码；302 行组件拆分；新增跨层 import 基线结构测试。
6. 验证与交付：`git diff --check`、Python 编译检查、Dart import 静态校验，
   分项 `Fix(scope):中文描述` commit，push origin/main，核对 SHA 与 CI。

## Concrete Steps

工作目录均为仓库根 `D:\BaiduSyncdisk\workspace\GitNews`，服务端命令在 `server/`。
本机可执行的检查：
- `python -m py_compile server/app/feeds.py`（预期退出 0）
- `python tools/check_dart_imports.py` 风格的只读静态校验（临时脚本，不落盘）
- `git diff --check`（预期无输出）
- `git diff --stat`、`git status --short`（确认改动范围）

本机**无法执行**（须如实记录，不得表述为通过）：
`dart format`、`flutter analyze`、`flutter test`、`flutter build windows --release`、
`uv run ruff check .`、`uv run ruff format --check .`、`uv run pytest`、
`uv run python tools/live_smoke.py`、Harness 各 suite、桌面交互烟测。
替代验证：push 后 `.github/workflows/harness.yml` 的 `ci-windows` 与 `server`。

## Validation and Acceptance

- 新增回归覆盖：快照整体损坏 / 单条损坏时不覆盖持久数据；观测历史损坏时
  `record()` 不覆盖原 payload；限流且无缓存时不发远端请求；feed 缺时间不排到最前。
- CI 两个 job 均 success；若失败，修复根因后重新推送并再次读取结论。
- `git status --short` 为空，本地 HEAD 与 `origin/main` SHA 一致。
- 计划 `Progress` 全部勾选、`Outcomes & Retrospective` 写明未执行项与剩余风险后
  才能标记 Complete。

## Idempotence and Recovery

所有改动为源码内可逆编辑；不删用户库、不改生产凭据、不 force push。
失败时按 commit 粒度 `git revert`，无需迁移脚本。重跑测试不会修改持久数据。
推送前确认 `git status -sb` 与远端一致；推送后如 CI 失败，只追加修复提交。

## Artifacts and Notes

- 梳理结论存于 `.workbuddy/memory/2026-11-07.md`（本地记忆，不提交）。
- 首轮 CI：https://github.com/XZQ/GitNews/actions/runs/42331315470
  （`server` success；`ci-windows` 格式步骤失败，证据 artifact `harness-flutter-windows`
  的 run id `20261107T025445312Z-1268/summary.json`）。
- 第二轮 CI：https://github.com/XZQ/GitNews/actions/runs/42332010580
  （`server` 6/6 通过；`ci-windows` 到 `flutter.analyze` 为止，6 个 error 已定位）。
- 第三轮 CI：https://github.com/XZQ/GitNews/actions/runs/42332593462
  （`server` 6/6；`ci-windows` 到 `flutter.analyze`，仅剩 1 个 info）。
- 第四轮 CI：https://github.com/XZQ/GitNews/actions/runs/42333112096
  （`server` 6/6；`ci-windows` 停在 `flutter.changed-format-check`，单文件 splatting bug）。
- 第五轮 CI 链接在结论确认后补入本节。
- `build/harness/` 为忽略目录；本轮本机 `-Suite docs -DryRun` 产生过一份计划摘要，
  该目录仍被忽略、不进入提交。

## Interfaces and Dependencies

不新增运行时依赖，不改 pubspec / uv.lock / pubspec.lock。
`decodeRepoSnapshots` / `decodeDeveloperSnapshots` 保持返回 Map 的旧签名，
新增 `hasCorrupt*Snapshots(String? raw)` 只读探测函数；
`MonitorObservationDao` 新增 `readWithStatus`，`read` 行为保持不变。
`DeviceFlowContent` 由死文件变为登录页条件渲染的子组件，公开构造不变。
