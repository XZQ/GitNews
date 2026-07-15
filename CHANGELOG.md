# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) 和[语义化版本](https://semver.org/spec/v2.0.0.html)。

## [Unreleased]

### Added

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
- 统一的数据新鲜度与指标口径标识：在线、新鲜缓存、过期缓存、种子，以及真实观测、估算、种子。
- `RepositoryFeed` 核心领域边界，供报告功能消费仓库摘要，避免功能模块反向依赖数据实现。

### Changed

- 所有远端仓库统一为“新鲜缓存 → 远端 → 过期缓存 → 种子/错误”的降级策略，并按模块使用集中 TTL。
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
