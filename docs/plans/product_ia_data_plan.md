# GitHub 情报站产品与数据方案

更新时间：2026-07-06

## 产品定位

GitHub 情报站不是普通 AI 新闻 App，而是面向开发者的 AI + GitHub 情报工作台。桌面端强调筛选、监控、趋势、报告和本地内容管理；手机端应做轻量阅读与跟踪，不直接复用桌面侧边栏结构。

## 信息架构

### 桌面端当前 7 个入口

1. 总览：跨模块入口和今日摘要。
2. AI 动态：AI 行业资讯流。
3. GitHub热榜：GitHub 热门仓库、本周趋势、Agent/MCP/AI Coding 榜单。
4. AI雷达：Agent、MCP、AI Coding、RAG、本地推理等主题信号矩阵。
5. 仓库监控：关注仓库、告警、规则和通知设置。
6. 深度报告：基于仓库和贡献者的聚合分析与 Markdown 导出。
7. 设置：主题、账号、本地能力中心、GitHub Token、数据管理。

### 手机端规划

手机端保留 4 个底部 Tab，但不在当前桌面端收尾批次中展开：

1. 今日：摘要、快讯、重点项目、机会雷达。
2. AI：模型、Agent/MCP、AI Coding、论文、产品动态。
3. 项目：GitHub热榜、本周增长、新晋项目、已监控仓库。
4. 设置：收藏、关注、监控、规则、报告。

## 当前数据状态

### 已接入真实远端

- AI 动态：第三方 AI 资讯源。
- GitHub热榜：GitHub Search API，可在设置中切换本地/GitHub 数据源。
- AI雷达：GitHub Search API 聚合主题。
- 仓库监控：GitHub Repository API。
- 仓库详情：GitHub Repository、Search、Contributors API。
- 深度报告：复用热榜仓库，并通过 Contributors API 聚合贡献者。
- 开发者设置：GitHub `/rate_limit` 查询。

### 已接入本地缓存

- 远端数据默认 TTL 为 5 分钟。
- 5 分钟内优先返回本地缓存，不因搜索框输入额外请求远端。
- 手动刷新删除当前查询缓存后重新请求，不影响其他查询缓存。
- 远端失败时优先回退过期缓存；没有缓存时再使用本地种子兜底或显示错误。
- `json_snapshot_cache` 用于结构仍在变化的聚合结果。
- `RepoSnapshotHistoryDao` 记录仓库每日 Star/Fork 快照。
- `TechHotspotHistoryDao` 记录技术主题每日 heat、mentions、relatedRepos 快照。

### 已接入本地用户数据

- 收藏仓库。
- 监控仓库。
- 关注开发者。
- 监控规则。
- 通知设置。
- 告警已读、归档和恢复。
- GitHub Token。
- 本地登录展示名。

### 仍是本地兜底或估算

- 没有服务端定时任务，因此跨天趋势依赖本机多次打开后的本地快照。
- 本地快照不足 2 天时，Star/Fork 趋势曲线会使用估算曲线兜底。
- 部分收藏、关注和监控默认列表来自种子数据，用于首次启动时给用户一个可操作初始状态。
- GH Archive、HN、Reddit、X 等社区信号暂未接入客户端。

## 无服务端阶段策略

当前用户无法搭建服务端，因此项目采用客户端直连公开 API + 本地缓存的策略：

- GitHub 请求优先使用用户配置的 Personal Access Token。
- 匿名 GitHub 模式只适合验证链路，稳定使用建议配置 Token。
- 搜索框只过滤当前已加载或已缓存数据。
- 所有远端聚合必须有缓存和失败兜底。
- 不在 Flutter 客户端直接处理 GH Archive 这类大体量事件数据。
- 用户内容管理保持本地数据，不伪装成云端同步。

## 已完成的桌面端收尾

- 顶部搜索框统一为页面主操作区宽度。
- 轻/暗色主题卡片边框、圆角和侧栏分隔线已做减重。
- GitHub热榜标题、设置入口和主导航命名已统一。
- 语言占比等动态长列表改为可滚动布局，避免固定高度溢出。
- 首页、AI 动态、GitHub热榜、AI雷达、监控、报告搜索均走本地过滤或跨页跳转写入目标页搜索词。
- 收藏、监控、关注、设置、通知、告警处理等本地交互已闭环并持久化。
- 仓库详情和列表中的主要仓库入口可跳转详情页。
- 深度报告支持当前筛选结果导出 Markdown。

## 继续优先级

1. 桌面端继续扫“看起来可点击但无动作”的细节入口。
2. 给关键桌面页面补布局回归测试，覆盖 1366x768 和窄宽度场景。
3. 拆分仍超过 300 行的页面或数据仓库文件。
4. 增强数据来源标识，让用户能区分真实观测、估算、本地兜底。
5. 手机端按 4 Tab 独立设计，不直接复制桌面端布局。

## 参考数据源

- GitHub REST Search API: https://docs.github.com/en/rest/search/search
- GitHub REST Rate Limit: https://docs.github.com/en/rest/rate-limit/rate-limit
- GitHub GraphQL API: https://docs.github.com/en/graphql
- GH Archive: https://www.gharchive.org/
- Hacker News API: https://github.com/HackerNews/API
- arXiv API: https://info.arxiv.org/help/api/user-manual.html
- OpenAI News RSS: https://openai.com/news/rss.xml
