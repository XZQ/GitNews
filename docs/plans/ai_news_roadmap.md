# AI 资讯模块 Roadmap

更新时间:2026-07-14
基线版本:`1.3.0+3`

## 背景与问题

当前 AI 动态模块的能力与短板(详见 `product_ia_data_plan.md`):

1. **单源风险**:唯一数据源 `aihot.virxact.com`,失效时整个模块只剩过期缓存;
   Agent Skills 排行源 404 的教训已经证明这种脆弱性。
2. **名为 AI 资讯,自身没有 AI**:无摘要、翻译、去重、重要性排序;总览只是入口聚合。
3. **资讯与 GitHub 两侧孤岛**:新闻无法跳转仓库详情或加入监控。
4. **缺全文搜索与内容沉淀**:搜索只过滤内存中已加载条目;没有稍后读/已读状态。
5. **无推送**(已知系统边界,后续阶段)。

## 阶段一(本次落地)

全部在「无服务端、本地闭环」约束内实现。

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

## 阶段二(后续,按优先级)

1. **源管理 UI**:设置页启用/禁用/自定义 RSS 源;源健康度展示(连续失败标记)。
2. **LLM 增强**:逐条摘要与翻译缓存、重要性打分排序、实体抽取
   (模型/公司/仓库)反哺 AI 雷达主题。
3. **事件聚类**:同一事件多源报道合并为事件卡(标题相似度 + 时间窗)。
4. **资讯库检索升级**:SQLite FTS5、按源/时间过滤、已读/未读视图。
5. **兴趣反馈**:不感兴趣/更多此类信号调整排序权重(本地)。
6. **托盘常驻 + 应用内提醒**:弱化「前台才采集」限制(仍非系统推送)。

## 阶段三(新系统边界,需专门设计)

服务端定时采集、系统推送、跨设备同步、全文归档服务。属于
`product_ia_data_plan.md` 第 9 节声明的下一阶段,不在客户端伪装实现。

## 验证口径

- 纯 Dart 单元测试:feed 解析、去重合并、仓库链接抽取。
- `dart format` / `flutter analyze` / `flutter test` / Windows Release 烟测。
- 手动:断网(staleCache)、主源不可用(RSS 兜底)、未配置 Key(引导态)。
