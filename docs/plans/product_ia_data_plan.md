# AI资讯：产品、数据与系统边界

更新时间：2026-07-16
对应基线：`1.4.0+4` 加 `Unreleased` 改动

## 1. 第一性原理

产品要解决的不是“展示更多卡片”，而是帮助开发者在有限注意力下完成三个判断：

1. 今天有哪些 AI 与 GitHub 变化值得看。
2. 哪些仓库或主题值得持续跟踪。
3. 当前判断来自实时数据、历史观测、估算还是兜底数据。

当前采用双边界：客户端继续以“直连公开 API + 本机持久化 + 明确数据口径”保证离线可用；需要持续运行、跨设备或多人共享的能力进入显式配置的 `server/` 自托管服务。服务端不可用时不得阻断客户端启动、缓存读取或本地写入。

## 2. 信息架构

### 桌面端：8 个主入口

1. 总览：跨模块摘要和快捷入口。
2. AI 动态：远端 AI 资讯流。
3. GitHub 热榜：按窗口、语言和榜单类型筛选仓库。
4. AI 雷达：聚合 Agent、MCP、AI Coding、RAG、本地推理等主题信号。
5. 发现：流行仓库、Agent Skills、官方账号和知名人士。
6. 仓库监控：仓库观测、规则、告警和应用内通知设置。
7. 深度报告：仓库与贡献者聚合、筛选和 Markdown 导出。
8. 设置：本地内容、主题、语言、GitHub Token、资讯源、自托管服务连接和数据管理。

### 紧凑窗口与移动端：5 个主入口

1. 今日：总览。
2. AI：AI 动态。
3. 发现：承接流行仓库、Agent Skills、官方账号和人物发现，并提供热榜、AI 雷达等项目情报入口。
4. 监控：直接进入仓库观测、规则和应用内告警闭环。
5. 我的：本地收藏、关注、主题、Token、数据管理和深度报告相关入口。

移动端不是桌面侧栏的缩小复刻；底部导航固定为五个用户目的地。热榜、AI 雷达和深度报告继续保留独立路由，但不占用底部导航位置，由发现、我的和详情入口承接。

## 3. 数据来源

| 功能 | 远端来源 | 本机持久化 | 无网络降级 |
|---|---|---|---|
| AI 动态 | aihot 精选流、可管理 RSS/Atom、自托管聚合 API | SQLite 条目、FTS5、增强结果、兴趣反馈、已读/稍后读/提醒 | 过期缓存 / 种子 / 错误态 |
| GitHub 热榜 | GitHub Search | JSON/仓库快照 | 过期缓存 / 种子 |
| AI 雷达 | GitHub Search | 主题每日快照 | 过期缓存 / 种子 |
| 发现 | GitHub Search、Skills 排行源 | JSON 快照 | 过期缓存 / 种子 |
| 仓库监控 | Repository、Contributors | 每日观测、告警事件 | 过期缓存 / 本地历史 |
| 仓库详情 | Repository、Search、Contributors、Events | 单资源 ETag、详情和真实活动快照 | 过期缓存 / 种子或空活动 |
| 深度报告 | RepositoryFeed、Contributors、Events | 按仓库集合与凭据隔离的聚合快照 | 过期缓存 / 种子或空活动 |
| API 配额 | Rate Limit | 短期状态 | 明确错误 |
| 跨设备与协作 | 可选 FastAPI 自托管服务 | 服务端 SQLite：版本记录、成员、批注、push outbox | 保留本机状态，显示连接失败 |
| GH Archive | `data.gharchive.org` 小时 gzip | 服务端按仓库/事件/小时聚合 | 已聚合历史 / 明确错误 |

## 4. 缓存和一致性

- AI 动态、GitHub 热榜、AI 雷达：5 分钟。
- 仓库监控：10 分钟。
- 仓库详情、深度报告：30 分钟。
- 发现：6 小时。
- Agent Skills 排行：24 小时。
- 默认读取新鲜缓存；缓存缺失、过期或显式刷新时请求远端。
- 远端失败时先用过期缓存；只有没有可用缓存时才进入种子或错误态。
- Repository、Contributors、User 等单资源请求保存 ETag；`304 Not Modified` 复用已解码实体并更新缓存时间。
- 手动刷新只影响当前查询或资源，不清空无关缓存。

## 5. 数据可信度模型

响应级新鲜度 `DataFreshness`：

- `live`：本次来自远端成功响应。
- `freshCache`：在 TTL 内的本地缓存。
- `staleCache`：远端失败后使用的过期缓存。
- `seed`：随应用提供的兜底数据。

指标级口径 `MetricBasis`：

- `observed`：来自 API 字段或本机历史实测。
- `estimated`：历史不足时生成的估算值。
- `seed`：种子数据自带的展示值。

二者不能混用：缓存中的真实指标仍然是 `observed`，只是响应新鲜度可能是 `freshCache` 或 `staleCache`。

## 6. 监控与告警闭环

1. 应用前台加载或刷新监控仓库。
2. 每个仓库每天保存一条 Star/Fork 观测。
3. 有足够历史时计算增长、停更和活跃下降；本次贡献者数据用于判断集中度。
4. 规则命中后生成稳定指纹并写入 SQLite，避免同一事件重复创建。
5. 用户在应用内完成已读、归档和恢复。

仓库规则仍以取得真实仓库数据为触发条件。AI 资讯另有桌面托盘常驻刷新：进程隐藏后每 15 分钟采集，新条目进入应用内提醒并尽力发本机通知；应用完全退出后不运行。跨设备系统推送由服务端 outbox 衔接 webhook 或外部 FCM/APNs/WNS 网关，只有部署者配置真实凭据后才会送达。

## 7. 本地数据与安全

- SQLite：远端缓存、FTS5 索引、LLM 增强、兴趣反馈、资讯提醒、仓库/主题每日快照、监控告警事件。
- SharedPreferences：收藏、关注、监控列表、规则、主题、语言和其他非敏感偏好。
- FlutterSecureStorage：GitHub Token、LLM Key、自托管服务 API Key；Windows 使用 DPAPI，macOS 使用 Keychain。
- Token 不进入日志、测试 fixture、导出报告或源码。
- OAuth Client ID 只通过 `GITHUB_OAUTH_CLIENT_ID` 构建配置注入；未配置构建不暴露失效登录入口。
- 配置导出使用非敏感白名单，导入先完整校验并在写入失败时回滚。
- 未配置自托管服务时所有用户内容都是设备本地状态；启用后仅白名单非敏感配置通过版本记录同步，敏感 Key 永不上传。
- 初始化失败不会触发自动删库；恢复界面只提供重试和打开数据目录。

## 8. 架构边界

- `core/` 提供配置、GitHub 协议、存储、数据可信度、跨功能领域接口和依赖组合。
- feature 的 presentation 不直接依赖 data 实现。
- 深度报告通过 `RepositoryFeed` 消费仓库摘要，不导入 trending 的 repository。
- API 路径、缓存 TTL 和 GitHub 头部集中管理，feature 不散落协议常量。
- 业务状态由 Riverpod notifier/provider 管理；页面级瞬时选择才使用 `setState`。
- `server/app/` 使用 FastAPI 路由 + 服务层 + 集中 SQLite schema；Bearer Key 和工作区头隔离访问，调度器、push outbox 和 GH Archive 解析均可独立测试。

## 9. 当前完成定义

本地优先客户端与可选服务边界在以下条件同时成立时才算闭环：

- 8/5 导航在对应窗口宽度下可达。
- 远端成功、缓存命中、过期降级和种子兜底均有明确口径。
- 真实观测能落库，规则能生成持久告警，处理状态可恢复。
- Token 使用系统安全存储。
- FTS5 迁移和触发器、源管理、增强缓存、聚类、兴趣排序与提醒状态有针对性测试。
- format、analyze、全量 test、Windows Release、可见主窗口烟测和关闭后托盘存活烟测全部通过。
- 服务端 Ruff、pytest、真实 Uvicorn 鉴权/源列表/同步往返，以及四个真实 RSS/Atom 源采集落库均已通过。Dockerfile 与 Compose 已提供且强制注入 Key；本次验证机器没有 Docker 命令，未把镜像构建误报为已执行。

`server/` 已实现定时 RSS/Atom 采集、版本化同步、成员/批注协作、可靠 push outbox、webhook 投递和 GH Archive 小时聚合。它是可部署实现，不代表仓库已经持有公网域名、TLS、云账号或移动推送生产凭据；FCM/APNs/WNS 必须由实际部署网关消费 outbox 并回执。
