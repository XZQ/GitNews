# AI资讯启动与发布指南

当前开发基线为 `1.5.0+5` 加 `Unreleased` 改动。Windows 桌面端是发布验证目标；紧凑窗口和移动端使用总览、AI、发现、监控、我的 5 Tab 导航。提交或发布前必须通过格式化、静态分析和全量测试；桌面影响改动还必须通过 Windows Release 构建和真实启动烟测。

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

应用账号固定提供邮箱验证码、Google 和 GitHub 三种登录方式，不提供手机登录。正式安装包必须由发布方预置认证服务连接信息，用户不参与配置；下面的参数只用于仓库开发和发布流水线。`SUPABASE_PUBLISHABLE_KEY` 是可随客户端分发的公开 key，不要使用 service role key：

```bash
flutter run -d windows --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=your_publishable_key --dart-define=AUTH_REDIRECT_URL=github-news://auth-callback/
```

发布前必须在 Supabase 配置邮箱 OTP 投递，并为 Google、GitHub 完成 OAuth App、provider 和 `AUTH_REDIRECT_URL` 对应的平台回调注册。三种方式随正式账号服务一起启用，不再使用单独的 `AUTH_*_ENABLED` 构建开关。认证 refresh token 与 PKCE verifier 使用系统安全存储，不写入 SharedPreferences，也不与 GitHub API Token 混用。

GitHub OAuth 设备登录默认关闭。只有在拥有 OAuth App Client ID 时才在构建命令加入：

```bash
flutter build windows --release --dart-define=GITHUB_OAUTH_CLIENT_ID=your_client_id
```

没有该构建配置时，界面会明确引导到 Personal Access Token，不会尝试无效 OAuth 请求。

AI 页默认展示无需 Key 的 AI HOT 官方日报；总览顶部展示同样无需 Key 的当前热点。“我的 AI 日报”和最终用户模型配置入口均已移除。资讯详情只使用内置 Agnes `https://apihub.agnes-ai.com/v1` 与 `agnes-2.0-flash`：真实生成并解析成功才展示 AI 深度解读，未注入 Key、网络失败、鉴权失败或响应无效时整块隐藏。发布方通过忽略的 `env.json` 写入 `AI_ENRICHMENT_AGNES_API_KEY`，再使用 `--dart-define-from-file=env.json` 构建；不要把真实 Key 写入源码、文档、脚本或提交记录。

## 3. 质量检查

日常开发优先使用统一 Harness；它会保留结构化摘要与逐步日志：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Doctor -Suite quick
powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Suite quick
powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Suite flutter
```

需要直接定位单项问题时，等价底层命令仍可单独运行：

```bash
dart format .
flutter analyze
flutter test
```

## 4. Windows Release 构建

有真实桌面会话时，标准发布验证使用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Suite desktop
```

无交互 CI 当前使用 `-Suite ci-windows`，对提交范围执行增量格式检查，并运行
analyzer、全量测试和 Release 构建。`-Suite windows-build` 仍代表包含全量
`lib/test` 格式检查的完整构建门禁；两者都不把无桌面会话表述成窗口或托盘已经
验证。对应底层命令为：

```bash
flutter build windows --release
powershell -NoProfile -ExecutionPolicy Bypass -File tools/windows_release_smoke.ps1 -ReleaseDir build/windows/x64/runner/Release -TimeoutSeconds 15
powershell -NoProfile -ExecutionPolicy Bypass -File tools/windows_tray_smoke.ps1 -ReleaseDir build/windows/x64/runner/Release -StartupTimeoutSeconds 15
```

发布时如需混淆并保留符号文件：

```bash
flutter build windows --release --obfuscate --split-debug-info=build/symbols
```

- 产物目录：`build/windows/x64/runner/Release/`。分发时必须连同 DLL 和 `data/` 目录整体打包。
- `build/symbols/` 用于还原混淆后的崩溃栈，必须与发布版本对应保存。
- 版本来自 `pubspec.yaml`，无需手改 `windows/runner/Runner.rc`。
- Windows Runner 声明支持 Windows 10/11。
- 启动烟测检查完整产物结构、存活进程和可见主窗口；托盘烟测进一步发送窗口关闭请求，并确认进程仍存活后再清理测试进程。

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
- 仓库和报告活动来自 GitHub Events API；远端失败时只使用对应过期缓存或显示空态。
- 仓库监控规则仍在取得真实仓库数据时计算；AI 资讯在 Windows 进程隐藏到托盘后每 30 分钟比较 AI HOT 精选流指纹，仅在变化时读取条目并写入本地提醒中心。
- 告警、观测、快照和偏好都保存在本机；清除应用数据会同时清除这些历史。
- 启动初始化失败时应用保留现有数据并提供重试和打开数据目录；不会自动重建数据库。

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
│   ├── profile/             # 本地内容、主题、Token 与数据管理
│   └── settings/            # 源管理、自托管服务连接与同步
└── shared/widgets/          # 跨功能展示组件
server/                      # 可选 FastAPI 自托管服务、测试和容器部署
```

## 8. 可选自托管服务

完整服务端门禁可从仓库根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Suite server
```

需要单独定位时，在 `server/` 下运行：

```bash
cd server
uv sync --all-groups
uv run ruff check .
uv run ruff format --check .
uv run pytest
uv run python tools/live_smoke.py
# 可选联网烟测：至少一个真实 RSS/Atom 源成功并完成落库往返。
uv run python tools/feed_live_smoke.py
```

本地启动前设置 `GITHUB_NEWS_MASTER_KEY`，再运行 `uv run uvicorn app.main:app --host 127.0.0.1 --port 8080`。Docker Compose、鉴权头、持久卷和多副本调度约束见 [server/README.md](server/README.md)。客户端在“设置 → 自托管服务与同步”中保存地址、工作区、成员和 Key，可测试连接并上传/拉取非敏感配置。

## 9. 明确边界

客户端默认不依赖服务端，完全退出后也不会继续执行托盘轮询。`server/` 已提供定时采集、同步、协作、推送 outbox 和 GH Archive 分析，但仓库没有任何外部云账号或 FCM/APNs/WNS 生产凭据；部署者必须自行配置 TLS、强 Key、备份和推送网关，不能把本地烟测表述为已经公网部署。
