"""
app/models.py

Itinerary data model and file I/O helpers.

All persistent data is stored in a JSON file under the /data directory:
  - data/itineraries.json – user itineraries
"""
import json
import os

# Resolve the /data directory relative to this file's location so the app
# works regardless of the current working directory.
_BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(_BASE_DIR, "data")

ITINERARIES_FILE = os.path.join(DATA_DIR, "itineraries.json")


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
# Itinerary helpers
# ---------------------------------------------------------------------------

def get_all_itineraries() -> list:
    """Return all itineraries across all users."""
    return _read_json(ITINERARIES_FILE)


def get_itineraries_for_user(email: str) -> list:
    """Return itineraries owned by the user with *email*."""
    return [it for it in get_all_itineraries() if it.get("email") == email]


def get_itineraries_shared_with(email: str) -> list:
    """Return itineraries another user has shared with *email*."""
    return [it for it in get_all_itineraries() if email in it.get("shared_with", [])]


def save_itinerary(itinerary: dict) -> None:
    """Append *itinerary* to the itineraries store."""
    itineraries = get_all_itineraries()
    itineraries.append(itinerary)
    _write_json(ITINERARIES_FILE, itineraries)


def update_itinerary(itinerary_id: str, owner_email: str, updates: dict) -> dict | None:
    """Apply *updates* to the itinerary with *itinerary_id*.

    Only the owner (*owner_email*) may update it. Returns the updated
    itinerary, or None if it doesn't exist or isn't owned by *owner_email*.
    """
    itineraries = get_all_itineraries()
    for it in itineraries:
        if it.get("id") == itinerary_id and it.get("email") == owner_email:
            it.update(updates)
            _write_json(ITINERARIES_FILE, itineraries)
            return it
    return None


def delete_itinerary(itinerary_id: str, owner_email: str) -> bool:
    """Delete the itinerary with *itinerary_id* if owned by *owner_email*.

    Returns True if an itinerary was deleted, False otherwise.
    """
    itineraries = get_all_itineraries()
    remaining = [it for it in itineraries if not (it.get("id") == itinerary_id and it.get("email") == owner_email)]
    if len(remaining) == len(itineraries):
        return False
    _write_json(ITINERARIES_FILE, remaining)
    return True


def share_itinerary(itinerary_id: str, owner_email: str, target_email: str) -> dict | None:
    """Grant *target_email* view access to the owner's itinerary.

    Returns the updated itinerary, or None if it doesn't exist or isn't
    owned by *owner_email*.
    """
    itineraries = get_all_itineraries()
    for it in itineraries:
        if it.get("id") == itinerary_id and it.get("email") == owner_email:
            shared_with = it.setdefault("shared_with", [])
            if target_email not in shared_with:
                shared_with.append(target_email)
            _write_json(ITINERARIES_FILE, itineraries)
            return it
    return None


def unshare_itinerary(itinerary_id: str, owner_email: str, target_email: str) -> dict | None:
    """Revoke *target_email*'s view access to the owner's itinerary.

    Returns the updated itinerary, or None if it doesn't exist or isn't
    owned by *owner_email*.
    """
    itineraries = get_all_itineraries()
    for it in itineraries:
        if it.get("id") == itinerary_id and it.get("email") == owner_email:
            shared_with = it.setdefault("shared_with", [])
            if target_email in shared_with:
                shared_with.remove(target_email)
            _write_json(ITINERARIES_FILE, itineraries)
            return it
    return None


def get_destination_popularity() -> dict:
    """Return a map of destination name (lowercased) -> number of itineraries
    that include it, across all users. Used by the Recommendation Service to
    boost popular destinations in its scoring.
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
