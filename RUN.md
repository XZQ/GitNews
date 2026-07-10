# 启动与发布指南

当前版本为 `1.2.0+2`。Windows 桌面端是发布验证目标；紧凑窗口和移动端已使用 4 Tab 导航，但本轮发布只要求 Windows Release 构建通过。

## 1. 环境检查

```bash
flutter doctor -v
flutter pub get
```

若仓库缺少 Windows 平台目录，再执行：

```bash
flutter create --platforms=windows .
```

## 2. Windows 启动

```bash
flutter run -d windows
```

应用可匿名访问 GitHub API；稳定使用建议在“设置 → 开发者选项”配置 Personal Access Token。Token 只存入系统安全存储，不写入仓库、日志或 SharedPreferences。

## 3. 质量检查

```bash
dart format .
flutter analyze
flutter test
```

在 Codex 环境中使用：

```bash
rtk dart format .
rtk flutter analyze
rtk flutter test
```

## 4. Windows Release 构建

标准验证构建：

```bash
flutter build windows --release
```

发布时如需混淆并保留符号文件：

```bash
flutter build windows --release --obfuscate --split-debug-info=build/symbols
```

- 产物目录：`build/windows/x64/runner/Release/`。分发时必须连同 DLL 和 `data/` 目录整体打包。
- `build/symbols/` 用于还原混淆后的崩溃栈，必须与发布版本对应保存。
- 版本来自 `pubspec.yaml`，无需手改 `windows/runner/Runner.rc`。
- Windows Runner 声明支持 Windows 10/11。

## 5. 其他平台

macOS 必须在安装 Xcode 的 Mac 上构建：

```bash
flutter run -d macos
flutter build macos --release
```

Android 或 Web 可用于交互调试，但不属于当前发布门禁：

```bash
flutter run -d android
flutter run -d chrome
```

## 6. 运行时数据行为

- 先读新鲜本地缓存；缓存缺失、过期或用户手动刷新时才请求远端。
- 远端失败时优先回退过期缓存；无缓存时部分列表使用种子数据。
- GitHub 单资源请求使用 ETag；服务端返回 `304` 时复用本地实体并刷新缓存时间。
- 监控仓库只在应用前台加载或刷新时产生每日观测并计算规则，没有后台常驻任务。
- 告警、观测、快照和偏好都保存在本机；清除应用数据会同时清除这些历史。

## 7. 目录速览

```text
lib/
├── core/                    # 配置、网络、GitHub 协议、存储、领域边界、DI、路由、主题
├── features/
│   ├── home/                # 今日总览
│   ├── ai_news/             # AI 资讯与缓存
│   ├── trending/            # GitHub 热榜与 RepositoryFeed 适配
│   ├── tech_hotspot/        # AI 主题雷达
│   ├── discover/            # 仓库、Skills、官方账号、人物发现
│   ├── monitor/             # 观测、规则、告警与设置
│   ├── project/             # 仓库与贡献者报告
│   ├── repo_detail/         # 仓库详情
│   └── profile/             # 本地内容、主题、Token 与数据管理
└── shared/widgets/          # 跨功能展示组件
```

## 8. 明确边界

当前客户端不具备服务端定时采集、系统通知推送、跨设备同步、多人协作或全量 GH Archive 事件分析。需要这些能力时，应新增经过鉴权和运维设计的服务端，而不是在 Flutter 客户端中用文案模拟。
