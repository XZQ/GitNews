# 资讯审查问题逐项修复与发布

状态：Active

本计划遵循 `.agent/PLANS.md`。用户已授权完成审查建议，并要求每完成一项单独 commit and push。

## Purpose / Big Picture

让 Windows 发布包可靠启动，让资讯搜索、刷新、离线详情、筛选和偏好结果一致，让图表与缓存状态可解释，并提高阅读、来源核验与仓库跟踪效率。保留 8/5 导航和本地优先边界。

## Progress

- [x] (2026-09-07 00:42Z) 读取当前状态、审查证据和项目规则；工作树干净，基线 `0880250c`，远端 `7ab635ac`。
- [x] (2026-09-07 01:05Z) S01 Release 初始化诊断与语义烟测：失效缓存已重建，SQLite 绑定和恢复页拒绝测试通过，完整 desktop Harness 10/10 通过。
- [x] (2026-09-07 01:36Z) S02 Star 历史日期、真实增量与图表口径：按 UTC 日期和共同样本聚合，负值保留，缺历史明确为空；desktop Harness 10/10 通过。
- [x] (2026-09-07 01:46Z) S03 中文搜索召回及完整结果访问：中文词内匹配、50 条连续分页、失败重试、逐篇保留检索顺序；desktop Harness 10/10 通过。
- [x] (2026-09-07 01:55Z) S04 显式刷新穿透缓存：REST/RSS TTL 内条件请求、等待远端完成、失败保留内容；desktop Harness 10/10 通过。
- [x] (2026-09-07 02:09Z) S05 过期缓存时间与列表来源状态：保留来源验证时间，失败状态跨重启保存，混合源降级可见；desktop Harness 10/10 通过。
- [x] (2026-09-07 02:16Z) S06 首启离线种子详情：独立只读详情通道、分类切换、示例标识与无远端缓存污染；desktop Harness 10/10 通过。
- [x] (2026-09-07 02:22Z) S07 聚类后的兴趣排序：最终事件按本地自然日及偏好排序，搜索顺序独立；desktop Harness 10/10 通过。
- [x] (2026-09-07 02:28Z) S08 稍后读统一筛选：分类、关键词、来源、日期、已读组合生效，独立快照逐篇可达；desktop Harness 10/10 通过。
- [x] (2026-09-12 06:25Z) S09 热榜加载态布局：主页面和热门仓库二级页可滚动，7 项浅/深与矮窗口回归；完整 desktop Harness 10/10 通过。
- [x] (2026-09-12) S10a 后台指纹与提醒成功提交、失败重试：仅成功验证结果推进检查点，提醒先幂等落库，空基线与并发触发有回归；desktop Harness 10/10 通过。
- [ ] S10b 后台缓存保留真实验证时间。
- [ ] S11 共享 AI 凭据迁至服务端边界。
- [ ] S12 AI 列表密度、来源文案和可读性。
- [ ] S13 详情阅读、AI 语义、来源与仓库跟踪闭环。
- [ ] S14 总览布局与指标解释。
- [ ] S15a 监控强制刷新失败保留持久快照。
- [ ] S15b 部分失败保留完整监控列表和各仓库观测。
- [ ] S15c 真实检查时间、失败状态与重试。
- [ ] 最终跨页面、主题、紧凑窗口验证和远端一致性确认。

## Surprises & Discoveries

- 2026-09-12 复查：现有 484 项测试通过、1 项因未注入 AI Key 跳过；新增隔离测试复现后台提前确认指纹、过期结果推进验证时间、强刷删除快照和部分失败缩小监控列表四个故障。用户再次授权全部修复并逐项提交推送。
- 原生截图工具两次返回 SetIsBorderRequired / 0x80004002，之后用户通过 Escape 停止 Computer Use。使用可执行布局/交互回归、Windows Release 和语义烟测验证；不把组件渲染或启动烟测当作真实窗口截图验收。
- 审查时既有 445 个测试通过、1 个跳过，但 6 个隔离行为复现失败；需要补正式回归覆盖。
- Release 缓存的 `dart_build_result.json` 保留了 2026-08-23 的空 code_assets；安装包 NativeAssetsManifest 也为空，探针捕获 `sqlite3_initialize` 解析失败。Debug 清单正常。已将该 Release 编译缓存单独备份至 ignored build 目录再重建，未修改用户库或全局 SDK。
- 基线有一个未推送的既有 Harness 修复提交，只涉及扫描和 pytest 临时目录；保留历史，不重写它。

## Decision Log

- 2026-09-12：延续当前 main，按可独立验收的问题提交：S09、S10a/b、S15a/b、S11、S15c、S14、阅读与来源/仓库闭环。每项发布后核对远端 SHA；只使用 pub.dev 和已锁定依赖，避免本机镜像设置引入无关依赖更新。
- 2026-09-07：按当前 `main` 逐项提交推送，先验证具体行为，再运行影响范围的完整 Harness。既有基线提交随第一次正常推送同步。
- 2026-09-07：不删除或重建用户数据库；初始化诊断只输出受控状态和错误分类，不记录凭据、SQL 参数或用户内容。
- 2026-09-07：共享 AI 服务以发布方配置的服务端保密边界实现，不要求最终用户填写模型 Key；未配置外部服务时公开资讯保持可用。

## Outcomes & Retrospective

实施中。每项的行为、验证日志和提交将在这里及 Progress 中更新；未部署的外部服务不得表述为已上线。

## Context and Orientation

- `lib/bootstrap.dart`、`core/storage` 和 `tools/windows_release_smoke.ps1` 负责启动与验证。
- `features/ai_news` 负责资讯缓存、搜索、刷新、聚类、兴趣、详情和后台提醒。
- `core/storage/repo_snapshot_history_dao.dart` 与 `features/trending` 负责仓库观测和图表。
- `features/home`、`features/monitor`、`core/theme` 负责总览、检查状态和阅读布局。
- `server/` 是可选 FastAPI 服务，不能成为本地启动或公开资讯的必需依赖。

## Plan of Work

按 S01–S15 依次实施。每项必须有独立可观察的结果、相关回归、完整适用门禁和独立提交；随后立即推送并核对本地/远端 SHA。发现同一根因影响多个入口时在该项中贯穿修复，避免临时接口或假成功。

## Concrete Steps

工作目录均为仓库根，除另有标注。

1. `dart format <本项 Dart 文件>`，再执行相关 `flutter test <测试文件>`。
2. Flutter/桌面项：`powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Suite desktop`，要求全部步骤退出码 0。
3. 服务端项：相应聚焦 pytest 后执行 `powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Suite server`；跨端项还需 desktop。
4. 暂存明确文件，执行 `git diff --cached --check` 并审查完整暂存差异，使用 `Fix(scope):中文描述` 等提交。
5. `git push origin main`，随后 `git rev-parse HEAD`、`git rev-parse origin/main`、`git rev-list --left-right --count origin/main...HEAD`，要求 SHA 相同且 `0 0`。

## Validation and Acceptance

- Release 的就绪信号必须来自真实存储初始化、主壳首帧及本地条目表可读；只有窗口句柄不算成功。
- 中文标题词内查询可命中；刷新 TTL 内也检查远端；过期结果不得更新成功时间；种子卡可打开详情。
- 聚类不撤销偏好；稍后读遵循分类、关键词及库筛选；后台失败不推进已处理指纹。
- 图表日期与统计对象可解释，不用比例伪造独立序列；无足够观测明确为空。
- 客户端构建不包含发布方 AI 密钥；服务端鉴权、额度、输入限制和失败边界可测试。
- 阅读和导航保持应用壳，主页面浅/深主题及紧凑尺寸无溢出；提供状态与来源说明。

## Idempotence and Recovery

使用迁移或兼容解码保留现有数据；测试用内存/独立临时目录。不得删除用户存储，不执行 reset/强推。推送冲突先读取远端状态并保留双方历史。只清理本任务启动且已核对路径的进程及 build 内明确产物。

## Artifacts and Notes

- S10a：`build/harness/20260912T063635933Z-19720/summary.json`，desktop 10/10；聚焦后台回归 10/10，覆盖下载失败、提醒写入失败、首次空列表、stale 指纹/条目和并发触发。缓存验证时间仍由独立 S10b 修复；系统通知是尽力投递，未验证真实通知送达。
- S09 与复查基线：`build/harness/20260912T061510260Z-10568/summary.json`，484 passed / 1 skipped，desktop 10/10；本次 `build/review/20260912/audit_regressions_test.dart` 和日志保留四个待修复故障。S09 代码与上述门禁时完全一致，计划文档更新后仅补文档检查。
原审查证据在被忽略的 `build/review/20260907/`；该目录不是后续执行必需依赖，问题和验收已完整记录在本计划。门禁证据写入 `build/harness/<run-id>/`；不提交运行数据、凭据或截图中的私密内容。

- S01：`build/review/20260907/startup-after-cache-repair.log` 记录 2026-09-07 01:01Z 的 Release 成功启动；原生资产清单恢复 SQLite 绑定。测试覆盖恢复页不得就绪、成功首帧就绪、旧库迁移以及空资产清单必须失败。
- S01 完整门禁：`build/harness/20260907T010219912Z-23628/summary.json`，包括全量 Flutter、Release、语义启动与托盘存活。

## Interfaces and Dependencies

保持现有 Riverpod、Dio、SQLite 和 FastAPI 技术栈。需要调整的契约包括显式 force 刷新、携带观测日期的趋势数据、检查状态、发布方 AI 代理。优先复用已有依赖，所有外部地址和协议常量继续集中配置。

- S02：新增日期对齐、稀疏窗口、负增长、旧缓存兼容和窄屏浅/深色图表回归；相关 112 项通过。完整门禁 `build/harness/20260907T013330545Z-29280/summary.json`，456 passed / 1 skipped；Release 启动与托盘通过。像素基线为测试渲染，仅作为布局证据，不代表真实远端历史。
- S02：总览桌面图表改读实际监控列表；热榜、平板/移动总览、项目和仓库详情共用同口径图表。移除固定比例对比线及硬编码窗口表，旧缓存无日期时不展示增长曲线。其他总览指标与布局仍在 S14 完成。

- S03：`build/harness/20260907T014308886Z-28548/summary.json`，461 passed / 1 skipped，Windows Release、实际启动和托盘通过。新增 121 条分页、过滤代际隔离、字面符号、重试和相似标题逐篇访问回归。资讯列表已提取到 `presentation/widgets/ai_news_item_list.dart`，S07 的排序修复应在该文件继续。

- S04：`build/harness/20260907T015254943Z-14132/summary.json`，Windows Release、实际启动和托盘通过。聚焦 23 项覆盖真实 REST/RSS 条件请求链路、缓存提前显示但刷新等待远端完成、失败后保留阅读内容；桌面与移动共用刷新控制器。

- S05：`build/harness/20260907T020645824Z-3100/summary.json`，471 passed / 1 skipped，Release、启动与托盘通过。41 项聚焦回归覆盖来源时间传递、TTL 内失败后重开、混合来源降级与 RSS 健康状态；3 项页面测试和移动截图验证状态说明。格式及单个 lint 问题在最终门禁前已修正。

- S06：`build/harness/20260907T021322496Z-19104/summary.json`，473 passed / 1 skipped，Release、启动与托盘通过；26 项聚焦测试通过。修复详情 Provider 在异步间隙后读取已释放 Ref 的问题；无监听者读取详情也能完成。示例不显示当前发布日期，不生成 AI 解读。

- S07：`build/harness/20260907T021920368Z-27376/summary.json`，474 passed / 1 skipped，Release、启动与托盘通过。5 项聚焦测试覆盖实际列表中的偏好更新和模式切换，修复搜索模式复用普通分组缓存的隐患；保留来源聚类成员。

- S08：`build/harness/20260907T022520258Z-22504/summary.json`，477 passed / 1 skipped，Release、启动与托盘通过。11 项聚焦测试覆盖清缓存后的快照筛选、日期边界、字面关键词、已读后的结果失效，以及旧来源选项在异步加载与模式切换时不导致下拉框断言。
