# 新鲜度合并口径归一与组合根装配守卫

状态：Active

本计划遵循 `.agent/PLANS.md`，执行期间必须保持内容与实际状态一致。
承接 `2026-11-08-core-feature-free.md`：那一轮把 core 的反向依赖清零后，
留下两处「看起来没问题、其实是静默缺陷」的地方。

## Purpose / Big Picture

上一轮引入了 `DataFreshness.partial`，但**没有任何一处检查它会流经哪些路径**。
本轮排查发现两个真实缺陷，都属于「不会报错、只会悄悄说错话」的类型：

| # | 缺陷 | 后果 |
| --- | --- | --- |
| 1 | 聚合仓库用**手写白名单**挑新鲜度档位，`partial` 落不到任何分支 | `[partial]` 单独出现被判成最差的 `seed`；`[live, partial]` 宣称 `live` |
| 2 | 组合根 override 清单**零测试** | 删掉任一条 override 只在运行时炸，且炸点在业务调用栈深处 |

两个缺陷的共同根因是同一件事：**规则写成了「列举」而不是「判定」**。
白名单需要人记得补，测试不存在就没有反馈。

观察方式：新增 `combineFreshness` 的穷举式合并 + `app_overrides` 守卫测试；
`flutter analyze` 零问题、`flutter test` 全绿、CI 双 job success。

## Progress

- [x] (2026-11-08 03:40Z) 排查 `DataFreshness` 的全部消费点，发现
      `aggregated_ai_news_repository._combinedFreshness` 是唯一遗漏处：
      `grep -rn "values.contains(DataFreshness" lib` 只命中这一处。
- [x] (2026-11-08 03:48Z) `core/domain/data_freshness.dart` 新增 `FreshnessRole`
      枚举与 `combineFreshness`：角色用穷举 switch 表达，新增 `DataFreshness`
      成员时编译器强制补齐；合并规则为「保守取严」（任一来源否决即整体降级）。
- [x] (2026-11-08 03:52Z) 聚合仓库删除本地 `_combinedFreshness`，改用 core 的
      `combineFreshness`；补端到端回归「partial 来源不能被 live 主源掩盖」。
- [x] (2026-11-08 03:58Z) 新增 `test/core/domain/freshness_combine_test.dart`：
      逐条锁住合并口径，含「任意两两组合不得产出未知档位」的全枚举遍历。
- [x] (2026-11-08 04:00Z) 新增 `test/app/di/app_overrides_test.dart`：断言每个
      占位 provider 都被 override、override 指向正确实现、配置失效钩子真的会
      失效 feature 侧的偏好项；顺带断言组合根不越界 override 无关 provider。
- [x] (2026-11-08 04:01Z) **验证守卫有效性**：故意把 `partial` 移出否决集合 →
      5 个用例失败（`partial` 被吞成 `live`）；故意删掉 `repositoryFeed` 的
      override → 3 个用例失败（缺省实现抛 `must be overridden`）。两次破坏
      均已还原，`git diff` 确认无残留。
- [x] (2026-11-08 04:02Z) `flutter analyze`：`No issues found!`；`flutter test`
      636 用例全过（上轮 616）；`dart format --set-exit-if-changed` 532 文件 0 changed。
- [ ] 文档与可移植性检查、提交、推送、读取 CI 双 job 结论。

## Surprises & Discoveries

- Observation: `partial` 的遗漏不是「忘了加一个分支」，而是**白名单式写法的必然结果**。
  Evidence: 原实现是 `values.contains(DataFreshness.staleCache) || values.contains(...)`
  的链式判断，新枚举成员不会触发任何编译错误；改成穷举 switch 后，编译器会
  直接报「switch 不完整」。
- Observation: `freshCache` 的角色与 `live` 不同——它「完整但不宣称实时」，而
  `partial` 是「宣称实时但有缺失」。合并时这两者对整体口径的影响方向相反：
  live 优先于 cached，但 partial 优先于 live。
  Evidence: `DataFreshnessBadge` 对 `freshCache` 直接 `SizedBox.shrink()`（不显示
  徽标），说明它被视为可信但无需标注；而 `partial` 用 warning 色。
- Observation: Riverpod 3 的 `Override.origin` 标注为 `@visibleForTesting`，但
  `ProviderBase` 未从公开入口导出。
  Evidence: `grep ProviderBase lib/src/` 只在内部文件出现；测试里只能写成
  `whereType<Object>()` 做集合比较。
- Observation: `configInvalidationHooksProvider` 的钩子签名是 `void Function(Ref)`，
  测试里不能凭空造一个 `Ref`——必须在一个真实 provider 内部执行才能拿到有效引用。
  Evidence: 探针 provider `_invalidationProbeProvider` 在 provider 体内读钩子并
  传自己的 `ref`，与生产路径一致。

## Decision Log

- Decision: 合并规则放在 `core/domain/data_freshness.dart`，而不是留在聚合仓库里。
  Rationale: 「多个来源如何合并成一个口径」是领域语义，不是某个 feature 的实现
  细节；放 core 才能被其它 feature 复用，也不会出现第二份白名单。
  Date: 2026-11-08
- Decision: 用「角色 + 否决 + 严重度」三段表达，而不是直接枚举档位优先级。
  Rationale: 直接排序无法表达「live 优先于 cached，但 partial 优先于 live」这种
  方向不一致的关系；拆成「是否否决」与「否决严重度」两个维度后，每一维都能用
  穷举 switch 表达，新增枚举成员时两处都会被编译器点到。
  Date: 2026-11-08
- Decision: `seed` 与其它来源共存时降级为 `staleCache`，而不是 `seed`。
  Rationale: 全部是种子数据时才是 `seed`；一旦混入真实来源，页面里就同时存在
  占位数据与实况，整体不能宣称「只有占位」，降级为陈旧更保守也更有用。
  Date: 2026-11-08
- Decision: 装配守卫同时断言「必须被 override 的」与「不该被 override 的」。
  Rationale: 只断言前者无法防止组合根越界接管 core 自己的 provider（例如把
  `dioProvider` 也塞进 override 清单），那会让 core 的依赖被悄悄架空。
  Date: 2026-11-08
- Decision: 不给 `lib/app/di/app_overrides.dart` 引入新的抽象层。
  Rationale: 它已经是一个 5 行的清单函数，再包一层只会增加间接。真正缺的是测试，
  不是结构。
  Date: 2026-11-08

## Outcomes & Retrospective

| 指标 | 前 | 后 |
| --- | --- | --- |
| 聚合仓库里手写的新鲜度白名单 | 1 处（漏 `partial`） | **0**（改为 core 穷举式合并） |
| `DataFreshness` 成员漏合并的编译期提示 | 无 | **有**（穷举 switch 不完整即报错） |
| 组合根 override 清单的测试 | 0 | **6 条守卫** |
| `flutter analyze` | — | `No issues found!` |
| `flutter test` | 616 | **636 全过** |
| `dart format --set-exit-if-changed` | — | 532 文件 0 changed |

复盘：

- 上一轮引入 `partial` 时只补了「新增档位在所有 `switch` 里的分支」，却没检查
  **非 switch 路径**——聚合仓库的白名单式判断就是那种路径。枚举扩展的检查清单
  里应当包含「所有按值挑选分支的地方」，而不只是 `switch` 语句。
- 这次特意做了「故意破坏 → 确认失败 → 还原」的动作。一个只会通过的测试说明不了
  它在守什么；两次破坏分别命中了 `partial` 被吞和 override 缺失，证明守卫有效。

## Context and Orientation

- `lib/core/domain/data_freshness.dart`：`DataFreshness` / `FreshnessRole` /
  `combineFreshness`；新鲜度语义的事实源。
- `lib/features/ai_news/data/aggregated_ai_news_repository.dart`：多源聚合仓库，
  现在只调用 core 的合并规则。
- `lib/app/di/app_overrides.dart`：core 占位 provider 的唯一实现处。
- `test/core/domain/freshness_combine_test.dart`：合并口径的规则测试。
- `test/app/di/app_overrides_test.dart`：组合根装配守卫。
- `test/features/ai_news/data/aggregated_ai_news_freshness_test.dart`：聚合层回归。

## Plan of Work

1. 定位 `DataFreshness` 的全部消费点，找出非 `switch` 的分支挑选路径。
2. 在 core 层实现穷举式 `combineFreshness`，删掉聚合仓库的本地白名单。
3. 为合并口径写规则测试（含全枚举两两组合遍历）。
4. 为组合根 override 清单写守卫测试。
5. 故意破坏验证守卫有效，还原。
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

- `grep -rn "values.contains(DataFreshness" lib` 为 0。
- `grep -rn "switch (freshness)" lib` 全部为穷举 switch（新增枚举成员会编译失败）。
- `flutter analyze` 无 error/warning/info；636 用例全绿；格式 0 changed。
- 守卫有效性已由两次故意破坏验证。
- CI `ci-windows` 与 `server` 均 success。

## Idempotence and Recovery

全部为源码内可逆编辑；守卫有效性验证用的是「临时破坏 → 立即还原」，
并用 `git diff` 确认无残留。不删用户数据、不改凭据、不 force push。

## Artifacts and Notes

- 合并口径的逐条规则见 `test/core/domain/freshness_combine_test.dart`。
- 装配守卫见 `test/app/di/app_overrides_test.dart`。
- CI 链接在结论确认后补入。

## Interfaces and Dependencies

不新增运行时依赖，不改 `pubspec.yaml` / `pubspec.lock`。

新增公开符号：`FreshnessRole`（枚举）、`combineFreshness(Iterable<DataFreshness>)`、
`DataFreshness.role`（getter）。

删除：`AggregatedAiNewsRepository._combinedFreshness`（私有静态方法）。
