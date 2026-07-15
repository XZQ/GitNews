def test_health_is_public_and_protected_routes_require_token(client, auth_headers):
    health = client.get("/health")
    assert health.status_code == 200
    assert health.json()["database"]["ok"] is True
    assert client.get("/v1/news").status_code == 401
    assert client.get("/v1/news", headers=auth_headers).status_code == 200


def test_sync_push_pull_and_conflict(client, auth_headers):
    record = {
        "namespace": "preferences",
        "record_id": "theme",
        "payload": {"mode": "dark"},
        "version": 2,
        "updated_at": 1000,
    }
    pushed = client.post("/v1/sync/push", headers=auth_headers, json={"records": [record]})
    assert pushed.status_code == 200
    assert pushed.json() == {"accepted": 1, "conflicts": []}

    stale = {**record, "version": 1, "payload": {"mode": "light"}, "updated_at": 1001}
    conflict = client.post("/v1/sync/push", headers=auth_headers, json={"records": [stale]})
    assert conflict.json()["accepted"] == 0
    assert conflict.json()["conflicts"][0]["payload"] == {"mode": "dark"}

    pulled = client.get("/v1/sync/pull?since=0", headers=auth_headers)
    assert pulled.status_code == 200
    assert pulled.json()[0]["record_id"] == "theme"


def test_collaboration_members_and_annotations(client, auth_headers):
    member = {"member_id": "alice", "display_name": "Alice", "role": "editor"}
    response = client.put("/v1/collaboration/members/alice", headers=auth_headers, json=member)
    assert response.status_code == 200
    assert client.get("/v1/collaboration/members", headers=auth_headers).json()[0]["role"] == "editor"

    annotation = {
        "id": "note-1",
        "item_id": "news-1",
        "author_id": "alice",
        "body": "Worth tracking",
        "version": 1,
        "updated_at": 2000,
    }
    response = client.put(
        "/v1/collaboration/annotations/note-1",
        headers=auth_headers,
        json=annotation,
    )
    assert response.status_code == 200
    notes = client.get("/v1/collaboration/annotations/news-1", headers=auth_headers).json()
    assert notes[0]["body"] == "Worth tracking"


def test_push_bridge_outbox_and_ack(client, auth_headers):
    subscription = {
        "id": "device-1",
        "kind": "fcm",
        "endpoint": "device-token",
    }
    assert (
        client.put("/v1/push/subscriptions/device-1", headers=auth_headers, json=subscription).status_code
        == 200
    )
    event = {"event_type": "news.created", "payload": {"item_id": "news-1"}}
    assert client.post("/v1/push/events", headers=auth_headers, json=event).json() == {"enqueued": 1}

    outbox = client.get("/v1/push/outbox", headers=auth_headers).json()
    assert outbox[0]["payload"] == {"item_id": "news-1"}
    event_id = outbox[0]["id"]
    assert client.post(f"/v1/push/outbox/{event_id}/ack", headers=auth_headers).json() == {
        "acknowledged": True
    }
