# 第二阶段实施计划（4 大模块升级）

> 历史快照（2026-07-08）：本文记录第二阶段启动前的设计输入，不是当前实施清单。发现、真实本地集合、Device Flow、数据缓存等内容已在后续版本部分或全部落地；当前基线为 `1.4.0+4` 加 `Unreleased` 改动，移动端已经采用 5 Tab。当前事实请以 [产品、数据与系统边界](product_ia_data_plan.md)、[README](../../README.md) 和实际代码为准。

> 基于架构 / 数据API / UI-UX / 测试 4 专家并行设计评审汇总。
> 项目约束：Flutter 桌面优先（Windows）、无后端、离线优先、本地缓存；feature-first；presentation 不依赖 data 类；跨 feature 经 core/domain|config|shared；.dart <300 行；Riverpod + go_router。
> 已定方向：① 数据=联网 GitHub API + 本地缓存兜底；② skill=AI Agent Skills 仓库；③ 登录=GitHub Device Flow。

## 任务划分
- #36 模块1：发现页（流行仓库 + AI Agent Skills + 官方账号 + 知名人士）+ 监控增删闭环
- #37 模块2：个人中心（GitHub Device Flow 登录/注册 + 真实个人状态）
- #38 模块3：设置页（独立 settings feature + 各 item 二级页）
- #39 模块4：数据增强（Trending 镜像 + Agent Skills 排行榜 + awesome lists）
- #40 终验（analyze + test + 桌面运行）

---

## 架构决策（架构专家）
1. **LocalContentController 上提到 `core/shared`**：统一收纳 monitored/bookmarks/developers/rules 本地集合，作为跨 feature 唯一访问点，消除 monitor_settings_cards 跨 feature 直引 profile 的偏差。
2. **监控闭环重构**：`monitor_digest_provider` 改读 `LocalContentController.monitoredRepos`（订阅），替换 `githubMonitorDefaultRepos` 硬编码；原 6 仓库降为首次空集的 seed 兜底；`monitor_repository.buildDigest(repos)` 入参化。
3. **Device Flow 集成点**：`profile/application/auth_provider` 调 `core/github/device_flow_client`（新增）；token 存 `flutter_secure_storage`（OAuth 与 PAT 分 key，常量入 core/config）；`/user` 回填落 `user_provider`；清除 `login_page` 假登录占位，触发 `profile_stats_provider` 读真实 `.length`。
4. **设置页 feature**：`SettingsItem`/`SettingsSection` 模型，点击路由二级页；真实读写经 `core/preferences` 的 `preferences_controller`；路由新增 `/settings`，sidebar_footer 加入口。
5. **数据层抽象**：discover/skill/trending_mirror 三 DataSource 统一到 `core/network` 的 Dio+缓存层，复用 `data_provenance` 标记来源；端点全收口 `api_endpoints_config`；awesome 用静态 seed。

## 数据层方案（数据专家）
- 端点（api_endpoints_config，static 方法）：
  - `trendingRepos({perPage=20})` → `/search/repositories?q=stars:>1000&sort=stars&order=desc&per_page=`
  - `aiAgentSkillsRepos({perPage=20})` → `/search/repositories?q=claude+skills+topics:skills&sort=stars&order=desc`
  - `deviceCode()` → `/login/device/code`；`deviceToken()` → `/login/oauth/access_token`
  - `user()` → `/user`
  - `skillsLeaderboard(String kind)` → `raw.githubusercontent.com/jaychempan/Agent-Skills-Leaderboard/main/data/{kind}.json`（第三方，抽 `thirdPartyBaseUrl`）
- DTO/mapper：复用 `RepoEntity.fromJson`；Skill 用**组合** `SkillEntity { RepoEntity repo; String category; String source; int rank; String? summary; }`，不污染 monitor 流程。
- 缓存：key `discover:trending:v1` / `discover:ai_skills:v1` / `discover:leaderboard:v1`；TTL `CacheTtlConfig.discover=6h`、`skills=24h`；复用 `JsonSnapshotCacheDao` + 「fetch→缓存→seed」三级回退。
- seed：`assets/seed/seed_repos.json`（20 高星仓）、`seed_skills.json`（30 Agent Skills 库），离线首批。
- LocalContentController 扩展：新增 `monitoredSkills`（Set<fullName>）+ `cachedUserName`/`cachedAvatarUrl`。
- Device Flow：device_code→浏览器 user-code→轮询（5s，≤900s，处理 pending/slow_down）→access_token 复用 `githubTokenController`→调 `/user`→Dio `headers()` 注入 `Authorization: Bearer`（提额至 5000/h）。
- 限流：统一经 `gatherAll`；429 指数退避；失败回退 seed。

## UI/UX 方案（UI 专家）
- **发现页**：`page_header`（标题=发现 + HeaderSearchField + HeaderAction 刷新）+ `SegmentedTab[流行仓库 | Agent Skills | 官方账号 | 知名人士]` + filter_row + 列表四态。流行仓库/Agent Skills 使用 `repo_tile` 列表（行尾 `monitor_toggle` 插槽，IconButton bookmark/bookmark_border 切换，isMonitored 驱动，tooltip「添加/移除监控」）并支持触底加载；官方账号/知名人士使用账号行，但点击进入代表仓库详情页，保持在桌面端 B 区域内，不打开全屏 WebView。
- **个人中心**：master-detail；Master=profile_summary_card（头像/昵称/在线/监控·收藏·关注真实 .length）；Detail=未登录(Device Flow 入口)/已登录(真实数据+列表)。Device Flow 状态机 idle→polling(显示 user-code+验证URL+复制+进度)→success→error/expired。
- **设置页**：master-detail；Master=settings_group(账号/外观/数据/通知/隐私/关于)；Detail=各二级页（语言 Radio / 主题 Segmented / 缓存·通知 Switch / 关于 static / 账号跳转 profile）。
- 复用：`page_header`+`HeaderAction`、`repo_tile`（加插槽）、`HeaderSearchField`、`SidebarProfileCard`（补字段）、`SegmentedTab`(按需新增，用 token)。
- 添加/移除监控用 **IconButton toggle**（非 Switch），与列表密度一致。
- i18n 键（中文）：`discover.*` / `auth.*` / `profile.*`(真实状态) / `settings.*`（见 UI 专家清单）。
- light/dark 检查点：边框权重、卡片圆角、溢出滚动、焦点环、对齐 44 基准。
- Golden：discover_page（双 tab+四态）、settings_page、auth.polling 弹层。

## 测试方案（测试专家）
- 模块1：`local_content_controller_test`（增删/isMonitored/持久化）、`discover_page_test`（开关同步/空态）、`project_providers_test`（拉取→缓存→seed 兜底 mock Dio）。
- 模块2：`device_flow_controller_test`（阶段机/FakeAsync 超时）、`token_secure_storage_test`、`profile_user_card_test`（.length 非硬编码）。
- 模块3：`profile_settings_card_test`（locale/主题/清缓存/断账号）、`profile_page_test`（二级路由可达）。
- 模块4：`search_mapper_test`/`trending_mapper_test`/`skills_mapper_test`、`cached_*_repository_test`（命中/过期/失败回退/429）。
- 边界：空集合、网络失败回退 seed、Device Flow denied/expired、并发增删、locale 双语言不崩。
- 验证顺序：`flutter analyze` → `flutter test` → `flutter run -d windows` 核对 golden → Windows build。
- 回归风险：移除硬编码占位计数、路由新增影响 app_router/route_error_view、LocalContentController 默认集依赖 DemoData、SharedPreferences 注入方式统一。

## 实施顺序
1. core 基建：api_endpoints_config + cache_ttl_config + LocalContentController 上提 core/shared + 扩展 skills/user 字段 + device_flow_client。
2. 模块1 发现页 + 监控闭环（含 seed、provider、UI、路由、sidebar 入口、monitor digest 改读）。
3. 模块2 个人中心 Device Flow + 真实状态。
4. 模块3 设置页 + 二级页 + sidebar 入口。
5. 模块4 数据增强（trending 镜像 / skills 排行榜 / awesome seed）。
6. #40 终验 + 提交推送。

## 当时范围确认（历史）

- 当前阶段只修改和验证 Windows 桌面端主链路。
- 手机端继续保持独立 4 Tab 规划，本轮不扩展、不重排、不复用桌面侧边栏结构。

## 与当前基线的关系

- 发现页、监控增删闭环、真实本地实体快照、GitHub Token 安全存储和 Device Flow 已进入当前代码。
- 独立 `lib/features/settings/` 已在后续 `Unreleased` 基线建立，承载 AI 资讯源和自托管服务连接；本文第 4 项仅保留为当时设计记录。
- 移动端已在后续品牌与导航迭代中调整为今日、AI、发现、监控、我的 5 Tab；上面的 4 Tab 是本计划当时的范围约束。
