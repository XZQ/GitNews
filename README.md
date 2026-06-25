# GitHub情报站 (GitHub Developer Intelligence)

一款基于 Flutter 的 GitHub 仓库趋势分析与监控告警桌面应用,
用响应式三档布局与 Material 3 主题,为你盯住每一个值得关注的仓库。

[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Android%20%7C%20iOS-0a84ff)](#支持平台)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A5%203.22-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%E2%89%A5%203.4-0175C2)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](#许可证)

---

## ✨ 功能特性

- **趋势榜 / 增长榜 / 健康榜 / 收藏趋势榜** 四个 Tab 联动
- **Star 增长趋势图** 7 / 14 / 30 天可切换,本周与上周对比
- **语言分布** 按全部 / AI / Web / 系统分类筛选,交互式柱状图
- **响应式三档布局**:Compact(< 600dp)底部导航、Medium(600–1024dp)紧凑侧栏、Expanded(≥ 1024dp)宽侧栏
- **浅色 / 深色主题** + 品牌 Logo 自绘,无外部资源依赖

## 🖼️ 预览

### 桌面端

![桌面端深色主题](https://raw.githubusercontent.com/XZQ/GitNews/main/docs/desktop-dark.png)

### 移动端

| 首页 | 报告 | 监控列表 | 监控详情 | 我的 |
| :---: | :---: | :---: | :---: | :---: |
| <img src="https://raw.githubusercontent.com/XZQ/GitNews/main/docs/mobile-home.png" width="160"> | <img src="https://raw.githubusercontent.com/XZQ/GitNews/main/docs/mobile-report.png" width="160"> | <img src="https://raw.githubusercontent.com/XZQ/GitNews/main/docs/mobile-monitor-list.png" width="160"> | <img src="https://raw.githubusercontent.com/XZQ/GitNews/main/docs/mobile-monitor-detail.png" width="160"> | <img src="https://raw.githubusercontent.com/XZQ/GitNews/main/docs/mobile-profile.png" width="160"> |

> 截图位于 `docs/`。

## 🛠️ 技术栈

| 维度 | 选型 |
|---|---|
| 框架 | Flutter ≥ 3.22(Dart ≥ 3.4) |
| 状态管理 | `flutter_riverpod` |
| 路由 | `go_router`(`StatefulShellRoute.indexedStack`) |
| HTTP | `dio` + 拦截器(超时 / 重试 / 限流) |
| 存储 | `shared_preferences`(键值)+ `drift`(数据库) |
| 图表 | `fl_chart` |
| 图片 | `cached_network_image` |
| 测试 | `flutter_test` + `mocktail` |

## 🧭 5 个 Tab

| Tab | 路径 | 职责 |
|---|---|---|
| `home` | `/home` | 概览仪表盘 |
| `trending` | `/trending` | GitHub 仓库趋势列表 |
| `monitor` | `/monitor` | 监控规则与告警 |
| `project` | `/project` | 收藏 / 监控仓库集合 |
| `profile` | `/profile` | 主题与偏好设置 |

## 📦 支持平台

Windows / macOS / Linux / Android / iOS(桌面端为优先开发目标)。

## 🚀 快速开始

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 开发
flutter run -d windows

# 打包
flutter build windows --release
flutter build apk --release
```

提交前请运行:

```bash
dart format .
flutter analyze
flutter test
```

## 🤝 贡献

代码规范见 [CLAUDE.md](./CLAUDE.md),
Commit 信息遵循 Conventional Commits:`<type>(<scope>): <subject>`。

## 📄 许可证

[MIT](./LICENSE)