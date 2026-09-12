# AI资讯

面向开发者的 AI + GitHub 本地优先情报工作台。项目使用 Flutter 构建，优先支持 Windows 桌面端；紧凑窗口和移动端使用独立的 5 Tab 导航。

## 界面预览

当前 Windows Release 构建的 AI 动态页面（2026-07-31，1440 × 900）：

![当前 AI 动态页面](docs/ui_design/desktop_ai_news_current.png)

以下截图采集于 2026-06-27，保留为早期桌面版视觉记录；当前品牌、导航和部分页面布局已经演进，能力判断以“当前能力”和实际代码为准。

| AI 动态 | GitHub 热榜 | AI 雷达 |
|---|---|---|
| ![AI 动态](docs/screenshots/ScreenShot_2026-06-27_223118_515.png) | ![GitHub 热榜](docs/screenshots/ScreenShot_2026-06-27_223128_041.png) | ![AI 雷达](docs/screenshots/ScreenShot_2026-06-27_223137_072.png) |

| 仓库监控 | 设置 |
|---|---|
| ![仓库监控](docs/screenshots/ScreenShot_2026-06-27_223145_699.png) | ![设置](docs/screenshots/ScreenShot_2026-06-27_223209_496.png) |

## 当前能力

- 桌面端 8 个主入口：总览、AI 动态、GitHub 热榜、AI 雷达、发现、仓库监控、深度报告、设置。
- 紧凑窗口和移动端 5 个主入口：总览、AI、发现、监控、我的；总览顶部先展示 AI HOT 当前热点，再承接 GitHub 热榜和 AI 雷达的 8 个内容区块，共 9 块重点情报；两个完整页面继续作为二级页面保留。
- AI 动态默认接入 AI HOT 精选 REST + RSS：总览当前热点、AI 时间流、官方日报及历史日报无需 Key；GitHub 热榜、AI 雷达、发现、监控、详情和报告接入 GitHub Search / Repository / Contributors / Events / Rate Limit API。
- 所有远端响应统一标记为在线数据、过期缓存或种子数据；有效缓存保持安静，不额外占用界面；趋势和指标另行标记真实观测、估算或种子口径。
- 仓库监控在应用前台加载或刷新时记录每日 Star/Fork 观测，计算增长、停更、活跃下降和贡献者集中度规则，并把命中事件持久化到本机告警中心。
- 告警支持已读、归档和恢复；收藏、监控仓库、关注开发者均保存真实实体快照，规则、主题和通知设置也在本机闭环。
- 仓库详情和深度报告展示 GitHub Events API 的真实活动；失败时只回退对应缓存，不生成看似真实的样例事件。
- 深度报告基于仓库、贡献者和活动数据生成本地聚合，并支持按当前语言导出 Markdown。
- GitHub 单资源请求支持 ETag 条件缓存；远端失败时优先使用过期缓存，最后才使用种子数据。
- AI 资讯支持设置页源管理、连续失败健康状态、英文 FTS5 与中文词内检索、可连续分页的本地搜索、来源/时间/已读过滤、多源事件聚类、本地兴趣排序，以及通过发布方代理生成的逐条摘要、翻译、重要性评分和实体缓存。模型密钥只在服务端；最终用户登录应用账号即可使用已配置的生成服务，无需填写模型 Key。代理未配置或生成失败时隐藏新的 AI 内容，已有缓存可离线阅读。REST 与 RSS 按 AI HOT ID/permalink 去重，RSS 补充作者、分类、原文和可再分发正文。
- Windows 关闭窗口后可隐藏到系统托盘；进程常驻时每 30 分钟先比较 AI HOT 精选流指纹，仅在变化时拉取条目，新条目进入应用内提醒中心，并尽力发送本机系统通知。
- 资讯列表按需展开全部相关报道，分别标明报道篇数与去重后的来源数，逐篇进入应用内详情。归组只依据标题相似度，不代表交叉核验；来源热度不代表事实可信度。搜索仍保留每篇原始结果。
- 资讯详情支持连续选文与复制已收录正文（无正文时复制来源摘要），AI 内容按摘要、翻译和实体标注并完整显示；重要性估计不代表可信度。相关仓库可在应用内打开，复用现有订阅监控功能并返回原文章。
- 可选的 `server/` 自托管服务提供定时采集、版本化跨设备配置同步、工作区成员与共享批注、可靠推送 outbox/webhook 衔接和 GH Archive 小时数据聚合。客户端不连接服务端时仍保持完整本地可用性。

## 缓存与数据边界

| 数据 | 缓存有效期 |
|---|---:|
| AI HOT 时间流/当前热点、GitHub 热榜、AI 雷达 | 5 分钟 |
| AI HOT 官方日报、精选 RSS、轮询指纹 | 30 分钟 |
| AI HOT API 版本 | 24 小时 |
| 仓库监控 | 10 分钟 |
| 仓库详情、深度报告 | 30 分钟 |
| 发现 | 6 小时 |
| Agent Skills 排行 | 24 小时 |

- SQLite 保存远端快照、每日观测和告警事件；SharedPreferences 保存非敏感的本机偏好与内容状态。
- GitHub Token 使用 `flutter_secure_storage`，在 Windows 上由 DPAPI 保护；旧版明文 Token 会在首次读取时迁移并清理。
- GitHub OAuth 设备登录只在构建时提供 `GITHUB_OAUTH_CLIENT_ID` 后出现；未配置构建只展示 Personal Access Token 路径。
- 应用账号固定支持邮箱 OTP、Google OAuth 和 GitHub OAuth，不提供手机登录。正式安装包由发布方预置认证服务的公开连接信息，用户无需配置；应用会话和 PKCE 校验材料使用系统安全存储，与 GitHub API Token 相互独立。
- 配置导出仅包含受支持的非敏感偏好；导入先完整校验，写入失败会回滚，Token 永不进入配置文件。
- 本地数据库或偏好初始化失败时显示恢复页，可重试或打开数据目录，不会自动删除用户数据。
- Flutter 客户端仍以本机 SQLite/SharedPreferences 为事实源；自托管服务端是显式配置的可选增强，不参与客户端启动依赖。用户自托管 API Key、GitHub Token 和账号会话使用系统安全存储，不进入配置导出；发布方模型 Key 仅来自服务端环境变量，客户端会清理旧版存储项。
- 托盘刷新属于桌面进程常驻能力，不等于操作系统在应用完全退出后的后台任务；移动系统推送需要在服务端 outbox 后接入真实 FCM/APNs/WNS 凭据和网关。
- Star 趋势按 UTC 观测日期对齐同一批仓库，显示相对首个共同观测日的累计净变化（含负值）、实际日期和样本覆盖数；历史不足时显示积累状态。不会从累计 Star、搜索评分或种子数据合成增长曲线。
- 总览栏目卡按窗口宽度和字号换行；数量描述已加载资讯、主题或仓库样本，加载失败不显示为零。资讯评分和不同主题的百分比不相加，Star 净变化说明实际日期与样本覆盖数。

## 技术栈

| 维度 | 选型 |
|---|---|
| 框架 | Flutter / Dart |
| 状态管理 | flutter_riverpod |
| 路由 | go_router |
| 网络 | dio |
| 本地存储与认证 | shared_preferences、sqflite_common_ffi、flutter_secure_storage、supabase_flutter |
| 桌面集成 | tray_manager、window_manager、local_notifier |
| 可选服务端 | FastAPI、SQLite、httpx、Uvicorn、Docker Compose |
| 图表 | fl_chart |
| 图片 | cached_network_image |
| 测试 | flutter_test、mocktail |

## 运行与验证

```bash
flutter pub get
flutter run -d windows
```

统一 Harness 可以列出、检查并执行仓库门禁：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -List
powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Suite quick
powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Suite desktop
```

`quick` 用于日常格式、可移植性和静态分析反馈，`flutter` 增加全量格式与测试，
`desktop` 再增加 Windows Release 构建与主窗口/托盘烟测。服务端使用
`-Suite server`，Windows
发布前的全工程门禁使用 `-Suite all`。每次运行的摘要和逐步日志保存在忽略的
`build/harness/`，详细说明见 [Agent Harness](docs/harness/README.md)。

等价的底层命令为：

```bash
dart format lib test
flutter analyze
flutter test
flutter build windows --release
powershell -NoProfile -ExecutionPolicy Bypass -File tools/windows_tray_smoke.ps1
```

服务端验证在 `server/` 下运行 `uv run ruff check .`、`uv run pytest` 和 `uv run python tools/live_smoke.py`，部署说明见 [server/README.md](server/README.md)。

更完整的环境和发布说明见 [RUN.md](RUN.md)。

## 文档

- [产品信息架构与数据方案](docs/plans/product_ia_data_plan.md)
- [文档索引](docs/README.md)
- [运行指南](RUN.md)
- [变更记录](CHANGELOG.md)
- [项目规则](AGENTS.md)
- [Agent Harness](docs/harness/README.md)
- [自托管服务端](server/README.md)

## 当前状态

当前开发基线为 `1.6.0+6`。阶段一的多源聚合、资讯库和资讯↔GitHub 已经扩展到阶段二客户端能力：独立 Settings、源管理、逐条 AI 增强、事件聚类、FTS5、兴趣反馈、托盘与提醒均已落地。`server/` 以可选、自托管方式实现定时采集、同步、协作、推送衔接、GH Archive 分析和有账号鉴权/额度限制的 Agnes 代理；代理与外部移动推送仍需部署者配置真实平台服务，仓库内本地验证不代表已上线。
