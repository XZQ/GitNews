# GitHub 情报站产品可信度加固 Implementation Plan

> 历史快照：本文是从 `1.2.0+2` 升级到 `1.3.0+3` 的执行计划，标题、命令、版本号和复选框保留为实施证据，不代表当前待办。当前中文产品名为“AI资讯”，当前基线请查看 [产品、数据与系统边界](../../plans/product_ia_data_plan.md) 和 [README](../../../README.md)。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 `1.2.0+2` 升级为 `1.3.0+3`，修复本地集合丢失、监控时间口径、缓存串用、虚假活动、失效 OAuth 入口、启动不可恢复和配置导入不可信等问题，并建立 Windows 可启动发布门禁。

**Architecture:** 保持 Flutter 单机、本地优先和 feature-first 架构。用户主动保存的实体快照进入 SharedPreferences，远端活动与聚合缓存继续进入 SQLite；领域模型位于 `core/domain`，数据获取与编解码留在各 feature 的 `data`，页面只消费 domain/application 层。

**Tech Stack:** Flutter、Dart、Riverpod、Dio、SharedPreferences、SQLite、flutter_test、mocktail、GitHub Actions、PowerShell。

## Global Constraints

- 目标版本固定为 `1.3.0+3`。
- 不新增后端、后台常驻任务、云同步或系统推送。
- 所有行为变更严格执行 RED → GREEN → REFACTOR；没有失败测试时不得改生产代码。
- 缓存 TTL 和 API 路径只放在 `lib/core/config/`；GitHub 协议头继续复用 `GitHubApiSupport`。
- UI 只消费 domain/application 类型，不直接引用 feature data 类型。
- 用户可见的真实、缓存、估算、种子和空态必须诚实标识，不显示无来源样例。
- 命令统一通过 `rtk` 执行；每个任务先跑目标测试，提交前跑 format、analyze 和全量 test。
- 提交信息使用首字母大写的 Conventional Commits 和中文主题。

---

## File Map

- `lib/core/shared/local_content_snapshots.dart`: 用户主动保存的仓库、开发者快照和 JSON 编解码。
- `lib/core/shared/local_content_controller.dart`: 集合 ID、实体快照、旧数据迁移及持久化事务编排。
- `lib/core/domain/repo_activity_event.dart`: GitHub 活动领域实体与事件类型。
- `lib/features/monitor/domain/monitor_rule_evaluator.dart`: 跨日观测的日均增量与复合日增长率。
- `lib/features/project/data/project_cache_keys.dart`: 仓库集合和 Token 作用域隔离的稳定缓存键。
- `lib/features/project/data/github_project_repository.dart`: 贡献者与活动聚合、缓存和降级。
- `lib/features/repo_detail/data/github_repo_detail_repository.dart`: 单仓库活动请求及详情摘要组合。
- `lib/bootstrap.dart`: 启动初始化结果、重试和数据目录恢复界面。
- `lib/core/preferences/config_service.dart`: 配置白名单、完整预检、回滚和 Provider 刷新。
- `.github/workflows/quality.yml`: Ubuntu 质量门禁与 Windows Release/启动烟测。
- `tools/windows_release_smoke.ps1`: 验证产物结构、进程存活和主窗口句柄。

---

### Task 1: 持久化真实收藏、监控和关注实体

**Files:**
- Create: `lib/core/shared/local_content_snapshots.dart`
- Modify: `lib/core/shared/local_content_controller.dart`
- Modify: `lib/features/discover/presentation/widgets/discover_repo_row.dart`
- Modify: `lib/features/repo_detail/presentation/repo_detail_page.dart`
- Modify: `lib/features/project/presentation/widgets/project_secondary_cards.dart`
- Modify: `lib/features/profile/presentation/collect_page.dart`
- Modify: `lib/features/profile/presentation/monitor_topics_page.dart`
- Modify: `lib/features/profile/presentation/followed_developers_page.dart`
- Test: `test/features/profile/application/local_content_controller_test.dart`
- Create: `test/features/profile/presentation/local_collection_pages_test.dart`

**Interfaces:**
- Produces: `SavedRepoSnapshot.fromEntity(RepoEntity)`, `SavedRepoSnapshot.minimal(String)`, `SavedRepoSnapshot.toEntity()`。
- Produces: `SavedDeveloperSnapshot.fromEntity(ContributorEntity)`、`SavedDeveloperSnapshot.toEntity()`。
- Produces: `LocalContentState.bookmarkedRepoSnapshots`、`monitoredRepoSnapshots`、`followedDeveloperSnapshots`。
- Changes: `toggleBookmark(RepoEntity repo)`、`addMonitor(RepoEntity repo)`、`toggleDeveloper(ContributorEntity developer)`。

- [ ] **Step 1: 写实体快照恢复失败测试**

```dart
final remoteRepo = RepoEntity(
  fullName: 'remote/new-repo',
  description: 'Only returned by GitHub',
  language: 'Rust',
  starCount: 42,
  starDelta: 3,
  forkCount: 7,
  accentArgb: 0xFFDEA584,
);
await notifier.toggleBookmark(remoteRepo);
await notifier.addMonitor(remoteRepo);
await notifier.toggleDeveloper(const ContributorEntity(
  login: 'remote-dev',
  contributions: 19,
  avatarAccentArgb: 0xFF6366F1,
));
final restored = await _container();
expect(restored.read(localContentControllerProvider).bookmarkedRepoSnapshots['remote/new-repo']!.description, 'Only returned by GitHub');
expect(restored.read(localContentControllerProvider).monitoredRepoSnapshots, contains('remote/new-repo'));
expect(restored.read(localContentControllerProvider).followedDeveloperSnapshots, contains('remote-dev'));
```

- [ ] **Step 2: 运行测试并确认 RED**

Run: `rtk flutter test test/features/profile/application/local_content_controller_test.dart`

Expected: FAIL，因为状态中不存在快照 Map，且三个写入方法仍只接受字符串。

- [ ] **Step 3: 实现快照模型、旧 ID 迁移和写入清理规则**

```dart
class SavedRepoSnapshot {
  const SavedRepoSnapshot({required this.fullName, required this.description, required this.language, required this.starCount, required this.forkCount, required this.accentArgb, required this.updatedAt});
  factory SavedRepoSnapshot.fromEntity(RepoEntity repo, DateTime now) => SavedRepoSnapshot(fullName: repo.fullName, description: repo.description, language: repo.language, starCount: repo.starCount, forkCount: repo.forkCount, accentArgb: repo.accentArgb, updatedAt: now.toUtc());
  factory SavedRepoSnapshot.minimal(String fullName, DateTime now) => SavedRepoSnapshot(fullName: fullName, description: '', language: 'Unknown', starCount: 0, forkCount: 0, accentArgb: 0xFF64748B, updatedAt: now.toUtc());
  final String fullName;
  final String description;
  final String language;
  final int starCount;
  final int forkCount;
  final int accentArgb;
  final DateTime updatedAt;
  RepoEntity toEntity() => RepoEntity(fullName: fullName, description: description, language: language, starCount: starCount, starDelta: 0, forkCount: forkCount, accentArgb: accentArgb);
}
```

快照使用新的 JSON 字符串 key：`local_content_repo_snapshots_v1` 和 `local_content_developer_snapshots_v1`。读取老 ID 时先匹配 `DemoData`，匹配失败则创建 minimal 快照；仓库同时不在收藏和监控集合时才删除仓库快照，开发者取消关注时删除开发者快照。

- [ ] **Step 4: 集合页直接渲染状态快照并补 Widget 测试**

```dart
final repos = content.bookmarkedRepos
    .map((id) => content.bookmarkedRepoSnapshots[id]!.toEntity())
    .toList(growable: false);
```

测试分别注入 `remote/new-repo` 和 `remote-dev`，断言收藏页、监控页和关注页可见，移除按钮拥有本地化 tooltip，且空集合显示本地化空态。

- [ ] **Step 5: 验证并提交**

Run: `rtk flutter test test/features/profile/application/local_content_controller_test.dart test/features/profile/presentation/local_collection_pages_test.dart`

Expected: PASS。

Commit: `Fix(profile):持久化真实收藏监控与关注实体`

---

### Task 2: 尊重空监控并统一跨日规则口径

**Files:**
- Modify: `lib/features/monitor/application/monitor_providers.dart`
- Modify: `lib/features/monitor/domain/monitor_rule_evaluator.dart`
- Modify: `test/features/monitor/application/monitor_providers_test.dart`
- Modify: `test/features/monitor/domain/monitor_rule_evaluator_test.dart`

**Interfaces:**
- Consumes: `LocalContentState.monitoredRepos` 已能区分“未设置时默认值”和“用户明确清空”。
- Produces: `monitorReposFor(Set<String>)`，返回排序后的真实集合，空集合保持为空。
- Produces: `_elapsedLocalDays(DateTime previous, DateTime current)`。

- [ ] **Step 1: 写空监控和 30 天间隔回归测试**

```dart
test('explicit empty monitor selection stays empty', () {
  expect(monitorReposFor(<String>{}), isEmpty);
});

test('thirty day growth is normalized before daily threshold evaluation', () {
  final events = evaluator.evaluate(
    previous: observation(day: 1, stars: 1000, forks: 10),
    current: observation(day: 31, stars: 1200, forks: 60),
    enabledRuleIds: allRules,
  );
  expect(events.map((event) => event.ruleId), isNot(contains(MonitorRuleIds.starDailyDelta)));
  expect(events.map((event) => event.ruleId), isNot(contains(MonitorRuleIds.forkDailyDelta)));
});
```

- [ ] **Step 2: 运行测试并确认 RED**

Run: `rtk flutter test test/features/monitor/application/monitor_providers_test.dart test/features/monitor/domain/monitor_rule_evaluator_test.dart`

Expected: FAIL，空集合回落默认仓库，30 天累计值触发日增长规则。

- [ ] **Step 3: 实现日均增量和复合日增长率**

```dart
final days = _elapsedLocalDays(previous.observedAt, current.observedAt);
if (days <= 0) return const [];
final starDelta = math.max(0, current.stars - previous.stars) / days;
final forkDelta = math.max(0, current.forks - previous.forks) / days;
final starRate = previous.stars <= 0 || current.stars <= previous.stars
    ? 0.0
    : (math.pow(current.stars / previous.stars, 1 / days) - 1) * 100;
```

`issueHeatRatio` 保持“本次观测相对上次观测”，相关中英文文案不得称为日均。事件 ID 仍为 `repo|rule|localDayKey`。

- [ ] **Step 4: 验证边界并提交**

增加同日、倒序时间、闰月跨月和连续一天阈值测试。

Run: `rtk flutter test test/features/monitor/application/monitor_providers_test.dart test/features/monitor/domain/monitor_rule_evaluator_test.dart`

Expected: PASS。

Commit: `Fix(monitor):统一跨日告警的每日增长口径`

---

### Task 3: 隔离深度报告贡献者缓存

**Files:**
- Create: `lib/features/project/data/project_cache_keys.dart`
- Modify: `lib/features/project/data/github_project_repository.dart`
- Create: `test/features/project/data/project_cache_keys_test.dart`
- Create: `test/features/project/data/github_project_repository_test.dart`

**Interfaces:**
- Produces: `String projectContributorsCacheKey({required Iterable<String> repos, required String cacheScope})`。
- Constructor stores the existing `cacheScope` as `_cacheScope`。

- [ ] **Step 1: 写缓存键顺序稳定和作用域隔离测试**

```dart
expect(
  projectContributorsCacheKey(repos: ['b/two', 'a/one'], cacheScope: 'anonymous'),
  projectContributorsCacheKey(repos: ['a/one', 'b/two'], cacheScope: 'anonymous'),
);
expect(
  projectContributorsCacheKey(repos: ['a/one'], cacheScope: 'anonymous'),
  isNot(projectContributorsCacheKey(repos: ['a/one'], cacheScope: 'token_abc')),
);
```

- [ ] **Step 2: 运行测试并确认 RED**

Run: `rtk flutter test test/features/project/data/project_cache_keys_test.dart`

Expected: FAIL，因为缓存键生成器尚不存在。

- [ ] **Step 3: 实现稳定键并让所有贡献者读写使用同一动态键**

```dart
String projectContributorsCacheKey({required Iterable<String> repos, required String cacheScope}) {
  final sorted = repos.toSet().toList()..sort();
  var hash = 0;
  for (final unit in '$cacheScope|${sorted.join('|')}'.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return 'project:github:contributors:v2:$hash';
}
```

`_contributorsFor` 在读取 feed 后先固定 `repoNames = digest.repos.take(4).map(...).toList()`，计算一次 key，并将其传给 `_readContributors(cacheKey)`、`isFresh(key:)` 和 `upsert(key:)`。

- [ ] **Step 4: 用两个 feed 和同一个 DAO 验证不会串用缓存**

测试先写入 A 仓库贡献者缓存，再创建 B 仓库集合仓库实例；断言 B 会请求自己的 contributors URL，不返回 A 的 login。

Run: `rtk flutter test test/features/project/data/project_cache_keys_test.dart test/features/project/data/github_project_repository_test.dart`

Expected: PASS。

Commit: `Fix(project):按仓库集合与凭据隔离贡献者缓存`

---

### Task 4: 为仓库详情接入真实 GitHub 活动

**Files:**
- Create: `lib/core/domain/repo_activity_event.dart`
- Modify: `lib/core/config/api_endpoints_config.dart`
- Modify: `lib/features/repo_detail/domain/repo_detail_repository.dart`
- Modify: `lib/features/repo_detail/data/github_repo_detail_repository.dart`
- Modify: `lib/features/repo_detail/data/github_repo_detail_cache_codec.dart`
- Modify: `lib/features/repo_detail/data/local_repo_detail_repository.dart`
- Modify: `lib/features/repo_detail/presentation/detail/repo_detail_activity.dart`
- Modify: `lib/features/repo_detail/presentation/repo_detail_page.dart`
- Create: `test/features/repo_detail/data/github_repo_activity_test.dart`
- Create: `test/features/repo_detail/presentation/repo_detail_activity_test.dart`

**Interfaces:**
- Produces: `RepoActivityEvent(repoFullName, type, title, actorLogin, occurredAt, htmlUrl, basis)`。
- Produces: `ApiEndpointsConfig.githubRepoEventsPath(String fullName)`。
- Changes: `RepoDetailDigest` gains required `List<RepoActivityEvent> activities`。
- Changes: `RepoDetailActivity({required List<RepoActivityEvent> activities})`。

- [ ] **Step 1: 写 GitHub PushEvent、ReleaseEvent 和空列表解析测试**

```dart
expect(digest.activities.single.type, RepoActivityType.push);
expect(digest.activities.single.title, 'feat: trusted activity');
expect(digest.activities.single.actorLogin, 'octocat');
expect(digest.activities.single.basis, MetricBasis.observed);
```

- [ ] **Step 2: 运行测试并确认 RED**

Run: `rtk flutter test test/features/repo_detail/data/github_repo_activity_test.dart`

Expected: FAIL，因为详情摘要没有 activities，且 events 端点不存在。

- [ ] **Step 3: 实现领域模型、API 解析和详情缓存编解码**

```dart
static String githubRepoEventsPath(String fullName) => '/repos/$fullName/events';

final activityResult = await _resources.getList(
  url: ApiEndpointsConfig.githubRepoEventsPath(fullName),
  queryParameters: const {'per_page': 20},
);
```

支持 `PushEvent`、`IssuesEvent`、`PullRequestEvent`、`ReleaseEvent`、`CreateEvent` 和 `Other`；标题只读取 GitHub payload，禁止生成看似真实的提交内容。详情顶层缓存加入 `activities` 字段，旧缓存缺字段时解码为空列表。

- [ ] **Step 4: 替换硬编码活动组件并验证空态**

```dart
if (activities.isEmpty) {
  return EmptyView(
    icon: Icons.history_toggle_off_rounded,
    message: l10n.tr('repo_detail.activity.empty'),
  );
}
```

每一行显示类型图标、真实标题、actor、相对时间并提供语义标签；有 `htmlUrl` 时通过现有链接打开策略打开。

- [ ] **Step 5: 验证并提交**

Run: `rtk flutter test test/features/repo_detail/data/github_repo_activity_test.dart test/features/repo_detail/presentation/repo_detail_activity_test.dart test/features/repo_detail/application/repo_detail_providers_test.dart`

Expected: PASS。

Commit: `Feat(repo):接入真实仓库活动并移除样例流`

---

### Task 5: 为深度报告聚合真实活动并提供过期缓存降级

**Files:**
- Modify: `lib/features/project/domain/project_repository.dart`
- Modify: `lib/features/project/data/project_cache_keys.dart`
- Modify: `lib/features/project/data/github_project_repository.dart`
- Modify: `lib/features/project/data/local_project_repository.dart`
- Modify: `lib/features/project/presentation/widgets/activity_events_card.dart`
- Modify: `lib/features/project/presentation/activity_page.dart`
- Modify: `test/features/project/data/github_project_repository_test.dart`
- Modify: `test/features/project/application/project_providers_test.dart`
- Create: `test/features/project/presentation/activity_events_card_test.dart`

**Interfaces:**
- Changes: `ProjectDigest` gains required `List<RepoActivityEvent> activities`。
- Produces: `projectActivitiesCacheKey({repos, cacheScope})`。
- Changes: `ActivityEventsCard({required activities})`。

- [ ] **Step 1: 写跨四仓库合并、排序、30 条上限和失败降级测试**

```dart
expect(digest.activities, hasLength(30));
expect(digest.activities.first.occurredAt.isAfter(digest.activities.last.occurredAt), isTrue);
expect(requestedEventPaths, containsAll(['/repos/a/one/events', '/repos/b/two/events']));
```

网络失败且已有活动聚合缓存时断言返回缓存；无缓存时断言 `activities` 为空，不出现 demo 文案。

- [ ] **Step 2: 运行测试并确认 RED**

Run: `rtk flutter test test/features/project/data/github_project_repository_test.dart`

Expected: FAIL，因为 ProjectDigest 与仓库当前没有活动字段。

- [ ] **Step 3: 实现并行拉取、聚合缓存与诚实降级**

```dart
final events = results
    .expand((result) => result.data)
    .toList()
  ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
return events.take(30).toList(growable: false);
```

活动缓存键与贡献者键分别使用 `v1`/`v2` 命名空间，均包含排序后的前四仓库集合和 `_cacheScope`。单仓库失败不丢弃其他仓库结果；全部失败时读取过期聚合缓存，再回空列表。

- [ ] **Step 4: 让 ActivityEventsCard 只渲染传入数据**

移除 `_EventSpec` 和静态 `_events`；卡片为空时显示 `project.activity.empty`，非空时显示真实来源 badge 和活动行。

- [ ] **Step 5: 验证并提交**

Run: `rtk flutter test test/features/project/data/github_project_repository_test.dart test/features/project/application/project_providers_test.dart test/features/project/presentation/activity_events_card_test.dart`

Expected: PASS。

Commit: `Feat(project):聚合真实活动并提供缓存降级`

---

### Task 6: 让 GitHub OAuth 入口与构建配置一致

**Files:**
- Modify: `lib/core/config/api_endpoints_config.dart`
- Modify: `lib/core/github/github_device_flow_controller.dart`
- Modify: `lib/features/profile/presentation/widgets/profile_user_card.dart`
- Modify: `lib/features/profile/presentation/login_page.dart`
- Modify: `lib/features/profile/presentation/widgets/device_flow_content.dart`
- Modify: `lib/core/i18n/strings_zh_cn.dart`
- Modify: `lib/core/i18n/strings_en_us.dart`
- Create: `test/core/github/github_device_flow_controller_test.dart`
- Create: `test/features/profile/presentation/github_auth_entry_test.dart`

**Interfaces:**
- Produces: `githubOAuthClientId = String.fromEnvironment('GITHUB_OAUTH_CLIENT_ID')`。
- Produces: `ApiEndpointsConfig.githubOAuthConfigured`。

- [ ] **Step 1: 写未配置时零网络请求和 UI 只展示 PAT 路径测试**

```dart
expect(ApiEndpointsConfig.githubOAuthConfigured, isFalse);
await container.read(githubDeviceFlowProvider.notifier).start();
expect(container.read(githubDeviceFlowProvider).error, 'not_configured');
verifyNever(() => dio.post<Map<String, Object?>>(any(), data: any(named: 'data'), options: any(named: 'options')));
```

Widget 测试断言未配置构建不显示“使用 GitHub 登录”，显示“配置 Personal Access Token”并导航 `/profile/developer`。

- [ ] **Step 2: 运行测试并确认 RED**

Run: `rtk flutter test test/core/github/github_device_flow_controller_test.dart test/features/profile/presentation/github_auth_entry_test.dart`

Expected: FAIL，因为当前用占位字符串判断配置且仍暴露登录主入口。

- [ ] **Step 3: 实现编译时配置和诚实入口**

```dart
static const String githubOAuthClientId = String.fromEnvironment('GITHUB_OAUTH_CLIENT_ID');
static bool get githubOAuthConfigured => githubOAuthClientId.trim().isNotEmpty;
```

Device Flow controller 支持注入 Dio 以便测试；未配置时立即结束。个人卡和登录页在未配置时显示 PAT 能力、匿名可用和本机安全存储，不声称同步、跨设备或邮箱登录。

- [ ] **Step 4: 验证配置构建分支并提交**

Run: `rtk flutter test test/core/github/github_device_flow_controller_test.dart test/features/profile/presentation/github_auth_entry_test.dart`

Expected: PASS。

Commit: `Fix(auth):按构建配置提供真实 GitHub 登录入口`

---

### Task 7: 建立可重试的启动恢复界面

**Files:**
- Create: `lib/bootstrap.dart`
- Modify: `lib/main.dart`
- Modify: `lib/core/i18n/strings_zh_cn.dart`
- Modify: `lib/core/i18n/strings_en_us.dart`
- Create: `test/bootstrap_test.dart`

**Interfaces:**
- Produces: `BootstrapResult.success(SharedPreferences, LocalDatabase)` 与 `BootstrapResult.failure(Object, StackTrace)`。
- Produces: `Future<BootstrapResult> initializeApplication()`。
- Produces: `BootstrapApp({Future<BootstrapResult> Function()? initializer})`。

- [ ] **Step 1: 写初始化失败、重试成功和不自动删库测试**

```dart
var attempts = 0;
await tester.pumpWidget(BootstrapApp(initializer: () async {
  attempts++;
  return attempts == 1 ? BootstrapResult.failure(StateError('db locked'), StackTrace.empty) : BootstrapResult.success(prefs, database);
}));
expect(find.text('重试'), findsOneWidget);
await tester.tap(find.text('重试'));
await tester.pumpAndSettle();
expect(find.byType(GitHubNewsApp), findsOneWidget);
```

- [ ] **Step 2: 运行测试并确认 RED**

Run: `rtk flutter test test/bootstrap_test.dart`

Expected: FAIL，因为 `BootstrapApp` 和恢复状态不存在。

- [ ] **Step 3: 让 runApp 先发生，再异步初始化依赖**

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureGlobalErrorWidget();
  runApp(const BootstrapApp());
}
```

`BootstrapApp` 显示加载状态；成功后构建带两个 override 的 ProviderScope；失败后显示错误摘要、重试和“打开数据目录”。打开目录只调用平台文件管理器，绝不自动删除、重命名或重建数据库。

- [ ] **Step 4: 验证并提交**

Run: `rtk flutter test test/bootstrap_test.dart test/widget_test.dart`

Expected: PASS。

Commit: `Fix(bootstrap):增加初始化失败恢复与重试界面`

---

### Task 8: 配置导入完整预检、回滚和状态刷新

**Files:**
- Modify: `lib/core/preferences/config_service.dart`
- Modify: `lib/features/profile/presentation/widgets/profile_data_card.dart`
- Create: `test/core/preferences/config_service_test.dart`

**Interfaces:**
- Produces: `ConfigDocument.parse(String)`，只接受 `app == 'github_news'`、`version == 1` 和白名单 preferences。
- Produces: `ConfigImportResult(importedCount)`。
- Produces: `ConfigService.importText(String)`，供剪贴板入口和单元测试共用同一解析/写入路径。
- `ConfigService` 构造函数增加可注入的 `ClipboardReader`，生产默认读取系统剪贴板。

- [ ] **Step 1: 写错误 app/version、未知 key、列表类型、Token 和零部分写入测试**

```dart
await expectLater(service.importText('{"app":"other","version":1,"preferences":{}}'), throwsFormatException);
await expectLater(service.importText('{"app":"github_news","version":2,"preferences":{}}'), throwsFormatException);
await expectLater(service.importText('{"app":"github_news","version":1,"preferences":{"theme_mode":"dark","unknown":true}}'), throwsFormatException);
expect(prefs.getString('theme_mode'), 'light');
expect(exported, isNot(contains('github_personal_access_token')));
```

- [ ] **Step 2: 运行测试并确认 RED**

Run: `rtk flutter test test/core/preferences/config_service_test.dart`

Expected: FAIL，因为当前导入不校验 app/version/白名单，并可能在列表 cast 时已写入前序 key。

- [ ] **Step 3: 实现完整预检、值域校验和失败回滚**

白名单固定为 `app_locale`、`theme_mode`、`app.theme_preset`、`startup_tab_segment`、`trending_data_source_mode`、`link_open_mode`、`local_content_monitor_rules`、`monitor_notification_settings`。先把所有值解码为 `Map<String, Object>` 并验证枚举/列表长度，再保存旧值，最后写入；setter 返回 false 或抛异常时按旧值回滚并抛 `StateError`。

```dart
const allowedKeys = <String>{
  'app_locale', 'theme_mode', 'app.theme_preset', 'startup_tab_segment',
  'trending_data_source_mode', 'link_open_mode',
  'local_content_monitor_rules', 'monitor_notification_settings',
};
```

- [ ] **Step 4: 成功写入后刷新对应 Provider**

依次 invalidate locale、theme mode、theme preset、startup tab、trending source、link mode、local content 和 monitor settings provider。ProfileDataCard 根据 `ConfigImportResult.importedCount` 显示本地化结果。

- [ ] **Step 5: 验证并提交**

Run: `rtk flutter test test/core/preferences/config_service_test.dart`

Expected: PASS。

Commit: `Fix(config):校验并原子导入本地偏好`

---

### Task 9: 完成本次流程的中英文、键盘、语义和三档布局回归

**Files:**
- Modify: `lib/core/i18n/strings_zh_cn.dart`
- Modify: `lib/core/i18n/strings_en_us.dart`
- Modify: `lib/features/project/application/project_exporter.dart`
- Modify: `lib/features/project/presentation/project_page.dart`
- Modify: `lib/features/tech_hotspot/presentation/tech_hotspot_page.dart`
- Modify: `lib/features/tech_hotspot/presentation/widgets/tech_hotspot_agent_signal_board.dart`
- Modify: `lib/features/tech_hotspot/presentation/widgets/tech_hotspot_page_header.dart`
- Modify: `lib/features/tech_hotspot/presentation/widgets/tech_hotspot_tags_cloud.dart`
- Modify: Task 1、4、5、6、7、8 中触及的 presentation 文件
- Create: `test/core/i18n/localization_keys_test.dart`
- Modify: `test/features/project/application/project_exporter_test.dart`
- Create: `test/features/profile/presentation/trust_flows_layout_test.dart`

**Interfaces:**
- Produces: 中英文 key 集合完全一致。
- Produces: 收藏、监控、关注、活动、OAuth/PAT、启动恢复和配置导入所需文案 key。
- Produces: `ProjectReportCopy`，由当前 locale 构造并传给 `formatProjectDigestMarkdown` / `writeProjectDigestMarkdown`。

- [ ] **Step 1: 写 key 对称、英文无中文字符、键盘语义和三档尺寸测试**

```dart
expect(stringsZhCn.keys.toSet(), stringsEnUs.keys.toSet());
expect(find.bySemanticsLabel('Remove bookmark'), findsOneWidget);
```

分别设置 `1366x768`、`1024x768`、`390x844`，渲染收藏页、活动页、雷达页和登录/PAT 页，断言 `tester.takeException()` 为 null；用 Tab/Shift+Tab 聚焦侧栏、搜索、刷新、收藏、监控和设置主要操作后按 Enter，断言动作发生。报告导出测试分别传入中英文 `ProjectReportCopy`，断言英文报告不含中文标题与字段名。

- [ ] **Step 2: 运行测试并确认 RED**

Run: `rtk flutter test test/core/i18n/localization_keys_test.dart test/features/profile/presentation/trust_flows_layout_test.dart`

Expected: FAIL，因为集合页、活动页、报告导出、雷达筛选/空态仍有硬编码中文且语义/焦点覆盖不足。

- [ ] **Step 3: 替换硬编码文案并补齐 Semantics/Tooltip**

所有计数使用 `{n}` 替换；IconButton 必须有本地化 tooltip；活动行、实体头像、恢复按钮和 PAT 主操作增加能描述结果而非图形的语义标签。把 `project_exporter.dart` 的报告标题、字段、空态和贡献单位改为 `ProjectReportCopy`；把雷达页分类筛选、主题/标签/Agent 信号空态迁入字符串表。保持现有 `AppSpacing`、`AppTypography`、`AppCard`、`HeaderSearchField` 和响应式断点。

- [ ] **Step 4: 验证并提交**

Run: `rtk flutter test test/core/i18n/localization_keys_test.dart test/features/profile/presentation/trust_flows_layout_test.dart`

Expected: PASS。

Commit: `Fix(ui):完善可信流程的国际化与可访问性`

---

### Task 10: 建立 CI、Windows 启动烟测并同步 1.3.0 文档

**Files:**
- Create: `.github/workflows/quality.yml`
- Create: `tools/windows_release_smoke.ps1`
- Modify: `pubspec.yaml`
- Modify: `README.md`
- Modify: `RUN.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/README.md`
- Modify: `docs/plans/product_ia_data_plan.md`
- Create: `test/tooling/windows_release_smoke_contract_test.dart`

**Interfaces:**
- PowerShell: `tools/windows_release_smoke.ps1 -ReleaseDir <path> -TimeoutSeconds 15`。
- CI: Ubuntu job runs format check、analyze、test with coverage；Windows job builds release and runs smoke script。

- [ ] **Step 1: 写烟测脚本契约测试**

```dart
expect(script, contains('github_news.exe'));
expect(script, contains('flutter_windows.dll'));
expect(script, contains('data\\app.so'));
expect(script, contains('MainWindowHandle'));
expect(script, contains('TimeoutSeconds'));
```

- [ ] **Step 2: 运行测试并确认 RED**

Run: `rtk flutter test test/tooling/windows_release_smoke_contract_test.dart`

Expected: FAIL，因为脚本和 workflow 尚不存在。

- [ ] **Step 3: 实现 Windows 产物结构和启动检查**

脚本验证 exe、`flutter_windows.dll`、`data/app.so` 和 `data/flutter_assets`；启动 exe 后最多等待 15 秒，要求进程未退出且 `MainWindowHandle != 0`，随后在 finally 中关闭进程。失败时打印退出码、Release 文件清单和最近的 Application Error 事件。

- [ ] **Step 4: 添加双平台 GitHub Actions**

Ubuntu 使用 `subosito/flutter-action` stable，执行 `dart format --output=none --set-exit-if-changed .`、`flutter analyze`、`flutter test --coverage`。Windows 执行 `flutter build windows --release` 和烟测脚本，并在失败时上传 Release 目录与 smoke 日志。

- [ ] **Step 5: 更新版本和文档边界**

将 `pubspec.yaml`、README 和 RUN 统一为 `1.3.0+3`；CHANGELOG 记录真实实体集合、日均监控、缓存隔离、真实活动、OAuth/PAT、启动恢复、配置安全和 CI。文档明确监控仍是前台观测，活动来自 GitHub Events API，OAuth 仅在构建时配置 Client ID 后出现。

- [ ] **Step 6: 运行完整发布门禁**

Run:

```powershell
rtk dart format .
rtk flutter analyze
rtk flutter test --coverage
rtk flutter build windows --release
rtk powershell -NoProfile -ExecutionPolicy Bypass -File tools/windows_release_smoke.ps1 -ReleaseDir build/windows/x64/runner/Release -TimeoutSeconds 15
```

Expected: 所有命令 exit 0，测试 0 failure，Release 进程在超时前出现非零主窗口句柄。

- [ ] **Step 7: 提交、推送和远端一致性验证**

Commit: `Chore(release):发布可信本地闭环 1.3.0`

Run:

```powershell
rtk git push -u origin codex/product-trust-hardening
rtk git fetch origin
rtk git rev-parse HEAD
rtk git rev-parse origin/codex/product-trust-hardening
rtk git status --short --branch
```

Expected: 两个哈希完全相同，工作区干净；合并到主分支后再次验证 `main`、`origin/main` 和 GitHub 主分支哈希相同。
