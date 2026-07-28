"""
tests/conftest.py

Shared pytest fixtures. Every test runs against an isolated set of JSON
data files in a temp directory (via monkeypatching app.models' file path
constants), so tests never read or write the real data/ files.
"""
import sys
from pathlib import Path

# Make sure `import app` works regardless of where pytest is invoked from.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pytest

from app import create_app, models

SAMPLE_DESTINATIONS = [
    {
        "id": "d1",
        "name": "Alpha Market",
        "Town": "Yaoundé",
        "quarter": "Terminus",
        "sector": "A lively local market with food stalls.",
        "tags": ["food", "culture"],
        "avg_cost_per_day": 2000,
    },
    {
        "id": "d2",
        "name": "Beta Park",
        "Town": "Yaoundé",
        "quarter": "Dubai City",
        "sector": "A quiet green park.",
        "tags": ["nature"],
        "avg_cost_per_day": 0,
    },
    {
        "id": "d3",
        "name": "Gamma Palace",
        "Town": "Yaoundé",
        "quarter": "Derriere Chefferie",
        "sector": "A historic palace and cultural landmark.",
        "tags": ["culture"],
        "avg_cost_per_day": 0,
    },
]


@pytest.fixture
def isolated_data(tmp_path, monkeypatch):
    """Point app.models at throwaway JSON files for the duration of a test."""
    monkeypatch.setattr(models, "USERS_FILE", str(tmp_path / "users.json"))
    monkeypatch.setattr(models, "ITINERARIES_FILE", str(tmp_path / "itineraries.json"))
    monkeypatch.setattr(models, "DESTINATIONS_FILE", str(tmp_path / "destinations.json"))
    monkeypatch.setattr(models, "USER_RECOMMENDATIONS_FILE", str(tmp_path / "user_recommendations.json"))
    return tmp_path


@pytest.fixture
def seeded_destinations(isolated_data):
    """Seed the isolated destinations file with a small, deterministic catalogue."""
    models._write_json(models.DESTINATIONS_FILE, SAMPLE_DESTINATIONS)
    return SAMPLE_DESTINATIONS


@pytest.fixture
def app(seeded_destinations):
    flask_app = create_app()
    flask_app.config.update(TESTING=True, SECRET_KEY="test-secret")
    return flask_app


@pytest.fixture
def client(app):
    return app.test_client()


@pytest.fixture
def auth(client):
    """Registers (if needed) and logs in a user, returning auth headers."""

    def _auth(username="alice", password="secret123", preferences=None, email=None):
        email = email or f"{username}@example.com"
        client.post(
            "/register",
            json={"username": username, "email": email, "password": password, "preferences": preferences or []},
        )
        res = client.post("/login", json={"email": email, "password": password})
        token = res.get_json()["token"]
        return {"Authorization": f"Bearer {token}"}

    return _auth
