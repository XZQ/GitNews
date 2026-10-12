# 深度审查与可靠性修复

状态：Complete

本计划遵循 `.agent/PLANS.md`。用户已授权深度 review、列出规划、逐项完成并 push；当前分支为 `main`，审查基线 `78ab162`，初始工作树干净。

## Purpose / Big Picture

让凭据始终只发送到用户配置的服务器，清除 Token 后不复活，网络暂时失败后可以恢复刷新与翻页，报告不把缺失数据当作完整数据；让可选服务端保留工作区隔离、原子版本更新、完整同步和可靠通知。本轮保持本地优先、桌面 8 入口/紧凑 5 Tab、现有依赖锁文件。

## Progress

- [x] (2026-10-12 00:38Z) 读取规则、产品边界、运行说明、历史整改与 Harness；检查 Git 状态和远端基线。
- [x] (2026-10-12 00:38Z) 三个独立方向完成代码审查，服务端使用真实 SQLite 复现隔离、并发、分页、时间排序和 outbox 丢失问题。
- [x] R01 自托管凭据与服务器绑定，保存失败和初始化竞争不造成错配。
- [x] R02 GitHub Token 迁移、设置、清除串行，移除旧明文并防止复活。
- [x] R03 托盘初始化失败恢复正常窗口关闭。
- [x] R04 AI HOT DTO 转换保留条件请求验证状态，后台 304 后可重试。
- [x] R05 普通资讯流翻页失败保留 cursor 和重试能力。
- [x] R06 深度报告部分失败保留完整快照并标记降级；活动状态参与汇总。
- [x] R07 批注按 workspace 隔离，版本检查与写入原子化。
- [x] R08 同步版本冲突与并发单调性、可靠分页游标；旧 since 保留原排序，revision 初始页使用 cursor=start。
- [x] R09 GH Archive 小时校验、数值排序与旧记录兼容。
- [x] R10 资讯条目与通知 outbox 同一事务提交。
- [x] R11 客户端定向拉取共享配置，处理删除记录。
- [x] R13 修复三处 try 中未 await 的异步异常边界；固定 CI SDK 与锁文件。
- [x] (2026-10-12 15:10Z) 聚焦 Flutter 回归 83 项通过，服务端首轮聚焦 26 项通过；托盘补 5 项 channel 回归，完整门禁开始。
- [x] (2026-10-12 15:16Z) 完整 server Harness 6/6 通过：Ruff、42 项 pytest、真实 Uvicorn health/auth/source/sync 往返。
- [x] (2026-10-12 22:33Z) 修复托盘 debug platform fixture，5/5 通过；换地址留空 Key、Token legacy 删除失败与持久化失败 UI 补充聚焦检查 16/16 通过。
- [x] (2026-10-12 22:31Z) 服务端 R07–R10 分项提交：6184095、8848546、3a0492d、b180e5d。
- [x] (2026-10-12 22:37Z) 完整 Flutter Harness 7/7 通过：599 项测试、全量 analyze、lib/test 格式、增量格式、可移植性、diff 与文档链接检查。
- [x] (2026-10-12 22:38Z) 客户端 R01–R06、R11、R13 分项提交；完整代码范围为 6184095..eabca1d，共 12 个 Fix 提交。
- [x] (2026-10-12 22:54Z) 代码与首轮文档正常 push main，提交 6d6044a；本地/远端 SHA 一致，工作树干净。
- [x] (2026-10-12 22:54Z) GitHub Actions 38317808095 全部 success：server 6/6，ci-windows 8/8，包含 Windows Release 构建；已读取最终日志确认。
- [x] R12 文档、独立复核、完整适用门禁、分项提交与 push。

## Surprises & Discoveries

- Observation: 现有回归覆盖许多正常和失败路径，但真实客户端 DTO 丢失 `revalidated`，mock 后台测试没有穿透该边界；普通流分页也没有网络失败后重试用例。
  Evidence: `ai_news_api_client.dart` 重建 DataResult；`ai_news_items_notifier.dart` 将 cursor 未变当作结束。
- Observation: 报告聚合的 `gatherAll` 丢弃部分失败后仍覆盖完整聚合缓存，活动 loader 丢失 freshness。
  Evidence: `github_project_repository.dart`、`github_project_activity_loader.dart`。
- Observation: 批注全局 ID 冲突跨工作区覆盖；sync SELECT 与写入之间并发可降版本，相同时间分页遗漏；GH 小时非补零字符串排序错误；资讯与 outbox 分开提交导致失败重试永久漏通知。
  Evidence: 服务端独立审查使用真实 SQLite 及并发/故障注入复现。
- Observation: 当前机器 Flutter/Dart 不在 PATH、没有现成依赖缓存或 Visual Studio；uv 在独立工具目录可用。
  Evidence: Harness Doctor 拒绝缺失 Flutter；为本轮验证在用户缓存目录恢复官方 Flutter 3.44.9 / Dart 3.12.2，与项目 Dart 3.12 格式基线一致；服务端按 uv.lock 创建隔离环境。
- Observation: 审查基线最近两次 Windows CI 均失败；滚动 stable 更新到 Dart 3.13 后暴露三处 try 返回 Future 未 await 的边界，并自动改写七项依赖。
  Evidence: GitHub Actions run `35793313242` 的 `flutter.analyze` 日志；修复异常边界并固定与锁文件/现有格式基线兼容的 SDK，不关闭分析规则。
- Observation: 独立复核发现 revision 分页不能直接替换 legacy 时间排序，否则旧客户端首轮分页可能跳过现存快照。
  Evidence: 构造 revision 顺序与 updated_at 相反的三条记录；保留旧排序并为 revision 分页显式定义起点。
- Observation: 地址绑定还必须贯通编辑界面；原界面更换 URL 后留空 Key 会把旧 Key 作为新 Key 重绑。Token 保存还需在写新 secure 值前完成旧明文清理，失败由界面展示。
  Evidence: 独立复核 controller 调用方，新增页面及偏好失败注入回归。
- Observation: server smoke 首轮与全量 Flutter 并发运行时超过 15 秒启动窗口，独立复跑通过。
  Evidence: 首轮 `20261012T151251712Z-16752` 中 pytest 42 通过但 smoke 超时；完整重跑 `20261012T151554315Z-20652` 全部通过，不改变超时阈值。

## Decision Log

- Decision: 优先修复有明确触发条件和用户后果的缺陷，不做全库风格整理或未经测量的性能重构。
  Rationale: 保持可审查范围，回归用例直接保护真实边界。
  Date: 2026-10-12
- Decision: 实现可并行，各项聚焦验证和最终验收集中串行执行；按独立问题分项提交，最后正常 push 当前 main。
  Rationale: 模块文件互不重叠，避免 Flutter 工具锁和质量证据混乱。
  Date: 2026-10-12
- Decision: Windows Release 完整构建可交由已有 `ci-windows` 门禁执行，当前机器缺失 Visual Studio 时必须明确记录本机未执行构建/烟测；其余适用门禁尽量本机完成。
  Rationale: 仓库允许 CI 作为完整验证边界，不为评审安装整套系统编译工具；push 后读取该提交 CI 结果并处理实际失败。
  Date: 2026-10-12
- Decision: 批注保留现有全局 ID schema，跨工作区碰撞明确返回 409，不迁移复合主键。
  Rationale: 在事务内检查所有权与版本即可保护隔离，并保留既有数据库/API 兼容性；回归确认原工作区内容不变。
  Date: 2026-10-13
- Decision: 本机单元测试/analyzer 进程设置 CI=true、FLUTTER_WINDOWS=false、FLUTTER_LINUX=false，CI Windows 构建仍开启正常桌面插件。
  Rationale: 当前非管理员环境无法生成 Windows plugin symlink；Flutter 官方 feature 环境开关允许本机纯 Dart/widget 验证，不能替代真正 Windows Release 构建与交互烟测。
  Date: 2026-10-13
- Decision: 提交沿用现有历史署名 XZQ <xuzhiqing@local>，仅使用单次 git -c 参数。
  Rationale: 本机缺少 user.email，最近五条提交均为同一署名；保留已有项目署名且不更改用户全局配置。
  Date: 2026-10-13

## Outcomes & Retrospective

12 组明确缺陷及 CI 可重复性问题已实现并有回归。本机完整 Flutter 599 项与服务端 42 项测试通过，完整适用 Harness 通过，依赖锁文件未改。12 项 Fix 分项提交及首轮文档已 push main，6d6044a 的服务端和 Windows CI 全部成功，Windows Release 构建已验证。独立复核补获旧同步排序、换地址留空凭据与 legacy 清理失败三个遗漏；用正式回归收敛后再执行全量门禁。

本机缺失 Visual Studio 和 plugin symlink 权限，未运行本机 Windows Release 构建、可见主窗口/托盘交互烟测；Release 构建由 Windows CI 完成，原生交互烟测仍未执行。没有执行真实账号认证、外部推送送达、公网/TLS 部署或联网全量 feed 验证。Mock/channel/widget 测试不替代这些边界。

## Context and Orientation

`lib/core/preferences` 管理 secure 凭据与配置，`core/platform` 管理托盘生命周期。`features/ai_news` 负责条件请求、条目分页和后台提醒；`features/project/data` 负责报告聚合；`features/settings` 负责可选服务连接。`server/app/db.py` 集中维护 SQLite schema，服务层处理 sync/collaboration/feeds/push/GH Archive，router 只处理 HTTP 边界。测试位于 `test/` 与 `server/tests/`。

## Plan of Work

按用户影响排序的审查结论与执行范围如下；每行均以真实失败路径回归保护。

| 项目 | 优先级 | 原问题及用户影响 | 修复范围 |
|---|---|---|---|
| R01 | P1 | 导入或编辑其他服务器地址后可能发送原服务器 Key；部分写失败造成错配 | 地址绑定、迁移/导入/保存队列、换地址留空保护、失败反馈 |
| R02 | P1 | 清除 Token 后旧明文重新迁移；初始化覆盖新设置，失败保存状态不一致 | 串行加载/设置/清除、先清理 legacy、持久成功后发布、失败反馈 |
| R03 | P2 | 托盘失败仍拦截关闭并隐藏窗口，用户无法恢复 | 托盘完整就绪后接管关闭，失败恢复默认关闭 |
| R04 | P2 | DTO 丢失条件请求重验证信息，后台未完成任务遇到 304 不能重试 | 复用 DataResult.map、穿透真实缓存/客户端的回归 |
| R05 | P2 | 翻页网络或缓存写失败被误判为结尾 | 原 cursor 重试、落盘后推进、显式重试按钮 |
| R06 | P2 | 部分仓库请求失败仍覆盖完整报告快照，活动降级被忽略 | 完整聚合后保存、完整旧快照兜底、汇总 freshness |
| R07 | P1 | 相同批注 ID 可跨 workspace 覆盖，竞争写可能降版本 | 写事务内检查所有权和版本，碰撞/内容冲突返回 409 |
| R08 | P1 | sync 竞争降版本、同版本覆盖、同时间或逆时钟分页遗漏 | 原子版本更新、幂等重试、持久 revision、显式起点游标及兼容旧排序 |
| R09 | P2 | GH Archive 9/10 点按字符串错误排序，旧表示可能重复计数 | 真实日期小时校验、规范化查询与兼容旧行 |
| R10 | P1 | 资讯提交后 outbox 失败，后续采集永久漏通知 | 条目与全部工作区 outbox 同事务、并发唯一创建 |
| R11 | P2 | 大量无关 namespace 挤掉共享配置，删除记录又被导入 | 精确 namespace/id 查询、忽略 tombstone |
| R13 | P2 | try 返回未 await 的 Future，异步异常越界；rolling SDK 改锁且 CI 失败 | 修复三处 await、固定 SDK、严格锁文件 |

第一里程碑完成 R01–R03，保护凭据生命周期与关闭行为。第二里程碑完成 R04–R06，保护条件请求、重试和报告完整性。第三里程碑完成 R07–R10，保护服务端隔离、版本、游标和通知原子性。第四里程碑完成 R11–R12，贯通客户端协议、更新文档、独立复核并执行完整适用门禁后提交推送。每项有独立回归，可合并同一根因的相关测试，不引入依赖变更。

## Concrete Steps

工作目录默认仓库根 `D:\BaiduSyncdisk\workspace\GitNews`，服务命令在 `server/`。

1. `dart format <changed Dart files>`；`flutter test <relevant tests>`；服务端 `uv run ruff check <paths>`、`uv run pytest <relevant tests>`，预期退出 0。
2. `powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Suite flutter`；`powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Suite server`，每步成功，日志位于 ignored build/harness。
3. 环境允许则 `-Suite desktop`，否则通过已存在 GitHub Actions 的 `ci-windows` 验证 Release 构建；本机视觉/烟测限制明确记录。
4. 审查 `git diff`，明确路径暂存，`git diff --cached --check`，用 `Fix(scope):中文描述` 分项 commit；`git push origin main`，确认本地和远端 SHA 一致，并读取该提交 CI。

## Validation and Acceptance

凭据换地址后不得复用旧 Key；secure 写失败不得呈现保存成功；clear 后重启不得恢复 legacy Token。托盘失败允许正常关闭。304 重验证后恢复未完成后台任务；普通流分页失败保留内容且同 cursor 可重试。报告缺任一资源不得覆盖完整成功缓存或显示完整 live。批注同 ID 在不同 workspace 不相互覆盖；并发 sync 不降版本，同版本不同内容冲突；可靠 cursor 遍历同时间多页及后续变更。GH 趋势正确跨小时边界；outbox 失败必须回滚条目，重试产生唯一通知。共享配置拉取不受其他 namespace 数量干扰。适用测试与门禁通过、push 同步、CI 证据真实。

## Idempotence and Recovery

不删除用户库，不修改生产凭据，不 force push。schema 迁移必须可重复初始化并保留数据；失败事务回滚。测试使用临时库、fake channel 和占位凭据。Flutter SDK 和构建证据位于缓存/ignored 路径，依赖使用现有锁文件。验证失败先查看对应日志并修复根因，再重跑必要检查。

## Artifacts and Notes

审查结论和进度保留本计划；新增回归本身也是可重复的缺陷证据。Ignored 本机证据：

- Flutter 全量：`build/harness/20261012T223404637Z-24568/summary.json`（7/7，599 tests）。
- 服务端全量：`build/harness/20261012T151554315Z-20652/summary.json`（6/6，42 tests + live smoke）。
- 首轮失败保留在 `20261012T151009582Z-9240` 与 `20261012T151251712Z-16752`，不覆盖失败证据。

代码提交范围 `6184095..eabca1d`，最后一项代码提交 `eabca1d`；首轮完整交付提交 `6d6044a3d10cd675e921836908b942f52a8b5ca9`。构建产物和本地临时库不提交。

- [完整交付 CI](https://github.com/XZQ/GitNews/actions/runs/38317808095)：最终 conclusion=success，两个 job 都 success。
- Windows 证据：`build/harness/20261012T224144332Z-2928/summary.json` 位于该 run 上传的 `harness-flutter-windows` artifact；最终日志确认 ci-windows 8/8，Release build success。
- 服务端证据：`build/harness/20261012T223847134Z-2178/summary.json` 位于 `harness-server-linux` artifact，server 6/6。

本计划的最后更新仅记录已完成验收，不改变已通过 CI 的运行代码；按文档范围执行 docs Harness 后提交推送。

## Interfaces and Dependencies

不新增运行时依赖。自托管 secure 项升级为绑定地址的凭据记录；服务端 sync 增加兼容的可靠 cursor 与定向过滤入口，旧 since/limit 保留。sync revision 的可重复迁移集中在 db.py，现有 SQLite 数据保留；批注全局 ID 不变，跨工作区碰撞返回冲突。报告活动 loader 保留 DataResult 信任语义。
