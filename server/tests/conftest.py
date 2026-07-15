from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app


@pytest.fixture
def settings(tmp_path: Path) -> Settings:
    return Settings(
        database_path=tmp_path / "test.db",
        master_key="test-secret",
        scheduler_enabled=False,
        ingest_interval_seconds=900,
        push_interval_seconds=30,
        request_timeout_seconds=5,
    )


@pytest.fixture
def client(settings: Settings) -> TestClient:
    with TestClient(create_app(settings)) as test_client:
        yield test_client


@pytest.fixture
def auth_headers() -> dict[str, str]:
    return {
        "Authorization": "Bearer test-secret",
        "X-Workspace-ID": "workspace-a",
    }
