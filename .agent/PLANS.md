# Codex 执行计划规范

本文件定义仓库内持久化执行计划（ExecPlan）的写法。ExecPlan 是复杂工作
的可恢复规格：后续执行者只读取当前工作树和这一份计划，也应能够继续完成
任务、验证结果并解释关键决策。

## 何时使用

以下工作需要 ExecPlan：跨越多个功能层的功能、重要架构调整、预计需要多轮
验证的迁移、具有明显外部依赖或未知风险的实现。单文件修复、文案调整和其他
容易在一次短反馈循环内完成的工作，不需要为了形式额外创建计划文件。

计划放在 `docs/plans/exec/`，文件名使用
`YYYY-MM-DD-short-description.md`。计划不依赖聊天记录、个人记忆或未提交的
外部文档；必要背景必须写进计划或引用仓库内稳定文档。

## 执行约定

- 计划是持续更新的工作文件，不是实现前写完后便冻结的说明。
- 每次明显停顿、发现新事实或改变方案时，同步更新进度、发现和决策。
- 未被用户要求时，计划不赋予提交、推送、部署或修改外部系统的权限。
- 遇到普通实现细节时自行作出保守决定并记录理由；只有用户选择会实质改变
  结果或需要扩大权限时才暂停询问。
- 验证针对原始目标和可观察行为，不以“代码看起来正确”作为完成证据。
- 命令必须写明工作目录、完整参数和预期结果。无法执行的检查要记录原因，
  不得表述成已经通过。
- 步骤应可重复执行。会覆盖数据、改变远端状态或难以恢复的动作必须给出安全
  前置检查和恢复方式。

## 必备内容

每份 ExecPlan 都必须保留以下章节，并在执行过程中维护：

1. `Purpose / Big Picture`：用户获得什么，以及如何观察结果。
2. `Progress`：带 UTC 时间的完成、进行中和待办清单。
3. `Surprises & Discoveries`：改变实现判断的新事实与简短证据。
4. `Decision Log`：决定、理由、日期；包含被否决的重要替代方案。
5. `Outcomes & Retrospective`：最终结果、未完成项和后续风险。
6. `Context and Orientation`：面向不了解仓库的执行者解释相关文件和边界。
7. `Plan of Work`：按可独立验证的里程碑描述改动顺序。
8. `Concrete Steps`：精确命令、工作目录与预期输出。
9. `Validation and Acceptance`：以行为和证据定义完成条件。
10. `Idempotence and Recovery`：重复执行与失败恢复方式。
11. `Artifacts and Notes`：重要日志、截图、构建产物或运行摘要的位置。
12. `Interfaces and Dependencies`：新增或变更的稳定入口、格式与依赖。

## 推荐模板

```md
# <面向结果的标题>

状态：Active

本计划遵循 `.agent/PLANS.md`，执行期间必须保持内容与实际状态一致。

## Purpose / Big Picture

说明改变后的可见能力和最短验证路径。

## Progress

- [x] (YYYY-MM-DD HH:MMZ) 已完成事项。
- [ ] 正在进行或待完成事项。

## Surprises & Discoveries

- Observation: 发现。
  Evidence: 支撑这一判断的命令、日志或代码位置。

## Decision Log

- Decision: 决定。
  Rationale: 为什么适合本仓库。
  Date: YYYY-MM-DD

## Outcomes & Retrospective

完成前保持简短；完成时对照目标记录结果与剩余限制。

## Context and Orientation

说明相关模块、当前行为、术语和必须保留的边界。

## Plan of Work

按里程碑说明修改内容及每一步如何独立验证。

## Concrete Steps

列出工作目录、命令和预期输出。

## Validation and Acceptance

用用户或自动化可以观察的结果定义通过条件。

## Idempotence and Recovery

说明重跑、失败清理和安全恢复方式。

## Artifacts and Notes

记录短证据和持久产物路径，不粘贴大段无关日志。

## Interfaces and Dependencies

记录文件格式、命令入口、公开类型和版本约束。
```

## 完成标准

只有目标行为已经实现、适用验证已经完成、计划的 `Progress` 与实际一致，且
`Outcomes & Retrospective` 记录了结果时，计划才能标记为 `Complete`。预算不足、
实现困难或仅完成部分代码都不是完成条件。
