# Dart & Flutter Style Guide

Reusable Dart/Flutter conventions for this and future projects. Mechanical
rules belong in `analysis_options.yaml`; this file records conventions that lint
cannot fully enforce.

If this file conflicts with `analysis_options.yaml`, the analyzer wins. If this
file conflicts with a project-specific `AGENTS.md`, the project-specific rule
wins.

## 1. Naming

| Kind | Convention | Example |
|---|---|---|
| Class, enum, typedef, mixin, extension | UpperCamelCase | `RateLimitGate` |
| File and directory | lowercase_with_underscores | `rate_limit_gate.dart` |
| Variable, parameter, function | lowerCamelCase | `fetchRepos()` |
| Private member | Leading underscore | `_readCache()` |
| Constant, including `static const` | lowerCamelCase | `defaultTimeout` |
| Boolean | Adjective or `is` / `has` / `can` / `should` | `isFresh` |
| Enum value | lowerCamelCase | `DataSource.live` |

Avoid unclear abbreviations (`btn`, `cfg`), Hungarian notation, and names that
shadow Dart SDK types such as `List`, `Future`, or `Record`.

## 2. Comments

- Use `/* ... */` block comments for every explanatory comment, including on
  public APIs, classes, methods, and fields. Do not use `///` doc comments;
  this project intentionally opts out of dartdoc-style comments.
- Every class and method must have a block comment explaining its purpose.
- Private code still needs a comment when intent, constraints, tradeoffs, or
  non-obvious fallbacks are not clear from the code itself.
- Magic numbers for timing, retry, cache, sizing, and limits need either a named
  constant or a short reason.
- TODO format: `/* TODO(owner, YYYY-MM-DD): actionable note */`.
- Do not leave author, generated-by, or chat transcript comments in source.

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

Project policy must choose one internal import style and keep it consistent.
This project uses relative imports inside `lib/` and package imports from tests
or external packages.

- Presentation code must not import feature `data` classes directly.
- Shared domain types belong in `core/domain` or a shared package, not in another
  feature's private folders.
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
- Business state belongs in Riverpod/Provider/Bloc/etc. Use `setState` only for
  local UI state such as hover, focus, expansion, or a chart selector.
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

## 9. Data And Caching

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

## Project Overlay: GitHub News

- Follow `AGENTS.md` for feature layout, data boundaries, commands, and Git
  workflow.
- Desktop UI should feel like an operational intelligence workspace: dense,
  calm, scannable, and consistent across light/dark themes.
- Use `HeaderSearchField`, `AppCard`, `PageHeader`, `DataProvenanceBadge`, and
  `core/theme` tokens before creating new variants.
- Primary in-app detail flows should stay inside the app shell/B region unless
  the requested behavior is explicitly external.
- Remote data must remain usable offline through local cache and clear fallback
  provenance.
