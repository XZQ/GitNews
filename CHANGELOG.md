# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) 和[语义化版本](https://semver.org/spec/v2.0.0.html)。

## [Unreleased]

### Added

- 深度审查整改(2026-11-11,详见 `docs/plans/exec/2026-11-11-deep-review-remediation.md`):报告页头新增二级页菜单(探索/活动速览/发现推荐/Star 增长趋势),热榜页头新增语言趋势入口,五个已实现但不可达的页面恢复导航。
- 「链接打开方式」偏好真正生效:资讯原文与仓库活动按偏好走应用内 WebView 或系统浏览器(新增共享 `openContentLink`);认证流仍固定系统浏览器。
- 首页预览卡与移动总览雷达话题趋势补齐错误态与重试(共享 `PreviewErrorRow`),失败不再显示与空数据不可区分的空白或永久骨架。
- 服务端 webhook 投递携带 `X-GitHub-News-Event-Id` 幂等键;outbox 新增 `failed` 死信状态可查询;新增 `GITHUB_NEWS_WEBHOOK_ALLOW_PRIVATE` 与 `GITHUB_NEWS_CORS_ORIGINS` 配置。
- GitHub OAuth 设备登录入口在注入 `GITHUB_OAUTH_CLIENT_ID` 的构建中接入应用账号登录页;未配置构建仍只提供 Personal Access Token 路径。
- 新增 `lib/app/` 组合根:首页迁入 `lib/app/home/`,根 widget 迁入 `lib/app/app.dart`;结构测试从「跨 feature 展示层引用基线 9」升级为「feature 之间互相 import 必须为 0」,并新增「组合根不得触达 feature `data/` 层」与「首页必须留在 `lib/app/home/`」断言。
- `lib/app/` 组合根补齐 `router/`(路由表与分支)与 `di/`(override 清单);`lib/core/` 不再 import 任何 feature,需要的 feature 能力改为 core 声明占位 provider、由 `lib/app/di/app_overrides.dart` 注入(`repositoryFeedProvider`、`configInvalidationHooksProvider`)。结构测试新增「core 不得反向依赖 feature」与「组合根持有路由与装配」两条断言。
- `DataFreshness` 新增 `partial`;发现页白名单条目部分拉取失败时降级标注「部分实时」(zh/en),不再把不完整结果标成实时。
- 多来源新鲜度的合并口径收敛到 `core/domain/data_freshness.dart` 的 `combineFreshness`,由 `FreshnessRole` 的穷举 switch 驱动;新增 `DataFreshness` 成员时编译器会强制补齐角色,不再静默降级成最差档。
- 组合根装配清单新增守卫测试(`test/app/di/app_overrides_test.dart`):断言每个占位 provider 都被 override、override 指向正确实现、配置失效钩子真的会失效 feature 侧的偏好项。
- `flutter.changed-format-check` 新增静态契约测试:固定 PowerShell splat 目标的 `[string[]]` 数组类型与 root 路径规范化;单改动文件场景由 CI 自身的真实 diff 直接验证。
- 设置页主题色预设名称接入 i18n(zh/en 各 10 个 key),英文环境不再显示中文预设名;新增开发者选项页、趋势总览页、看板选择器与监控规则示例文案的完整英译。

### Changed

- 深度审查整改(2026-11-11):发现页白名单结果按 kind 落盘共享 TTL,新鲜缓存命中零远端请求(原先每次串行 10 个条件请求),部分失败回退过期白名单并整体标陈旧;热榜同键并发请求合并,刷新链路加 `force` 参数。
- 快照缓存 payload 与 meta(+ETag/校验器)同事务写入,`CacheMetaDao` 改单条 UPSERT;启动清理联动删除孤儿 payload,豁免观测历史用户数据键,保留仅存 ETag/失败标记的占位行;仓库/主题观测历史按 key 串行化。
- 服务端 master key 要求 ≥16 字符并拒绝 `.env.example` 占位值;sync payload 64KiB / push payload 1MiB 上限;gharchive 小时重 ingest 原子化并设下载/解压硬上限(超限 413);`/health` 不再泄露数据库路径。
- AI 雷达 heat 是加权公式,口径由实测改标估算(含旧缓存兜底);search 限定符逐 OR 分支绑定(发现页 skills 与雷达各 topic),不再只约束最后一个分支。
- 自托管服务请求路径与请求头集中到 `ApiEndpointsConfig` / `SelfHostedApiSupport`;可清理缓存表清单改名为 `_kClearableCacheTables` 并写清用户数据的甄别标准。
- 桌面托盘与窗口控制、认证初始化、后台资讯刷新、发现白名单、未匹配路由等关键失败路径统一走 `AppLogger` 留痕;修复三处编码损坏的中文注释。
- 固定 Harness CI 使用 Flutter 3.44.9 / Dart 3.12.2，Flutter 与服务端依赖解析严格使用现有锁文件。
- 主题基线收敛为冷静工具风(Slate 低饱和色阶、发丝边框、扁平化共享组件与导航)。
- 按 300 行约束拆分超大文件(star_trend_chart / ai_news_providers / home_mobile_trending_overview / ai_news_feed_parser / ai_news_detail_components),并升级依赖基线。
- GitHub Token 卡的「检查配额」异步状态由页面 `setState` 迁到 `githubRateLimitCheckProvider`;保存或清除 token 后主动作废旧配额结果。
- 趋势总览页按数据归属迁到 project 特性(`StarGrowthPage`,路由 `/project/growth`),i18n 键由 `trending.overview.*` 改为 `project.star_growth.*`;`repo_detail/domain/entities.dart` 这一只转发 core 的 barrel 删除,改为直接依赖 `core/domain/contributor_entity.dart`。
- 路由装配(`app_router` / `app_route_branches`)迁到 `lib/app/router/`,`core/router/` 只保留 `route_specs` 与错误视图;投影仓库装配(`project_composition`)按归属迁回 `features/project/application/`,project 不再认识 trending。
- 搜索防抖、启动并行加载与聚类缓存。
- 共享模型凭据迁入鉴权限额代理,源码不再接触明文凭据。
- 首页栏目入口、AI 资讯详情、引导页与活动流的强调色统一跟随主题主色(`colors.primary`),清除硬编码品牌青残留;侧边栏头像由渐变改纯色,与扁平化基线一致。
- 服务端连接默认值(baseUrl / workspaceId / memberId)与资讯保留窗口(2 天)提取为单一常量,消除重复字面量。

### Removed

- 删除零生产者的 `discoverRefreshTickProvider` 死触发器(刷新按钮直接调 `refresh()`);删除设计稿已移除、仅被测试保活的 `HomeMobileRadarTopicList` 及其私有 helper 与对应测试片段。
- 删除未使用的演示告警数据(`DemoData.alerts`、`DemoAlertFixture` 与 `alertSeverity*` 常量)及其 mapper,`core/demo_data_mappers.dart` 因此不再依赖 monitor 的 domain。
- 删除全仓库零引用的死代码:`ai_news_grouping.dart`、`core/di/feature_providers.dart`(同时消除 7 条 `core → features` 依赖)、`core/platform/platform_extensions.dart`、`app/home/widgets/home_alerts_panel.dart`。

### Fixed

- 深度审查整改(2026-11-11)服务端:webhook 订阅与投递双重 SSRF 校验(拒绝内网/回环/link-local/云元数据,含 IPv4-mapped IPv6,DNS rebinding 投递时复查);outbox 12 次重试后置死信、delivered 7 天/failed 30 天清理、ack 仅接受 pending;调度循环异常兜底不再一次 DB 异常永久停摆;`run_feeds` busy 判定原子化;非 ASCII bearer token 不再触发 500。
- 深度审查整改(2026-11-11)客户端:发现页 profile 缓存解码读回 `enriched/enrichFailed`,修复分页计数失效、补全队列跳过与 0 粉丝当真实值展示;force 刷新不再预删缓存,失败保留过期缓存回退;资讯 DTO 逐条跳过坏 id 条目不毁整页主源;雷达 403 配额耗尽正确触发全局限流闸门;热榜坏缓存行删除自愈、远端失败无缓存回退种子;监控空仓库 `pushed_at=null` 不再误判解析失败;project 最弱环新鲜度补 `partial` 档消除 null 断言地雷;仓库详情种子兜底构造同名 unavailable 占位,不借用无关仓库数据;自托管 pullConfig 跳过坏 version 行不泄漏裸 TypeError。
- 多源聚合的资讯列表不再把「部分实时」静默当成实时或最差的种子:聚合仓库原先用手写白名单挑档位,新增的 `partial` 落不到任何分支,`[partial]` 单独出现会被判成 `seed`、`[live, partial]` 会宣称 `live`;现改为 core 层穷举式合并,任一来源缺条目即整体降级为 `partial`。
- 快照文本损坏时不再把 hydrate 后的占位数据整体写回;观测历史读取失败(非数据损坏)时保留原 payload,避免用空历史覆盖持久化数据。
- 热榜在 GitHub 限流且无缓存时回退种子数据并标注示例口径,不再继续消耗受限配额或伪装成实时数据。
- 服务端 feed 缺少或无法解析发布时间时不再用当前时间顶替,避免旧文章排到最前并被 `since` 增量反复返回。
- 配置导出失败改用自己的 zh/en 提示文案,不再误报「导入失败」。
- 修复 Harness 在「仅 1 个改动 Dart 文件」时把文件路径逐字符传给 `dart format` 的问题:单元素数组经 `if` 表达式赋值会退化成标量字符串,splat 后按字符展开,导致 `No file or directory found at "t"` 并误扫系统卷目录。
- 自托管 API Key 绑定服务器地址，配置导入与凭据迁移/保存串行；GitHub Token 清除旧明文，避免重启恢复与初始化覆盖新设置。
- 托盘初始化失败恢复普通窗口关闭，避免窗口隐藏后无法重新打开。
- AI HOT 条件请求保留重验证状态；普通资讯翻页失败保留游标并提供重试，缓存写失败不推进页码。
- 深度报告聚合失败保留完整快照，活动数据降级参与整份报告的可信度。
- 自托管批注隔离工作区；同步版本更新原子化并提供 revision 游标、精确配置过滤与删除记录处理。
- GH Archive 校验有效小时，修复跨小时排序与旧表示重复计数；采集条目和所有通知 outbox 同事务提交。
- 外链启动、缓存清理和监控历史解析捕获实际异步异常，避免 Future 越过原有错误边界。
- 发布模式启动验证并校验 SQLite 绑定。
- 热榜按真实日期计算 Star 净变化并统一图表口径;修复热榜加载态在窄窗口溢出。
- 中文词内检索并支持完整结果分页。
- 主动刷新穿透资讯与 RSS 缓存;保留真实验证时间并显示资讯降级状态。
- 打通示例资讯详情并保持分类与来源一致;兴趣偏好作用于聚类后的最终列表。
- 统一稍后读筛选并即时更新阅读状态。
- 后台更新确认与失败重试;保留后台资讯的真实验证时间。
- 监控:保留强制刷新失败时的持久快照、保留部分失败仓库及真实观测状态、展示真实检查状态并完善刷新重试。
- 总览指标校正并适配窄窗口大字号;开放聚类报道访问并改善列表可读性。
- 完善正文阅读及资讯到仓库监控流程;修复搜索与详情页回归。
- Harness:扫描免疫不可读产物并钉住 pytest 临时根。

### Removed

- 删除零引用的死代码 `devintel_demo.dart`。

## [1.6.0+6] - 2026-08-10

### Added

- 新增 BestBlogs.dev 内置资讯源(AI 分类精选 RSS,官方公开端点,2026-07-16 核验);可在设置页停用。
- 完整接入 AI HOT 7 个匿名 REST 端点与精选 RSS：AI 页新增官方日报、历史日报和当前热点，REST/RSS 使用 ID/permalink 去重，并解析作者、分类、原文与可再分发正文。

### Changed

- CI 的 Windows 门禁从增量格式检查升级为完整 `lib/test` 格式、可移植性、
  analyzer、全量测试和 Release 构建；Dart 3.12 格式基线已完成迁移。
- AI 视觉测试改用仓库内带许可证与哈希记录的 Noto Sans SC 测试子集，并统一
  加载 Flutter Material Icons，不再依赖 Windows 字体或本机 Flutter SDK 路径。
- sqlite3 恢复默认原生资产打包，Windows 测试和干净构建不再依赖系统
  `sqlite3.dll`；仓库检查同时阻止 Xcode 工程对象重复定义回归。
- 刷新真实 Windows Release 界面证据，移除重复、过时及误入的桌面截图。
- 应用账号删除手机号与短信验证码登录，只保留邮箱 OTP、Google OAuth 和 GitHub OAuth；移除三个独立登录方式构建开关，正式账号服务配置完成后三种入口固定展示。
- 当前热点移动到总览顶部，移动端首个底栏入口由“今日”改为“首页”；AI 页移除“我的 AI 日报”主流程入口，热点详情复用精简标题栏。
- TTL 内有效缓存不再显示口径徽章，过期缓存、在线数据、种子与估算口径仍按信任风险显式标记。
- AI HOT 请求保存 ETag/Last-Modified 并支持 `304` 复用；桌面轮询由每 15 分钟全量读取改为每 30 分钟先比较精选流指纹。
- 资讯列表重设计为「标题优先」的安静排版(参照 Apple News / Google News / 少数派范式):标题不再被分类彩标和徽章挤压;来源/分类/相对时间收进底部一行小字,分类改为颜色点;精选与热度合并为行尾小元素;移除左侧时间线槽(占约 15% 行宽且与相对时间重复),改为留白 + 细分隔线;相对时间与「精选」文案接入 i18n,消除组件内硬编码中文。
- 按 AGENTS.md 的 300 行约束拆分 5 个超标文件:`star_trend_chart.dart` 抽出
  `mini_charts.dart`(MiniBars/Sparkline),`ai_news_providers.dart` 抽出
  `ai_news_items_notifier.dart`,`home_mobile_trending_overview.dart` 拆为热门仓库卡与
  Star 增长卡,`ai_news_feed_parser.dart` 抽出 `feed_date_parser.dart`;原文件保留
  `export` 转发,现有调用方无需改动。
- `discover_repo_row.dart` 改为复用 `discover_profile_metrics.dart` 的
  `DiscoverProfileMetricPill`/`DiscoverProfileIconMetric`/`shortNumber`,移除本地重复实现。
- 文档治理:`docs/plans/` 下 4 份计划补状态头(已完成快照 / 活跃维护),一次性设计走查
  记录归档为 `docs/audits/ai_news_detail_design_qa.md`。

## [1.5.0+5] - 2026-07-16

### Added

- CI 新增 `server-quality` 任务：uv 环境下运行 ruff 检查/格式校验、pytest 与真实进程冒烟,自托管服务与客户端同门禁。
- 独立 `settings` feature 与 AI 资讯源管理：支持 RSS/Atom 源增删、启停、健康状态和非敏感配置导入导出。
- AI 资讯阶段二：逐条 LLM 摘要/翻译/重要性与实体缓存、时间窗事件聚类、SQLite FTS5 全文检索、按源/时间/已读筛选，以及“更多此类/不感兴趣”本地排序反馈。
- Windows 托盘常驻、周期刷新、应用内提醒中心和本机系统通知；新增可验证关闭窗口后进程驻留的托盘烟测。
- 可选 `server/` 自托管服务：FastAPI + SQLite 定时 RSS/Atom 采集、版本化跨设备配置同步、成员与共享批注、可靠 push outbox、签名 webhook、GH Archive 小时聚合、Docker 部署文件和真实进程烟测。
- 客户端自托管服务设置页：API Key 安全存储、连通性检查、成员注册和非敏感配置手动推送/拉取。

### Changed

- 本地数据库升级至 schema v6，新增 FTS5 索引、增强缓存、兴趣反馈和提醒表，并覆盖迁移回填与触发器同步。
- 品牌与信息架构：中文产品名统一为“AI资讯”，落地 Branch Pulse 全平台图标；紧凑窗口与移动端导航调整为今日、AI、发现、监控、我的 5 个目的地。
- 移动端滚动性能:热榜/项目/监控/告警中心的 `ListView(children:) + shrinkWrap` 反模式全部改为 `CustomScrollView` + Sliver 懒构建,长列表不再一次性构建全部条目;滚动内容中的 fl_chart 图表统一包 `RepaintBoundary` 隔离重绘。
- 移动端视觉密度:`RepoTile` 新增 `dense` 紧凑变体(小头像/单行描述/收紧内边距),移动列表去掉外层 AppCard 嵌套,直接以卡片条目呈现。
- 移动端顶部沉浸式:启动开启 edge-to-edge,状态栏/导航栏透明并关闭系统对比度遮罩;`AppBarTheme.systemOverlayStyle` 按主题亮暗钉死状态栏样式,防止 AppBar 默认样式覆盖全局设置(MIUI 等 ROM 上的灰色顶条随之消失)。
- 移动端第二轮打磨(对照真机截图):总览页补 AppBar、无告警时告警卡收成单行入口;趋势图轴标签防重叠(纵轴等距 5 刻度、横轴整数间隔并丢弃边界重复标签、量程比例留白);发现页去掉双头部(徽章/刷新并入 AppBar、紧凑搜索框内联)、分段选择器改单行横向滚动;零增量仓库不再显示「+0 ↗」噪声;AI 日报未配置态收成单行引导,安全说明挪进配置对话框。

### Fixed

- 监控页移动分支此前把自滚动的 `MonitorMonitoredRepos`(内含 CustomScrollView)嵌入 `ListView` children,存在高度无界的布局风险;改为 Sliver 化的紧凑监控行。
- 托盘后台提醒的已见集合改为与历史合并而非整表覆盖:此前单源临时失败会把旧条目挤出 head 页,源恢复后被误判为新条目而重复提醒。
- 自托管配置推送冲突不再被吞成笼统「操作失败」:新增 `settings.server.conflict` 提示引导先拉取;健康检查与冲突异常统一收敛到 `AppException` 边界。
- `.gitignore` 排除 `server/.venv`、`server/data/` 与 `__pycache__`,防止本地虚拟环境和运行时数据库被意外提交。

### Security

- 服务端 master key 改为 fail-fast:未设置或保留默认值 `change-me` 时拒绝启动(compose 已有 `:?` 强制,本修复覆盖裸 uvicorn 路径);`app.main:app` 入口改为 PEP 562 惰性构造,import 不再隐式读取环境。
- 推送订阅 upsert 限定在调用方工作区:客户端自报的订阅 id 与他人碰撞时返回 409,不再可能改写其他工作区的 endpoint/secret;新增跨工作区抢占回归测试与 master key 校验测试。

## [1.4.0+4] - 2026-07-15

### Added

- AI 动态多源聚合:主源之外并行接入 OpenAI News、Hugging Face Blog、Google AI Blog、arXiv cs.AI 四个 RSS/Atom 源,规范化 URL/标题去重合并;单源失败隔离,主源失效时模块仍有实时数据。
- 资讯库:关键词搜索改查 SQLite 全部本地沉淀条目;新增已读与稍后读状态(schema v5 `ai_news_state`,实体快照模式,清缓存不丢用户状态),列表页可只看稍后读。
- 资讯 ↔ GitHub 打通:详情页从标题/摘要/链接抽取相关仓库,一键跳转仓库详情(`/ai_news/repo/:fullName`)。
- 今日 AI 日报:用户自带 OpenAI 兼容 API Key(secure storage),基于本地资讯库当天条目生成中文日报,按天缓存不重复计费;未配置不发请求,失败明确报错。
- SQLite 迁移链 v1→v5 往返测试覆盖全链路与部分链路,锁死 onUpgrade 数据守卫。
- 主屏视觉 Golden 在原页头基线之外,新增「完整 chrome」基线(PageHeader + MetricCard 行 + AppCard + Skeleton),锁定桌面端 B/C 区域真实组合。
- `feature_providers` DI 桶补齐 `themeModeControllerProvider`/`themePresetControllerProvider`/`sidebarWidthProvider` 的 re-export,消除历史 TODO。

### Changed

- 统一仓库列表设计语言:`RepoTile` 升级为全局一致的卡片式条目(细边框 + md 圆角 + 排名角标 + 尾部插槽),深度报告「本周热门/最近活跃」、仓库监控、热榜、收藏、监控主题等页统一改为间距卡片列表,替换原分隔线扁平行。
- 数据口径诚实化:列表右侧趋势曲线只在存在真实观测历史时绘制;无历史时展示 Star 增量与趋势箭头,不再用合成曲线兜底(消除千篇一律的假曲线)。视觉基线需在 Windows 上 `flutter test --update-goldens` 重新生成 `repo_tile.png`。
- 发现页继续按 AGENTS.md 300 行约束拆分:`discover_repository` 的 profile 抽取到 `discover_profile_composition`;3 个 Notifier 抽到 `discover_notifiers`;`discover_page` 的三个 section 抽到 `discover_sections`;`discover_profile_row` 的 _Pill/_IconMetric 抽到 `discover_profile_metrics`。4 个原超长文件全部回到 300 行以内。
- 移动端趋势、热门仓库二级页、语言趋势、项目仓库列表、监控最近告警等 6 个用户可见文件全部接入 i18n,新增 30+ 文案 key,消除裸中文字面量。

### Fixed

- 将像素 Golden 基线固定在 Windows 执行，并在 Windows CI 中显式运行全部视觉回归，避免 Ubuntu 字体与渲染差异造成伪失败。
- 告警列表从 `for` 循环改为 `ListView.separated` + `RepaintBoundary`,大列表滚动重绘开销下降。
- `HeaderSearchField` 用 `ListenableBuilder` 替换受保护的 `setState`,彻底消除输入时的双重 rebuild。
- 发现页 3 个 `loadMore` 补齐 `catch → AsyncError`,网络异常不再被 `try/finally` 吞掉,UI 能正确展示错误并阻止重试风暴。

## [1.3.0+3] - 2026-07-11

### Added

- 收藏、监控仓库和关注开发者保存真实实体快照，重启后不再依赖演示目录恢复展示。
- 仓库详情与深度报告接入 GitHub Events API 真实活动，并提供按仓库集合和凭据隔离的聚合缓存降级。
- 启动初始化失败恢复页，支持安全重试和打开数据目录，不自动删除用户数据。
- Linux 格式化/分析/覆盖率测试与 Windows Release/可见主窗口烟测双平台 CI。

### Changed

- 监控 Star/Fork 阈值统一按本地自然日归一化，跨多日观测不再把累计变化误报为单日变化。
- OAuth Client ID 改为构建时配置；未配置版本只展示 Personal Access Token 入口并保持零 OAuth 网络请求。
- 配置导出收敛为非敏感白名单；导入执行信封、键和值域完整预检，写入失败自动回滚并刷新运行中状态。
- 深度报告 Markdown 文案跟随当前语言，中英文键保持对称；活动相对时间、主要操作语义和三档窗口布局完成回归。

### Fixed

- 修复空监控集合被默认仓库重新填充、贡献者缓存跨仓库或凭据串用、窄窗口仓库元数据溢出等可信度问题。
- 移除仓库与报告活动中的静态样例流，远端和缓存均不可用时诚实显示空态。

## [1.2.0+2] - 2026-07-10

### Added

- 桌面端新增“发现”主入口，形成 8 个主入口；紧凑窗口和移动端收敛为今日、AI、项目、设置 4 Tab。
- 仓库每日 Star/Fork 真实观测、增长/停更/活跃下降/贡献者集中度规则计算和 SQLite 告警事件存储。
- 告警已读、归档、恢复以及唯一真实可用的应用内告警开关。
- GitHub Repository、Contributors 和 User 请求的单资源 ETag 条件缓存。
- 统一的数据新鲜度与指标口径标识：在线、有效缓存、过期缓存、种子，以及真实观测、估算、种子。
- `RepositoryFeed` 核心领域边界，供报告功能消费仓库摘要，避免功能模块反向依赖数据实现。

### Changed

- 所有远端仓库统一为“有效缓存 → 远端 → 过期缓存 → 种子/错误”的降级策略，并按模块使用集中 TTL。
- 报告、发现、登录流程、偏好设置和监控聚合拆分为更小的职责文件；业务 Dart 文件控制在 300 行左右，i18n 与机械种子数据除外。
- 发现页官方账号和人物入口统一进入应用壳内的代表仓库详情。
- GitHub Token 改用 `flutter_secure_storage`，旧版 SharedPreferences 明文值会自动迁移并清除。
- 删除无服务端或商业系统支撑的 PRO 升级入口、每日报告和外部推送承诺。

### Fixed

- 修复通知控制器只有一个开关、桌面卡片仍按四项读取导致的越界崩溃。
- 修复 AI 动态缺少下一页游标时持续显示底部加载的问题。
- 补齐深色模式状态色、键盘焦点与关键入口语义标签。

## [0.1.0+1] - 2026-06-27

### Added

- 初始 Flutter 桌面工作台、Feature-first 目录、响应式布局、主题、基础缓存和四态页面。
- 当时提供总览、AI 动态、GitHub 热榜、技术热点、仓库监控、深度报告、设置 7 个入口。
