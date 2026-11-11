import pytest

from app.config import Settings


def test_from_env_rejects_missing_or_default_master_key(monkeypatch):
    monkeypatch.delenv("GITHUB_NEWS_MASTER_KEY", raising=False)
    with pytest.raises(RuntimeError):
        Settings.from_env()

    monkeypatch.setenv("GITHUB_NEWS_MASTER_KEY", "change-me")
    with pytest.raises(RuntimeError):
        Settings.from_env()

    monkeypatch.setenv("GITHUB_NEWS_MASTER_KEY", "a-real-secret-0123456789")
    assert Settings.from_env().master_key == "a-real-secret-0123456789"


def test_from_env_rejects_example_placeholder_and_short_keys(monkeypatch):
    # Copying .env.example verbatim must not start a publicly-known key.
    monkeypatch.setenv("GITHUB_NEWS_MASTER_KEY", "replace-with-a-long-random-secret")
    with pytest.raises(RuntimeError):
        Settings.from_env()

    monkeypatch.setenv("GITHUB_NEWS_MASTER_KEY", "short-key")
    with pytest.raises(RuntimeError):
        Settings.from_env()


def test_from_env_parses_webhook_and_cors_options(monkeypatch):
    monkeypatch.setenv("GITHUB_NEWS_MASTER_KEY", "a-real-secret-0123456789")
    monkeypatch.delenv("GITHUB_NEWS_WEBHOOK_ALLOW_PRIVATE", raising=False)
    monkeypatch.delenv("GITHUB_NEWS_CORS_ORIGINS", raising=False)
    defaults = Settings.from_env()
    assert defaults.webhook_allow_private is False
    assert defaults.cors_origins == ["*"]

    monkeypatch.setenv("GITHUB_NEWS_WEBHOOK_ALLOW_PRIVATE", "true")
    monkeypatch.setenv("GITHUB_NEWS_CORS_ORIGINS", "https://a.example, https://b.example")
    configured = Settings.from_env()
    assert configured.webhook_allow_private is True
    assert configured.cors_origins == ["https://a.example", "https://b.example"]
