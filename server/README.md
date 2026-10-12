# AI资讯 Self-hosted Server

This optional service extends the local-first Flutter client with capabilities that require a continuously running system boundary:

- scheduled RSS/Atom ingestion with source-level failure isolation;
- versioned cross-device record sync;
- workspace members and shared annotations;
- durable push outbox with direct webhook delivery and FCM/APNs/WNS gateway polling;
- GH Archive hourly ingestion and repository trend aggregation.
- authenticated, quota-limited article enrichment with a server-only model key.

The client remains usable without this service. SQLite is the default durable store; one process is sufficient for personal and small-team deployments.

## Local run

```powershell
cd server
$env:GITHUB_NEWS_MASTER_KEY = "replace-with-a-long-random-secret"
uv sync --all-groups
uv run uvicorn app.main:app --host 127.0.0.1 --port 8080
```

Open `http://127.0.0.1:8080/docs` for the generated OpenAPI UI. Existing self-hosted APIs (excluding `/health` and the separate AI endpoint below) require:

```text
Authorization: Bearer <GITHUB_NEWS_MASTER_KEY>
X-Workspace-ID: personal
```

Run verification with:

```powershell
uv run ruff check .
uv run ruff format --check .
uv run pytest
uv run python tools/live_smoke.py
# Requires internet access; succeeds when at least one real feed is fetched and persisted.
uv run python tools/feed_live_smoke.py
```

## Docker Compose

```powershell
cd server
$env:GITHUB_NEWS_MASTER_KEY = "replace-with-a-long-random-secret"
docker compose up --build -d
```

The persistent database is stored in the `github-news-data` volume. Put a TLS reverse proxy in front of port 8080 before exposing the API outside a trusted network.

## API boundaries

- `POST /v1/ai/enrichment`: article summary/translation with a verified application user session, never the self-hosted master key.
- `GET /v1/news`, `POST /v1/ingest/run`: aggregated content and manual collection.
- `POST /v1/sync/push`, `GET /v1/sync/pull`: namespace-based records with optimistic versions and tombstones.
- `/v1/collaboration/*`: workspace members and versioned item annotations.
- `/v1/push/*`: subscriptions, durable events, gateway outbox, acknowledgement.
- `POST /v1/gharchive/ingest`, `GET /v1/gharchive/trends`: real GH Archive hourly files and aggregated activity.

The built-in scheduler runs feed ingestion and webhook dispatch. Run one scheduler-enabled replica; additional API replicas should set `GITHUB_NEWS_SCHEDULER_ENABLED=false` to avoid duplicate jobs. FCM/APNs/WNS entries intentionally remain in the outbox until a credentialed delivery gateway reads and acknowledges them—provider credentials are never fabricated or committed.

## Sync and durable writes

Sync writes check versions while holding a SQLite write transaction. A higher version replaces the record; an equal version is accepted only when its payload and tombstone match the stored record, and this retry does not change the stored timestamp or server revision. A lower version, or an equal version with different content, returns the existing record in `conflicts`. Annotation updates follow the same version rule and reject IDs already owned by another workspace with HTTP 409.

`GET /v1/sync/pull` keeps the list response and the existing `since`/`limit` arguments. Optional `namespace` and `record_id` arguments filter records independently or together, including tombstones. To retrieve the shared client configuration, use `since=0&limit=1&namespace=app_config&record_id=shared`; a deleted result must not be imported.

Each returned record also carries a monotonically increasing server `revision` and an opaque, workspace-scoped `cursor`. For reliable paging and incremental sync, explicitly start with `cursor=start`, retain the last record's `cursor` only after applying the page, and send that opaque cursor on the next pull. Both the initial `start` checkpoint and later cursors read records in server revision order and ignore `since`, so records whose client clocks repeat or move backwards remain reachable. Keep the same filters while paging; changing the workspace or filters requires a fresh `cursor=start` pull. Continue until an empty page, and keep the last successful cursor for later polls. Invalid or other-workspace opaque cursors return HTTP 400.

Without `cursor`, the legacy `since` filter and `updated_at, namespace, record_id` ordering remain unchanged. Timestamp-only paging cannot guarantee incremental delivery when client clocks repeat or move backwards. Do not switch from a legacy timestamp page to its returned revision cursor midway through a scan; begin a new scan with `cursor=start` to opt into revision paging from the first page.

Startup upgrades older SQLite databases in place by adding `sync_records.revision` and a single-row `sync_clock` counter, assigning revisions to existing records without changing their payloads, client versions, timestamps or tombstones. Migration and concurrent sync writes are serialized; revisions and checkpoints survive service restart. The sync endpoint returns current record snapshots rather than every historical edit.

Feed ingestion writes article changes and notifications for all subscribed workspaces in one transaction. An outbox failure rolls back those article changes so a later ingestion can retry; concurrent ingestion instances create one notification for a newly persisted article. Webhook delivery remains an at-least-once external boundary, so receivers should handle retries idempotently.

GH Archive accepts actual calendar hours with one or two hour digits, stores new hours with two digits, and compares hours chronologically. Existing rows with unpadded hours remain readable; when older data contains both representations of the same repository/event/hour, trends use the most recently updated row. Reingestion replaces both representations of the same hour. Downloads keep GH Archive's unpadded filename format.

## Security and operations

- Change the default master key before any non-local run.
- Use a distinct workspace id for each personal/team data boundary.
- Back up the SQLite database and its WAL files consistently, or stop the service before copying.
- Webhook secrets are used for an HMAC-SHA256 `X-GitHub-News-Signature` header.
- GH Archive unique actors are exact per hour and summed across hours in the trend endpoint; the cross-hour value is an activity sample, not a global distinct-user count.

## AI enrichment proxy

The optional publisher proxy uses the existing Agnes model. Configure these **server environment variables** (or the Compose `.env`, kept out of Git):

- `AI_ENRICHMENT_AGNES_API_KEY`: publisher's model key, never a Flutter build parameter.
- `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`: the same Supabase project used for application accounts. The URL must use HTTPS. No service-role key is needed.
- `AI_ENRICHMENT_USER_DAILY_LIMIT`: accepted generation attempts per authenticated user per UTC day, default 20.
- `AI_ENRICHMENT_GLOBAL_DAILY_LIMIT`: total accepted attempts per UTC day, default 500.

The client build receives only `AI_ENRICHMENT_PROXY_URL`, a public HTTPS origin, plus its existing public Supabase account configuration. Each generation validates the current user access token against `/auth/v1/user`; missing, expired, anonymous and master-key sessions cannot generate. Public AI HOT feeds, local storage, startup and offline reading never depend on this endpoint.

The endpoint accepts only `title` (512 characters), `title_en` (512), `summary` (8000), `source` (128), and `url` (2048). It never fetches supplied URLs or accepts caller-selected system prompts/models. Request and response bodies are bounded to 64 KiB; generated responses must match the typed schema. A server-owned prompt and 2048 output-token ceiling bound each call. Failed upstream calls consume their accepted quota too; the Flutter client does not automatically retry paid requests. Both quota counters are reserved in one SQLite transaction and survive restart; counters retain at most 14 previous days. Article content and credentials are not stored by this endpoint.

Use TLS and account signup controls in a public deployment. Rotate/revoke any model key distributed in an older client build; removing the build constant cannot revoke historical copies. Repository tests use deterministic account/model responses and real SQLite. They prove the local contract and quota boundary, not deployment, real account delivery or model availability.
