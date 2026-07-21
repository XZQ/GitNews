# 建立仓库原生 Agent Harness

状态：Complete

本计划遵循 `.agent/PLANS.md`，执行期间必须保持内容与实际状态一致。

## Purpose / Big Picture

完成后，编码 Agent 和开发者可以通过一个仓库内入口发现并执行 Flutter、Windows
桌面和可选 Python 服务端的质量门禁。每次运行都产生结构化摘要和逐步日志，复杂
后续工作也有可恢复的执行计划规范。用户可以运行
`powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -List`
看到入口，并用 `-Suite quick` 观察真实验证结果。

## Progress

- [x] (2026-07-20 08:35Z) 调研当前 Harness Engineering、ExecPlan 和 AGENTS.md 实践。
- [x] (2026-07-20 08:48Z) 实现机器可读任务清单、PowerShell 运行器、doctor、dry-run、超时与运行证据。
- [x] (2026-07-20 08:49Z) 用真实 `docs` suite 验证子进程执行、退出码和日志生成。
- [x] (2026-07-20 10:55Z) 补齐仓库知识地图、增量 CI 和使用文档。
- [x] (2026-07-21 11:04Z) 完成清单、Doctor、DryRun、quick、ci-windows、server 与桌面烟测验证并记录最终结果。

## Surprises & Discoveries

- Observation: PowerShell 5.1 在脚本参数默认值阶段不能可靠使用 `$PSScriptRoot`。
  Evidence: 首次 `-List` 返回 `Join-Path` 的空 Path 错误；改成进入主函数后解析即通过。
- Observation: 字符串数组展开到 PowerShell 脚本时，`-Root` 这样的元素按位置参数
  处理，而不是再次解释为命名参数。
  Evidence: 首次真实 `docs` suite 把 `-Root` 当成路径；清单改为声明有序参数值后通过。
- Observation: Dart 3.12 全量格式检查在干净基线上报告 299 个文件会变化。
  Evidence: quick run `20260720T105329856Z-23344` 的格式步骤返回 1；检查模式未改写
  `lib/` 或 `test/`，因此不在 Harness 任务中扩张为大规模机械格式提交。

## Decision Log

- Decision: Harness 由 JSON 清单与 PowerShell 运行器组成，而不是把流程写死在 CI YAML。
  Rationale: Windows 是当前优先平台，PowerShell 5.1 已存在；结构化清单可由本机、CI
  和 Agent 共用，也避免拼接任意 shell 字符串。
  Date: 2026-07-20
- Decision: 区分 `windows-build` 与 `desktop`。
  Rationale: Release 构建可在无交互 CI 运行，但可见窗口和托盘生命周期必须在真实
  桌面会话验证，二者不能互相冒充。
  Date: 2026-07-20
- Decision: v1 不立即增加所有可能的架构 lint 和 UI 自动化。
  Rationale: 先建立可观察反馈闭环，再根据重复失败逐项机械化，避免没有信号支撑的
  流程膨胀。
  Date: 2026-07-20
- Decision: CI 暂时使用增量 Dart 格式门禁，同时保留完整格式步骤为显式红灯。
  Rationale: 新改动不能继续增加格式债务，但已知 299 文件迁移应作为独立、可审查
  的任务处理，不能隐藏，也不能混入 Harness 基础设施改动。
  Date: 2026-07-20

## Outcomes & Retrospective

Agent Harness 已形成仓库原生的声明式门禁入口，本机与 GitHub Actions 共用同一份
suite 清单。`quick`、`ci-windows` 和 `server` 均产生了成功的结构化摘要；Windows
Release 主窗口与关闭后托盘存活也通过真实桌面烟测。完整 `lib/test` 格式门禁仍会
如实暴露既有 299 文件格式债务，增量门禁已经阻止本次改动继续增加该债务。

## Context and Orientation

仓库根 `AGENTS.md` 是 Agent 规则入口，`STYLE.md`、`RUN.md` 与
`docs/plans/product_ia_data_plan.md` 分别保存代码风格、运行门禁和产品数据边界。
Flutter 客户端位于 `lib/` 与 `test/`，可选 FastAPI 服务位于 `server/`。Windows
发布已有 `tools/windows_release_smoke.ps1` 与 `tools/windows_tray_smoke.ps1`，但
此前没有统一编排、超时和机器可读结果。

## Plan of Work

第一个里程碑建立声明式 suite 与隔离子进程执行，确保每个步骤有工作目录、参数、
超时、日志和退出码。第二个里程碑把 Harness 变成知识地图的一部分，并增加复杂
工作的持久化计划规范与诚实的能力记分卡。第三个里程碑让 GitHub Actions 调用同一
入口，最后用 doctor、dry-run、真实 docs/quick gate 和差异检查验收。

## Concrete Steps

所有命令从仓库根 `D:\workspace\github_news` 运行：

    powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -List
    powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Doctor -Suite quick
    powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Suite all -DryRun
    powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Suite quick
    git diff --check

预期前三条分别列出 suite、确认依赖、生成完整计划；真实 quick gate 的所有步骤应
通过并在 `build/harness/<run-id>/summary.json` 中记录 `success: true`。

## Validation and Acceptance

`-List` 必须列出 docs、quick、flutter、ci-windows、windows-build、desktop、server 和 all。
`-Doctor -Suite quick` 必须解析 git、Dart、Flutter 与 Markdown 检查脚本。真实
`quick` 必须执行而非只展示命令，失败时 Harness 必须返回非零状态和日志位置。
GitHub Actions 必须直接调用 `tools/harness.ps1`，不能复制一套漂移的门禁命令。

## Idempotence and Recovery

所有检查可以重复运行；每次使用新的 run id，不覆盖旧证据。Harness 不修改源码，
格式步骤使用 check 模式。构建和测试只写入已忽略的 `build/` 或工具自身缓存。
失败后查看对应 step 日志，修复根因后重新运行同一 suite 即可。

## Artifacts and Notes

运行证据位于忽略的 `build/harness/`。首次通过的 docs run 为
`20260720T084825583Z-11860`，证明 `git diff --check` 与 Markdown 本地链接检查均
通过。最终验收的 quick run 为 `20260721T110033918Z-20484`，ci-windows run 为
`20260721T110109255Z-13268`，server run 为 `20260721T110405211Z-1588`；三者的
`summary.json` 均记录 `success: true`。同一 Release 产物随后通过主窗口和托盘烟测。

## Interfaces and Dependencies

稳定入口是 `tools/harness.ps1`；清单格式版本为 `tools/harness.json` 中的
`schemaVersion: 1`。每个 step 使用 `process` 或 `powershell` kind、有序参数数组、
相对工作目录和 1 至 7200 秒超时。运行摘要格式同样为 `schemaVersion: 1`。
