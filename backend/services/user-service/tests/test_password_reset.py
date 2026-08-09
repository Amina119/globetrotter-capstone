"""Tests for app/auth.py: /forgot-password and /reset-password."""
import datetime

from app import models


def _register(client, email="alice@example.com", password="secret123"):
    client.post("/register", json={"name": "Alice", "email": email, "password": password})


def test_forgot_password_returns_200_for_known_email(client):
    _register(client)
    res = client.post("/forgot-password", json={"email": "alice@example.com"})
    assert res.status_code == 200


def test_forgot_password_returns_200_for_unknown_email(client):
    """Doesn't leak whether an account exists."""
    res = client.post("/forgot-password", json={"email": "ghost@example.com"})
    assert res.status_code == 200


def test_forgot_password_requires_email(client):
    res = client.post("/forgot-password", json={})
    assert res.status_code == 400


def test_forgot_password_sets_reset_token(client):
    _register(client)
    client.post("/forgot-password", json={"email": "alice@example.com"})
    user = models.get_user_by_email("alice@example.com")
    assert user["reset_token"]
    assert user["reset_token_expires"]


def test_reset_password_success(client):
    _register(client)
    client.post("/forgot-password", json={"email": "alice@example.com"})
    token = models.get_user_by_email("alice@example.com")["reset_token"]

    res = client.post(
        "/reset-password",
        json={"email": "alice@example.com", "token": token, "password": "newpass456"},
    )
    assert res.status_code == 200

    # Old password no longer works, new one does.
    old = client.post("/login", json={"email": "alice@example.com", "password": "secret123"})
    assert old.status_code == 401
    new = client.post("/login", json={"email": "alice@example.com", "password": "newpass456"})
    assert new.status_code == 200


def test_reset_password_rejects_wrong_token(client):
    _register(client)
    client.post("/forgot-password", json={"email": "alice@example.com"})

    res = client.post(
        "/reset-password",
        json={"email": "alice@example.com", "token": "not-the-real-token", "password": "newpass456"},
    )
    assert res.status_code == 400


def test_reset_password_rejects_expired_token(client):
    _register(client)
    client.post("/forgot-password", json={"email": "alice@example.com"})
    user = models.get_user_by_email("alice@example.com")
    expired = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(hours=1)).isoformat()
    models.update_user("alice@example.com", {"reset_token_expires": expired})

    res = client.post(
        "/reset-password",
        json={"email": "alice@example.com", "token": user["reset_token"], "password": "newpass456"},
    )
    assert res.status_code == 400


def test_reset_password_token_is_single_use(client):
    _register(client)
    client.post("/forgot-password", json={"email": "alice@example.com"})
    token = models.get_user_by_email("alice@example.com")["reset_token"]

    first = client.post("/reset-password", json={"email": "alice@example.com", "token": token, "password": "newpass456"})
    second = client.post("/reset-password", json={"email": "alice@example.com", "token": token, "password": "another789"})

    assert first.status_code == 200
    assert second.status_code == 400
