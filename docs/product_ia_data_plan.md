# GitHub 情报站产品规划与数据方案

> 更新时间: 2026-07-04

## 当前工程基线

- Flutter: 3.44.0 stable
- Dart: 3.12.0
- 当前优先改动范围: 桌面端体验
- 手机端状态: 暂不跟随桌面端直接重构,需要单独规划信息架构与导航
- 项目定位: 面向开发者的 AI + GitHub 情报雷达,不是普通 AI 新闻 App

## 竞品/同学方案观察

同学方案主要是四栏移动端信息 App:

- 今日 / 新闻资讯
- AI / AI 聚焦
- 项目 / GitHub 热门项目
- 我的 / 内容管理

视觉特征偏内容消费:大 Hero、新闻列表、项目卡片、底部 Tab。这个方向清晰,但容易变成通用资讯 App。

本项目需要拉开的差异:

- 强化开发者场景,不是泛 AI 新闻
- 强化 GitHub 热榜、本周趋势、Agent/MCP/Coding 工具榜
- 强化仓库监控、收藏、报告、个人情报库
- 桌面端做工作台,手机端做轻量阅读与跟踪

## 推荐信息架构

### 手机端

手机端建议保留 4 个底部 Tab,控制复杂度:

1. 今日
   - 今日摘要
   - AI 快讯
   - GitHub 新晋项目
   - Agent 热点
   - 机会雷达
2. AI
   - 模型更新
   - Agent / MCP
   - AI Coding
   - 产品动态
   - 论文研究
3. 项目
   - GitHub 热榜
   - 本周增长
   - Agent 项目榜
   - 新晋项目
   - 已监控仓库
4. 我的
   - 收藏
   - 关注关键词
   - 关注仓库
   - 监控规则
   - 生成过的报告

### 桌面端

桌面端不做手机放大版,保留更细的信息工作台:

1. 总览
2. 情报流 / AI 动态
3. AI 雷达
4. GitHub 热榜
5. Agent 榜
6. 仓库监控
7. 深度报告
8. 我的 / 设置

桌面端主区域适合:

- 顶部搜索 + 全局筛选
- 多列信息流
- 热榜表格
- 趋势图
- 监控提醒
- 右侧今日摘要 / 关注关键词 / AI 结论

## 当前桌面端改动原则

- 先统一桌面端顶部搜索与一级页面结构
- 先保证桌面端体验稳定,不要让手机端被桌面端布局牵连
- 桌面端可保留 7-8 个侧边栏入口
- 手机端后续收敛为 4 个底部 Tab

## 第一阶段改造记录

2026-07-03:

- 桌面端先不新增第 8 个 Tab,避免当前共享导航把手机端底栏一起带偏
- 原 `/tech_hotspot` 暂升级为 `AI雷达`,承载 Agent、MCP、AI Coding、本地推理等趋势信号
- `Agent 榜` 先作为 AI雷达内的榜单观察区落地,后续接真实数据后再决定是否独立为桌面一级入口
- 手机端仍按 4 Tab 单独规划,不要直接复用桌面侧边栏结构

2026-07-04:

- GitHub 热榜先完成 `TrendingQuery -> TrendingDataSource -> TrendingRepository` 边界
- 当前仍使用 `LocalTrendingDataSource`,但 `today/week/month` 与语言筛选已经进入 Repository 查询参数
- 后续接 GitHub Search API 时,优先新增 `GithubTrendingDataSource`,不要改页面层和 `TrendingDigest`
- 已新增 `GithubTrendingDataSource`,能调用 GitHub Search API 并归一化为 `TrendingDataSnapshot`
- 默认数据源仍保持本地模拟,避免未登录/未配置 token 时触发 GitHub Search 限流
- GitHub Search 不返回 Star 增量,当前 REST 数据源里的 `starDelta` 只是动量代理值;真实本周趋势仍需要本地快照或 GH Archive
- 设置页已提供 `本地 / GitHub` 热榜数据源切换,并持久化到 SharedPreferences
- 当前 GitHub 模式仍是匿名请求,适合验证链路;稳定使用前需要接入 GitHub token 与缓存降频
- GitHub 热榜已接入 SQLite 快照缓存:`TrendingCacheDao + CachedTrendingDataSource`
- 缓存 key 按 `window + board + language` 生成,TTL 为 5 分钟;远端失败时可回退到过期缓存
- 开发者选项已支持配置 GitHub Personal Access Token,GitHub Search 请求会自动带 Bearer token
- 热榜缓存按匿名/Token scope 隔离,避免清除 token 后复用认证态缓存
- 开发者选项已支持手动检查 GitHub `/rate_limit`,展示 REST Core 与 Search API 剩余额度和重置时间
- GitHub 热榜顶部已展示当前数据源状态:本地数据 / GitHub 匿名 / GitHub Token 与缓存 TTL
- GitHub 热榜手动刷新会删除当前 `window + language + token scope` 缓存后再拉取,不影响其它查询缓存
- GitHub 热榜顶部搜索已接入本地过滤,只筛选当前 `window + language` 结果,不会因关键词输入额外请求 GitHub Search
- AI 动态顶部搜索已接入本地过滤,只筛选当前已加载/缓存条目,不会因输入关键词额外请求第三方接口
- AI 雷达顶部搜索已接入本地过滤,筛选主题名称、分类、摘要与标签;标签点击会直接写入搜索词
- 仓库监控顶部搜索已接入本地过滤,筛选监控仓库、最近告警与监控规则,统计卡仍展示全局状态
- 深度报告顶部搜索已接入本地过滤,筛选报告内仓库与贡献者
- 深度报告导出已接入 Markdown 文件落盘,导出当前筛选后的仓库与贡献者数据
- 总览顶部搜索作为全局入口,按关键词跳转到 AI 动态、GitHub 热榜、AI 雷达、仓库监控或深度报告,并写入目标页搜索词
- 统一搜索框已支持搜索词回显与清除按钮,从总览跳转后的过滤状态可见且可一键恢复
- AI 雷达筛选面板已接入本地分类筛选,可与搜索词叠加过滤主题
- 设置页登录入口已接入本地会话,可保存显示名并在设置页切换登录/退出状态
- PRO 入口已改为本地能力中心,串联 Token 配置、深度报告与监控工作台
- 已移除搜索、筛选、导出、登录、PRO 等已完成能力的旧占位提示文案
- GitHub 热榜新增榜单类型维度:`全部 / Agent / MCP / AI Coding / 新晋项目`
- 榜单类型已进入 `TrendingQuery`、GitHub Search 查询、本地模拟过滤和 SQLite 缓存 key,避免不同榜单串缓存
- 无服务端阶段统一采用客户端直连公开 API + SQLite 缓存策略,AI 动态与 GitHub 热榜 TTL 均为 5 分钟;5 分钟内返回本地缓存,手动刷新可删除当前查询缓存后重新请求

## 数据源规划

### 无服务端阶段统一策略

当前没有服务端,先采用客户端直连公开 API 的轻量策略:

- 所有远端数据源必须有 SQLite 快照缓存与 `cache_meta` TTL
- 默认 TTL 统一为 5 分钟;5 分钟内只返回本地缓存
- 手动刷新删除当前查询缓存后再请求远端,不影响其它查询缓存
- 远端失败时优先回退过期缓存,无缓存才展示错误态
- GitHub 请求优先使用用户配置的 Personal Access Token,匿名模式仅用于验证链路
- 搜索框只过滤当前已加载/已缓存数据,不因输入关键词额外请求远端
- 分页和详情请求要做并发锁,避免滚动触底或重复点击打爆公开 API

### AI 资讯流

第一阶段:

- 保留现有卡兹克 / aihot 作为精选源
- 客户端继续使用本地缓存,但后续应通过聚合层访问,避免直接绑定单一第三方源

第二阶段:

- 官方博客/RSS:OpenAI News RSS、Google AI Blog、DeepMind Blog、Microsoft AI Blog
- 论文:arXiv API,关键词优先 `cat:cs.AI OR cat:cs.CL OR cat:cs.LG`
- 社区:Hacker News Firebase API 的 `topstories/newstories/beststories`
- 开源动态:GitHub REST Search/Repository API

### GitHub 热门项目

可用数据:

- GitHub REST Search API: 仓库搜索、stars、language、pushed、created 等
- GitHub GraphQL Search: 批量查询更细字段
- GH Archive: 公开 GitHub 事件,适合计算趋势

建议榜单:

- 今日热门
- 本周趋势
- 新晋项目
- Agent 项目榜
- MCP 项目榜
- AI Coding 工具榜

### Agent 榜

Agent 榜不直接等同于 GitHub Trending,需要自定义口径:

- topic 命中: `agent`, `ai-agent`, `llm-agent`, `mcp`, `multi-agent`
- 关键词命中: README / description / topic
- GitHub 指标: stars、forks、watchers、open issues、最近 push
- 趋势指标: 1 日 / 7 日 star 增量
- 社区指标: HN / Reddit / X 后续可接入

### 仓库监控

无服务端阶段优先接 GitHub REST API:

- Repository 基础信息:`GET /repos/{owner}/{repo}`
- Releases:`GET /repos/{owner}/{repo}/releases`
- Issues:`GET /repos/{owner}/{repo}/issues`
- Contributors:`GET /repos/{owner}/{repo}/contributors`
- Events:`GET /repos/{owner}/{repo}/events`
- 本地保存监控仓库列表、告警规则、最近一次快照
- 指标变化先用本地相邻快照计算,后续再升级为服务端定时采集

### AI 雷达

无服务端阶段先由多个 GitHub Search 查询组成主题雷达:

- Agent:`agent OR ai-agent OR llm-agent OR langgraph OR autogen`
- MCP:`mcp OR model-context-protocol OR modelcontextprotocol`
- AI Coding:`coding agent OR copilot OR code assistant OR claude-code OR codex`
- RAG:`rag OR retrieval augmented generation OR vector database`
- Local Inference:`llama.cpp OR ollama OR vllm OR local llm`

每个主题单独缓存 5 分钟,再在客户端按 stars、forks、最近 push、open issues 与命中关键词计算热度。

## 数据处理管线

建议新增聚合层,不要让 Flutter 直接拼所有外部 API:

```text
Fetch -> Normalize -> Deduplicate -> Classify -> Score -> Summarize -> Store -> Serve
```

统一数据模型:

```text
id
title
summary
source
sourceType
url
publishedAt
category
entities
topics
importanceScore
confidenceScore
duplicateGroupId
relatedRepos
relatedPapers
whyItMatters
actions
```

## 实施顺序

1. 固化桌面端一级页面与顶部搜索体验
2. 新增数据聚合接口抽象,Flutter 只依赖 Repository
3. AI 资讯流:卡兹克 + 本地缓存继续可用
4. GitHub 热榜:接入 GitHub Search API
5. 本周趋势:先做本地每日快照,再接 GH Archive
6. Agent 榜:用 topic/keyword + 综合分数生成
7. 手机端重构为 4 Tab,复用同一套数据层
8. 深度报告:由聚合数据生成日报/周报

## 注意事项

- GitHub 没有稳定官方 Trending API,不要把爬 GitHub Trending 当核心数据源
- GitHub Search API 有搜索限流,需要缓存与后端聚合
- GH Archive 更适合趋势计算,但数据量大,不适合直接在 Flutter 端处理
- 手机端需要单独设计,不要直接复用桌面端侧边栏信息架构
- 数据是核心壁垒:去重、评分、关联仓库、为什么重要,比单纯 UI 更关键

## 参考数据源

- GitHub REST Search API: https://docs.github.com/en/rest/search/search
- GitHub REST Rate Limit: https://docs.github.com/en/rest/rate-limit/rate-limit
- GitHub GraphQL API: https://docs.github.com/en/graphql
- GH Archive: https://www.gharchive.org/
- Hacker News API: https://github.com/HackerNews/API
- arXiv API: https://info.arxiv.org/help/api/user-manual.html
- OpenAI News RSS: https://openai.com/news/rss.xml
