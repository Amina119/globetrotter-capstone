"""Tests for the /health liveness endpoint (app/__init__.py)."""


def test_health_returns_ok(client):
    res = client.get("/health")
    assert res.status_code == 200
    body = res.get_json()
    assert body["status"] == "ok"
    assert body["service"] == "user-service"
