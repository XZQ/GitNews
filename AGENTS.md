# Agent Guide

This file is the single source of truth for AI agents in this repository.
Claude reads it through `CLAUDE.md`; keep `CLAUDE.md` as a tiny pointer and do
not duplicate rules there.

The structure is reusable across projects:

1. Keep **Universal Agent Contract** mostly unchanged.
2. Replace **Project Profile** and project-specific commands when copying to a
   new repository.
3. Move long product plans, audits, and implementation notes into `docs/`.

## Universal Agent Contract

- Read the local project state before changing files. Prefer existing patterns
  over new abstractions.
- Do not revert or overwrite user changes unless explicitly asked. If the
  worktree is dirty, change only the files needed for the request.
- Keep edits focused, reviewable, and reversible. Avoid unrelated formatting,
  migrations, or dependency churn.
- Ask questions only when blocked. Otherwise make a reasonable assumption,
  implement it, and state the assumption in the handoff.
- Use structured APIs and parsers when available. Avoid ad hoc string parsing
  for JSON, YAML, XML, Markdown tables, or generated files.
- Keep secrets out of source control, logs, screenshots, and test fixtures.
- Verify meaningful changes with the smallest useful check first, then run the
  full required checks before commit.
- When a command cannot be run, say exactly what was skipped and why.

## Project Profile

- Flutter desktop-first app for AI and GitHub intelligence.
- Windows desktop is the current implementation priority.
- Mobile keeps the planned 4-tab information architecture, but do not expand
  mobile scope unless requested.
- There is no backend server in this phase. Remote data must be cached locally
  and the app must remain usable offline.

## Commands

- In this Codex environment, run shell commands through `rtk`, for example
  `rtk flutter analyze`.
- Before commit, run:
  - `rtk dart format .`
  - `rtk flutter analyze`
  - `rtk flutter test`
- For desktop-impacting changes, also run:
  - `rtk flutter build windows --release`

## Architecture

- Use the existing feature-first layout:
  - `lib/core/`: network, storage, theme, router, platform, errors, config,
    shared domain primitives.
  - `lib/features/<feature>/data`: API clients, DTOs, repository
    implementations, cache codecs.
  - `lib/features/<feature>/domain`: pure Dart entities and repository
    contracts.
  - `lib/features/<feature>/application`: Riverpod providers, notifiers,
    controllers, use-case orchestration.
  - `lib/features/<feature>/presentation`: pages and feature widgets.
  - `lib/shared/widgets/`: reusable UI components.
- Small display-only features may omit `data/domain/application`; keep them
  under `presentation/` and `widgets/`.
- Presentation must not directly depend on feature `data` classes.
- Cross-feature sharing goes through `lib/core/domain/`, `lib/core/config/`, or
  `lib/shared/`, not direct feature-to-feature imports.
- Prefer Riverpod providers/notifiers over page-level `setState` for business
  state. `setState` is acceptable for private, short-lived UI state only.
- Keep repositories focused on orchestration. Move JSON codecs, query builders,
  mappers, and cache key helpers into small files.
- Keep `.dart` files under 300 lines where practical; i18n maps, generated
  code, and mechanical codecs are acceptable exceptions.
- Split complex `build` methods into private widget classes instead of
  widget-returning helper methods.

## Data

- Cache TTLs are centralized in `lib/core/config/cache_ttl_config.dart`; do not
  introduce new top-level cache `Duration(...)` constants in features.
- API endpoints (base URLs + request paths) are centralized in
  `lib/core/config/api_endpoints_config.dart`; do not hardcode URLs or paths in
  feature data clients. Static paths are `static const String`; templated paths
  (e.g. `/repos/$fullName`) are static methods that take the parameter and
  return the full path.
- Per-service HTTP headers and protocol constants (Accept,
  X-GitHub-Api-Version, User-Agent, ETag) live in their respective core support
  file (e.g. `lib/core/github/github_api_support.dart`); reuse the shared
  `headers(...)` builder instead of rebuilding header maps per call.
- Read fresh local cache first; call remote only when cache is missing, expired,
  or explicitly refreshed.
- On remote failure, prefer stale cache, then seed data as the last fallback.
- Surface data provenance in UI when it changes user trust: live remote, fresh
  cache, stale cache, estimated data, or seed data.
- Current remote sources include AI news feeds and GitHub Search / Repository /
  Contributors / Rate Limit APIs.
- Store user data locally with the existing SharedPreferences / SQLite patterns:
  favorites, monitored repos, followed developers, read or archived alerts,
  notification settings, and GitHub token.
- Do not introduce a backend service, cron worker, or cloud sync unless the user
  explicitly changes scope.

## UI And Product

- Reuse `core/theme` tokens for colors, spacing, radius, typography, and theme
  presets.
- Avoid naked visual constants in feature UI when an existing token works.
- Keep desktop layouts dense, calm, and operational; avoid marketing-style hero
  sections.
- Header search fields should use the shared `HeaderSearchField` style and fill
  the intended header area consistently.
- User-facing pages need loading, data, error, and empty states unless they are
  purely static settings.
- Check light and dark themes for border weight, card radius, overflow, focus
  states, sidebar alignment, and header alignment.
- Details opened from primary navigation should stay inside the app shell/B
  region unless the user explicitly asks for an external or full-screen flow.

## Testing

- Add focused tests when changing repository behavior, cache logic, notifiers,
  routing, shared widgets, or parsing.
- Prefer targeted tests while iterating, then run the full required checks before
  commit.
- For visual/layout fixes, verify with a desktop run, screenshot, golden test,
  or Windows build when practical.

## Git

- Do not revert user changes unless explicitly asked.
- Use Conventional Commits with concise Chinese subjects. The type's first
  letter MUST be uppercase, for example `Fix(ui): 修复语言占比溢出`,
  `Docs(spec): ...`, `Feat(core): ...`. Subject text after the colon starts
  with a Chinese character, no space before it.
- When asked to submit, commit to the active branch and push to GitHub after
  checks pass.

## Reference Docs

- Style guide: `STYLE.md`
- Product and data plan: `docs/product_ia_data_plan.md`
- Current capabilities and data boundary: `README.md`
- Local run guide: `RUN.md`
