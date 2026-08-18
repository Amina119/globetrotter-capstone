"""Tests for gateway/app.py: route-prefix dispatch, without a real network call."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pytest
import requests

import app as gateway_module


class _FakeResponse:
    def __init__(self, status_code=200, content=b'{"ok": true}', headers=None):
        self.status_code = status_code
        self.content = content
        self.headers = headers or {"Content-Type": "application/json"}


@pytest.fixture
def client():
    flask_app = gateway_module.create_app()
    flask_app.config.update(TESTING=True)
    return flask_app.test_client()


@pytest.fixture
def fake_upstream(monkeypatch):
    """Records the URL routed to and returns a canned response."""
    calls = []

    def fake_request(method, url, **kwargs):
        calls.append((method, url))
        return _FakeResponse()

    monkeypatch.setattr(gateway_module.requests, "request", fake_request)
    return calls


def test_health_is_handled_locally_not_proxied(client, fake_upstream):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.get_json()["service"] == "gateway"
    assert fake_upstream == []


@pytest.mark.parametrize(
    "path,expected_base",
    [
        ("/register", gateway_module.USER_SERVICE_URL),
        ("/login", gateway_module.USER_SERVICE_URL),
        ("/forgot-password", gateway_module.USER_SERVICE_URL),
        ("/reset-password", gateway_module.USER_SERVICE_URL),
        ("/itineraries", gateway_module.ITINERARY_SERVICE_URL),
        ("/itineraries/shared", gateway_module.ITINERARY_SERVICE_URL),
        ("/itineraries/abc123/share", gateway_module.ITINERARY_SERVICE_URL),
        ("/destinations", gateway_module.RECOMMENDATION_SERVICE_URL),
        ("/recommendations", gateway_module.RECOMMENDATION_SERVICE_URL),
        ("/my-recommendations", gateway_module.RECOMMENDATION_SERVICE_URL),
        ("/admin/recommendations", gateway_module.RECOMMENDATION_SERVICE_URL),
    ],
)
def test_routes_to_expected_service(client, fake_upstream, path, expected_base):
    res = client.get(path)
    assert res.status_code == 200
    assert len(fake_upstream) == 1
    method, url = fake_upstream[0]
    assert url == f"{expected_base}{path}"


def test_unknown_path_returns_404(client, fake_upstream):
    res = client.get("/not-a-real-route")
    assert res.status_code == 404
    assert fake_upstream == []


def test_internal_routes_are_never_proxied(client, fake_upstream):
    res = client.get("/internal/users/alice@example.com")
    assert res.status_code == 404
    assert fake_upstream == []


def test_upstream_connection_error_returns_502(client, monkeypatch):
    def failing_request(method, url, **kwargs):
        raise requests.ConnectionError("boom")

    monkeypatch.setattr(gateway_module.requests, "request", failing_request)
    res = client.get("/destinations")
    assert res.status_code == 502
