"""
app/models.py

Data models and file I/O helpers.

All persistent data is stored in JSON files under the /data directory.
  - data/users.json       – registered users
  - data/itineraries.json – user itineraries
  - data/destinations.json – static destination catalogue (seed data)
"""
import json
import os

# Resolve the /data directory relative to this file's location so the app
# works regardless of the current working directory.
_BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(_BASE_DIR, "data")

USERS_FILE = os.path.join(DATA_DIR, "users.json")
ITINERARIES_FILE = os.path.join(DATA_DIR, "itineraries.json")
DESTINATIONS_FILE = os.path.join(DATA_DIR, "destinations.json")
USER_RECOMMENDATIONS_FILE = os.path.join(DATA_DIR, "user_recommendations.json")


# ---------------------------------------------------------------------------
# Generic file I/O helpers
# ---------------------------------------------------------------------------

def _read_json(filepath: str) -> list:
    """Read a JSON file and return its contents as a Python list.

    Returns an empty list if the file does not exist or is empty.
    """
    if not os.path.exists(filepath):
        return []
    with open(filepath, "r", encoding="utf-8") as fh:
        content = fh.read().strip()
        if not content:
            return []
        return json.loads(content)


def _write_json(filepath: str, data: list) -> None:
    """Serialise *data* and write it to *filepath* (pretty-printed)."""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2)


# ---------------------------------------------------------------------------
# User helpers
# ---------------------------------------------------------------------------

def get_all_users() -> list:
    """Return all registered users."""
    return _read_json(USERS_FILE)


def get_user_by_username(username: str) -> dict | None:
    """Return the user dict for *username*, or None if not found."""
    users = get_all_users()
    for user in users:
        if user.get("username") == username:
            return user
    return None


def get_user_by_email(email: str) -> dict | None:
    """Return the user dict whose email matches *email* (case-insensitive)."""
    email = email.strip().lower()
    users = get_all_users()
    for user in users:
        if user.get("email", "").strip().lower() == email:
            return user
    return None


def save_user(user: dict) -> None:
    """Append *user* to the users store."""
    users = get_all_users()
    users.append(user)
    _write_json(USERS_FILE, users)


# ---------------------------------------------------------------------------
# Destination helpers
# ---------------------------------------------------------------------------

def get_all_destinations() -> list:
    """Return all destinations from the static catalogue."""
    return _read_json(DESTINATIONS_FILE)


# ---------------------------------------------------------------------------
# Itinerary helpers
# ---------------------------------------------------------------------------

def get_all_itineraries() -> list:
    """Return all itineraries across all users."""
    return _read_json(ITINERARIES_FILE)


def get_itineraries_for_user(username: str) -> list:
    """Return itineraries owned by the user with *username*."""
    return [it for it in get_all_itineraries() if it.get("username") == username]


def get_itineraries_shared_with(username: str) -> list:
    """Return itineraries another user has shared with *username*."""
    return [it for it in get_all_itineraries() if username in it.get("shared_with", [])]


def save_itinerary(itinerary: dict) -> None:
    """Append *itinerary* to the itineraries store."""
    itineraries = get_all_itineraries()
    itineraries.append(itinerary)
    _write_json(ITINERARIES_FILE, itineraries)


def update_itinerary(itinerary_id: str, owner_username: str, updates: dict) -> dict | None:
    """Apply *updates* to the itinerary with *itinerary_id*.

    Only the owner (*owner_username*) may update it. Returns the updated
    itinerary, or None if it doesn't exist or isn't owned by *owner_username*.
    """
    itineraries = get_all_itineraries()
    for it in itineraries:
        if it.get("id") == itinerary_id and it.get("username") == owner_username:
            it.update(updates)
            _write_json(ITINERARIES_FILE, itineraries)
            return it
    return None


def delete_itinerary(itinerary_id: str, owner_username: str) -> bool:
    """Delete the itinerary with *itinerary_id* if owned by *owner_username*.

    Returns True if an itinerary was deleted, False otherwise.
    """
    itineraries = get_all_itineraries()
    remaining = [it for it in itineraries if not (it.get("id") == itinerary_id and it.get("username") == owner_username)]
    if len(remaining) == len(itineraries):
        return False
    _write_json(ITINERARIES_FILE, remaining)
    return True


def share_itinerary(itinerary_id: str, owner_username: str, target_username: str) -> dict | None:
    """Grant *target_username* view access to the owner's itinerary.

    Returns the updated itinerary, or None if it doesn't exist or isn't
    owned by *owner_username*.
    """
    itineraries = get_all_itineraries()
    for it in itineraries:
        if it.get("id") == itinerary_id and it.get("username") == owner_username:
            shared_with = it.setdefault("shared_with", [])
            if target_username not in shared_with:
                shared_with.append(target_username)
            _write_json(ITINERARIES_FILE, itineraries)
            return it
    return None


def unshare_itinerary(itinerary_id: str, owner_username: str, target_username: str) -> dict | None:
    """Revoke *target_username*'s view access to the owner's itinerary.

    Returns the updated itinerary, or None if it doesn't exist or isn't
    owned by *owner_username*.
    """
    itineraries = get_all_itineraries()
    for it in itineraries:
        if it.get("id") == itinerary_id and it.get("username") == owner_username:
            shared_with = it.setdefault("shared_with", [])
            if target_username in shared_with:
                shared_with.remove(target_username)
            _write_json(ITINERARIES_FILE, itineraries)
            return it
    return None


def get_all_user_recommendations() -> list:
    """Return all user-submitted recommendations, across all users."""
    return _read_json(USER_RECOMMENDATIONS_FILE)


def get_user_recommendations_for_user(username: str) -> list:
    """Return recommendations submitted by the user with *username*."""
    return [r for r in get_all_user_recommendations() if r.get("username") == username]


def save_user_recommendation(recommendation: dict) -> None:
    """Append *recommendation* to the user-recommendations store."""
    recommendations = get_all_user_recommendations()
    recommendations.append(recommendation)
    _write_json(USER_RECOMMENDATIONS_FILE, recommendations)


def get_destination_popularity() -> dict:
    """Return a map of destination name (lowercased) -> number of itineraries
    that include it, across all users. Used to boost popular destinations
    in recommendations.
    """
    counts: dict = {}
    for it in get_all_itineraries():
        seen_in_this_itinerary = set()
        for name in it.get("destinations", []):
            key = str(name).strip().lower()
            if key and key not in seen_in_this_itinerary:
                counts[key] = counts.get(key, 0) + 1
                seen_in_this_itinerary.add(key)
    return counts
