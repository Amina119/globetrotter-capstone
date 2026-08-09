"""Tests for app/auth.py: registration and login."""


def test_register_success(client):
    res = client.post(
        "/register",
        json={"name": "Alice", "email": "alice@example.com", "password": "secret123", "preferences": ["beach"]},
    )
    assert res.status_code == 201
    body = res.get_json()
    assert body["email"] == "alice@example.com"
    assert body["name"] == "Alice"


def test_register_missing_fields(client):
    res = client.post("/register", json={"name": "Alice", "email": "", "password": ""})
    assert res.status_code == 400


def test_register_invalid_email(client):
    res = client.post("/register", json={"name": "Alice", "email": "not-an-email", "password": "secret123"})
    assert res.status_code == 400


def test_register_duplicate_email(client):
    payload = {"name": "Alice", "email": "alice@example.com", "password": "secret123"}
    first = client.post("/register", json=payload)
    second = client.post("/register", json=payload)
    assert first.status_code == 201
    assert second.status_code == 409


def test_first_registered_user_is_admin(client):
    first = client.post("/register", json={"name": "Alice", "email": "alice@example.com", "password": "secret123"})
    second = client.post("/register", json={"name": "Bob", "email": "bob@example.com", "password": "secret123"})

    assert first.get_json()["is_admin"] is True
    assert second.get_json()["is_admin"] is False


def test_login_success(client):
    client.post("/register", json={"name": "Alice", "email": "alice@example.com", "password": "secret123"})
    res = client.post("/login", json={"email": "alice@example.com", "password": "secret123"})
    assert res.status_code == 200
    body = res.get_json()
    assert body["name"] == "Alice"
    assert isinstance(body["token"], str) and body["token"]


def test_login_reports_is_admin(client, auth):
    admin_headers = auth(email="alice@example.com", name="Alice")
    auth(email="bob@example.com", name="Bob")

    admin_login = client.post("/login", json={"email": "alice@example.com", "password": "secret123"}).get_json()
    other_login = client.post("/login", json={"email": "bob@example.com", "password": "secret123"}).get_json()

    assert admin_login["is_admin"] is True
    assert other_login["is_admin"] is False
    assert admin_headers != {}


def test_login_wrong_password(client):
    client.post("/register", json={"name": "Alice", "email": "alice@example.com", "password": "secret123"})
    res = client.post("/login", json={"email": "alice@example.com", "password": "wrong"})
    assert res.status_code == 401


def test_login_unknown_user(client):
    res = client.post("/login", json={"email": "ghost@example.com", "password": "secret123"})
    assert res.status_code == 401


def test_login_missing_fields(client):
    res = client.post("/login", json={"email": "", "password": ""})
    assert res.status_code == 400
