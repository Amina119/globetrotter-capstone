"""
tests/conftest.py

Shared pytest fixtures.

This service reads user data and itinerary data from other services via
app.services_client instead of owning them, so tests replace those calls
with small in-memory fakes (`fake_users`, `fake_itineraries`) rather than
making real network calls — true unit tests of this service alone.

Like the Itinerary Service, this service has no /register or /login of its
own, so the `auth` fixture mints JWTs directly with the shared test secret
and registers the user's profile into the `fake_users` store.
"""
import datetime
import sys
from pathlib import Path

# Make sure `import app` works regardless of where pytest is invoked from.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import jwt
import pytest

from app import create_app, models, services_client

TEST_SECRET = "test-secret"

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
    monkeypatch.setattr(models, "DESTINATIONS_FILE", str(tmp_path / "destinations.json"))
    monkeypatch.setattr(models, "USER_RECOMMENDATIONS_FILE", str(tmp_path / "user_recommendations.json"))
    return tmp_path


@pytest.fixture
def seeded_destinations(isolated_data):
    """Seed the isolated destinations file with a small, deterministic catalogue."""
    models._write_json(models.DESTINATIONS_FILE, SAMPLE_DESTINATIONS)
    return SAMPLE_DESTINATIONS


@pytest.fixture
def fake_users(monkeypatch):
    """In-memory stand-in for the User Service's /internal/users/<email>."""
    users = {}
    monkeypatch.setattr(services_client, "get_user", lambda email: users.get(email))
    return users


@pytest.fixture
def fake_itineraries(monkeypatch):
    """In-memory stand-in for the Itinerary Service's
    /internal/itineraries and /internal/itineraries/popularity.
    """
    itineraries = []  # list of {"email": ..., "destinations": [...]}

    def get_user_itineraries(email):
        return [it for it in itineraries if it["email"] == email]

    def get_destination_popularity():
        counts = {}
        for it in itineraries:
            seen_in_this_itinerary = set()
            for name in it.get("destinations", []):
                key = str(name).strip().lower()
                if key and key not in seen_in_this_itinerary:
                    counts[key] = counts.get(key, 0) + 1
                    seen_in_this_itinerary.add(key)
        return counts

    monkeypatch.setattr(services_client, "get_user_itineraries", get_user_itineraries)
    monkeypatch.setattr(services_client, "get_destination_popularity", get_destination_popularity)
    return itineraries


@pytest.fixture
def add_itinerary(fake_itineraries):
    """Add a fake itinerary (owner email + destination names) to the
    in-memory Itinerary Service stand-in."""

    def _add(email, destinations):
        fake_itineraries.append({"email": email, "destinations": destinations})

    return _add


@pytest.fixture
def app(seeded_destinations):
    flask_app = create_app()
    flask_app.config.update(TESTING=True, SECRET_KEY=TEST_SECRET)
    return flask_app


@pytest.fixture
def client(app):
    return app.test_client()


def _make_token(email: str) -> str:
    now = datetime.datetime.now(datetime.timezone.utc)
    payload = {"sub": email, "iat": now, "exp": now + datetime.timedelta(hours=24)}
    return jwt.encode(payload, TEST_SECRET, algorithm="HS256")


@pytest.fixture
def auth(fake_users):
    """Registers a fake user profile and returns a bearer token for it.

    Mirrors the real User Service's "first registered account is admin"
    rule, tracked here as "first account registered in this test".
    """

    def _auth(email="alice@example.com", name="Alice", preferences=None, is_admin=None):
        if is_admin is None:
            is_admin = len(fake_users) == 0
        fake_users[email] = {
            "email": email,
            "name": name,
            "preferences": preferences or [],
            "is_admin": is_admin,
        }
        return {"Authorization": f"Bearer {_make_token(email)}"}

    return _auth
