"""
tests/conftest.py

Shared pytest fixtures. Every test runs against an isolated users.json in a
temp directory (via monkeypatching app.models' file path constant), so
tests never read or write the real data/ file.
"""
import sys
from pathlib import Path

# Make sure `import app` works regardless of where pytest is invoked from.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pytest

from app import create_app, models


@pytest.fixture
def isolated_data(tmp_path, monkeypatch):
    """Point app.models at a throwaway JSON file for the duration of a test."""
    monkeypatch.setattr(models, "USERS_FILE", str(tmp_path / "users.json"))
    return tmp_path


@pytest.fixture
def app(isolated_data):
    flask_app = create_app()
    flask_app.config.update(TESTING=True, SECRET_KEY="test-secret")
    return flask_app


@pytest.fixture
def client(app):
    return app.test_client()


@pytest.fixture
def auth(client):
    """Registers (if needed) and logs in a user, returning auth headers."""

    def _auth(email="alice@example.com", password="secret123", name="Alice", preferences=None):
        client.post(
            "/register",
            json={"name": name, "email": email, "password": password, "preferences": preferences or []},
        )
        res = client.post("/login", json={"email": email, "password": password})
        token = res.get_json()["token"]
        return {"Authorization": f"Bearer {token}"}

    return _auth
