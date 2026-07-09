# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- 发现页官方账号/知名人士点击行为改为进入代表仓库详情页，保持在桌面端应用壳 B 区域内，不再打开全屏 WebView。
- 发现页文档同步为 4 个分段：流行仓库、Agent Skills、官方账号、知名人士；手机端仍保持既有规划不变。
- 发现页 4 个分段切换和列表改为接近 AI 动态的信息流样式，仓库、Skills、官方账号、知名人士均使用卡片式列表。

### Fixed
- AI 动态触底加载在远端返回 `hasNext=true` 但缺少 `nextCursor` 时不再无限显示底部 loading。

### Security
- **BREAKING**: GitHub Token 存储从 SharedPreferences 明文迁移至 `flutter_secure_storage`（Windows DPAPI / macOS Keychain 加密存储）
- 首次启动自动迁移旧版明文 Token 至安全存储，迁移后清除 SharedPreferences 中的旧记录
- WebView URL scheme 校验已实现（`_isHttpScheme`，拒绝 `javascript:` / `file:` / `blob:` / `data:`，CWE-939）

### i18n
- `github_token_card.dart` 全部硬编码中文迁移至 i18n key（`profile.token.*`）
- `home_chart_helpers.dart` 图表标题/副标题/图例标签迁移至 i18n key（`home.chart.*`、`home.tab.*`）
- `home_section_entry_row.dart` 5 个入口卡标签和 KPI 后缀迁移至 i18n key（`home.entry.*`）
- 新增 `strings_en_us.dart` 对应英文翻译

### Accessibility
- `HomeSectionEntryRow` 入口卡添加 `Semantics` 标签（label + button: true）
- `InkWell` 添加 `focusColor` 使键盘焦点可见

### Visual
- `_StatusPill` 深色模式颜色修复：inactive 状态按 `brightness` 切换 `textMutedLight` / `textMutedDark`
- `demo_data.dart` 20+ 处硬编码语言颜色值改为引用 `AppColors.langXxxValue` token
- `github_token_card.dart` 中 `BorderRadius.circular(999)` 改为 `AppRadius.pill`

### Architecture
- `AppColors` 新增 `static const int` ARGB 值常量（`langXxxValue`），供 fixture / JSON 序列化引用
- `HomeLegacyTab` enum 的 `label` 从字段改为方法 `label(AppLocalizations l10n)`，支持 i18n

## [0.1.0+1] - 2026-06-27

### Added
- 初始版本发布
- 7 个主入口：首页 / AI动态 / GitHub热榜 / 技术热点 / 仓库监控 / 深度报告 / 设置
- Feature-first 架构：`lib/core/` + `lib/features/<feature>/{data,domain,application,presentation}` + `lib/shared/widgets/`
- 三级数据降级：真实远端 → 本地缓存(TTL 5/10/30min) → 种子数据兜底
- 三档响应式布局：compact(<600) / medium(600-1024) / expanded(≥1024)
- 可拖拽侧栏（200-800px，持久化）
- 全局快捷键 Ctrl/Cmd+1~7 切换 Tab
- 全局搜索智能分发
- 10 种主题色预设 + 浅深双模
- GitHub API Rate Limit 全局熔断
- SQLite FFI 本地缓存 + 1GB 容量守卫
- 每页四态：loading(骨架屏) / error(差异化) / empty / data
