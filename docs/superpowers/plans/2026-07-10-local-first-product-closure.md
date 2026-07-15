# Local-First Product Closure Implementation Plan

> Historical snapshot: this plan targeted `1.2.0+2`; its four-tab compact shell was the decision at that time. The current `1.4.0+4` plus `Unreleased` baseline uses five mobile destinations. See the current [product and data boundary](../../plans/product_ia_data_plan.md) and [README](../../../README.md).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn GitHub 情报站 into an honest, complete local-first desktop client with foreground rule evaluation, durable alerts, consistent data trust labels, a four-tab compact shell, aligned release docs, and verified Windows output.

**Architecture:** Keep the existing feature-first/Riverpod structure. Add pure monitor domain services, a SQLite alert store, JSON-backed daily observations, transport-level freshness wrappers, and a Core repository-feed contract; do not add a backend or background scheduler. Migrate incrementally behind existing providers so every task remains testable.

**Tech Stack:** Flutter 3.22+, Dart 3.4+, Riverpod 2.x, go_router 17.x, Dio 5.x, sqflite_common_ffi, SharedPreferences, flutter_secure_storage, flutter_test, mocktail.

## Global Constraints

- Windows desktop remains the implementation priority.
- Do not add a backend, cloud sync, scheduled service, email delivery, tray process, or new remote data source.
- Compact navigation exposes exactly Today, AI, Project, Settings.
- Foreground checks use real observations only; cached or seed data never creates alerts.
- GitHub Token remains in Secure Storage.
- Production Dart files stay below 300 lines where practical; i18n maps and mechanical seed/codecs are exempt.
- Every behavior change starts with a failing focused test.
- Final version is `1.2.0+2`.
- Final commands are `rtk dart format .`, `rtk flutter analyze`, `rtk flutter test`, and `rtk flutter build windows --release`.

---

## File Structure

**Create:**

- `lib/core/domain/data_freshness.dart` — response freshness, metric basis, and `DataResult<T>`.
- `lib/core/domain/repository_feed.dart` — Core report input contract.
- `lib/core/github/github_resource_cache.dart` — URL-scoped ETag payload cache.
- `lib/features/monitor/domain/monitor_observation.dart` — daily observation model.
- `lib/features/monitor/domain/monitor_rule.dart` — stable rule definitions.
- `lib/features/monitor/domain/monitor_rule_evaluator.dart` — pure threshold evaluation.
- `lib/features/monitor/data/monitor_observation_dao.dart` — 90-day JSON observation history.
- `lib/features/monitor/data/monitor_alert_event_dao.dart` — durable SQLite alert CRUD/status.
- `test/core/domain/data_freshness_test.dart`.
- `test/core/github/github_resource_cache_test.dart`.
- `test/core/router/route_specs_test.dart`.
- `test/features/monitor/domain/monitor_rule_evaluator_test.dart`.
- `test/features/monitor/data/monitor_observation_dao_test.dart`.
- `test/features/monitor/data/monitor_alert_event_dao_test.dart`.

**Modify:** routing, monitor repositories/providers/pages, storage schema/providers, GitHub repositories, shared provenance badge, project DI, i18n copy, version and project documentation.

---

### Task 1: Compact Navigation and Honest Capability Copy

**Files:**
- Create: `test/core/router/route_specs_test.dart`
- Modify: `lib/core/router/route_specs.dart`
- Modify: `lib/shared/widgets/responsive_scaffold.dart`
- Modify: `lib/core/i18n/strings_zh_cn.dart`
- Modify: `lib/core/i18n/strings_en_us.dart`
- Modify: `lib/features/monitor/application/monitor_settings_controller.dart`
- Modify: `lib/features/monitor/presentation/monitor_settings_page.dart`

**Interfaces:**
- Produces: `mobileAppTabs: List<MobileTabSpec>` and `mobileDestinationIndex(int branchIndex)`.
- Produces: one supported in-app alert setting; removes unsupported mail/report switches.

- [ ] **Step 1: Write the failing navigation test**

```dart
test('compact IA maps eight desktop branches into four destinations', () {
  expect(mobileAppTabs.map((e) => e.branchIndex), [0, 1, 2, 7]);
  expect(mobileDestinationIndex(0), 0);
  expect(mobileDestinationIndex(1), 1);
  for (final branch in [2, 3, 4, 5, 6]) {
    expect(mobileDestinationIndex(branch), 2);
  }
  expect(mobileDestinationIndex(7), 3);
});
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `rtk flutter test test/core/router/route_specs_test.dart`

Expected: compile failure because `mobileAppTabs` is undefined.

- [ ] **Step 3: Implement the four-tab mapping**

```dart
class MobileTabSpec {
  const MobileTabSpec({required this.labelKey, required this.branchIndex});
  final String labelKey;
  final int branchIndex;
}

const mobileAppTabs = <MobileTabSpec>[
  MobileTabSpec(labelKey: 'mobile.today', branchIndex: 0),
  MobileTabSpec(labelKey: 'mobile.ai', branchIndex: 1),
  MobileTabSpec(labelKey: 'mobile.project', branchIndex: 2),
  MobileTabSpec(labelKey: 'mobile.settings', branchIndex: 7),
];

int mobileDestinationIndex(int branchIndex) => switch (branchIndex) {
  0 => 0,
  1 => 1,
  7 => 3,
  _ => 2,
};
```

- [ ] **Step 4: Render only `mobileAppTabs` in `_BottomBar`**

Pass destination indexes to `navigationShell.goBranch`; use `mobileDestinationIndex` for the selected bottom index. Keep medium/expanded on all eight `appTabs`.

- [ ] **Step 5: Remove unsupported copy and settings**

Use “打开应用时检查” and “应用内告警中心”. Change `monitorNotificationCount` to 1 and migrate any previous list to `[old.firstOrNull ?? true]`. Remove mail/daily/weekly/cross-device/push claims from zh-CN and en-US strings.

- [ ] **Step 6: Run focused tests**

Run: `rtk flutter test test/core/router/route_specs_test.dart test/features/monitor/application/monitor_settings_controller_test.dart`

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/core/router lib/shared/widgets/responsive_scaffold.dart lib/core/i18n lib/features/monitor test/core/router test/features/monitor/application
git commit -m "Fix(product):收敛本地能力口径与移动端导航"
```

---

### Task 2: Data Freshness and Metric Basis Types

**Files:**
- Create: `lib/core/domain/data_freshness.dart`
- Create: `test/core/domain/data_freshness_test.dart`
- Modify: `lib/core/domain/repo_entity.dart`
- Modify: `lib/shared/widgets/data_provenance_badge.dart`
- Modify: `test/shared/widgets/data_provenance_badge_test.dart`

**Interfaces:**
- Produces: `enum DataFreshness { live, freshCache, staleCache, seed }`.
- Produces: `enum MetricBasis { observed, estimated, seed }`.
- Produces: `class DataResult<T> { T data; DataFreshness freshness; }`.
- Produces: `RepoEntity.valueBasis` and `RepoEntity.trendBasis`.

- [ ] **Step 1: Write failing round-trip tests**

```dart
test('DataResult maps data without losing freshness', () {
  const source = DataResult(data: 2, freshness: DataFreshness.staleCache);
  final mapped = source.map((value) => '$value');
  expect(mapped.data, '2');
  expect(mapped.freshness, DataFreshness.staleCache);
});

test('unknown enum names use safe seed defaults', () {
  expect(DataFreshness.fromName('unknown'), DataFreshness.seed);
  expect(MetricBasis.fromName('unknown'), MetricBasis.seed);
});
```

- [ ] **Step 2: Run the test and confirm compile failure**

Run: `rtk flutter test test/core/domain/data_freshness_test.dart`

- [ ] **Step 3: Implement the types**

```dart
class DataResult<T> {
  const DataResult({required this.data, required this.freshness});
  final T data;
  final DataFreshness freshness;
  DataResult<R> map<R>(R Function(T value) convert) =>
      DataResult(data: convert(data), freshness: freshness);
}
```

Add localized label/tooltip getters through the shared badge. Keep `DataProvenance` temporarily as a compatibility decoder until every cache codec is migrated in Task 7.

- [ ] **Step 4: Add basis fields without breaking codecs**

Map old `live` to `observed`, old `estimated` to `estimated`, and old `seed` to `seed`. Add deprecated provenance getters only while migrating callers.

- [ ] **Step 5: Run focused tests**

Run: `rtk flutter test test/core/domain/data_freshness_test.dart test/core/domain/data_provenance_test.dart test/shared/widgets/data_provenance_badge_test.dart`

- [ ] **Step 6: Commit**

```bash
git add lib/core/domain lib/shared/widgets/data_provenance_badge.dart test/core/domain test/shared/widgets/data_provenance_badge_test.dart
git commit -m "Refactor(domain):拆分数据新鲜度与指标口径"
```

---

### Task 3: Pure Foreground Monitor Rule Evaluator

**Files:**
- Create: `lib/features/monitor/domain/monitor_observation.dart`
- Create: `lib/features/monitor/domain/monitor_rule.dart`
- Create: `lib/features/monitor/domain/monitor_rule_evaluator.dart`
- Create: `test/features/monitor/domain/monitor_rule_evaluator_test.dart`
- Modify: `lib/features/monitor/domain/entities.dart`

**Interfaces:**
- Consumes: current and previous `MonitorObservation`.
- Produces: `List<MonitorAlertEvent> evaluate(...)`.
- Stable IDs: `repo|ruleId|yyyy-MM-dd`.

- [ ] **Step 1: Write failing threshold tests**

Cover first observation, below/exact/above threshold for all four rules, disabled rules, negative deltas, and stable same-day IDs.

```dart
final events = const MonitorRuleEvaluator().evaluate(
  previous: observation(stars: 1000, forks: 10, issues: 2, day: 1),
  current: observation(stars: 1200, forks: 60, issues: 14, day: 2),
  enabledRuleIds: const {
    MonitorRuleIds.starDailyDelta,
    MonitorRuleIds.forkDailyDelta,
    MonitorRuleIds.issueHeatRatio,
  },
);
expect(events.map((e) => e.ruleId), contains(MonitorRuleIds.starDailyDelta));
```

- [ ] **Step 2: Run and confirm failure**

Run: `rtk flutter test test/features/monitor/domain/monitor_rule_evaluator_test.dart`

- [ ] **Step 3: Implement pure models and evaluator**

Use exact thresholds 200 stars, 10 percent, 50 forks, and 5x issue ratio. Reject evaluation when observations are on the same local date. Clamp negative changes to zero.

- [ ] **Step 4: Run the evaluator tests**

Expected: all evaluator tests pass without Flutter bindings.

- [ ] **Step 5: Commit**

```bash
git add lib/features/monitor/domain test/features/monitor/domain
git commit -m "Feat(monitor):实现前台监控规则计算器"
```

---

### Task 4: Daily Monitor Observation Storage

**Files:**
- Create: `lib/features/monitor/data/monitor_observation_dao.dart`
- Create: `test/features/monitor/data/monitor_observation_dao_test.dart`
- Modify: `lib/core/storage/storage_providers.dart`

**Interfaces:**
- Produces: `record(MonitorObservation)`, `latestBefore(repo, day)`, and `read(repo)`.
- Persists under `monitor_observation:v1:<lowercase repo>` in `JsonSnapshotCacheDao`.

- [ ] **Step 1: Write failing DAO tests**

Test no history, same-day overwrite, different-day ordering, latest previous point, malformed payload recovery, and 90-point cap.

- [ ] **Step 2: Run and confirm failure**

Run: `rtk flutter test test/features/monitor/data/monitor_observation_dao_test.dart`

- [ ] **Step 3: Implement the DAO**

Use local `yyyy-MM-dd` as the replacement key and UTC ISO-8601 for timestamps. On malformed payload, delete only the corrupt key and return an empty history.

- [ ] **Step 4: Run storage tests**

Run: `rtk flutter test test/features/monitor/data/monitor_observation_dao_test.dart test/core/storage/json_snapshot_cache_dao_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/features/monitor/data/monitor_observation_dao.dart lib/core/storage/storage_providers.dart test/features/monitor/data/monitor_observation_dao_test.dart
git commit -m "Feat(monitor):保存仓库每日真实观测"
```

---

### Task 5: Durable Monitor Alert Events

**Files:**
- Modify: `lib/core/storage/database_schema.dart`
- Modify: `lib/core/storage/local_database.dart`
- Create: `lib/features/monitor/data/monitor_alert_event_dao.dart`
- Create: `test/features/monitor/data/monitor_alert_event_dao_test.dart`
- Modify: `lib/core/storage/storage_providers.dart`
- Replace: `lib/features/monitor/application/monitor_alert_state_controller.dart`

**Interfaces:**
- Produces: `upsertAll`, `list({includeArchived})`, `markRead`, `markAllRead`, `archive`, `archiveRead`, `restoreAll`.
- Provider exposes `AsyncNotifier<List<MonitorAlertEvent>>`.

- [ ] **Step 1: Write failing schema/DAO tests**

Assert v4 creates `monitor_alert_event`; upsert is idempotent; read/archive timestamps persist; sorting is newest-first; pruning keeps 500; `clearAll()` cache cleanup preserves alert rows.

- [ ] **Step 2: Run and confirm failure**

Run: `rtk flutter test test/features/monitor/data/monitor_alert_event_dao_test.dart test/core/storage/local_database_test.dart`

- [ ] **Step 3: Add schema v4**

Create the table and indexes on `observed_at`, `archived_at`, and `(repo_full_name, rule_id)`. Exclude the table from `_kBusinessTables` because that list is the cache-clear list.

- [ ] **Step 4: Implement DAO and controller**

Use database transactions for multi-row upsert and bulk status changes. Make the controller reload from SQLite after every mutation.

- [ ] **Step 5: Run focused tests**

Run: `rtk flutter test test/features/monitor/data/monitor_alert_event_dao_test.dart test/features/monitor/application/monitor_alert_state_controller_test.dart test/core/storage/local_database_test.dart`

- [ ] **Step 6: Commit**

```bash
git add lib/core/storage lib/features/monitor/data/monitor_alert_event_dao.dart lib/features/monitor/application/monitor_alert_state_controller.dart test/core/storage test/features/monitor
git commit -m "Feat(monitor):持久化告警事件与处理状态"
```

---

### Task 6: Monitor Repository and UI Integration

**Files:**
- Modify: `lib/features/monitor/data/github_monitor_repository.dart`
- Modify: `lib/features/monitor/domain/monitor_repository.dart`
- Modify: `lib/features/monitor/application/monitor_providers.dart`
- Modify: `lib/features/monitor/presentation/monitor_page.dart`
- Modify: `lib/features/monitor/presentation/monitor_alerts_page.dart`
- Modify: `lib/features/monitor/presentation/monitor_detail_page.dart`
- Modify: `lib/features/monitor/widgets/monitor_alert_list_tile.dart`
- Test: `test/features/monitor/application/monitor_providers_test.dart`

**Interfaces:**
- Repository returns `DataResult<MonitorDigest>` and exposes `forceRefresh()` or accepts `force`.
- Remote success writes observations, evaluates rules, persists events, and returns stored alerts.

- [ ] **Step 1: Write failing integration tests**

Test cache hit does not record/evaluate; remote success does; remote/limit fallback does not; manual refresh deletes only the active key; partial repo failure keeps successful results; repeated same-day refresh deduplicates events.

- [ ] **Step 2: Run and confirm failure**

Run: `rtk flutter test test/features/monitor/application/monitor_providers_test.dart`

- [ ] **Step 3: Inject evaluator and DAOs**

Add `MonitorObservationDao`, `MonitorAlertEventDao`, enabled rule IDs, and `DataFreshness` to repository construction. Remove `_alertsFor`, because alerts now come only from persisted rule events.

- [ ] **Step 4: Update UI state**

Render durable event timestamps and read/archive state from the async alert controller. Page headers show “实时检查 / 新鲜缓存 / 陈旧缓存 / 本地种子”.

- [ ] **Step 5: Run monitor tests**

Run: `rtk flutter test test/features/monitor`

- [ ] **Step 6: Commit**

```bash
git add lib/features/monitor test/features/monitor
git commit -m "Feat(monitor):接通真实观测规则与应用内告警"
```

---

### Task 7: Migrate All Remote Digests to DataResult

**Files:**
- Modify: `lib/features/ai_news/application/ai_news_providers.dart`
- Modify: `lib/features/ai_news/data/remote_ai_news_repository.dart`
- Modify: `lib/features/trending/domain/trending_repository.dart`
- Modify: `lib/features/trending/data/cached_trending_data_source.dart`
- Modify: `lib/features/trending/application/trending_providers.dart`
- Modify: `lib/features/tech_hotspot/domain/tech_hotspot_models.dart`
- Modify: `lib/features/tech_hotspot/data/github_tech_hotspot_repository.dart`
- Modify: `lib/features/tech_hotspot/application/tech_hotspot_providers.dart`
- Modify: `lib/features/discover/domain/discover_entities.dart`
- Modify: `lib/features/discover/data/discover_repository.dart`
- Modify: `lib/features/discover/application/discover_providers.dart`
- Modify: `lib/features/monitor/domain/monitor_repository.dart`
- Modify: `lib/features/monitor/data/github_monitor_repository.dart`
- Modify: `lib/features/monitor/application/monitor_providers.dart`
- Modify: `lib/features/repo_detail/domain/repo_detail_repository.dart`
- Modify: `lib/features/repo_detail/data/github_repo_detail_repository.dart`
- Modify: `lib/features/repo_detail/application/repo_detail_providers.dart`
- Modify: `lib/features/project/domain/project_repository.dart`
- Modify: `lib/features/project/data/github_project_repository.dart`
- Modify: `lib/features/project/application/project_providers.dart`
- Modify: the corresponding cache codecs and page headers in those feature directories.
- Test: the existing application/repository/widget tests under `test/features/<feature>/`.

**Interfaces:**
- All remote repository entry points return `DataResult<T>`.
- Cache codecs persist metric basis, not response freshness.

- [ ] **Step 1: Add failing freshness tests per feature**

For each feature, cover remote success=`live`, valid cache=`freshCache`, remote failure with expired cache=`staleCache`, and no cache fallback=`seed`.

- [ ] **Step 2: Run the feature tests and confirm failures**

Run: `rtk flutter test test/features/ai_news test/features/trending test/features/tech_hotspot test/features/discover test/features/monitor test/features/repo_detail test/features/project`

- [ ] **Step 3: Migrate one feature at a time**

Update signatures, providers, codecs and UI in this order: AI news, trending, tech hotspot, discover, monitor, repo detail, project. Delete compatibility provenance fields after the last caller is migrated.

- [ ] **Step 4: Verify no mixed provenance remains**

Run: `rtk rg "DataProvenance|valueProvenance|trendProvenance" lib`

Expected: no production matches outside an explicit backward-compatible cache decoder, which is deleted after migration tests pass.

- [ ] **Step 5: Run all feature tests**

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add lib test
git commit -m "Refactor(data):统一远端新鲜度与趋势计算口径"
```

---

### Task 8: URL-Scoped GitHub ETag Cache

**Files:**
- Create: `lib/core/github/github_resource_cache.dart`
- Create: `test/core/github/github_resource_cache_test.dart`
- Modify: `lib/features/repo_detail/data/github_repo_detail_repository.dart`
- Modify: `lib/features/project/data/github_project_repository.dart`
- Modify: `lib/features/discover/data/discover_repository.dart`

**Interfaces:**
- Produces: `Future<DataResult<Map<String, Object?>>> getObject(...)` and `Future<DataResult<List<Object?>>> getList(...)`.
- Cache key includes token scope, HTTP method, and URL.

- [ ] **Step 1: Write failing 200/304 tests**

Use a Dio adapter to prove: 200 stores payload+ETag; second request sends `If-None-Match`; 304 returns cache and refreshes metadata; 304 without payload throws cache error; malformed cached payload is deleted and retried without ETag.

- [ ] **Step 2: Run and confirm failure**

Run: `rtk flutter test test/core/github/github_resource_cache_test.dart`

- [ ] **Step 3: Implement the cache helper**

Use existing `JsonSnapshotCacheDao.readWithEtag/upsertWithEtag` and `GitHubApiSupport.headers(token:, etag:)`. Do not apply it to Search digests.

- [ ] **Step 4: Integrate resource endpoints**

Use the helper for `/repos/{name}`, `/repos/{name}/contributors`, and `/users/{login}`. Preserve repository-level stale fallback.

- [ ] **Step 5: Run GitHub repository tests**

Run: `rtk flutter test test/core/github test/features/repo_detail test/features/project test/features/discover`

- [ ] **Step 6: Commit**

```bash
git add lib/core/github lib/features/repo_detail lib/features/project lib/features/discover test/core/github test/features
git commit -m "Feat(github):接入单资源 ETag 缓存"
```

---

### Task 9: Project Dependency Boundary and File Splits

**Files:**
- Create: `lib/core/domain/repository_feed.dart`
- Create: `lib/features/discover/data/discover_queries.dart`
- Create: `lib/features/discover/data/discover_profile_client.dart`
- Create: `lib/features/discover/data/discover_cache_codec.dart`
- Create: `lib/features/profile/presentation/widgets/device_flow_content.dart`
- Create: `lib/features/profile/presentation/widgets/profile_preferences_sections.dart`
- Create: `lib/core/router/app_route_branches.dart`
- Modify: `lib/core/di/feature_providers.dart`
- Modify: `lib/features/project/data/local_project_repository.dart`
- Modify: `lib/features/project/data/github_project_repository.dart`
- Split: `lib/features/discover/data/discover_repository.dart`
- Split: `lib/features/profile/presentation/login_page.dart`
- Split: `lib/features/profile/presentation/widgets/profile_settings_card.dart`
- Split: `lib/core/router/app_router.dart`

**Interfaces:**
- Produces: `abstract interface class RepositoryFeed { Future<DataResult<RepositoryFeedDigest>> load(); }`.
- Project repositories depend only on `RepositoryFeed` and Core entities.

- [ ] **Step 1: Write a failing Project boundary test**

Construct Project repository with a fake `RepositoryFeed`; assert repos/trends are carried through without importing a Trending implementation.

- [ ] **Step 2: Implement the Core adapter and move DI wiring**

The composition root may import both feature implementations; project data/domain files may not import `features/trending`.

- [ ] **Step 3: Verify the import boundary**

Run: `rtk rg "\.\./\.\./trending" lib/features/project`

Expected: no matches.

- [ ] **Step 4: Split oversized production files**

Move query construction, profile fetching/codecs, login state widgets, settings sections, and router branch builders into focused sibling files. Preserve public class names.

- [ ] **Step 5: Verify file size policy**

Run a PowerShell line-count query and assert no non-i18n/non-seed production file exceeds 300 lines.

- [ ] **Step 6: Run affected tests and commit**

```bash
git add lib test
git commit -m "Refactor(arch):收敛跨模块依赖与超长文件"
```

---

### Task 10: Release Documentation and Final Verification

**Files:**
- Modify: `pubspec.yaml`
- Modify: `README.md`
- Modify: `RUN.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/plans/product_ia_data_plan.md`
- Modify: `docs/README.md`

**Interfaces:** None; this task aligns the release contract with implemented behavior.

- [ ] **Step 1: Set `version: 1.2.0+2`**

- [ ] **Step 2: Update documentation facts**

Document eight desktop entries, four compact tabs, foreground-only monitoring, durable local alerts, split TTL values, secure Token storage, explicit freshness/basis labels, and the absence of cloud sync/email/background jobs.

- [ ] **Step 3: Run stale-claim scans**

```bash
rtk rg "7 个主入口|邮件摘要|每日报告|周报推送|跨设备|实时告警推送|1GB|1 GB" README.md RUN.md CHANGELOG.md docs lib/core/i18n
```

Expected: no unsupported current-capability claims; historical changelog entries must be labeled historical or corrected.

- [ ] **Step 4: Run formatting and static analysis**

```bash
rtk dart format .
rtk flutter analyze
```

Expected: no formatting diff and no analyzer issues.

- [ ] **Step 5: Run all tests**

Run: `rtk flutter test`

Expected: zero failures.

- [ ] **Step 6: Build Windows Release**

Run: `rtk flutter build windows --release`

Expected: `build/windows/x64/runner/Release/github_news.exe` exists and command exits 0.

- [ ] **Step 7: Audit requirements and repository state**

Verify every acceptance criterion in the design document, inspect `git diff --check`, and confirm only intentional changes remain.

- [ ] **Step 8: Commit final release alignment**

```bash
git add pubspec.yaml README.md RUN.md CHANGELOG.md docs lib test
git commit -m "Docs(release):同步本地优先产品能力与版本"
```

- [ ] **Step 9: Push active branch**

Run: `rtk git push origin main`

Expected: local `main` and remote `origin/main` resolve to the same commit.

---

## Self-Review Results

- Spec coverage: all nine acceptance requirements map to Tasks 1–10.
- Placeholder scan: complete; every implementation step names its concrete output.
- Type consistency: `DataResult<T>`, `DataFreshness`, `MetricBasis`, monitor models, DAOs, and `RepositoryFeed` are introduced before consumers.
- Scope: the work is large but sequentially coupled; every task produces a testable commit, and no backend/background scope is introduced.
