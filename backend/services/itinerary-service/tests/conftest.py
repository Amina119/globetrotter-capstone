"""
tests/conftest.py

Shared pytest fixtures.

This service has no /register or /login of its own (those live in the User
Service) so tests mint JWTs directly with the same shared secret the app is
configured with, standing in for a token the User Service would have
issued. Likewise, `app.services_client.user_exists` (the one outbound HTTP
call this service makes, to check a share target has an account) is
monkeypatched against an in-memory set of "known" emails instead of making
a real network call, so these are true unit tests of this service alone.
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


@pytest.fixture
def isolated_data(tmp_path, monkeypatch):
    """Point app.models at a throwaway JSON file for the duration of a test."""
    monkeypatch.setattr(models, "ITINERARIES_FILE", str(tmp_path / "itineraries.json"))
    return tmp_path


@pytest.fixture
def known_users(monkeypatch):
    """Emails treated as having a real account, standing in for the User
    Service's /internal/users/<email>/exists during unit tests.
    """
    emails = set()
    monkeypatch.setattr(services_client, "user_exists", lambda email: email in emails)
    return emails


@pytest.fixture
def app(isolated_data):
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
def auth(known_users):
    """Mints a bearer token for *email* and marks it as a known account (so
    it can be used as a share target in other calls)."""

    def _auth(email="alice@example.com"):
        known_users.add(email)
        return {"Authorization": f"Bearer {_make_token(email)}"}

    return _auth
