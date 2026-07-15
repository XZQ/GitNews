import pytest

from app.config import Settings


def test_from_env_rejects_missing_or_default_master_key(monkeypatch):
    monkeypatch.delenv("GITHUB_NEWS_MASTER_KEY", raising=False)
    with pytest.raises(RuntimeError):
        Settings.from_env()

    monkeypatch.setenv("GITHUB_NEWS_MASTER_KEY", "change-me")
    with pytest.raises(RuntimeError):
        Settings.from_env()

    monkeypatch.setenv("GITHUB_NEWS_MASTER_KEY", "a-real-secret")
    assert Settings.from_env().master_key == "a-real-secret"
