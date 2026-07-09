# 启动指南

> 当前项目已能在本机执行 `flutter analyze` 与 `flutter test`。当前迭代只验证 Windows 桌面端主链路；手机端保持既有 4 Tab 规划，不作为本轮改动范围。

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

### 2.1 Release 打包(Windows)

发布构建使用 `--release`,并开启符号混淆与调试信息分离,降低逆向可读性:

```bash
flutter build windows --release \
  --obfuscate \
  --split-debug-info=build/symbols
```

要点:

- `--obfuscate` 会混淆 Dart 符号;`--split-debug-info=build/symbols` 把调试信息
  (用于解析崩溃栈)输出到指定目录。**该目录必须妥善保管**,丢失后无法解析线上崩溃栈。
- 产物在 `build/windows/x64/runner/Release/`,分发时需连同 `flutter_windows.dll`
  及数据目录整体打包。
- 版本号由 `pubspec.yaml` 的 `version: 0.1.0+1` 自动注入到 `Runner.rc` 的
  `VERSION_AS_NUMBER` / `VERSION_AS_STRING`(经 CMake 的 `FLUTTER_VERSION_*` 宏)，
  右键「属性 → 详细信息」可见。改版本只改 `pubspec.yaml`,无需手改 `Runner.rc`。
- 运行环境最低要求 **Windows 10**(已在 `runner.exe.manifest` 的 `supportedOS` 中
  仅声明 Win10/11 GUID;WebView2 控件依赖 Win10+ 预装的 Edge 运行时)。
- 混淆构建出现崩溃时,用 `flutter symbolize -i <stack-trace.txt> -d build/symbols`
  还原符号后再定位。

## 3. 桌面端启动(macOS)

macOS 桌面端必须在 Mac + Xcode 环境运行,Windows 不能模拟或构建 macOS
桌面目标。

```bash
flutter pub get
flutter run -d macos
```

打包验证:

```bash
flutter build macos --release
```

如果 AI 动态首屏显示网络失败,先验证接口与沙盒权限:

```bash
curl -I -A "GitHubNews/0.1 (Flutter)" "https://aihot.virxact.com/api/public/items?mode=selected"
```

`macos/Runner/*.entitlements` 必须包含
`com.apple.security.network.client`,否则 macOS App Sandbox 会阻止出站网络请求。

## 4. 其它平台(可选)

```bash
flutter run -d android   # 需连真机 / 模拟器
flutter run -d chrome     # 浏览器调试
```

## 5. 静态检查 + 测试

```bash
dart format .
flutter analyze
flutter test
```

## 6. 已知产品化待办

| 位置 | 风险 | 修法 |
|---|---|---|
| 本地 Repository | 除 `ai_news` 外仍以本地模拟数据为主 | 真实 API 阶段替换 Repository 实现 |
| `lib/core/storage/local_database.dart` | 当前负责 AI 动态缓存与通用 `cache_meta`; 其它 feature 尚未接入持久缓存 | 接入真实 API 时按 feature 补 DAO 与迁移 |
| `StarTrendChart` 中 `LineChartData.maxY` 用 `+50` 留白 | 极小数据集可能反序 | 真实接入时按数据动态算 |

## 7. 目录速览

```
lib/
├── main.dart, app.dart
├── core/                  # theme / errors / network / storage / di / router / utils / platform / demo_data
├── features/
│   ├── home/              # 总览(手机 + 桌面 + 指标 / 趋势 / 预览)
│   ├── ai_news/           # AI 动态(远端 API + 本地缓存 DAO + 响应式信息流)
│   ├── trending/          # 趋势 + 3 个二级页(总览 / 语言 / 热门仓库)
│   ├── discover/          # 发现页(流行仓库 / Agent Skills / 官方账号 / 知名人士)
│   ├── tech_hotspot/      # 技术趋势(本地 Repository + 响应式趋势面板)
│   ├── monitor/           # 监控 + 3 个二级页(详情 / 告警 / 设置)
│   ├── project/           # 报告 + 3 个二级页(探索 / 活动 / 发现)
│   ├── repo_detail/       # 仓库详情(手机 + 桌面)
│   └── profile/           # 设置 + 5 个二级页(收藏 / 关注 / 监控主题 / 监控规则 / 开发者选项) + 登录
└── shared/widgets/        # 通用 AppCard / MetricCard / SectionHeader / RepoTile / StarTrendChart / ResponsiveLayout / ResponsiveScaffold / ErrorView / EmptyView / Skeleton
```

## 8. 设计稿对应

- 手机一级页: `总览` / `AI 动态` / `GitHub热榜` / `技术趋势` / `仓库监控` / `深度报告` / `设置`。本轮桌面端收尾不调整手机端实现。
- 5 个手机二级页: `首页2级 (1) ~ (5).png`
- 5 个趋势页(已合并进 trending): `趋势页.png` + `趋势1 ~ 4.png`
- 4 个监控页(已合并进 monitor): `监控页.png`
- 桌面端: `桌面.png` (深色) + `桌面端白色.png` (浅色,默认主题)
