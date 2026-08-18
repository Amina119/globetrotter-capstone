"""Tests for the internal (service-to-service) endpoints in app/auth.py."""


def _register(client, email="alice@example.com", name="Alice", preferences=None):
    client.post(
        "/register",
        json={"name": name, "email": email, "password": "secret123", "preferences": preferences or ["beach"]},
    )


def test_user_exists_true(client):
    _register(client)
    res = client.get("/internal/users/alice@example.com/exists")
    assert res.status_code == 200
    assert res.get_json() == {"exists": True}


def test_user_exists_false(client):
    res = client.get("/internal/users/ghost@example.com/exists")
    assert res.status_code == 200
    assert res.get_json() == {"exists": False}


def test_get_user_internal_returns_public_profile(client):
    _register(client, preferences=["beach", "food"])
    res = client.get("/internal/users/alice@example.com")
    assert res.status_code == 200
    body = res.get_json()
    assert body["email"] == "alice@example.com"
    assert body["name"] == "Alice"
    assert body["preferences"] == ["beach", "food"]
    assert body["is_admin"] is True
    assert "password_hash" not in body


def test_get_user_internal_404_for_unknown_email(client):
    res = client.get("/internal/users/ghost@example.com")
    assert res.status_code == 404
