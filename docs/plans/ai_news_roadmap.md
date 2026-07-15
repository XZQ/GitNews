# AI 资讯模块 Roadmap

更新时间:2026-07-16
基线版本:`1.4.0+4` 加 `Unreleased`

## 阶段一启动时的背景与问题

以下是阶段一启动前的能力缺口，保留用于解释 1.4.0+4 的设计动机；其中第 1～4 项已经由阶段一解决或显著缓解（详见 `product_ia_data_plan.md`）：

1. **单源风险**:唯一数据源 `aihot.virxact.com`,失效时整个模块只剩过期缓存;
   Agent Skills 排行源 404 的教训已经证明这种脆弱性。
2. **名为 AI 资讯,自身没有 AI**:无摘要、翻译、去重、重要性排序;总览只是入口聚合。
3. **资讯与 GitHub 两侧孤岛**:新闻无法跳转仓库详情或加入监控。
4. **缺全文搜索与内容沉淀**:搜索只过滤内存中已加载条目;没有稍后读/已读状态。
5. **无推送**:阶段二已用桌面托盘、应用内提醒和本机系统通知补齐单机闭环；跨设备系统推送则由可选自托管服务的可靠 outbox 衔接，仍需部署方提供 FCM/APNs/WNS 网关和凭据。

## 阶段一（1.4.0+4 已落地）

这些能力均在当时的「无服务端、本地闭环」约束内实现，且在当前版本继续作为服务端不可用时的离线基线。

### 1. 多源 RSS/Atom 聚合

- 新增 `lib/core/config/ai_news_sources_config.dart`,声明式配置补充源
  (OpenAI News、Hugging Face Blog、Google AI Blog、arXiv cs.AI,均已核验可用)。
- 新增 `AiNewsFeedParser`(基于 `package:xml`,支持 RSS 2.0 与 Atom)与
  `AiNewsRssClient`;每个源独立失败隔离,任一源不可用不影响其余源。
- 新增 `AggregatedAiNewsRepository`:head 页并行拉取主源 + RSS 源,
  规范化 URL/标题去重合并,按发布时间倒序;分页游标页仍走主源。
- 主源失败但 RSS 存活时模块仍有 live 数据,消除单点。
- 数据口径不变:live / freshCache / staleCache / seed 全链路保留。

### 2. 资讯库:持久沉淀 + 全文搜索 + 稍后读

- `ai_news_item` 表本身不随 TTL 清除(TTL 只控制远端请求),继续作为本地资讯库。
- 新增 `ai_news_state` 表(schema v5):已读、稍后读状态 + 条目实体快照,
  与收藏/监控一致的「真实实体快照」模式;不在 `clearAll` 业务表清单内,
  清缓存不丢用户状态。
- 搜索升级:关键词非空时改查 SQLite 全库(title/title_en/summary/source LIKE),
  不再只过滤已加载的内存分页。
- 详情页打开自动标记已读;新增稍后读开关;列表页可只看稍后读。

### 3. 资讯 ↔ GitHub 打通

- 纯函数 `extractGitHubRepoLinks`:从标题/摘要/链接中抽取 `owner/repo`,
  过滤保留字路径(topics/search/blog 等)。
- 详情页新增「相关仓库」区,点击跳转 `ai_news` 分支下新增的仓库详情路由,
  复用现有 `RepoDetailPage`(收藏/监控入口随之可用)。

### 4. LLM 每日日报(用户自带 Key)

- OpenAI 兼容接口:用户在 AI 动态页配置 base URL / model / API key;
  Key 走 `flutter_secure_storage`(与 GitHub Token 同级安全),
  base URL 与 model 走 SharedPreferences。
- 日报基于本地资讯库当天条目生成,按天缓存(`ai_digest:YYYY-MM-DD`),
  不重复计费;未配置 Key 时只显示引导,不发任何请求。
- 失败明确报错,不伪造摘要;Key 永不进入日志与配置导出。

## 阶段二（Unreleased 已落地）

1. **独立设置与源管理**:`lib/features/settings/` 已建立；可启用、禁用、新增和删除 RSS/Atom 源，并记录最近成功、失败次数和健康状态。
2. **LLM 条目增强**:在用户自带 OpenAI 兼容 Key 的前提下生成逐条摘要、翻译、重要性评分和实体，结果持久缓存；未配置或失败时不伪造内容。
3. **事件聚类**:按规范化标题相似度和时间窗合并多源报道，事件卡明确显示报道来源数量。
4. **资讯库检索升级**:schema v6 引入 SQLite FTS5、迁移回填和同步触发器，并支持按源、时间、已读状态和稍后读筛选。
5. **兴趣反馈**:“更多此类/不感兴趣”写入本地反馈表并参与排序，反馈可撤销。
6. **托盘与提醒**:Windows 关闭主窗口后保持托盘常驻，按周期刷新并生成应用内提醒；桌面活跃时可发本机系统通知，提醒中心可查看和标记已读。

### 1.4.0+4 中已偿还的技术债务(阶段一配套)

- AI 动态多源聚合、资讯库、资讯 ↔ GitHub 打通、LLM 日报均为阶段一成果,已发布。
- 阶段一相关的代码质量债务(300 行拆分、loadMore 错误处理、i18n 裸中文、
  SQLite 迁移往返测试、Golden 完整 chrome)在 1.4.0+4 一并清理。
- 上述债务在 `Unreleased` 中继续收口；当前数据库版本为 v6，独立 Settings、FTS5、增强、反馈、聚类、托盘和提醒均已进入代码与测试。

## 阶段三（Unreleased 已提供可选自托管实现）

`server/` 已提供 FastAPI + SQLite 的可部署实现：定时 RSS/Atom 采集、版本化配置同步与冲突返回、工作区成员和共享批注、可靠 push outbox、签名 webhook 投递，以及 GH Archive 小时数据聚合。客户端设置页可保存服务地址、工作区、成员和安全 API Key，执行连通性检查与手动配置推送/拉取。

仓库交付的是自托管软件和本地验证，不包含公网域名、TLS、云主机或生产推送凭据。FCM/APNs/WNS 的最终投递由部署方网关消费 outbox 并回执；未配置服务端时，客户端继续完整使用本地缓存、资讯库、反馈和提醒。

## 验证口径

- Flutter：feed 解析、去重、聚类、增强解析、反馈排序、FTS5、迁移、提醒、配置同步等单元/组件测试。
- Windows：`dart format`、`flutter analyze`、`flutter test`、Release 构建、可见窗口烟测和托盘驻留烟测。
- 服务端：Ruff、pytest、真实 Uvicorn 进程健康烟测；Docker 可用时再验证镜像构建。
- 手动边界：断网读取 stale cache、主源不可用时 RSS 兜底、未配置 Key 时不发 LLM 请求、未配置服务端时不影响本地能力。
