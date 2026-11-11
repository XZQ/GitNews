# 全项目深度审查：35 项发现的核实与分批整改

状态：Active

本计划遵循 `.agent/PLANS.md`，执行期间必须保持内容与实际状态一致。
用户要求：深度 review 当前项目，列出问题、遗漏、不足与改进点，修复完善后
commit and push。

## Purpose / Big Picture

三路并行审计（server / Flutter 数据层 / 架构与 UI）共确认 35 项真实问题：
server 14 项（含 1 项高危 SSRF）、数据层 15 项（含 5 项高危）、架构 UI 6 项。
整改后：出站 webhook 不再能被用于探测内网；outbox 有死信与清理；缓存刷新失败
不再丢失过期缓存或把占位数据当真实值；估算指标不再冒充实测；失效的设置项恢复
作用；不可达的已实现页面获得入口；首页与移动总览的失败态可见可重试。

观察方式：新增回归测试全绿、`flutter analyze` 零问题、`flutter test` 全过、
Windows Release 构建与烟测通过、server ruff/pytest/live-smoke 全过、CI 双 job
success、远端 SHA 与本地一致。

## Progress

- [x] (2026-11-11 04:50Z) 读取 AGENTS.md / STYLE.md / README.md / RUN.md 与近期
      review 计划，确认本轮不重复报告 2026-11-07/08 已修项。
- [x] (2026-11-11 05:00Z) 发现本机 Flutter SDK 被 Temp 清理删除
      （`package_config.json` 指向 `Temp/flutter3449/flutter` 仅剩 docs）；
      从官方 storage 下载 3.44.9（sha256 校验）恢复到 `C:\Users\24491\dev\flutter`。
      网络需绕过已停止的 127.0.0.1:7897 代理（`--noproxy` / unset env）。
- [x] (2026-11-11 05:10Z) 三路审计代理完成，逐条人工核实关键发现。
- [x] (2026-11-11 05:40Z) 批次 A（server）：14 项全部修复 + 31 个回归，
      ruff / pytest 74 过 / live-smoke 通过；提交 `9073dcb` 经 Git Data API 推送。
- [x] (2026-11-11 06:30Z) 批次 B（数据层）：15 项全部修复 + 21 个回归，
      analyze 零问题、相关测试全过；提交 `88b980c` 经 Git Data API 推送。
- [x] (2026-11-11 07:10Z) 批次 C（架构 UI）：6 项修复 + 6 个回归，
      全量 `flutter test` 665 全过、analyze 零问题、format 复检通过；
      提交 `678be87` 经 Git Data API 推送。
- [ ] (2026-11-11 07:20Z) 批次 D：本地 Windows Release 构建**跳过**——
      本机 Developer Mode 未开启（`AppModelUnlock` 无
      `AllowDevelopmentWithoutDevLicense` 值），插件符号链接创建失败
      （PathExistsException 清理后转为 Developer Mode 提示），进程非管理员；
      用户选择依赖 CI 完整门禁（ci-windows 在 windows-latest 跑 Release 构建）。
      另清理了旧 SDK 遗留的 `windows/flutter/ephemeral`（生成目录）。
      CHANGELOG 已更新；待 CI 双 job 确认与本计划收尾。

## Surprises & Discoveries

- Observation: 本机 `flutter` 不在 PATH，SDK 实际位于 Temp 且已被清理。
  Evidence: `.dart_tool/package_config.json` 的 flutter rootUri 指向
  `Temp/flutter3449/flutter`，该目录仅剩 `docs/`。
- Observation: `discoverRefreshTickProvider` 零生产者——刷新按钮直接调
  `notifier.refresh()`，tick 永远为 0。审计初判「点过刷新后永久 force」不成立，
  实际是死触发器；按死代码移除。
  Evidence: `grep discoverRefreshTickProvider lib test` 仅 3 处 watch + 定义。
- Observation: `gatherAll` 全失败时抛 `AppException(network)`，原始限流异常被
  包裹丢失——即使修正 403 映射，外层 catch 也识别不到限流。必须在分类点上报。
  Evidence: `lib/core/network/parallel.dart` guard 吞掉原异常只留 runtimeType。
- Observation: `combineFreshness` 是「live 优先 + 否决」口径，project 报告是
  「最弱环」口径，两者语义不同。直接替换会改变两个既有测试锁定的行为；改为
  穷举 switch 的最弱环实现，补 partial 档消除 null 断言地雷，不改口径。
  Evidence: `github_project_partial_refresh_test.dart` 期望 freshCache/seed。
- Observation: `whenComplete(() => map.remove(key))` 表达式体把移除的 Future
  返回给 whenComplete 等待，形成「等自己完成」死锁，测试超时 30s。
  Evidence: trending 缓存测试挂起；改块体后通过。
- Observation: github.com 的 git HTTPS 传输被网络重置，api.github.com 可达。
  沿用 2026-11-07 的 Git Data API 推送方案，并以原始 author/committer 时间与
  cat-file 精确 message 重建提交，远端 SHA 与本地一致。
  Evidence: `git push` Recv failure；API 推送后 SHA 逐一对齐。
- Observation: RSS 摘要无截断，push payload 上限若设 256KiB 可能让
  `news.items.created`（20 条）校验失败并回滚整个采集事务；放宽到 1MiB。
  Evidence: `server/app/feeds.py` `_clean` 不截断 summary。
- Observation: `SyncRecord`（pull/conflict 输出）继承 `SyncRecordInput`，
  payload 尺寸校验放在输入模型会让旧库大记录 pull 时 500；移到
  `SyncPushRequest` 请求层。
  Evidence: `server/app/models.py` 继承关系。

## Decision Log

- (2026-11-11) SSRF 防护默认拒绝非公网目标，提供
  `GITHUB_NEWS_WEBHOOK_ALLOW_PRIVATE` 显式放开：自托管 LAN 投递是合理需求，
  但默认必须安全。否决「只做 scheme 白名单」——挡不住 169.254.169.254。
- (2026-11-11) CORS 默认保持 `*` 并新增 `GITHUB_NEWS_CORS_ORIGINS` 白名单：
  桌面/移动客户端不受 CORS 约束，收紧默认会破坏现有浏览器用法且无安全收益
  （Bearer 方案）。否决「默认收紧」。
- (2026-11-11) 死路由选择「接入入口」而非删除：5 个页面均为完整实现
  （四态/骨架屏俱全），StarGrowthPage 近期刚按归属迁移，删除会回退用户工作。
  入口遵循既有 header action 模式；project 四入口收进弹出菜单避免头部拥挤。
  `/login` 保留为深链别名；顶层 `/webview` 由链接偏好 inApp 路径激活。
- (2026-11-11) 链接打开偏好只对内容链接生效（资讯原文、仓库活动）；设备登录
  等认证流固定系统浏览器，避免凭据输入留在应用内 WebView。
- (2026-11-11) 启动 prune 豁免 `repo_snapshot_history:` /
  `monitor_observation:` 用户数据键（前缀由装配层 bootstrap 传入，core 不
  认识 feature 键名）；`last_fetched_at=0` 占位行保留，避免丢失 ETag/失败标记。
- (2026-11-11) gharchive 小时表达式规范化导致索引失效（审计第 8 条）本轮
  不改：现有行为正确且有 legacy 兼容测试，迁移涉及 PK 冲突消解，风险/收益
  不匹配；记入后续风险。

## Outcomes & Retrospective

（完成后填写：最终 SHA、CI 结论、未完成项与后续风险。）

## Context and Orientation

- `server/app/`：FastAPI 自托管服务。`push_service.py` outbox 投递；
  `webhook_security.py`（新增）出站 URL 校验；`runtime.py` 调度；
  `config.py` 环境守卫；`models.py` 请求契约。
- `lib/core/storage/`：`cache_meta_dao.dart`（TTL/ETag 元信息）、
  `json_snapshot_cache_dao.dart`（通用快照）、`repo_snapshot_history_dao.dart`
  （用户观测数据）。schema 集中在 `database_schema.dart`。
- `lib/features/discover/data/`：搜索 + 白名单合成 + 缓存；
  `discover_profile_composition.dart` 是白名单缓存层所在。
- `lib/features/trending/data/cached_trending_data_source.dart`：
  TTL 缓存 + 并发合并 + 自愈。
- `lib/app/home/widgets/`：首页预览卡；共享错误行在
  `lib/shared/widgets/home_section_preview_card.dart` 的 `PreviewErrorRow`。
- `lib/shared/utils/open_content_link.dart`（新增）：链接打开偏好统一入口。
- 分层边界由 `test/core/architecture/layer_imports_test.dart` 机械强制。

## Plan of Work

1. 批次 A（server，已完成）：安全 → 可靠性 → 测试 → ruff/pytest/smoke → 提交推送。
2. 批次 B（数据层，已完成）：discover → DTO/雷达/监控 → trending/project/
   repo_detail/settings → core 存储 → 回归 → 提交推送。
3. 批次 C（架构 UI，进行中）：链接偏好 → 死路由入口 → 移动雷达错误态 →
   discover 懒列表 → 首页预览错误态 → 死 widget 清理 → 回归 → 全量测试 →
   提交推送。
4. 批次 D：Windows Release 构建 + 烟测、server 全套复检、CI 双 job 确认、
   CHANGELOG、计划收尾。

## Concrete Steps

工作目录均为仓库根 `D:\BaiduSyncdisk\workspace\GitNews`（server 检查在
`server/`）。本机 flutter 不在 PATH，使用
`C:\Users\24491\dev\flutter\bin\flutter`；所有网络命令先
`unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy`（死代理）。

```bash
# Flutter 门禁
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build windows --release
powershell -NoProfile -ExecutionPolicy Bypass -File tools/windows_release_smoke.ps1 -ReleaseDir build/windows/x64/runner/Release -TimeoutSeconds 15

# server 门禁（server/ 下）
uv run ruff check .
uv run ruff format --check .
uv run pytest
uv run python tools/live_smoke.py

# 推送（github.com git 传输被重置时）
python -I <scratchpad>/api_push.py   # Git Data API 重建提交并对齐 origin/main
```

预期：analyze 零问题；全量测试通过；Release 构建成功且烟测主窗口存活；
server 74+ 测试通过；CI `ci-windows` 与 `server` 均 success。

## Validation and Acceptance

- 每项修复都有对应回归测试锁定行为（server 31 / 数据层 21 / UI 6+）。
- SSRF：`test_push_service.py` 参数化拒绝回环/内网/元数据/非 http scheme，
  投递时复查 dead-letter；订阅 400。
- 缓存回退：force 失败保留 stale（discover/trending）；坏缓存自愈；
  白名单新鲜缓存零远端请求。
- 口径：heat=estimated；占位 profile enriched=false 往返保留；
  repo_detail 占位 unavailable。
- UI：链接偏好 inApp/external 分流；5 个二级页可达；预览卡/雷达失败可见可重试。
- 完整门禁与 CI 双 job success 为最终完成证据。

## Idempotence and Recovery

- 所有修复为纯代码改动，无数据迁移；重复执行测试/构建无副作用。
- API 推送脚本在远端 SHA 与本地 origin/main 不一致时拒绝执行，需先对齐；
  重建提交 SHA 与本地一致，失败不产生分叉。
- 启动 prune 为最佳努力（失败不阻断启动），豁免用户数据键，重复执行安全。
- 本机 SDK 恢复：重新下载 3.44.9 zip（sha256
  8ef1107d…0ac）解压到 `C:\Users\24491\dev\flutter` 即可。

## Artifacts and Notes

- Harness 证据（如运行）：`build/harness/`（git 忽略）。
- 全量测试日志：会话临时目录 `toolu_726571860d6b41288752ea7c-stdout.log`。
- 提交：A `9073dcb`（server）、B `88b980c`（数据层）、C/D 待填。

## Interfaces and Dependencies

- 新增环境变量：`GITHUB_NEWS_WEBHOOK_ALLOW_PRIVATE`（默认 false）、
  `GITHUB_NEWS_CORS_ORIGINS`（默认 `*`）；master key 最小长度 16。
- webhook 投递新增 `X-GitHub-News-Event-Id` 幂等头；outbox 新增 `failed`
  状态（`GET /v1/push/outbox?status=failed`）；ack 仅接受 pending。
- `/health` 响应不再含 `database.path`。
- gharchive ingest 超限返回 413。
- Dart：`TrendingDataSource.fetchTrending` / `FreshnessTrendingDataSource.
  fetchTrendingResult` / `TrendingRepository.getDigest` 新增 `{bool force}`；
  `CacheMetaDao.pruneStale` 返回 `List<String>` 并支持 `excludePrefixes`；
  新增 `openContentLink`、`PreviewErrorRow`、`JsonSnapshotCacheDao.
  pruneSnapshotPayloads` / `deleteKeys`、`TrendingCacheDao.deleteKeys`。
- 移除：`discoverRefreshTickProvider`、`HomeMobileRadarTopicList`。
