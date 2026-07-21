# Reusable Dart & Flutter Style Guide

Baseline conventions for Dart and Flutter projects. This file contains only
rules that can be reused across applications; product behavior, feature
architecture, concrete class names, platform targets, and repository commands
belong in each project's own documentation.

Mechanical rules belong in `analysis_options.yaml`; this file records
conventions that lint and formatting tools cannot fully enforce. Apply the
following precedence:

1. The Dart compiler, analyzer, and formatter configuration determine
   mechanically valid code.
2. A project-specific `AGENTS.md` or `CONTRIBUTING.md` may add or override
   architecture, product, workflow, and verification rules.
3. This guide supplies the reusable default when no project overlay exists.

## 1. Naming

| Kind | Convention | Example |
|---|---|---|
| Class, enum, typedef, mixin, extension | UpperCamelCase | `SessionController` |
| File and directory | lowercase_with_underscores | `session_controller.dart` |
| Variable, parameter, function | lowerCamelCase | `loadSettings()` |
| Private member | Leading underscore | `_parseValue()` |
| Constant, including `static const` | lowerCamelCase | `defaultTimeout` |
| Boolean | Adjective or `is` / `has` / `can` / `should` | `isFresh` |
| Enum value | lowerCamelCase | `LoadState.ready` |

Avoid unclear abbreviations (`btn`, `cfg`), Hungarian notation, and names that
shadow Dart SDK types such as `List`, `Future`, or `Record`.

## 2. Comments

- Do not use `///` doc comments; projects adopting this guide use block and line
  comments instead of dartdoc-style comments.
- Every class and method must have a `/* ... */` block comment explaining its
  purpose. The form depends on the declaration kind:
  - **Class, enum, mixin, extension, and typedef declarations** always use the
    multi-line form below, even when the comment is short. Type declarations
    are structural; their header comment should never collapse to one line.
  - **Methods and top-level functions** prefer the single-line form
    `/* 用途说明。 */` when the comment fits on one line (rough under ~200
    chars). Only expand to the multi-line form when the content genuinely
    needs multiple paragraphs or exceeds ~200 chars.
  The multi-line form is:
  ```
  /*
  *第一行:用途。
  *
  *第二段:细节、约束、注意事项。
  *  跨行续行用 2 空格缩进,保持视觉对齐。
  */
  ```
  The `/*` is followed by a space and a newline, each continuation line begins
  with `*` glued to the content (no separating space), and the block ends with
  `*/` on its own line. Do not split a logical comment into multiple adjacent
  `/* ... */` blocks.
- Member variables (fields) must carry a `//` line comment that explains
  intent, units, ownership, or constraints. Use `//`, not `/* ... */`:
  ```
  // 目标路由路径。
  final String route;
  ```
  Trivial locally-scoped fields whose name and initializer are self-evident
  (e.g. `final isLoading = false` inside a private widget) may skip the
  comment; when in doubt, write one.
- Enum case members use `//` line comments above each case, not `/* ... */`:
  ```
  enum SyncStatus {
    // 当前没有同步任务。
    idle,

    // 同步任务正在执行。
    running;
  }
  ```
- Local variables and parameters may use `//` line comments inline or above.
- Private code still needs a comment when intent, constraints, tradeoffs, or
  non-obvious fallbacks are not clear from the code itself.
- Magic numbers for timing, retry, cache, sizing, and limits need either a named
  constant or a short reason. Magic strings — API base URLs, request paths,
  HTTP header names and values, MIME types — must reference a shared constant,
  not be inlined as string literals.
- TODO format: `// TODO(owner, YYYY-MM-DD): actionable note`.
- Do not leave author, generated-by, or chat transcript comments in source.

## 2a. Control Flow

- Single-statement bodies of `if` / `else` / `for` / `while` / `do-while` must
  be wrapped in curly braces. Do not write `if (x) return;`; write
  `if (x) { return; }` (or the multi-line equivalent).
- When a control-flow body fits, place the body on its own line. Prefer:
  ```
  if (x) {
    return y;
  }
  ```
  over the one-line `if (x) { return y; }`. This matches `dart format`'s
  default line-break style and keeps diffs reviewer-friendly.

## 2b. Line Width And Trailing Commas

- The baseline formatter page width is 200. Projects adopting this guide should
  set `formatter: page_width: 200` in `analysis_options.yaml` and keep IDE or
  editor settings aligned with it.
- Run the formatting command defined by the project before commit. A Dart-only
  repository may use `dart format .`; a mixed-language repository should scope
  formatting to its Dart source and test directories.
- **Argument-count rule (overrides the single-line preference below):**
  - **4 or more arguments**: always multi-line with a trailing comma,
    even if the whole call fits on one line under 200 chars. Four-plus
    args on one line are too dense to scan; density does not justify
    crushing them together.
  - **3 arguments**: single-line if the full line (with indent) is under
    180 chars; otherwise multi-line with a trailing comma.
  - **1-2 arguments**: single-line if the full line is under 200 chars;
    otherwise multi-line with a trailing comma.
  - "Argument" counts top-level parameters of a call, declaration, or
    literal. A single named-parameter block `{a, b, c, d}` counts as 4
    arguments, not 1.
- Do NOT add a trailing comma to a single-line construct that should
  stay single-line. A trailing comma forces `dart format` to expand to
  multi-line.
- For multi-line constructs, write them WITH a trailing comma before the
  closing bracket so `dart format` uses 2-space block indent and puts
  the closing bracket on its own line:
  ```
  return RetryPolicy(
    maxAttempts: maxAttempts,
    delay: retryDelay,
    shouldRetry: shouldRetry,
  );
  ```
  Avoid the trailing-comma-less multi-line form, which makes `dart format`
  use 4-space continuation indent and glues the closing bracket to the
  last argument:
  ```
  // AVOID — dart format produces this when the trailing comma is missing:
  return RetryPolicy(
      maxAttempts: maxAttempts,
      delay: retryDelay,
      shouldRetry: shouldRetry);
  ```
- When adding a new argument to a multi-line construct, you may need to
  add a comma to the previously-last argument. This is the accepted
  trade-off for keeping short code on one line.

## 3. Types And Immutability

- Declare return types, parameter types, and field types explicitly.
- Avoid `dynamic`; if external JSON requires it, isolate parsing in DTO/codec
  code and expose typed domain objects.
- Prefer `final` fields and immutable value objects.
- Exhaustive `switch` statements should not use `default` when the enum is
  controlled by the app.
- Prefer `late final` over nullable fields plus `!` when initialization is
  guaranteed before use.
- Use records for small internal multi-value returns; use named value classes
  for public APIs or long-lived domain concepts.

## 4. Imports And Files

Import order:

1. `dart:`
2. `package:`
3. Relative imports
4. Exports

Each project must choose one internal import style and keep it consistent. When
a project does not define an override, use relative imports within `lib/` and
package imports from tests or external packages.

- In a layered architecture, higher-level UI and domain code should depend on
  contracts rather than importing data-source implementations directly.
- Types shared across features belong in the project's declared shared boundary
  or package, not in another feature's private directory.
- Keep files under 300 lines where practical. i18n maps, generated code, and
  mechanical codecs may exceed this.
- Prefer cohesive small files over large mixed files. Split by responsibility,
  not by arbitrary line count.

## 5. Classes And Constructors

Recommended order:

1. `static const`
2. fields
3. constructors
4. getters/setters
5. public methods
6. private methods
7. `toString`, `==`, `hashCode`

- Prefer `this.field` constructor parameters.
- Immutable values should use `copyWith`; avoid public setters.
- Implement equality for values that are compared in tests, collections, or
  state transitions.
- Prefer top-level providers/factories over hand-written mutable singletons.

## 6. Async, Errors, And Logging

- Public async APIs expose `Future` or `Stream`, not `Completer`.
- Await futures or mark intentionally ignored work with `unawaited(...)`.
- Convert infrastructure errors at repository or boundary layers into the
  project's typed error model.
- Fallbacks must be explicit: log the failure, explain the fallback, and avoid
  silently returning fake success.
- Error messages should tell callers whether retry, login, cache fallback, or
  user action is expected.
- Do not use `print`; use the project logger.

## 7. Flutter UI

- `build` methods should compose widgets. Move complex branches into private
  widget classes instead of widget-returning helper methods.
- Business state belongs in the project's selected state-management layer (for
  example Riverpod, Provider, or Bloc). Use `setState` only for local UI state
  such as hover, focus, expansion, or a chart selector.
- Use theme tokens for color, spacing, radius, typography, and motion. Avoid
  naked `Color(0x...)`, ad hoc border widths, or one-off dimensions.
- Every user-facing data page should cover loading, data, error, and empty
  states.
- User-visible strings go through localization or the project's string layer.
- Icon-only actions need a tooltip or semantic label.
- Click targets should be comfortably clickable on desktop; important actions
  should be at least 40px high/wide when layout allows.

## 8. Flutter Performance

- Use lazy lists (`ListView.builder`, `SliverList`, `SliverGrid`) for unbounded
  or remote-sized collections.
- Static settings pages and short fixed sections may use `ListView(children)`.
- Isolate expensive charts, canvases, images, and frequently updating widgets
  with `RepaintBoundary` when profiling or visual complexity justifies it.
- Avoid triggering full-page rebuilds for a small control. Put local selectors,
  sliders, and hover states in small stateful widgets or local notifiers.
- Prefer `const` widgets and stable keys where they reduce rebuild work.
- Do not optimize blindly; use DevTools, tests, or screenshots for risky changes.

## 9. Data And Caching (When Applicable)

- Separate DTOs/codecs from domain entities.
- Repositories orchestrate source selection, cache policy, fallback, and mapping;
  they should not become large JSON parsing files.
- Cache keys should be named and versioned when payload shape can change.
- Remote failure fallback order should be explicit: fresh cache, stale cache,
  seed/demo data, or error.
- UI must not pretend estimated, stale, or seed data is live remote data when
  that distinction affects user trust.
- Search boxes should not fire remote requests on every keystroke. Debounce,
  local-filter, or require explicit submit depending on the feature.

## 10. Testing

- Each test file should focus on one unit: repository, notifier, parser, route,
  or widget.
- Test names describe behavior, not implementation details.
- Cover error paths, stale cache, empty data, parse failure, and boundary values.
- Keep fixtures small and readable. Large JSON responses belong in fixture files.
- Widget tests should wait for the UI to settle before assertions when async
  work is expected.
- Add regression tests with bug fixes when the behavior can reasonably break
  again.

## 11. Project Overlay Boundary

Keep this shared guide free of application-specific facts. Record the following
in the adopting repository's `AGENTS.md`, `CONTRIBUTING.md`, `README.md`, or run
guide instead:

- application and feature names, navigation structure, and product behavior;
- concrete shared widget, provider, logger, error type, and package names;
- feature-layer directories and project-specific dependency boundaries;
- exact API endpoints, cache durations, fallback order, and data provenance
  rules;
- supported platforms, release targets, and exact validation commands;
- repository-specific Git, CI, deployment, and secret-management workflows.

Project overlays should reference this guide and state only their additions or
exceptions. Do not copy the complete shared guide into an overlay, because
duplicated rules drift independently.
