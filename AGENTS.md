# GitHub News Agent Guide

This is the single source of truth for agent instructions in this repo.
Claude reads it through `CLAUDE.md`; do not duplicate these rules there.

## Project

- Flutter desktop-first app for AI and GitHub intelligence.
- Windows desktop is the current implementation priority.
- Mobile keeps the planned 4-tab information architecture, but do not expand mobile scope unless requested.
- There is no backend server in this phase. Remote data must be cached locally and the app must remain usable offline.

## Commands

- In this Codex environment, run shell commands through `rtk`, for example `rtk flutter analyze`.
- Before commit, run:
  - `rtk dart format .`
  - `rtk flutter analyze`
  - `rtk flutter test`
- For desktop-impacting changes, also run `rtk flutter build windows --release`.

## Architecture

- Use the existing feature-first layout:
  - `lib/core/` for network, storage, theme, router, platform, errors, shared domain primitives.
  - `lib/features/<feature>/data` for API, DTO, repository implementation, cache codecs.
  - `lib/features/<feature>/domain` for pure Dart entities and repository contracts.
  - `lib/features/<feature>/presentation` for pages, widgets, Riverpod notifiers/controllers.
  - `lib/shared/widgets/` for reusable UI.
- Presentation must not directly depend on feature `data` classes.
- Prefer Riverpod providers/notifiers over page-level `setState` for business state.
- Keep Repository classes focused on orchestration; move JSON codecs, builders, and mapping helpers into small files.
- Keep `.dart` files under 300 lines where practical; i18n string maps are an acceptable exception.
- Split any complex `build` method into private widget classes instead of widget-returning helper methods.
- Small, display-only features (e.g. `home`) may omit the `data/domain/application` sublayers; they live directly under `presentation/` and `widgets/`. Cross-feature data sharing must go through `lib/core/domain/`, not direct feature-to-feature imports.
- Cache TTLs are centralized in `lib/core/config/cache_ttl_config.dart`. Do not introduce new top-level `Duration(minutes: ...)` constants for cache expiry.

## Data

- Cache TTL is configured per module in `lib/core/config/cache_ttl_config.dart` (lists 5min, monitor 10min, repo_detail/project 30min).
- Read fresh local cache first; only call remote when the cache is missing, expired, or explicitly refreshed.
- On remote failure, prefer stale cache, then seed data as the last fallback.
- Current remote sources include AI news feeds and GitHub Search / Repository / Contributors / Rate Limit APIs.
- Store user data locally with the existing SharedPreferences / SQLite patterns: favorites, monitored repos, followed developers, read or archived alerts, notification settings, and GitHub token.
- Do not introduce a backend service, cron worker, or cloud sync unless the user explicitly changes scope.

## UI

- Reuse `core/theme` tokens for colors, spacing, radius, typography, and theme presets.
- Avoid naked visual constants in feature UI when an existing token works.
- Keep desktop layouts dense, calm, and operational; avoid marketing-style hero sections.
- Check both light and dark themes for border weight, card radius, overflow, and sidebar/header alignment.
- Header search fields should use the shared `HeaderSearchField` style and fill the intended header area consistently.
- Every user-facing page needs loading, data, error, and empty states.

## Testing

- Add focused tests when changing repository behavior, cache logic, notifiers, routing, or shared widgets.
- Prefer targeted tests while iterating, then run the full required checks before commit.
- For visual/layout fixes, verify with Windows build or an actual desktop run when practical.

## Git

- Do not revert user changes unless explicitly asked.
- Use Conventional Commits with concise Chinese subjects, for example `fix(ui): 修复语言占比溢出`.
- When asked to submit, commit to the active branch and push to GitHub after checks pass.

## Reference Docs

- Product and data plan: `docs/product_ia_data_plan.md`
- Current capabilities and data boundary: `README.md`
- Local run guide: `RUN.md`
