# GitHub 情报站

面向开发者的 AI + GitHub 情报桌面应用。项目用 Flutter 构建，优先打磨桌面端工作台，同时保留手机端 4 Tab 信息架构规划。

## 界面预览

### AI 动态

![AI 动态](docs/screenshots/ScreenShot_2026-06-27_223118_515.png)

### GitHub 热榜

![GitHub 热榜](docs/screenshots/ScreenShot_2026-06-27_223128_041.png)

### 技术热点

![技术热点](docs/screenshots/ScreenShot_2026-06-27_223137_072.png)

### 仓库监控

![仓库监控](docs/screenshots/ScreenShot_2026-06-27_223145_699.png)

### 设置

![设置](docs/screenshots/ScreenShot_2026-06-27_223209_496.png)

## 当前能力

- 总览、AI 动态、GitHub热榜、AI雷达、仓库监控、深度报告、设置 7 个主入口。
- AI 动态接入远端资讯源，并使用本地缓存与分页。
- GitHub热榜支持本地数据与 GitHub Search 数据源切换，支持榜单类型、窗口、语言和本地搜索。
- AI雷达通过 GitHub Search 聚合 Agent、MCP、AI Coding、RAG、本地推理等主题信号。
- 仓库监控、仓库详情、深度报告接入 GitHub Repository / Search / Contributors API。
- 所有远端链路统一按本地缓存优先，默认 TTL 为 5 分钟；手动刷新只刷新当前查询缓存。
- 无服务端阶段使用 SharedPreferences 保存收藏、监控仓库、关注开发者、告警已读/归档、通知设置和 GitHub Token。
- 仓库 Star/Fork 与热点 heat 会写入本地快照；有跨天历史时优先使用本地观测趋势，不足时使用估算曲线兜底。

## 数据边界

当前不是纯静态 Demo，但也不是完全服务端化产品：

- 真实远端：AI 动态、GitHub Search、Repository、Contributors、Rate Limit。
- 本地缓存：AI 动态、GitHub热榜、AI雷达、监控、详情、报告聚合。
- 本地用户数据：收藏、关注、监控规则、通知、告警处理状态。
- 本地兜底：远端失败且无过期缓存时，部分页面会回退到种子数据，保证桌面端可用。
- 未接入服务端定时任务：跨用户同步、推送通知、GH Archive 全量事件趋势、账号云同步暂不支持。

## 技术栈

| 维度 | 选型 |
|---|---|
| 框架 | Flutter / Dart |
| 状态管理 | flutter_riverpod |
| 路由 | go_router |
| 网络 | dio |
| 本地存储 | shared_preferences、sqflite_common_ffi |
| 图表 | fl_chart |
| 图片 | cached_network_image |
| 测试 | flutter_test、mocktail |

## 运行

```bash
flutter pub get
flutter run -d windows
```

打包：

```bash
flutter build windows --release
```

提交前必须运行：

```bash
dart format .
flutter analyze
flutter test
```

## 文档

- 文档索引：[docs/README.md](docs/README.md)
- 产品信息架构与数据方案：[docs/plans/product_ia_data_plan.md](docs/plans/product_ia_data_plan.md)
- 项目规则：根目录 `AGENTS.md`

## 状态

桌面端主链路已进入可用收尾阶段。当前继续优先补齐桌面端交互闭环、真实数据口径说明、布局回归和文档同步；手机端仍按独立 4 Tab 方案规划，尚未作为本轮实现重点。
