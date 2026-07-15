# AI资讯 Self-hosted Server

This optional service extends the local-first Flutter client with capabilities that require a continuously running system boundary:

- scheduled RSS/Atom ingestion with source-level failure isolation;
- versioned cross-device record sync;
- workspace members and shared annotations;
- durable push outbox with direct webhook delivery and FCM/APNs/WNS gateway polling;
- GH Archive hourly ingestion and repository trend aggregation.

The client remains usable without this service. SQLite is the default durable store; one process is sufficient for personal and small-team deployments.

## Local run

```powershell
cd server
$env:GITHUB_NEWS_MASTER_KEY = "replace-with-a-long-random-secret"
uv sync --all-groups
uv run uvicorn app.main:app --host 127.0.0.1 --port 8080
```

Open `http://127.0.0.1:8080/docs` for the generated OpenAPI UI. Except for `/health`, requests require:

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

- `GET /v1/news`, `POST /v1/ingest/run`: aggregated content and manual collection.
- `POST /v1/sync/push`, `GET /v1/sync/pull`: namespace-based records with optimistic versions and tombstones.
- `/v1/collaboration/*`: workspace members and versioned item annotations.
- `/v1/push/*`: subscriptions, durable events, gateway outbox, acknowledgement.
- `POST /v1/gharchive/ingest`, `GET /v1/gharchive/trends`: real GH Archive hourly files and aggregated activity.

The built-in scheduler runs feed ingestion and webhook dispatch. Run one scheduler-enabled replica; additional API replicas should set `GITHUB_NEWS_SCHEDULER_ENABLED=false` to avoid duplicate jobs. FCM/APNs/WNS entries intentionally remain in the outbox until a credentialed delivery gateway reads and acknowledges them—provider credentials are never fabricated or committed.

## Security and operations

- Change the default master key before any non-local run.
- Use a distinct workspace id for each personal/team data boundary.
- Back up the SQLite database and its WAL files consistently, or stop the service before copying.
- Webhook secrets are used for an HMAC-SHA256 `X-GitHub-News-Signature` header.
- GH Archive unique actors are exact per hour and summed across hours in the trend endpoint; the cross-hour value is an activity sample, not a global distinct-user count.
