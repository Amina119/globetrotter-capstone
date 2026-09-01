"""
app/models.py

Destination catalogue and user-submitted-recommendation data models, plus
file I/O helpers.

All persistent data is stored in JSON files under the /data directory:
  - data/destinations.json         – static destination catalogue (seed data)
  - data/user_recommendations.json – recommendations submitted by users
"""
import json
import os

# Resolve the /data directory relative to this file's location so the app
# works regardless of the current working directory.
_BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(_BASE_DIR, "data")


DESTINATIONS_FILE = os.path.join(DATA_DIR, "destinations.json")
USER_RECOMMENDATIONS_FILE = os.path.join(DATA_DIR, "user_recommendations.json")
PLACE_REVIEWS_FILE = os.path.join(DATA_DIR, "place_reviews.json")
PLACE_COMMENTS_FILE = os.path.join(DATA_DIR, "place_comments.json")


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
# Destination helpers
# ---------------------------------------------------------------------------

def get_all_destinations() -> list:
    """Return all destinations from the static catalogue."""
    return _read_json(DESTINATIONS_FILE)


def get_destination_by_id(destination_id: str) -> dict | None:
    """Return the destination with *destination_id*, or None if not found."""
    for dest in get_all_destinations():
        if dest.get("id") == destination_id:
            return dest
    return None


def save_destination(destination: dict) -> None:
    """Append *destination* to the catalogue."""
    destinations = get_all_destinations()
    destinations.append(destination)
    _write_json(DESTINATIONS_FILE, destinations)


def update_destination(destination_id: str, updates: dict) -> dict | None:
    """Apply *updates* to the destination with *destination_id*.

    Returns the updated destination, or None if no destination matches.
    """
    destinations = get_all_destinations()
    for dest in destinations:
        if dest.get("id") == destination_id:
            dest.update(updates)
            _write_json(DESTINATIONS_FILE, destinations)
            return dest
    return None


def delete_destination(destination_id: str) -> bool:
    """Remove the destination with *destination_id*.

    Returns True if a destination was removed, False if none matched.
    """
    destinations = get_all_destinations()
    remaining = [d for d in destinations if d.get("id") != destination_id]
    if len(remaining) == len(destinations):
        return False
    _write_json(DESTINATIONS_FILE, remaining)
    return True


# ---------------------------------------------------------------------------
# User-submitted recommendation helpers
# ---------------------------------------------------------------------------

def get_all_user_recommendations() -> list:
    """Return all user-submitted recommendations, across all users."""
    return _read_json(USER_RECOMMENDATIONS_FILE)


def get_user_recommendations_for_user(email: str) -> list:
    """Return recommendations submitted by the user with *email*."""
    return [r for r in get_all_user_recommendations() if r.get("email") == email]


def save_user_recommendation(recommendation: dict) -> None:
    """Append *recommendation* to the user-recommendations store."""
    recommendations = get_all_user_recommendations()
    recommendations.append(recommendation)
    _write_json(USER_RECOMMENDATIONS_FILE, recommendations)


# ---------------------------------------------------------------------------
# Per-place review helpers
# ---------------------------------------------------------------------------

def get_reviews_for_place(place_id: str) -> list:
    """Return every review for *place_id*, newest first."""
    entries = [e for e in _read_json(PLACE_REVIEWS_FILE) if e.get("place_id") == place_id]
    return sorted(entries, key=lambda e: e.get("updated_at", ""), reverse=True)


def upsert_place_review(place_id: str, email: str, entry: dict) -> None:
    """Create or replace *email*'s review of *place_id*."""
    entries = _read_json(PLACE_REVIEWS_FILE)
    entries = [e for e in entries if not (e.get("place_id") == place_id and e.get("email") == email)]
    entries.append(entry)
    _write_json(PLACE_REVIEWS_FILE, entries)


def delete_place_review(place_id: str, email: str) -> bool:
    """Remove *email*'s review of *place_id*. Returns False if none existed."""
    entries = _read_json(PLACE_REVIEWS_FILE)
    remaining = [e for e in entries if not (e.get("place_id") == place_id and e.get("email") == email)]
    if len(remaining) == len(entries):
        return False
    _write_json(PLACE_REVIEWS_FILE, remaining)
    return True

# ---------------------------------------------------------------------------
# Per-place comment helpers
# ---------------------------------------------------------------------------
def get_comments_for_place(place_id: str) -> list:
    """Return every comment for *place_id*, oldest first."""
    
    entries = [e for e in _read_json(PLACE_COMMENTS_FILE) if e.get("place_id") == place_id]
    return sorted(entries, key=lambda e: e.get("created_at", ""))

def add_comment(entry: dict) -> None:
    """Append *entry* to the comments store."""
    entries = _read_json(PLACE_COMMENTS_FILE)
    entries.append(entry)
    _write_json(PLACE_COMMENTS_FILE, entries)


def delete_comment(comment_id: str, email: str) -> bool:
    """Replace *email*'s comment with a "[deleted]" placeholder.

    Returns False if no comment with that id belongs to *email*.
    """
    entries = _read_json(PLACE_COMMENTS_FILE)
    match = next((e for e in entries if e.get("id") == comment_id and e.get("email") == email), None)
    if match is None:
        return False
    match["text"] = "[deleted]"
    _write_json(PLACE_COMMENTS_FILE, entries)
    return True










