import json
from concurrent.futures import ThreadPoolExecutor
from dataclasses import replace
from uuid import UUID

import httpx
import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.ai_enrichment_quota import reserve_enrichment_request
from app.ai_enrichment_service import AiEnrichmentService
from app.main import create_app

ARTICLE = {"title": "A public article", "summary": "Public summary", "source": "Example"}
CONTENT = {
    "generated_summary": "摘要",
    "translated_title": "标题",
    "translated_summary": "翻译",
    "importance_score": 80,
    "entities": {"models": [], "companies": [], "repositories": []},
}


@pytest.fixture
def proxy(settings):
    configured = replace(
        settings,
        ai_enrichment_key="publisher-fixture",
        supabase_url="https://accounts.example",
        supabase_publishable_key="publishable-fixture",
        ai_user_daily_limit=2,
        ai_global_daily_limit=3,
    )
    app = create_app(configured)
    calls = []
    behavior = {"model_status": 200, "content": CONTENT, "anonymous": False}

    def upstream(request):
        if request.url.host == "accounts.example":
            assert request.url.path == "/auth/v1/user"
            assert request.headers["apikey"] == "publishable-fixture"
            tokens = {"Bearer user-a-fixture": 1, "Bearer user-b-fixture": 2}
            identity = tokens.get(request.headers.get("Authorization"))
            if identity is None:
                return httpx.Response(401, json={"error": "invalid token"})
            return httpx.Response(
                200,
                json={
                    "id": str(UUID(int=identity)),
                    "role": "authenticated",
                    "is_anonymous": behavior["anonymous"],
                },
            )
        assert request.url.host == "apihub.agnes-ai.com"
        assert request.headers["Authorization"] == "Bearer publisher-fixture"
        payload = json.loads(request.content)
        calls.append(payload)
        return httpx.Response(
            behavior["model_status"],
            json={"choices": [{"message": {"content": json.dumps(behavior["content"])}}]},
        )

    app.state.ai_enrichment = AiEnrichmentService(
        app.state.database, configured, httpx.MockTransport(upstream)
    )
    with TestClient(app) as client:
        yield client, app, calls, behavior, configured


def generate(client, token="user-a-fixture", article=None):
    return client.post(
        "/v1/ai/enrichment", headers={"Authorization": f"Bearer {token}"}, json=article or ARTICLE
    )


def test_user_session_is_separate_from_publisher_key(proxy):
    client, _, calls, _, _ = proxy
    response = generate(client)
    assert response.status_code == 200
    assert response.json()["enrichment"] == CONTENT
    assert response.json()["model"] == "agnes-2.0-flash"
    assert calls[0]["max_tokens"] == 2048
    assert calls[0]["messages"][0]["role"] == "system"
    assert json.loads(calls[0]["messages"][1]["content"])["title"] == ARTICLE["title"]
    assert "publisher-fixture" not in response.text


def test_missing_expired_master_and_anonymous_sessions_cannot_generate(proxy):
    client, app, calls, behavior, configured = proxy
    assert client.post("/v1/ai/enrichment", json=ARTICLE).status_code == 401
    assert generate(client, "expired-fixture").status_code == 401
    assert generate(client, configured.master_key).status_code == 401
    behavior["anonymous"] = True
    assert generate(client).status_code == 401
    assert not calls
    with app.state.database.connection() as connection:
        assert connection.execute("SELECT COUNT(*) FROM ai_enrichment_usage").fetchone()[0] == 0


def test_user_and_global_daily_limits_persist_without_partial_charges(proxy):
    client, app, calls, _, _ = proxy
    assert generate(client).status_code == 200
    assert generate(client).status_code == 200
    limited = generate(client)
    assert limited.status_code == 429
    assert int(limited.headers["Retry-After"]) > 0
    assert generate(client, "user-b-fixture").status_code == 200
    assert generate(client, "user-b-fixture").status_code == 429
    assert len(calls) == 3
    with app.state.database.connection() as connection:
        counts = [
            row[0] for row in connection.execute("SELECT requests FROM ai_enrichment_usage ORDER BY requests")
        ]
    assert counts == [1, 2, 3]


@pytest.mark.parametrize(
    "extra", [{"model": "other"}, {"system_prompt": "override"}, {"summary": "x" * 8001}]
)
def test_rejects_open_proxy_fields_and_oversized_inputs(proxy, extra):
    client, _, calls, _, _ = proxy
    response = generate(client, article={**ARTICLE, **extra})
    assert response.status_code == 422
    assert response.json() == {"detail": "invalid article fields"}
    assert not calls


def test_bounds_streamed_request_bodies_before_parsing(proxy):
    client, _, calls, _, _ = proxy
    response = client.post(
        "/v1/ai/enrichment",
        headers={"Authorization": "Bearer user-a-fixture"},
        content=iter([b"x" * 33000, b"x" * 33000]),
    )
    assert response.status_code == 413
    assert not calls


@pytest.mark.parametrize(
    "status,content", [(500, CONTENT), (200, {"invalid": True}), (200, {**CONTENT, "importance_score": 101})]
)
def test_model_failures_have_no_fabricated_output_or_sensitive_error_body(proxy, status, content):
    client, _, calls, behavior, _ = proxy
    behavior.update(model_status=status, content=content)
    response = generate(client)
    assert response.status_code == 502
    assert response.json() == {"detail": "AI enrichment unavailable"}
    assert len(calls) == 1


def test_unconfigured_proxy_does_not_affect_public_health(client):
    assert client.get("/health").status_code == 200
    assert generate(client).status_code == 503


def test_concurrent_requests_cannot_exceed_user_quota(proxy):
    _, app, _, _, configured = proxy
    settings = replace(configured, ai_user_daily_limit=3, ai_global_daily_limit=4)

    def reserve(_):
        try:
            reserve_enrichment_request(app.state.database, settings, "same-user")
            return True
        except HTTPException as error:
            assert error.status_code == 429
            return False

    with ThreadPoolExecutor(max_workers=8) as pool:
        results = list(pool.map(reserve, range(12)))
    assert sum(results) == 3
    with app.state.database.connection() as connection:
        assert [row[0] for row in connection.execute("SELECT requests FROM ai_enrichment_usage")] == [3, 3]
