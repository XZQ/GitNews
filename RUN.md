# 启动指南

> 当前项目已能在本机执行 `flutter analyze` 与 `flutter test`。桌面运行以 Windows 为优先目标。

## 1. 拉依赖

```bash
cd D:\workspace\github_news
flutter pub get
```

## 2. 桌面端启动(Windows)

```bash
flutter run -d windows
```

如果首次启用 Windows 桌面平台,需要先:

```bash
flutter create --platforms=windows .
```

## 3. 其它平台(可选)

```bash
flutter run -d android   # 需连真机 / 模拟器
flutter run -d chrome     # 浏览器调试
```

## 4. 静态检查 + 测试

```bash
dart format .
flutter analyze
flutter test
```

## 5. 已知产品化待办

| 位置 | 风险 | 修法 |
|---|---|---|
| 本地 Repository | 除 `ai_news` 外仍以本地模拟数据为主 | 真实 API 阶段替换 Repository 实现 |
| `lib/core/storage/local_database.dart` | 当前负责 AI 动态缓存与通用 `cache_meta`; 其它 feature 尚未接入持久缓存 | 接入真实 API 时按 feature 补 DAO 与迁移 |
| `StarTrendChart` 中 `LineChartData.maxY` 用 `+50` 留白 | 极小数据集可能反序 | 真实接入时按数据动态算 |

## 6. 目录速览

```
lib/
├── main.dart, app.dart
├── core/                  # theme / errors / network / storage / di / router / utils / platform / demo_data
├── features/
│   ├── home/              # 总览(手机 + 桌面 + 指标 / 趋势 / 预览)
│   ├── ai_news/           # AI 动态(远端 API + 本地缓存 DAO + 响应式信息流)
│   ├── trending/          # 趋势 + 3 个二级页(总览 / 语言 / 热门仓库)
│   ├── tech_hotspot/      # 技术趋势(本地 Repository + 响应式趋势面板)
│   ├── monitor/           # 监控 + 3 个二级页(详情 / 告警 / 设置)
│   ├── project/           # 报告 + 3 个二级页(探索 / 活动 / 发现)
│   ├── repo_detail/       # 仓库详情(手机 + 桌面)
│   └── profile/           # 设置 + 5 个二级页(收藏 / 关注 / 监控主题 / 监控规则 / 开发者选项) + 登录
└── shared/widgets/        # 通用 AppCard / MetricCard / SectionHeader / RepoTile / StarTrendChart / ResponsiveLayout / ResponsiveScaffold / ErrorView / EmptyView / Skeleton
```

## 7. 设计稿对应

- 手机一级页: `总览` / `AI 动态` / `GitHub热榜` / `技术趋势` / `仓库监控` / `深度报告` / `设置`
- 5 个手机二级页: `首页2级 (1) ~ (5).png`
- 5 个趋势页(已合并进 trending): `趋势页.png` + `趋势1 ~ 4.png`
- 4 个监控页(已合并进 monitor): `监控页.png`
- 桌面端: `桌面.png` (深色) + `桌面端白色.png` (浅色,默认主题)
