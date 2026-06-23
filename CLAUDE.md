# Flutter 编码规范(通用)

本规范为通用 Flutter / Dart 编码规范,适用于任何 Flutter 项目。**项目专属约定**(技术栈选型、路由表、缓存策略等)请见项目根目录的 `README.md`。

> 提交前必须通过 `dart format . && flutter analyze && flutter test`。

---

## 一、目录结构

推荐 **Feature-first** 结构,通用骨架:

```
project/
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── main.dart                    # 入口,仅做 bootstrap
│   ├── app.dart                     # MaterialApp.router + 主题注入
│   ├── core/                        # 跨特性通用能力
│   │   ├── network/                 # HTTP 客户端与拦截器
│   │   ├── storage/                 # 本地数据库与键值存储
│   │   ├── theme/                   # 设计 token(颜色/字体/间距)
│   │   ├── router/                  # 路由配置
│   │   ├── di/                      # 全局 Provider / 依赖装配
│   │   ├── errors/                  # 异常体系
│   │   └── utils/                   # 工具与扩展
│   ├── features/                    # 每个特性下三层
│   │   └── <feature>/  {data, domain, presentation}
│   └── shared/
│       ├── widgets/                 # 通用组件
│       └── extensions/              # 扩展方法
├── test/
└── integration_test/
```

**特性三层职责**:

| 层 | 内容 | 约束 |
|---|---|---|
| `domain/` | Entity + Repository 抽象 | 纯 Dart,零 Flutter / 零 IO 依赖 |
| `data/` | Repository 实现 + DataSource(remote/local) + DTO | 负责异常转换与缓存策略 |
| `presentation/` | Page / Widget / Notifier | 只依赖 domain 层,不直接 import data 层 |

> **务实 Clean Architecture**:UseCase 合并进 Repository。Domain 仅在跨特性复用或需要纯 Dart 单测时存在,小型特性可省略。

---

## 二、命名规范

| 类型 | 规则 | 示例 |
|---|---|---|
| 类、枚举、typedef、mixin | UpperCamelCase | `TrendingRepository`、`RepoEntity` |
| 库、包、目录、文件 | snake_case | `trending_repository.dart`、`star_trend_chart.dart` |
| 变量、方法、参数 | lowerCamelCase | `repoName`、`fetchTrending()` |
| 常量 | lowerCamelCase(`const` 声明) | `const cacheTtlTrending = Duration(minutes: 5);` |
| 布尔值 | 带 `is` / `has` / `can` / `should` 前缀 | `isLoading`、`hasMore`、`canRetry` |
| 私有成员 | 下划线前缀 | `_internalState`、`_sub` |
| 枚举值 | lowerCamelCase | `Status.loading`、`AppExceptionKind.rateLimit` |
| 文件与主类同名 | 一文件一主类 | `home_page.dart` → `HomePage` |

---

## 三、代码风格

### 1. `const` 优先

```dart
// ✅
const SizedBox(height: 8);
const Padding(padding: EdgeInsets.all(16));
const items = <String>[];

// ❌
SizedBox(height: 8);
final items = List<String>();
```

### 2. 字符串插值优先于拼接

```dart
'Hello, $name! Score: ${user.score}'     // ✅
'Hello, ' + name + '! Score: ' + user.score.toString()  // ❌
```

### 3. 空安全用 `??` / `?.` / `?:`

```dart
final name = user?.name ?? 'Unknown';    // ✅
final name = user != null ? user.name : 'Unknown';  // ❌
```

### 4. 级联与集合字面量

```dart
final paint = Paint()
  ..color = Colors.black
  ..strokeWidth = 5.0;

final tiles = [
  for (final r in repos) RepoTile(repo: r),
  if (hasMore) const LoadMoreTile(),
];
```

### 5. `final` 优先,只在需要重赋时用 `var`

---

## 四、Widget 规范

### 1. 拆分阈值

- 单个 `build` 方法 **超过 80 行** 必须拆
- 单个 `.dart` 文件 **超过 300 行** 必须拆
- 优先拆为**私有 Widget 类**(`class _Xxx extends StatelessWidget`),不要拆成返回 Widget 的方法(后者破坏 `const` 优化与 rebuild 范围)

```dart
// ✅
class _RepoAvatar extends StatelessWidget {
  const _RepoAvatar({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) =>
      CircleAvatar(backgroundImage: NetworkImage(url));
}

// ❌
Widget _buildAvatar() => CircleAvatar(...);
```

### 2. 构造参数顺序

`key` → 必填 → 可选 → 回调。

### 3. 不变 Widget 一律 `const`;高频重绘区域用 `RepaintBoundary` 隔离

### 4. 列表性能

- `ListView.builder` / `GridView.builder` 必须指定 `itemExtent` 或 `prototypeItem`
- 禁止 `Column + SingleChildScrollView` 渲染长列表
- 图片统一 `cached_network_image` + 占位 + 错误图

### 5. 响应式布局

按 Material 3 断点分档,在 Widget 内通过 `LayoutBuilder` / `MediaQuery` / 自定义 `Breakpoint` 工具判定:

| 断点 | 宽度区间(dp) | 典型设备 | 导航 |
|---|---|---|---|
| Compact(手机) | `< 600` | 手机竖屏 | 底部 NavigationBar |
| Medium(平板) | `600 – 1024` | 平板、小屏桌面 | 侧边 NavigationRail(紧凑) |
| Expanded(桌面) | `>= 1024` | 桌面、笔电、折叠屏展开 | 侧边 NavigationRail(展开) + 多栏 |

> 列表宽度跨档变化时,优先用 `GridView.builder` 的 `crossAxisCount` 调整列数,而不是重建为多页面。

---

## 五、状态管理

跨组件状态推荐 **Riverpod**(`AsyncNotifier` / `Provider` / `Notifier`),业务页避免 `setState`。

### 1. Provider 命名

| 类型 | 命名 | 示例 |
|---|---|---|
| `AsyncNotifierProvider` | `<feature>NotifierProvider` | `trendingNotifierProvider` |
| `Provider`(只读) | `<name>Provider` | `dioProvider`、`trendingRepoProvider` |
| `NotifierProvider` | `<feature>ControllerProvider` | `themeModeControllerProvider` |
| `family` | `<name>Provider.family<Args, T>` | `repoDetailProvider.family<String, RepoEntity>` |

### 2. 三种 Notifier 的选择

| 场景 | 选择 |
|---|---|
| 页面级数据加载/刷新 | `AsyncNotifier<T>` + `AsyncNotifierProvider` |
| 派生/组合数据 | `Provider<T>` 内部 `ref.watch(...)` 组合 |
| 全局开关/筛选 | `Notifier<T>` + `NotifierProvider` |

### 3. UI 用 `AsyncValue.when`

```dart
final state = ref.watch(trendingNotifierProvider);
return state.when(
  data: (repos) => RepoList(repos: repos),
  loading: () => const TrendingSkeleton(),
  error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(trendingNotifierProvider)),
);
```

### 4. 生命周期

- 需要 `Timer` / `StreamSubscription` 的 Notifier,重写 `ref.onDispose` 释放
- 路由参数变化导致数据重载:用 `family` 或 `ref.watch(argProvider)`

---

## 六、异步与错误处理

### 1. 异常分层(推荐范式)

```
DataSourceException (HTTP / 解析 / DB 原始异常)
        ↓ Repository 边界转换
AppException { kind, cause, stack }
        ↓ Notifier 透传
AsyncValue.error(AppException, StackTrace)
        ↓ UI
ErrorView 根据 kind 渲染对应提示
```

**禁止**:
- 在 Notifier / Widget 内 `catch (_) {}` 吞异常
- 把底层异常(网络 / 解析 / 数据库)直接抛到 UI 层

### 2. 精确 catch

```dart
// ✅
try {
  await api.fetchTrending();
} on DioException catch (e, st) {
  throw e.toAppException();
} on FormatException catch (e, st) {
  throw AppException(kind: AppExceptionKind.parse, cause: e);
}

// ❌
try { ... } catch (_) {}
```

### 3. 独立并发用 `Future.wait`

```dart
final results = await Future.wait([
  ref.read(trendingRepoProvider).getTrending(),
  ref.read(localStatsProvider).getDaily(),
]);
```

### 4. 资源释放

`StreamSubscription` / `Timer` / `TextEditingController` 一律在 `dispose()` 或 `ref.onDispose` 释放。

### 5. 超时与重试

集中在 HTTP 拦截器中:
- 默认超时 10s,Repository 可覆盖
- 5xx / 网络错误重试 2 次,指数退避(500ms / 1500ms)
- 429 不重试,把 `Retry-After` 写入异常元数据

---

## 七、数据模型

### 1. Entity vs DTO

- **Entity**(domain 层,纯 Dart):不可变,业务语义,`freezed`
- **DTO**(data 层):与 API JSON 一一对应,`fromJson` / `toJson` 在 DTO 上,Entity 构造函数转换

### 2. `freezed` 模板

```dart
@freezed
class RepoEntity with _$RepoEntity {
  const factory RepoEntity({
    required String fullName,
    required String description,
    @Default(0) int starCount,
    @Default(0) int forkCount,
    DateTime? updatedAt,
  }) = _RepoEntity;
}
```

### 3. 不可变集合 / 时间类型

时间用 `DateTime`(UTC 存储,展示时区转换)。`Set` / `List` 等可变集合不要放进 Entity。

---

## 八、依赖注入

通过 **Provider / GetIt / 构造函数注入**,Widget 只 `watch` / `read`,不 `new` Service / Repo。

```dart
final dioProvider = Provider<Dio>((ref) => DioClient.create(ref));

final trendingRepoProvider = Provider<TrendingRepository>((ref) {
  return TrendingRepositoryImpl(ref.watch(githubApiProvider), ref.watch(repoCacheDaoProvider));
});
```

---

## 九、路由

- 顶层 Tab 用 `StatefulShellRoute.indexedStack`,每个分支独立导航栈
- 路径全小写下划线:`/repo_detail`、`/monitor/new`
- 详情/子页:嵌套 `GoRoute`(子路由),不 push 到根
- 深链 fallback:未匹配路由跳到根 Tab
- 推荐 `go_router_builder` 生成类型安全跳转

---

## 十、平台差异

- 默认实现跨平台共用,只在必要时拆
- 平台判断收敛到 `core/platform/` 扩展,UI 通过扩展调用,不直接 `Platform.isXxx`
- 桌面端特性(右键菜单、窗口大小监听)写在平台扩展内

---

## 十一、错误与空状态

每个页面必须实现四态:`loading` / `data` / `error` / `empty`。

- `loading`:`const Skeleton()`
- `empty`:`EmptyView(icon, message, action?)`
- `error`:`ErrorView(error, onRetry)`,根据异常 `kind` 渲染不同文案与操作

---

## 十二、主题与资源

- 设计 Token(颜色 / 字体 / 间距 / 圆角)集中在 `core/theme/`,**禁止裸值**
- 资源命名:`ic_xxx.png` / `bg_xxx.png` / `img_xxx.png`,多分辨率 `2x` / `3x`

---

## 十三、注释

- **公共 API** 必须 `///` 文档注释
- 注释写**为什么**,不写**是什么**
- TODO 格式:`// TODO(yourname): 描述`

```dart
/// 加载仓库 Star 历史(增量缓存)
///
/// 失败时抛出 [AppException.kind == notFound | network]。
Future<List<StarPoint>> getStarHistory(String owner, String name);
```

---

## 十四、测试

### 1. 范围与目标

- 核心逻辑覆盖率 **≥ 70%**
- **Repository**:`mocktail` mock DataSource,验证异常转换与缓存命中
- **Notifier**:`ProviderContainer.test` + `overrideWith`,验证 `AsyncValue` 流转
- **Widget**:核心页面 `testWidgets`,关键截图 `golden` 测试

### 2. 命名与结构

- 文件路径与源码镜像:`test/features/<feature>/data/<thing>_test.dart`
- 用例命名:`test('should <行为> when <条件>', () {})`
- AAA 模式(Arrange / Act / Assert),空行分段

### 3. 集成测试

`integration_test/` 目录,跨特性场景。

---

## 十五、Lint(`analysis_options.yaml`)

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude: ["build/**", "**/*.g.dart", "**/*.freezed.dart"]
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    avoid_print: true
    prefer_final_locals: true
    prefer_single_quotes: true
    require_trailing_commas: true
    sort_constructors_first: true
    sort_unnamed_constructors_first: true
    avoid_dynamic_calls: true
    use_super_parameters: true
    unawaited_futures: true
```

---

## 十六、Git 规范

### 1. 提交前必跑

```bash
dart format .
flutter analyze
flutter test
```

### 2. Commit 格式(Conventional Commits)

`<type>(<scope>): <subject>`

- `type`:`feat` / `fix` / `refactor` / `test` / `docs` / `chore` / `perf`
- `scope`:模块名(如 `trending`、`monitor`、`core-network`)
- `subject`:中文祈使句,不超 50 字

示例:`feat(trending): 新增按语言筛选功能`

### 3. 分支

- `feat/<feature>` / `fix/<issue>` / `hotfix/<issue>` / `chore/<task>`
- 主干:`main`,保护分支,需 PR
