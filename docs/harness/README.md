# Agent Harness

本工程的 Harness 是帮助编码 Agent 稳定理解、修改和验证仓库的工程环境，
不是新的应用运行时，也不把 Flutter 客户端改成依赖服务端。它把知识入口、
工程边界、验证命令和运行证据放回仓库，减少不同 Agent 在隐含约定上反复猜测。

## 组成

```text
AGENTS.md（地图）
  -> STYLE / 产品边界 / RUN / 本文（按需展开）
  -> .agent/PLANS.md（复杂工作的可恢复计划）
  -> tools/harness.json（机器可读的 suite 与 step）
  -> tools/harness.ps1（超时、执行、退出码、证据）
  -> build/harness/<run-id>/（summary.json 与逐步日志）
  -> 把重复失败提升为文档、lint、测试或新 step
```

`AGENTS.md` 继续作为短入口和优先级最高的仓库规则。详细产品与技术事实保留在
它引用的文档中。`tools/harness.json` 是完整门禁的单一命令清单，运行器不拼接
任意 shell 字符串，只按清单中的命令和参数数组执行。

## 使用

在仓库根目录运行：

```powershell
# 查看可用 suite。
powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -List

# 只检查清单、平台、脚本和命令是否可用，不执行门禁。
powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Doctor -Suite desktop

# 查看将执行什么，并生成机器可读的计划摘要。
powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Suite quick -DryRun

# 运行日常快速反馈。
powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Suite quick
```

Suite 分层如下：

| Suite | 用途 | 内容 |
|---|---|---|
| `docs` | 文档或非运行时代码 | `git diff --check`、本地 Markdown 链接 |
| `quick` | 日常 Flutter 快速反馈 | `docs`、改动 Dart 文件格式、静态分析 |
| `flutter` | Flutter 完整门禁 | `quick`、`lib/test` 全量格式、全量测试 |
| `ci-windows` | 当前增量 CI | `quick`、全量测试、Windows Release 构建 |
| `windows-build` | 无交互 Windows CI | `flutter`、Windows Release 构建 |
| `desktop` | 可见桌面的发布验证 | `windows-build`、主窗口与托盘烟测 |
| `server` | 可选服务端完整门禁 | `docs`、Ruff、pytest、本地 Uvicorn 往返 |
| `all` | Windows 发布前全工程门禁 | `desktop` 与 `server` |

开发迭代仍应先运行与改动直接相关的最小检查。上述 suite 用于把完整门禁变成
同一个可重复入口，不替代 `AGENTS.md` 中对聚焦测试和实际 UI 验证的要求。

## 结果与失败语义

每次运行创建独立的 `build/harness/<run-id>/`：

- `summary.json` 记录 suite、平台、Git 提交和脏状态、清单哈希、每步耗时、
  状态、退出码和日志文件名。
- `<nn>-<step>.log` 保留该步骤的标准输出与错误输出。
- `<nn>-<step>.input.json` 保存实际执行的结构化命令，便于复现和审计。

任一步非零退出或超时都会让 Harness 以非零状态结束。默认在首个失败后停止；
`-KeepGoing` 会继续收集其余步骤结果。`-VerboseSteps` 会把成功步骤的完整输出也
显示到终端。`-OutputFormat Json` 让标准输出只返回最终摘要，适合外部 Agent 或
CI 解析。清单不得包含 Token、密码或其他敏感参数，Harness 也不会采集环境变量。

## 修改 Harness

新增检查时先判断它是否是稳定、可机械判断的工程不变量。满足条件后：

1. 在 `tools/harness.json` 的 `steps` 中增加一个小而明确的步骤。
2. 使用参数数组，不把多个命令塞进一段 shell 字符串。
3. 设置现实但有限的 `timeoutSeconds`，并指定准确工作目录。
4. 把步骤加入最小适用 suite，再通过 `includes` 让更完整的 suite 继承。
5. 运行 `-Doctor`、`-DryRun` 和至少一个真实包含该步骤的 suite。
6. 更新本文和 [质量记分卡](quality_scorecard.md)，说明新增保障或仍存在的缺口。

重复出现的 Agent 失败不应靠追加泛化提示解决。优先把它归类为缺失知识、缺失
工具、不可见运行状态或未机械执行的边界，然后分别补进文档、脚本、测试或
静态检查。清单与运行器的修改必须保持小步、可回退，并用运行产物证明效果。

## CI 与本机边界

GitHub Actions 直接调用同一个 Harness。当前 Windows 任务运行 `ci-windows`：对
PR 基线以来的 Dart 改动执行格式检查，并运行全量测试与 Release 构建；完整
`lib/test` 格式债务仍由 `flutter`/`windows-build` 明确暴露。Linux 服务任务运行
`server`。可见主窗口和关闭后托盘存活需要真实 Windows 桌面会话，因此保留在
本机 `desktop` suite，不把无交互 CI 结果伪装成 UI 已验证。CI 无论成功失败都会
上传 `build/harness/` 作为诊断证据。

## 当前限制

- 目前没有自动采集当前 UI 截图、视频或可查询的应用日志；烟测只证明窗口和
  托盘生命周期，不证明视觉质量。
- 架构依赖方向主要依靠目录约定、代码评审和 analyzer；尚未有专门的 Dart
  结构测试阻止所有跨层导入。
- 文档检查能发现本地断链，但还不能自动判断内容是否陈旧。
- 当前 Dart 3.12 全量格式检查会报告 299 个既有文件需要格式化；增量 CI 阻止新
  改动继续增加债务，但完整 `flutter` gate 在单独完成格式基线迁移前保持失败。

这些限制记录在质量记分卡中，后续应依据真实失败频率逐项机械化，而不是一次
加入大量暂时没有反馈价值的流程。

## 依据

- [OpenAI：Harness engineering](https://openai.com/index/harness-engineering/)
- [OpenAI Cookbook：使用持久化执行计划](https://cookbook.openai.com/articles/codex_exec_plans)
- [AGENTS.md 开放格式](https://agents.md/)
