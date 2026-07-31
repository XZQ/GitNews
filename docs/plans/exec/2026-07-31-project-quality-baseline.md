# 恢复跨平台质量绿线并刷新工程基线

状态：Completed

本计划遵循 `.agent/PLANS.md`，执行期间必须保持内容与实际状态一致。

## Purpose / Big Picture

完成后，当前 `main` 应重新具备可重复的 Flutter、Windows 与服务端绿线：
Windows 测试不依赖机器预装 SQLite DLL，视觉测试不依赖固定系统字体或本机
Flutter SDK 路径，Dart 3.12 格式基线全部迁移。仓库不再包含误入的聊天截图，
macOS 工程文件没有重复对象定义，README、质量记分卡和当前 UI 截图与实际版本
一致。

## Progress

- [x] (2026-07-30 23:30Z) 复核当前代码、文档、Harness、CI 和失败证据。
- [x] (2026-07-30 23:30Z) 建立本 ExecPlan。
- [x] (2026-07-30 23:35Z) 恢复 sqlite3 默认原生资产打包，并将 AI 视觉测试
  切换到仓库内的 Noto Sans SC 测试字体子集；数据库与 7 项视觉测试通过。
- [x] (2026-07-30 23:40Z) 删除误入且包含聊天内容的截图，并将 macOS
  `Pods_Runner.framework` 文件引用从两份重复定义收敛为一份。
- [x] (2026-07-30 23:45Z) 使用 `dart format lib test` 迁移 291 个既有
  Dart 文件，并把无交互 Windows CI 升级为完整格式门禁。
- [x] (2026-07-31 00:13Z) 同步版本、质量记分卡与运行说明，启动真实 Windows
  Release 应用完成人工核验并刷新当前 UI 截图。
- [x] (2026-07-31 00:08Z) Harness `all` 运行
  `20260731T000255764Z-5220` 的 14 项 Flutter、Windows 桌面与服务端门禁全部通过。

## Surprises & Discoveries

- Observation: 本机 `flutter test` 有 110 项失败，绝大多数来自
  `sqlite3.dll` 无法加载。
  Evidence: `pubspec.yaml` 把 sqlite3 hook 全局配置为 `source: system`；
  `.dart_tool/hooks_runner/sqlite3/*/input.json` 显示 Windows 目标被解析为
  `dynamic_loading_system`，没有 bundle 文件。
- Observation: 当前 GitHub Actions 的服务端任务通过，但 Windows Flutter
  任务有 5 项失败。
  Evidence: Harness run `30149608001` 中 4 项视觉测试找不到
  `C:/Windows/Fonts/NotoSansSC-VF.ttf`，另 1 项找不到
  `C:/Windows/Fonts/simhei.ttf`。
- Observation: 完整格式门禁的既有债务从文档记录的 299 个变为 291 个文件。
  Evidence: `dart format --output=none --set-exit-if-changed lib test` 报告
  `Formatted 477 files (291 changed)`。
- Observation: `docs/ui_design/desktop_home_top2.png` 是与产品无关的聊天截图，
  但已被 Git 跟踪。
  Evidence: 图片人工检查与 `git ls-files`。
- Observation: macOS Xcode 工程连续定义了两次同一个
  `PBXFileReference` UUID。
  Evidence: `macos/Runner.xcodeproj/project.pbxproj` 第 84、85 行。
- Observation: 视觉测试除中文字体外还依赖 Material Icons；仅替换中文字体时，
  移动端 golden 仍会因图标缺失产生像素差异。
  Evidence: `build/unit_test_assets/FontManifest.json` 提供了可移植的
  `fonts/MaterialIcons-Regular.otf`，统一测试字体加载器同时注册该字体后，
  7 项目标视觉测试全部通过。
- Observation: 一次性格式迁移让增量格式检查需要处理 294 个路径，旧脚本把所有
  路径放进一次 Windows 命令，触发命令行长度上限。
  Evidence: 首轮 Harness `20260730T234813808Z-9540` 的第 3 步失败；脚本改为
  超过 80 个文件或 7000 个参数字符时执行一次完整 `lib/test` 检查后，复跑通过。
- Observation: 当前 Windows 版本不支持 Computer Use 截图接口请求的窗口边框
  能力，但可访问性树和输入接口可正常读取真实应用。
  Evidence: `get_window_state` 的窗口捕获返回 `0x80004002`；使用相同唯一窗口的
  Win32 前台客户区抓取后，人工检查 1440 × 900 Release 界面无溢出或乱码。

## Decision Log

- Decision: 保留 sqlite3 默认下载/打包行为，不在跨平台根配置中强制使用系统库；
  macOS 系统库诉求使用平台限定配置或由包的默认 hook 处理。
  Rationale: Windows 测试和干净构建必须自带可解析的原生资产，不能依赖机器 PATH
  中偶然存在 `sqlite3.dll`。
  Date: 2026-07-31
- Decision: 视觉测试使用仓库内稳定测试字体或 Flutter 测试字体加载能力，不读取
  `C:/Windows/Fonts` 或固定 `D:/flutter_sdk`。
  Rationale: CI runner、开发机和 SDK 安装目录都不稳定，测试基线必须由仓库控制。
  Date: 2026-07-31
- Decision: 测试字体 fixture 只包含视觉用例所需字形，并保留上游提交、许可证和
  SHA-256 记录；不把该字体加入产品运行时 assets。
  Rationale: 在保证 CI 像素稳定的同时，避免给发布包增加未使用的完整字体及体积。
  Date: 2026-07-31
- Decision: 格式基线单独作为机械里程碑执行，不在格式化时夹带行为修改。
  Rationale: 291 文件的机械差异需要与功能修复区分审查，并在格式后重新运行全量测试。
  Date: 2026-07-31
- Decision: 基线迁移完成后，`ci-windows` 直接继承 `windows-build`，不再保留
  “只检查改动文件”的临时豁免；`quick` 仍保留增量格式检查以获得快速反馈。
  Rationale: 完整格式门禁已经可通过，CI 应机械阻止任何旧文件或新文件回退。
  Date: 2026-07-31

## Outcomes & Retrospective

目标已完成。Harness `all` 运行 `20260731T000255764Z-5220` 的 14 项检查全部
通过；当前真实桌面证据为 `docs/ui_design/desktop_ai_news_current.png`。SQLite
原生库与视觉测试字体不再依赖机器环境，Dart 3.12 格式债务归零，CI 已升级为
完整门禁，误入/重复截图和 Xcode 重复对象均已清理。

本机是 Windows，无法执行真实 macOS/Xcode Release 构建；macOS 工程只完成了
重复对象结构检查，并由新增的仓库可移植性步骤持续守护。外部推送、认证与联网
feed 的真实平台凭据验证不属于本轮工程基线修复，现有本地优先边界保持不变。

## Context and Orientation

Flutter 客户端位于 `lib/`，测试位于 `test/`；原生 SQLite 由
`sqflite_common_ffi` 和 `sqlite3` hook 提供。视觉测试集中在
`test/features/ai_news/presentation/`。Windows 发布验证由
`tools/harness.ps1 -Suite desktop` 编排，服务端位于 `server/`。
当前 UI 证据保存在 `docs/ui_design/`，其中只有真实产品截图可以继续保留。

## Plan of Work

第一个里程碑修复原生资产和字体加载，使全量 Flutter 测试在干净 Windows 环境
可执行。第二个里程碑清理隐私资产和 macOS 工程重复定义，并增加能够阻止回归的
轻量检查。第三个里程碑运行全量 Dart 格式迁移，同步 README、RUN、Harness
记分卡和变更记录。第四个里程碑执行 Flutter、Windows Release/烟测、服务端门禁，
最后启动真实桌面应用检查浅色主界面并更新当前截图。

## Concrete Steps

所有根命令从 `D:\workspace\github_news` 运行：

    dart format lib test
    dart format --output=none --set-exit-if-changed lib test
    flutter analyze
    flutter test
    powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Suite desktop
    powershell -NoProfile -ExecutionPolicy Bypass -File tools/harness.ps1 -Suite server
    git diff --check

macOS 工程在 Windows 上执行结构检查；真实 macOS Release 构建只能在安装 Xcode
的 Mac 上运行，若当前环境不可用必须明确记录为未执行。

## Validation and Acceptance

- `flutter test` 不再出现 `sqlite3.dll`、系统字体或固定 SDK 路径失败。
- `dart format --output=none --set-exit-if-changed lib test` 返回 0。
- `flutter analyze` 返回 0。
- Windows Release 构建、可见窗口烟测和托盘烟测通过。
- 服务端 Ruff、pytest 和 live smoke 通过。
- `git ls-files` 不再包含误入聊天截图。
- Xcode 工程同一 PBX 对象 UUID 不再重复定义。
- README、RUN、质量记分卡与 `pubspec.yaml` 的 `1.5.0+5` 基线一致。
- `docs/ui_design/` 中的“current”截图来自本次真实应用运行。

## Idempotence and Recovery

格式化、测试和 Harness 可以重复运行。删除的误入截图已在 Git 历史中存在，如需
恢复可从原提交取回，但当前树不应继续分发。macOS 工程只删除完全相同的重复定义，
其余对象保持不变。桌面截图使用新文件覆盖前先确认目标窗口是 AI资讯。

## Artifacts and Notes

Harness 证据写入忽略的 `build/harness/<run-id>/`。桌面当前截图保存在
`docs/ui_design/desktop_ai_news_current.png`。最终记录本次 quick、desktop、server
运行摘要和截图采集时间。

## Interfaces and Dependencies

不新增产品运行时接口。允许调整 `pubspec.yaml` 的 sqlite3 hook、视觉测试字体
fixture、Xcode 工程对象和文档资产。不得改变本地优先数据边界、账号/Token 语义、
桌面 8 入口或紧凑窗口 5 Tab 信息架构。
