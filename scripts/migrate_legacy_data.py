"""
scripts/migrate_legacy_data.py

One-off migration: splits the monolith's single data/ directory into the
per-service data directories each new microservice owns, and cleans up
legacy rows along the way.

What it does
------------
- users.json       -> services/user-service/data/users.json
    Drops rows with no "email" (legacy username-only accounts — already
    orphaned under the current email-based model, since every other route
    joins on email). Fills in missing "is_admin"/"reset_token"/
    "reset_token_expires" fields so every row has the same shape.
- itineraries.json -> services/itinerary-service/data/itineraries.json
    Drops rows with no "email" (legacy username-only itineraries) for the
    same reason. Fills in a missing "shared_with" with [].
- destinations.json -> services/recommendation-service/data/destinations.json
    Copied as-is (no legacy rows here).
- user_recommendations.json, if it exists, is copied as-is to
    services/recommendation-service/data/.

This is a one-time developer utility, not part of the running system — run
it once from the repo root:

    python scripts/migrate_legacy_data.py
"""
import json
import os
import sys

_REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_OLD_DATA_DIR = os.path.join(_REPO_ROOT, "data")

_USER_SERVICE_DATA = os.path.join(_REPO_ROOT, "services", "user-service", "data")
_ITINERARY_SERVICE_DATA = os.path.join(_REPO_ROOT, "services", "itinerary-service", "data")
_RECOMMENDATION_SERVICE_DATA = os.path.join(_REPO_ROOT, "services", "recommendation-service", "data")


def _read_json(path):
    if not os.path.exists(path):
        return []
    with open(path, "r", encoding="utf-8") as fh:
        content = fh.read().strip()
        return json.loads(content) if content else []


def _write_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2)


def migrate_users():
    users = _read_json(os.path.join(_OLD_DATA_DIR, "users.json"))
    kept, dropped = [], []
    for user in users:
        if not user.get("email"):
            dropped.append(user.get("username") or user.get("id") or "<unknown>")
            continue
        user.setdefault("is_admin", False)
        user.setdefault("reset_token", None)
        user.setdefault("reset_token_expires", None)
        kept.append(user)

    _write_json(os.path.join(_USER_SERVICE_DATA, "users.json"), kept)
    print(f"users.json: kept {len(kept)}, dropped {len(dropped)} legacy row(s) {dropped}")


def migrate_itineraries():
    itineraries = _read_json(os.path.join(_OLD_DATA_DIR, "itineraries.json"))
    kept, dropped = [], []
    for it in itineraries:
        if not it.get("email"):
            dropped.append(it.get("username") or it.get("id") or "<unknown>")
            continue
        it.setdefault("shared_with", [])
        kept.append(it)

    _write_json(os.path.join(_ITINERARY_SERVICE_DATA, "itineraries.json"), kept)
    print(f"itineraries.json: kept {len(kept)}, dropped {len(dropped)} legacy row(s) {dropped}")


def migrate_destinations():
    destinations = _read_json(os.path.join(_OLD_DATA_DIR, "destinations.json"))
    _write_json(os.path.join(_RECOMMENDATION_SERVICE_DATA, "destinations.json"), destinations)
    print(f"destinations.json: copied {len(destinations)} row(s)")


def migrate_user_recommendations():
    path = os.path.join(_OLD_DATA_DIR, "user_recommendations.json")
    if not os.path.exists(path):
        print("user_recommendations.json: none to migrate")
        return
    recommendations = _read_json(path)
    _write_json(os.path.join(_RECOMMENDATION_SERVICE_DATA, "user_recommendations.json"), recommendations)
    print(f"user_recommendations.json: copied {len(recommendations)} row(s)")


if __name__ == "__main__":
    if not os.path.isdir(_OLD_DATA_DIR):
        print(f"No old data/ directory found at {_OLD_DATA_DIR} — nothing to migrate.")
        sys.exit(0)

    migrate_users()
    migrate_itineraries()
    migrate_destinations()
    migrate_user_recommendations()
