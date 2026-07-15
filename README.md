# GitHub 情报站

面向开发者的 AI + GitHub 本地优先情报工作台。项目使用 Flutter 构建，优先支持 Windows 桌面端；紧凑窗口和移动端使用独立的 4 Tab 导航。

## 界面预览

| AI 动态 | GitHub 热榜 | AI 雷达 |
|---|---|---|
| ![AI 动态](docs/screenshots/ScreenShot_2026-06-27_223118_515.png) | ![GitHub 热榜](docs/screenshots/ScreenShot_2026-06-27_223128_041.png) | ![AI 雷达](docs/screenshots/ScreenShot_2026-06-27_223137_072.png) |

| 仓库监控 | 设置 |
|---|---|
| ![仓库监控](docs/screenshots/ScreenShot_2026-06-27_223145_699.png) | ![设置](docs/screenshots/ScreenShot_2026-06-27_223209_496.png) |

## 当前能力

- 桌面端 8 个主入口：总览、AI 动态、GitHub 热榜、AI 雷达、发现、仓库监控、深度报告、设置。
- 紧凑窗口和移动端 4 个主入口：今日、AI、项目、设置；项目入口承接热榜、雷达、发现、监控和报告的详情路由。
- AI 动态接入远端资讯源；GitHub 热榜、AI 雷达、发现、监控、详情和报告接入 GitHub Search / Repository / Contributors / Events / Rate Limit API。
- 所有远端响应统一标记为在线数据、新鲜缓存、过期缓存或种子数据；趋势和指标另行标记真实观测、估算或种子口径。
- 仓库监控在应用前台加载或刷新时记录每日 Star/Fork 观测，计算增长、停更、活跃下降和贡献者集中度规则，并把命中事件持久化到本机告警中心。
- 告警支持已读、归档和恢复；收藏、监控仓库、关注开发者均保存真实实体快照，规则、主题和通知设置也在本机闭环。
- 仓库详情和深度报告展示 GitHub Events API 的真实活动；失败时只回退对应缓存，不生成看似真实的样例事件。
- 深度报告基于仓库、贡献者和活动数据生成本地聚合，并支持按当前语言导出 Markdown。
- GitHub 单资源请求支持 ETag 条件缓存；远端失败时优先使用过期缓存，最后才使用种子数据。

## 缓存与数据边界

| 数据 | 新鲜缓存时效 |
|---|---:|
| AI 动态、GitHub 热榜、AI 雷达 | 5 分钟 |
| 仓库监控 | 10 分钟 |
| 仓库详情、深度报告 | 30 分钟 |
| 发现 | 6 小时 |
| Agent Skills 排行 | 24 小时 |

- SQLite 保存远端快照、每日观测和告警事件；SharedPreferences 保存非敏感的本机偏好与内容状态。
- GitHub Token 使用 `flutter_secure_storage`，在 Windows 上由 DPAPI 保护；旧版明文 Token 会在首次读取时迁移并清理。
- GitHub OAuth 设备登录只在构建时提供 `GITHUB_OAUTH_CLIENT_ID` 后出现；未配置构建只展示 Personal Access Token 路径。
- 配置导出仅包含受支持的非敏感偏好；导入先完整校验，写入失败会回滚，Token 永不进入配置文件。
- 本地数据库或偏好初始化失败时显示恢复页，可重试或打开数据目录，不会自动删除用户数据。
- 当前没有服务端、后台定时任务、云同步或系统推送。监控规则只在应用运行并取得数据时计算，通知仅指应用内告警中心。
- 跨天趋势依赖本机积累的真实观测；历史不足时会明确显示估算口径。

## 技术栈

| 维度 | 选型 |
|---|---|
| 框架 | Flutter / Dart |
| 状态管理 | flutter_riverpod |
| 路由 | go_router |
| 网络 | dio |
| 本地存储 | shared_preferences、sqflite_common_ffi、flutter_secure_storage |
| 图表 | fl_chart |
| 图片 | cached_network_image |
| 测试 | flutter_test、mocktail |

## 运行与验证

```bash
flutter pub get
flutter run -d windows
```

提交或发布前运行：

```bash
dart format .
flutter analyze
flutter test
flutter build windows --release
```

Codex 环境中的命令需加 `rtk` 前缀。更完整的环境和发布说明见 [RUN.md](RUN.md)。

## 文档

- [产品信息架构与数据方案](docs/plans/product_ia_data_plan.md)
- [文档索引](docs/README.md)
- [运行指南](RUN.md)
- [变更记录](CHANGELOG.md)
- [项目规则](AGENTS.md)

## 当前状态

`1.4.0+4` 在上一版可信本地闭环基础上补齐 AI 资讯阶段一(多源聚合、资讯库、资讯↔GitHub 打通、LLM 日报)与配套技术债务清偿:发现页大文件按 300 行约束拆分、6 个移动/监控/项目页接入 i18n、SQLite v1→v5 迁移链往返测试、告警列表与搜索框的渲染优化、loadMore 异常落地为 AsyncError。AI 资讯阶段二(源管理 UI、LLM 增强、事件聚类、FTS5、兴趣反馈、托盘常驻)与独立 `lib/features/settings/` feature 模块保留为后续路线,不在本版范围内。服务端定时采集、系统推送和跨设备同步属于下一阶段的新系统边界,不在当前客户端能力中伪装实现。
