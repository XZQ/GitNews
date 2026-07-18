# Contributing to AI资讯

感谢你参与本项目！以下是开发环境搭建和工作流指南。

## 开发环境

### 前置要求

| 工具 | 最低版本 | 备注 |
|------|----------|------|
| Flutter SDK | 3.22.0 | 使用 `flutter --version` 确认 |
| Dart SDK | 3.4.0 | 随 Flutter 附带 |
| Windows | 10 (1903+) | 桌面端需 WebView2 运行时 |
| macOS | 12+ | 需 Xcode + CocoaPods |
| Python | 3.12+ | 仅开发 `server/` 时需要 |
| uv | 最新稳定版 | 服务端依赖、检查和测试入口 |
| Docker | 最新稳定版 | 可选，仅用于验证自托管镜像 |

### IDE 推荐

- **VS Code**：安装 Flutter 扩展 + Dart 扩展
- **Android Studio**：安装 Flutter 插件

### 搭建步骤

```bash
# 1. 克隆仓库
git clone <repo-url>
cd github_news

# 2. 安装依赖
flutter pub get

# 3. 生成代码（如有 build_runner）
# flutter pub run build_runner build --delete-conflicting-outputs

# 4. 运行（Windows）
flutter run -d windows

# 4. 运行（macOS）
flutter run -d macos
```

## 项目结构

```
lib/
├── app.dart                  # 应用根
├── main.dart                 # 入口
├── core/                     # 基础设施
│   ├── config/               # 配置（TTL、常量）
│   ├── di/                   # 依赖注入
│   ├── domain/               # 领域基础（DataFreshness、MetricBasis）
│   ├── errors/               # 异常体系
│   ├── github/               # GitHub 相关（rate limit gate）
│   ├── i18n/                 # 国际化
│   ├── network/              # 网络层（DioClient）
│   ├── platform/             # 平台判断
│   ├── preferences/          # 偏好存储
│   ├── router/               # 路由
│   ├── storage/              # 本地数据库
│   ├── theme/                # 主题 Token
│   └── utils/                # 工具
├── features/                 # 功能模块
│   ├── ai_news/              # AI 动态
│   ├── discover/             # 仓库、Skills、官方账号与人物发现
│   ├── home/                 # 首页
│   ├── monitor/              # 仓库监控
│   ├── project/              # 深度报告
│   ├── repo_detail/          # 仓库详情
│   ├── tech_hotspot/         # 技术热点
│   ├── trending/             # GitHub 热榜
│   ├── profile/              # 个人中心与设置入口
│   ├── settings/             # 独立设置、资讯源与自托管服务页面
│   └── webview/              # 应用内浏览器
└── shared/                   # 共享组件
    └── widgets/
server/                       # 可选 FastAPI 自托管服务
├── app/                      # API、调度器和领域服务
├── tests/                    # 服务端测试
└── tools/                    # 真实进程烟测
```

### Feature 分层规则

每个 feature 遵循四层结构：

```
features/<feature>/
├── data/          # API client + DTO + cache DAO + remote repository
├── domain/        # entity + repository interface
├── application/   # providers + business logic
└── presentation/  # pages + widgets
```

**依赖方向**：`presentation → application → domain ← data`，不允许反向依赖。

## 开发规则

详见 [AGENTS.md](./AGENTS.md)，核心规则摘要：

1. **文件 < 300 行**：超出时拆分为子 widget / helper
2. **复用 theme token**：颜色用 `AppColors`、间距用 `AppSpacing`、圆角用 `AppRadius`、字号用 `AppTypography`，不写裸值
3. **每页四态**：loading（骨架屏）/ error（ErrorView）/ empty（EmptyView）/ data
4. **i18n**：UI 字符串使用 `l10n.tr('key')`，不硬编码中文
5. **异常处理**：Repository 边界转换为项目的 `AppException`，UI 用 `ErrorView` 渲染
6. **日志**：使用 `AppLogger`，不调用 `print()`
7. **测试**：mocktail + in-memory DB，新功能需附带测试

## 提交前检查

```bash
# 格式化
dart format .

# 静态分析
flutter analyze

# 测试
flutter test

# Windows 桌面影响改动
flutter build windows --release

# 托盘行为影响改动
powershell -ExecutionPolicy Bypass -File tools/windows_tray_smoke.ps1

# 文档改动
powershell -ExecutionPolicy Bypass -File tools/check_markdown_links.ps1
```

在 `AGENTS.md` 的命令基础上，服务端改动另运行：

```bash
cd server
uv sync --all-groups
uv run ruff format --check .
uv run ruff check .
uv run pytest
uv run python tools/live_smoke.py
# 需要联网：验证真实 RSS/Atom 拉取和落库。
uv run python tools/feed_live_smoke.py
```

## Git 工作流

1. 从 `main` 拉取最新代码
2. 创建分支：`feat/<feature-name>` 或 `fix/<bug-name>`
3. 提交前运行上述检查命令
4. 提交 PR，描述变更内容和测试结果

## 调试技巧

### Flutter DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### 查看数据库

```bash
# 数据库文件名为 github_news.db。
# 具体目录由 path_provider 决定，可在应用恢复页或数据管理入口打开。
sqlite3 github_news.db ".tables"
```

### 查看 SharedPreferences

```bash
# 具体位置由 shared_preferences 的平台实现管理，不应依赖硬编码路径。
```

### 查看 Secure Storage

- Windows: GitHub Token、LLM Key 和自托管服务 API Key 由 DPAPI 加密，无法直接查看
- macOS: 使用 Keychain Access 工具搜索 `github_personal_access_token`
