# AI资讯账号与登录体系规划

更新时间：2026-07-19

状态：规划基线，尚未实现

实施分支：`codex/auth-login`

## 1. 结论先行

AI资讯需要新增的是“应用账号”，不是继续扩展 GitHub Personal Access Token 页面。

推荐采用以下基线：

1. 匿名模式继续作为完整、默认、可长期使用的状态，不强制注册。
2. 国内用户首发以手机验证码为默认主入口，同时提供邮箱验证码、GitHub 和 Google；四者归属于同一个应用账号，可在登录后绑定。
3. 手机验证码是 P0 能力。真实短信供应商、地区覆盖、费用控制、CAPTCHA 和反滥用是首发完成条件，而不是推迟手机号入口的理由。
4. “掘金登录”按稀土掘金账号理解。目前没有查到面向普通第三方 App 的官方 OAuth/OIDC 接入文档，因此不进入可承诺范围；禁止通过抓 Cookie、模拟网页密码登录或非公开接口实现。若这里原意是“GitHub 登录”，GitHub 已在首发范围内。
5. 推荐使用 Supabase Auth 作为身份代理，客户端使用 PKCE 和系统浏览器完成 OAuth；应用自己的 FastAPI 服务只验证用户 JWT，并继续负责同步、协作和业务数据，不自行保存密码或短信验证码。
6. GitHub 登录身份与 GitHub API 连接是两件事。登录方式只证明应用账号身份；现有 PAT / GitHub OAuth Token 继续作为设备上的 GitHub 数据源凭据，不能因应用登录而被隐式复用、上传或删除。

Supabase Auth 的官方能力覆盖邮箱/手机 OTP、Google、GitHub、身份绑定与 Flutter 桌面 OAuth。Google 官方为桌面安装应用推荐 PKCE；GitHub 也建议原生公共客户端优先使用授权码 + PKCE，而不是把 Device Flow 当作普通登录首选：

- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Supabase Flutter 的 Google 登录](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Supabase 的 GitHub 登录](https://supabase.com/docs/guides/auth/social-login/auth-github)
- [Supabase 手机 OTP](https://supabase.com/docs/guides/auth/phone-login)
- [Supabase 身份绑定](https://supabase.com/docs/guides/auth/auth-identity-linking)
- [Google 桌面 OAuth 2.0](https://developers.google.com/identity/protocols/oauth2/native-app)
- [GitHub OAuth 最佳实践](https://docs.github.com/en/enterprise-cloud@latest/apps/oauth-apps/building-oauth-apps/best-practices-for-creating-an-oauth-app)

## 2. 现状判断

### 2.1 当前已有能力

- 客户端可匿名使用全部本地功能。
- `ProfileSessionController` 只把显示名写入 SharedPreferences；它是本地展示状态，不是真实认证会话。
- GitHub Device Flow / PAT 会把 GitHub Token 写入系统安全存储，并回填 GitHub 用户名和头像。
- 可选 FastAPI 服务使用一个部署级 `GITHUB_NEWS_MASTER_KEY` 保护全部接口，通过客户端可传的 `X-Workspace-ID` 区分空间。
- 本地收藏、关注、监控、偏好和缓存已有持久化基础，可选服务已有版本化同步记录。

### 2.2 当前结构性问题

- UI 把“本地显示名”“GitHub API 已连接”“应用已登录”混成同一个状态，容易产生虚假登录感。
- 一个部署级 master key 不能证明具体用户身份，也不能安全支撑公开多用户同步。
- 任意客户端可提交 workspace id；服务端尚未按已认证用户验证空间成员关系。
- 退出当前“登录”只清理部分本地状态，没有账号级会话、跨设备注销、账号绑定或数据隔离语义。
- GitHub Device Flow 适合 GitHub API 授权，但不能代替应用自身账号体系。

## 3. 产品原则

- 主要用户：希望跨设备保存 AI/GitHub 情报工作状态的开发者和技术从业者。
- 主要问题：用户当前数据只在单机存在，身份、数据源授权和同步归属不清晰。
- 承诺结果：不登录也能完整使用；登录后可以安全恢复身份，并为跨设备同步建立唯一、可验证的数据归属。
- 三个最高频任务：
  1. 用常用身份快速登录或恢复会话。
  2. 查看、绑定或解除登录方式，并明确 GitHub 数据源是否另行连接。
  3. 在新设备安全恢复个人配置和收藏/关注/监控状态。
- 产品类型：本地优先的阅读与监控工作台，账号是可选增强能力。
- 平台优先级：Windows 桌面优先验证；移动端保持原生登录编排和 5 Tab 信息架构。

### 明确不做

- 不强制登录，不用登录墙阻断总览、AI、发现、监控和本地“我的”。
- 首发不做自研密码库，不保存用户密码。
- 不用 WebView 收集 Google、GitHub 或掘金密码。
- 不把 Supabase service role key、OAuth client secret、短信供应商密钥放入客户端。
- 不把 GitHub PAT、LLM Key 或自托管服务密钥同步到账号云端。
- 不把“登录成功”描述成“同步成功”；两者有独立状态和失败处理。
- 首发不做企业 SSO、Apple、微信、QQ、微博、通行密钥和 MFA；保留扩展点，按真实用户需求再排期。

## 4. 名词与边界

| 概念 | 作用 | 凭据位置 | 是否影响匿名使用 |
|---|---|---|---|
| 应用账号 | 标识 AI资讯 用户，承载绑定身份和同步归属 | Supabase Auth 会话；客户端安全存储 refresh token | 否 |
| GitHub 登录 | 用 GitHub 身份登录应用账号 | OAuth 由 Supabase 托管，客户端只持有应用会话 | 否 |
| GitHub API 连接 | 提升 GitHub API 配额并按授权范围访问 GitHub | 设备安全存储中的 PAT / GitHub Token | 否 |
| 自托管服务连接 | 指向业务同步、协作、聚合服务 | 服务地址和非敏感配置；用户请求改用应用账号 JWT | 否 |
| 匿名本地身份 | 单设备、无远程账号的本地作用域 | 本机 SQLite / SharedPreferences | 是，默认状态 |

关键规则：应用登出不自动清除 GitHub API Token；断开 GitHub 也不注销应用账号。两个操作必须在 UI 中分开呈现。

## 5. 登录方式决策

| 方式 | 产品优先级 | 首发决策 | 交互 | 外部依赖与约束 |
|---|---:|---|---|---|
| 手机验证码 | P0 | 首条垂直切片 | 国家/地区码 + 手机号 → 6 位验证码 | 短信供应商、地区法规、成本、CAPTCHA、风控和限频 |
| 邮箱验证码 | P0 | 首发 | 输入邮箱 → 发送 6 位验证码 → 校验 | 自定义 SMTP、频率限制、邮件投递与退信监控 |
| Google | P0 | 首发 | 系统浏览器 OAuth；移动端可后续切原生体验 | Google Cloud OAuth 配置、品牌/域名校验、回调 URI |
| GitHub | P0 | 首发 | 系统浏览器 OAuth + PKCE | GitHub OAuth App、最小身份 scope、回调 URI |
| 掘金 | 待定 | 不提供入口 | 只有官方 OAuth/OIDC 和正式应用资质具备后再设计 | 当前未找到官方第三方身份提供商文档 |
| Apple / Microsoft | P2 | 不首发 | 后续按用户分布增加 | Apple 平台政策、Azure/OIDC 配置 |
| Passkey / MFA | P2 | 不首发 | 账号安全中心扩展 | 恢复策略、设备管理和高风险操作定义 |

不使用邮箱密码作为首发方式。验证码减少密码重置和密码存储边界，但必须配合发送频控、枚举保护、一次性消费、过期时间和 CAPTCHA。

## 6. 页面与信息架构

登录仍属于“我的 / 设置”的二级能力，不新增桌面主入口或移动底部 Tab。

| 页面 | 用户目的 | 首要操作 | 次要操作 | 入口 / 返回路径 | 导航层级 | 首发必需 |
|---|---|---|---|---|---|---|
| 账号入口 `/profile/login` | 选择登录方式或继续匿名 | 手机验证码登录 | 邮箱、Google、GitHub、查看隐私说明、继续匿名 | 我的用户卡、桌面侧栏用户卡 → 返回原页面 | 二级 | 是 |
| 邮箱验证码 | 完成邮箱认证 | 提交验证码 | 重发、修改邮箱、返回 | 账号入口内的步骤页 | 三级或同页状态 | 是 |
| 手机验证码 | 完成手机认证 | 提交验证码 | 重发、修改号码、返回 | 账号入口首屏 | 三级或同页状态 | 是 |
| OAuth 等待 / 回调 | 清楚看到浏览器授权进度 | 继续浏览器授权 | 重试、取消 | 账号入口 → 系统浏览器 → App 回调 | 临时状态 | 是 |
| 账号中心 `/profile/account` | 查看身份和账号状态 | 管理账号 | 查看同步、登录方式、安全与数据 | 已登录用户卡 | 二级 | 是 |
| 登录方式 `/profile/account/identities` | 绑定或解除身份 | 绑定新方式 | 解除非最后一种方式 | 账号中心 | 三级 | 是 |
| 设备与会话 `/profile/account/sessions` | 查看并注销设备会话 | 注销其他设备 | 注销当前设备 | 账号中心 | 三级 | 后续 |
| 数据与账号 `/profile/account/data` | 导入本机数据、导出或删除账号 | 选择本机数据合并策略 | 导出、删除 | 账号中心 | 三级 | 同步阶段 |

### 账号入口的内容优先级

首屏只显示：

1. 清楚标题“登录 AI资讯”；
2. 国家/地区码与手机号验证码主表单；
3. 邮箱验证码入口；
4. GitHub 与 Google 第三方登录按钮；
5. “继续匿名使用”；
6. 一句用途和隐私说明。

手机号是国内版本首屏主入口；短信能力未配置时明确显示“当前版本未启用手机登录”，不能回退成假验证码。PAT、GitHub API 配额、LLM Key 和自托管 Key 不出现在账号登录页。

## 7. 移动端与桌面端编排

| 页面 | 模式 | 移动端 | 桌面端 | 共享内容与状态 |
|---|---|---|---|---|
| 账号入口 | 共享业务逻辑，分编排 | 全宽二级页，键盘安全区，按钮纵向排列 | App Shell 内 420–480 px 居中面板，不做营销 Hero | 方式可用性、提交状态、错误、回调状态 |
| 验证码 | 共享业务逻辑，分编排 | 数字键盘、自动聚焦/粘贴、返回保留目标地址 | 单行 6 位输入，可粘贴完整验证码 | 倒计时、校验结果、过期时间 |
| OAuth | 共享业务逻辑，平台回调不同 | Android App Link / 自定义 scheme；外部浏览器 | Windows 自定义 URI 或受控 loopback；外部浏览器 | state、PKCE、取消、超时、回调成功 |
| 账号中心 | 共享业务逻辑，分编排 | 设置列表进入二级页 | 左侧分组 + 右侧详情，延续现有 master-detail | 用户资料、绑定身份、同步与安全状态 |

移动端不复制桌面的双栏。桌面端也不弹一个脱离 App Shell 的全屏登录站，除非外部 OAuth 提供商接管浏览器页面。

## 8. 账号领域与客户端架构

### 8.1 领域状态

`AuthSessionState` 至少区分：

- `anonymous`：没有应用账号，正常使用本地数据；
- `unconfigured`：构建未注入认证服务配置，隐藏不可用入口；
- `authenticating`：正在发送验证码或等待 OAuth；
- `authenticated`：会话有效；
- `refreshing`：刷新会话，不应让整个页面闪回匿名；
- `offlineAuthenticated`：本机有已验证会话，但当前无法刷新或访问服务器；
- `expired`：会话不可恢复，需要重新登录；
- `error`：认证基础设施失败，匿名功能继续可用。

用户实体至少包含稳定 `userId`、显示名、头像、已验证邮箱/手机的脱敏值、绑定身份列表和创建时间。UI 不以 provider 的可变用户名作为本地数据主键。

### 8.2 目录建议

认证是全局横切能力，避免 `profile`、`settings`、`sync` 互相直接依赖：

```text
lib/core/auth/
├── app_identity.dart
├── auth_repository.dart
├── auth_session_controller.dart
├── auth_config.dart
├── auth_callback_handler.dart
└── supabase_auth_repository.dart

lib/features/profile/presentation/auth/
├── login_page.dart
├── email_code_page.dart
├── phone_code_page.dart
├── account_page.dart
├── linked_identities_page.dart
└── widgets/
```

- `core/auth` 暴露稳定领域契约和 Riverpod 会话状态；UI 不直接调用 Supabase SDK。
- Supabase URL、publishable key、回调 scheme 和功能开关通过构建配置注入；缺失时进入 `unconfigured`，不渲染坏按钮。
- refresh token 使用 `FlutterSecureStorage`；普通用户资料可缓存，但日志、埋点和异常中不得出现 token、完整邮箱、完整手机号或验证码。
- 现有 `ProfileSessionController.signInLocal()` 不能继续表达登录成功；迁移后只保留匿名显示偏好，或被新的认证会话完全替代。
- 现有 GitHub Token controller 与认证会话 controller 独立，缓存作用域继续按 GitHub 数据源凭据隔离。

## 9. 服务端认证与数据所有权

现有 master key 只适合部署者管理，不适合公开用户身份。同步上线前必须完成以下改造：

1. FastAPI 使用认证服务的 JWKS 验证短期 JWT，校验签名、`iss`、`aud`、`exp`，从 `sub` 得到稳定 `user_id`。不要自行实现 JWT 加密算法。参考 [Supabase JWT 验证](https://supabase.com/docs/guides/auth/jwts)。
2. `RequestContext` 增加 `user_id`、`session_id` 和授权级别；用户 API 不再接受部署级 master key 作为用户身份。
3. `GITHUB_NEWS_MASTER_KEY` 降级为 operator / ingest 管理凭据，不得分发给普通客户端。
4. 新增 `users`、`workspaces` 和规范化 `workspace_members(user_id, role)`；个人空间由服务端根据用户创建或选择，不能仅相信请求头。
5. 访问 `sync_records`、annotations、push subscriptions 前验证用户是该 workspace 的成员。
6. 所有本地个人数据按 `anonymous` 或稳定 `user_id` 分作用域；切换账号不得读到上一账号的收藏、关注、监控或同步游标。
7. 首次登录不静默上传匿名数据。展示一次“合并此设备数据”确认，提供“合并”“仅保留本机”“稍后处理”；冲突遵循现有版本与 tombstone 语义。
8. 登出立即移除本机应用会话并切走账号作用域。默认保留公开缓存；账号个人数据隐藏，用户可另选“退出并清除此设备的账号数据”。

服务端 JWT 使用短期 access token 与可轮换 refresh token。会话刷新、注销与多设备行为以认证服务为准，不在 Flutter 侧发明第二套 token 生命周期。参考 [Supabase 会话模型](https://supabase.com/docs/guides/auth/sessions)。

## 10. 身份绑定与账号恢复

- 相同且已验证邮箱的 OAuth 身份可按认证服务规则自动关联。
- 不对未验证邮箱自动合并，避免预注册账号接管。
- 手机、不同邮箱或没有公开邮箱的 GitHub 身份，只能在已登录状态下手动绑定。
- 绑定新身份前要求近期认证；回调完成后刷新身份列表。
- 至少保留一种可用登录方式，不能解除最后一个身份。
- 解除身份、注销其他设备、删除账号属于高风险操作，需要再次确认；删除账号需要最近认证。
- 首发恢复方式就是重新完成任一已绑定的邮箱/手机/OAuth 登录，不使用安全问题。
- 账号删除必须同时撤销会话、删除或匿名化服务端个人资料与同步数据，并明确本机公开缓存和 GitHub PAT 不会被误删。

## 11. 数据可信度与安全契约

| 数据 | 来源 | 新鲜度 | 缺失处理 | 失败回退 | 用户可见说明 |
|---|---|---|---|---|---|
| 应用会话 | Supabase Auth | 短期 JWT + refresh token | 进入匿名或过期状态 | 离线时保留本地模式，不伪造在线认证 | 已登录 / 离线 / 需重新登录 |
| 用户资料 | 认证元数据 + 业务服务资料 | 登录/刷新时更新，本机缓存 | 使用账号 ID 的中性占位，不造用户名 | 显示缓存头像/名称并标记离线 | 最近同步时间或离线标记 |
| 绑定身份 | 认证服务 | 打开安全页时刷新 | 显示“暂时无法获取” | 不允许在未知状态下解除身份 | provider + 脱敏标识 + 已验证状态 |
| 同步归属 | FastAPI workspace membership | 每次受保护请求校验 | 阻止同步 | 本机写入 outbox，恢复后重试 | 本机 / 待同步 / 已同步 / 冲突 |
| GitHub API 连接 | 本机安全存储 + GitHub `/user` | 独立于应用会话 | 匿名 GitHub API | PAT / OAuth Token 原有回退 | “GitHub 已连接”，不写“应用已登录” |
| 短信 / 邮件验证码 | 认证服务 + 投递供应商 | 一次性、短时有效 | 允许重发 | 限频后显示可重试时间 | 已发送到脱敏地址 |

## 12. 状态矩阵

| 状态 | 登录入口行为 | 已登录区域行为 | 下一步 |
|---|---|---|---|
| 加载 | 固定骨架，按钮不跳动 | 保留上次稳定身份，显示小型刷新状态 | 等待或取消 |
| 未配置 | 隐藏 OAuth/OTP 提交，解释当前版本未启用账号 | 匿名使用 | 继续匿名；开发构建检查配置 |
| 离线 | 禁止发验证码和新 OAuth | 本地功能可用，账号标记离线，同步入 outbox | 检查网络后重试 |
| 验证码错误 | 保留邮箱/手机号，不清空整页 | 不改变当前会话 | 修改验证码或重发 |
| 验证码过期 | 明确过期，不写笼统“失败” | 不改变当前会话 | 重发验证码 |
| 发送限频 | 展示剩余秒数 | 不改变当前会话 | 倒计时后重试 |
| OAuth 取消/拒绝 | 返回账号入口，保留来源页 | 不改变当前会话 | 重试或换方式 |
| OAuth 回调丢失 | 显示“未收到授权结果” | 不产生半登录状态 | 重试并检查系统浏览器/协议关联 |
| 身份冲突 | 不自动合并不确定账号 | 原会话保持有效 | 近期认证后手动绑定或联系支持 |
| 会话刷新失败 | 不立即清空页面 | 先进入离线状态；确认过期后再登出 | 重新联网或登录 |
| 服务端 401 | 区分 JWT 过期和无权限 | 先刷新一次；仍失败则过期 | 重新登录 |
| 服务端 403 | 会话仍有效 | 不展示他人 workspace 数据 | 请求访问或切换个人空间 |
| 首次登录有本地数据 | 登录成功 | 暂停自动上传 | 选择合并、仅本机或稍后 |
| 登出 | 返回匿名用户卡 | 公开缓存可用，账号作用域隐藏 | 可重新登录或清除设备数据 |
| 删除账号 | 二次确认 + 近期认证 | 进入可恢复的删除进度；失败不得显示成功 | 重试或联系支持 |

验证码页还必须覆盖完整邮箱/手机号过长、6 位粘贴、系统大字体、窄屏键盘遮挡、深浅主题和中英文错误文案。

## 13. 最小 UI 契约

- 复用 `AppCard`、`SecondaryPageScaffold`、主题色、间距、圆角与字体；不建立第二套设计系统。
- 登录面板桌面最大宽度 480 px，手机使用页面安全区和底部键盘 inset。
- 主按钮高度至少 44 px；每个第三方按钮同时使用图标与文字，不只靠品牌颜色识别。
- Google/GitHub 按钮保持供应商品牌规范；不可用时隐藏或给出明确原因，不渲染可点击假入口。
- 邮箱输入与发送按钮是首屏主表单；手机号在“其他方式”中，未配置短信供应商时不出现。
- 标题最多两行；provider 返回的长名称和邮箱在用户卡单行截断，完整值仅在账号页可查看。
- 错误显示在对应输入/操作附近，保留用户已填写的非敏感内容；验证码不写入日志或持久化。
- 登录成功返回用户原本尝试访问的页面；没有来源页时回到 `/profile`。
- 登录页必须有“继续匿名使用”、隐私政策和服务条款入口；匿名不使用贬义或警告式视觉。
- 状态不能只靠颜色：加载、错误、已验证、离线均配图标或文字。

## 14. 第一条垂直切片

第一条切片只做“手机验证码登录 → 会话恢复 → 账号中心 → 登出”，先证明国内主入口和账号地基，再批量接邮箱与第三方 provider。

### 路径

1. 匿名用户从“我的”用户卡进入 `/profile/login`。
2. 选择 `+86`，输入真实测试手机号并发送验证码。
3. 输入正确验证码，收到应用账号会话。
4. 返回“我的”，用户卡显示账号身份，并明确 GitHub 数据源仍是未连接/已连接的独立状态。
5. 关闭并重启 Windows App，会话从安全存储恢复，不出现匿名闪烁。
6. 进入账号区域，查看已验证手机和同步未启用/待配置状态。
7. 登出，回到匿名作用域；GitHub PAT 状态不受影响。

### 必测状态

- 手机格式错误、验证码错误、验证码过期、重发倒计时、发送限频；
- OAuth/认证服务未配置、断网、服务超时、应用重启、refresh token 轮换；
- 有/无 GitHub API Token；
- 匿名本地数据为空和非空；
- Windows 宽屏/紧凑窗口、Android 窄屏、深浅主题和 200% 字体缩放。

### 完成标准

- 没有任何仅写入本地显示名却标记“已登录”的路径。
- 会话 token 只存在系统安全存储，日志、截图、测试 fixture 和导出文件均无 token/验证码。
- 离线和认证服务失败时，匿名本地功能仍完整可用。
- 登录、重启恢复、登出完整路径在 Windows Release 和 Android 真机各走通一次。
- GitHub API Token 在应用登录和登出前后保持符合用户显式操作的状态。

## 15. 实施顺序

### 阶段 0：外部配置与契约

- 建立 Supabase 项目或等价可替换环境，确定区域、域名、隐私政策和数据处理边界。
- 配置 SMTP、Google OAuth、GitHub OAuth 与 Windows/Android 回调 URI。
- 定义 `AuthRepository`、账号实体、构建参数和错误码；建立 fake repository 测试基线。
- 明确目标地区后选择短信供应商；没有生产供应商时保持手机入口关闭。

### 阶段 1：手机账号客户端垂直切片

- 替换本地假会话，完成 `+86` 手机 OTP、会话恢复、账号用户卡和登出。
- 建立账号入口、回调处理和安全存储适配。
- 将 PAT / GitHub Device Flow 文案改为“连接 GitHub”，移回开发者选项或账号页的“外部连接”。
- 完成首条切片的单元、Widget、路由与 Windows/Android 验收。

### 阶段 2：Google、GitHub 与身份绑定

- 接入外部浏览器 PKCE 回调。
- 完成 verified email 自动关联和登录后手动绑定。
- 加入回调丢失、用户取消、provider 不可用和身份冲突路径。

### 阶段 3：服务端用户化与同步归属

- FastAPI 增加 JWKS JWT 验证与 workspace membership 授权。
- SQLite schema 增加用户/空间所有权迁移；保留现有版本、outbox 和 tombstone 语义。
- 客户端本地存储按匿名/用户作用域隔离，加入首次登录的数据合并确认。
- 把部署级 master key 从普通用户同步请求中移除。

### 阶段 4：邮箱与短信生产加固

- 在首条切片已接真实 SMS provider 或 Send SMS Hook 的基础上，完成投递监控、成本告警与多地区策略。
- 接入邮箱 OTP 与自有域名 SMTP。
- 完成国家/地区码、E.164 规范化、CAPTCHA、IP/号码/设备限频、成本告警和投递监控。
- 在目标地区真机验证实际短信可达率后才公开入口。

### 阶段 5：账号安全与生命周期

- 设备/会话列表、注销其他设备、解除身份、数据导出和账号删除。
- 根据风险与真实用户需求决定 MFA、Passkey、Apple、Microsoft 或企业 OIDC。

## 16. 验收门槛

### 功能

- [ ] 匿名用户无需登录即可完成当前所有本地核心任务。
- [ ] 邮箱、Google、GitHub 的成功/取消/失败路径可观察且可恢复。
- [ ] 手机入口只有在真实短信、限频、CAPTCHA 和监控可用时才展示。
- [ ] 同一用户绑定多个身份后仍只有一个稳定 `user_id`。
- [ ] 登录、GitHub API 连接、自托管服务连接三个状态和操作完全分开。
- [ ] 应用重启、短时断网和 token 刷新不会导致账号页面闪烁或串号。
- [ ] 切换账号不能读取上一账号的个人数据或同步游标。

### 安全与隐私

- [ ] PKCE、state/nonce、redirect allowlist 和外部系统浏览器路径已验证。
- [ ] JWT 校验签名、issuer、audience、expiry；workspace 每次验证成员关系。
- [ ] 客户端包中没有 provider secret、service role key、master key、短信密钥。
- [ ] token、验证码、完整邮箱/手机不进入日志、分析事件、截图、fixture 或导出。
- [ ] 发送 OTP 有 CAPTCHA、枚举保护、IP/设备/目标地址限频和告警。
- [ ] 解除最后一种身份、删除账号和跨账号自动合并被阻止。

### 工程

- [ ] `dart format --output=none --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `flutter build windows --release`
- [ ] Windows Release 启动烟测通过，并人工完成真实外部浏览器回调。
- [ ] Android 真机完成邮箱、Google、GitHub及手机（启用后）真实登录。
- [ ] `server/` 的 Ruff、pytest 和 live smoke 通过，包含跨用户/跨 workspace 越权负例。
- [ ] 回归验证匿名缓存、GitHub PAT、LLM Key 和本地数据未被迁移或误删。

## 17. 未决策事项

| 事项 | 影响 | 截止点 | 临时假设 |
|---|---|---|---|
| “掘金登录”是否确指稀土掘金 | 决定是否继续申请平台资质或改为 GitHub | 阶段 0 结束前 | 按字面理解；无官方 OAuth 时不实现 |
| Supabase 托管还是自托管 Auth | 运维、合规、域名、可用性和成本 | 阶段 0 | 首发用托管 Supabase Auth；保留标准 JWT/JWKS 边界 |
| 主要发行地区 | 手机号地区码、短信供应商、合规与成本 | 阶段 0 | 国内优先，`+86` 为默认区号；其他地区后续开放 |
| 邮箱投递服务与发件域名 | OTP 可达率、限额、品牌信任 | 首条切片真实烟测前 | 使用自有域名 SMTP，不用默认低额度邮件服务发布生产版 |
| 首次登录本地数据合并默认项 | 隐私、冲突和用户预期 | 同步阶段前 | 必须显式选择，不静默上传 |
| 账号删除保留期 | 可恢复性、隐私和服务端清理 | 删除功能前 | 先设计立即冻结 + 短期可撤销，具体期限待定 |

## 18. 当前实施假设与外部条件

2026-07-19 开始首条客户端切片时采用以下假设：

1. “掘金”按稀土掘金理解；没有公开、正式的第三方认证能力时不实现。
2. 首发身份代理采用托管 Supabase Auth，同时保留可替换的 `AuthRepository` 边界。
3. 国内手机号验证码是默认主入口；邮箱、GitHub、Google 已有客户端能力开关，但只有发布方完成真实 provider 配置后才展示。
4. 当前仓库没有生产 Supabase 项目、短信供应商、域名、SMTP 或 OAuth 应用凭据，因此只能完成客户端实现、Fake 验证和未配置降级，不能声称真实短信或 OAuth 已上线。

生产入口启用前仍需补齐真实供应商、CAPTCHA、限频、回调注册、投递监控和目标地区真机验收。
