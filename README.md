# GitHub情报站 (GitHub Developer Intelligence)

一款基于 Flutter 的 GitHub 仓库趋势分析与监控告警桌面应用,
用响应式三档布局与 Material 3 主题,为你盯住每一个值得关注的仓库。

[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Android%20%7C%20iOS-0a84ff)](#支持平台)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A5%203.22-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%E2%89%A5%203.4-0175C2)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](#许可证)

---

## ✨ 功能特性

- **总览 / AI 动态 / GitHub热榜 / AI雷达 / 仓库监控 / 深度报告 / 设置** 七个入口联动
- **Star 增长趋势图** 7 / 14 / 30 天可切换,本周与上周对比
- **语言分布** 按全部 / AI / Web / 系统分类筛选,交互式柱状图
- **响应式三档布局**:Compact(< 600dp)底部导航、Medium(600–1024dp)紧凑侧栏、Expanded(≥ 1024dp)宽侧栏
- **AI 动态远程接入**:`ai_news` 走真实远端 + 本地缓存 DAO(`sqflite_common_ffi`),其余特性暂以本地数据源占位,Repository 边界已就绪,后续可平替为真实 API
- **浅色 / 深色主题** + 品牌 Logo 自绘,无外部资源依赖

## 🖼️ 预览

### 桌面端

| AI 动态 | 概览仪表盘 | 开发者情报 |
| :---: | :---: | :---: |
| <img src="https://raw.githubusercontent.com/XZQ/GitNews/main/docs/ScreenShot_2026-06-27_223118_515.png" width="320"> | <img src="https://raw.githubusercontent.com/XZQ/GitNews/main/docs/ScreenShot_2026-06-27_223128_041.png" width="320"> | <img src="https://raw.githubusercontent.com/XZQ/GitNews/main/docs/ScreenShot_2026-06-27_223137_072.png" width="320"> |

| 仓库监控 | 趋势榜 |
| :---: | :---: |
| <img src="https://raw.githubusercontent.com/XZQ/GitNews/main/docs/ScreenShot_2026-06-27_223145_699.png" width="320"> | <img src="https://raw.githubusercontent.com/XZQ/GitNews/main/docs/ScreenShot_2026-06-27_223209_496.png" width="320"> |

> 截图位于 `docs/`。

## 🛠️ 技术栈

| 维度 | 选型 |
|---|---|
| 框架 | Flutter ≥ 3.22(Dart ≥ 3.4) |
| 状态管理 | `flutter_riverpod` |
| 路由 | `go_router`(`StatefulShellRoute.indexedStack`) |
| HTTP | `dio` + 拦截器(超时 / 重试 / 限流) |
| 存储 | `shared_preferences`(键值) + `sqflite_common_ffi` / `sqlite3_flutter_libs`(本地缓存 DAO) |
| 图表 | `fl_chart` |
| 图片 | `cached_network_image` |
| 测试 | `flutter_test` + `mocktail` |

## 🧭 7 个入口

| 入口 | 路径 | 职责 |
|---|---|---|
| 总览 | `/home` | 概览仪表盘 |
| AI 动态 | `/ai_news` | AI 情报流 |
| GitHub热榜 | `/trending` | GitHub 仓库趋势列表 |
| AI雷达 | `/tech_hotspot` | Agent、MCP 与 AI Coding 趋势雷达 |
| 仓库监控 | `/monitor` | 监控规则与告警 |
| 深度报告 | `/project` | 深度报告 / 仓库集合 |
| 设置 | `/profile` | 主题与偏好设置 |

产品信息架构、桌面端/手机端分工和数据源规划见
[docs/product_ia_data_plan.md](docs/product_ia_data_plan.md)。

## 📦 支持平台

Windows / macOS / Linux / Android / iOS(桌面端为优先开发目标)。

## 🚀 快速开始

```bash
flutter pub get

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
