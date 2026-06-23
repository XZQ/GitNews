# GitHub Developer Intelligence — 客户端设计文档

> 日期:2026-06-23
> 范围:MVP 全量架构与首屏骨架

---

## 1. 目标与边界

- 客户端支持浏览 GitHub 仓库的 Star 趋势、配置监控告警、管理关注仓库。
- **匿名优先**:打开即可浏览 trending;登录延后到收藏 / 跨设备同步场景。
- **纯前端**:无后端代理,直接调用 GitHub 公开 API(匿名 60/h,登录 5000/h)。

## 2. 支持形态

三档响应式(Material 3 断点):

| 形态 | 宽度(dp) | 导航 | 列表列数(默认) |
|---|---|---|---|
| 手机 | < 600 | 底部 NavigationBar | 1 |
| 平板 | 600 – 1024 | 紧凑 NavigationRail(80dp) | 2 |
| 桌面 | ≥ 1024 | 展开 NavigationRail(240dp) | 3 / 多栏 |

切换点用 `LayoutBuilder` + 自定义 `Breakpoint` 工具,默认 Android / iOS / Windows / macOS / Linux 全部支持。

## 3. 信息架构

5 个顶层 Tab:

- `home` — 仪表盘:今日 Trending Top5、未读告警、关注仓库最近动态
- `trending` — 全量 Trending + 筛选(语言 / 时间窗)
- `monitor` — 监控规则列表 + 告警流
- `project` — 已收藏 / 已监控仓库集合
- `profile` — 偏好 + 缓存 + 主题

`repo_detail` 作为可从任意 Tab 进入的详情页(嵌套子路由)。

## 4. 架构

**务实 Clean Architecture**,Feature-first:

```
presentation → domain ← data
```

- `domain`:Entity(freezed)+ Repository 抽象,纯 Dart
- `data`:Repository 实现 + DataSource(remote dio / local drift)+ DTO + 异常转换
- `presentation`:Page / Widget / AsyncNotifier(只依赖 domain)

UseCase 合并进 Repository,domain 在跨特性复用或纯 Dart 单测时存在。

## 5. 关键模块设计

### 5.1 异常体系

```
DataSourceException
  ↓ toAppException()
AppException { kind, cause, stack, meta? }
  ↓ AsyncValue.error
ErrorView 按 kind 渲染
```

`kind`:`network` / `rateLimit(retryAfter)` / `parse` / `notFound` / `unauthorized` / `unknown`。

### 5.2 HTTP(dio)

- 拦截器链:Logging → Retry → RateLimit → Cache(可选)
- 默认超时 10s
- 5xx / 网络错误指数退避重试 2 次(500ms / 1500ms)
- 429:不重试,`Retry-After` 写入异常 `meta.retryAfter`

### 5.3 缓存

| 数据 | TTL | 存储 |
|---|---|---|
| Trending | 5 min | drift |
| Repo Detail | 30 min | drift |
| Star History | 增量 | drift |
| 偏好 | 永久 | shared_preferences |

### 5.4 路由

`StatefulShellRoute.indexedStack` 包 5 个 `StatefulShellBranch`;`/repo_detail/:owner/:name` 为可嵌入各分支的子路由;未知路径 fallback `/home`。

### 5.5 主题

- Material 3,深色为默认,浅色预留(`ThemeMode.system`)
- 所有颜色 / 间距 / 字号 / 圆角集中在 `core/theme/`,**禁止裸值**
- 通过 `ThemeExtension` 暴露业务色(品牌色、Star 色、告警色)

## 6. 依赖

```
flutter_riverpod, go_router, dio, drift, shared_preferences,
fl_chart, freezed_annotation, json_annotation,
cached_network_image, intl
dev: build_runner, freezed, json_serializable, drift_dev,
     flutter_lints, mocktail
```

## 7. 测试策略

- 核心逻辑覆盖率 ≥ 70%
- Repository 用 mocktail mock DataSource
- Notifier 用 ProviderContainer.test
- 关键页面 golden test(首页 / 趋势页 / 详情页,各断点各 1 张)

## 8. 迭代计划(本次为脚手架)

1. **M1(本次)**:可运行骨架 — 三档响应式、5 Tab 占位页、主题、路由、异常体系、依赖注入容器。
2. **M2**:Trending 接入(API + DTO + 缓存 + 列表 + 详情)。
3. **M3**:Star 历史图表(fl_chart + 增量缓存)。
4. **M4**:监控规则 + 告警(本地调度)。
5. **M5**:收藏 / 偏好持久化 + 登录入口预留。

---

## 9. 脚手架交付清单

- `pubspec.yaml` / `analysis_options.yaml`
- `lib/main.dart` / `lib/app.dart`
- `lib/core/` 全部 8 个子模块的入口文件
- `lib/shared/widgets/responsive_scaffold.dart`(三档切换核心)
- 5 个 Feature 的 presentation 占位页
- CLAUDE.md(通用规范)+ README.md(项目专属)
