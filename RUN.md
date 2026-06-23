# 启动指南

> 由于沙箱内 `flutter pub get` 拉不到 pub 镜像,本环境的 `flutter run` 验证留到你本机执行。

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

## 5. 已知可能要修的小问题(analyzer 可能报)

| 位置 | 风险 | 修法 |
|---|---|---|
| `lib/core/utils/breakpoint.dart` 顶部 `unused_import` 警告 | 没用到 `package:flutter/widgets.dart` 之外的导入 | 删除多余 import |
| `app_theme.dart` 中 `appBarTheme.surfaceTintColor` 在 Flutter 3.22 之前不存在 | Flutter 3.44 OK,旧版要去掉 | 升级 Flutter |
| `StarTrendChart` 中 `LineChartData.maxY` 用 `+50` 留白,极小数据集可能反序 | 不影响 demo | 真实接入时按数据动态算 |
| 9 个文件里都定义私有 `extension _ColumnCopy on Column` | 不同 library 不冲突 | 如果要把多个 .dart merge 成 part file,需要改名 |

## 6. 目录速览

```
lib/
├── main.dart, app.dart
├── core/                  # theme / errors / network / storage / di / router / utils / platform / demo_data
├── features/
│   ├── home/              # 首页(手机 + 桌面 + Hero / QuickNav / Trending / Alerts / Topics)
│   ├── trending/          # 趋势 + 3 个二级页(总览 / 语言 / 热门仓库)
│   ├── monitor/           # 监控 + 3 个二级页(详情 / 告警 / 设置)
│   ├── project/           # 报告 + 3 个二级页(探索 / 活动 / 发现)
│   ├── repo_detail/       # 仓库详情(手机 + 桌面)
│   └── profile/           # 我的 + 5 个二级页(收藏 / 关注 / 监控主题 / 监控规则 / 开发者选项) + 登录
└── shared/widgets/        # 通用 AppCard / MetricCard / SectionHeader / RepoTile / StarTrendChart / ResponsiveLayout / ResponsiveScaffold / ErrorView / EmptyView / Skeleton
```

## 7. 设计稿对应

- 5 个手机一级页: `首页.png` / `趋势.png` / `监控.png` / `报告.png` / `我的.png`
- 5 个手机二级页: `首页2级 (1) ~ (5).png`
- 5 个趋势页(已合并进 trending): `趋势页.png` + `趋势1 ~ 4.png`
- 4 个监控页(已合并进 monitor): `监控页.png`
- 桌面端: `桌面.png` (深色) + `桌面端白色.png` (浅色,默认主题)
