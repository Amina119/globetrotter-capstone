"""
app/models.py

User data model and file I/O helpers.

All persistent data is stored in a JSON file under the /data directory:
  - data/users.json – registered users
"""
import json
import os
import threading

# Resolve the /data directory relative to this file's location so the app
# works regardless of the current working directory.
_BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(_BASE_DIR, "data")

USERS_FILE = os.path.join(DATA_DIR, "users.json")
CHAT_MESSAGES_FILE = os.path.join(DATA_DIR, "chat_messages.json")

FEEDBACK_FILE = os.path.join(DATA_DIR, "feedback.json")


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


def get_user_by_email(email: str) -> dict | None:
    """Return the user dict for *email*, or None if not found."""
    users = get_all_users()
    for user in users:
        if user.get("email") == email:
            return user
    return None


def save_user(user: dict) -> None:
    """Append *user* to the users store."""
    users = get_all_users()
    users.append(user)
    _write_json(USERS_FILE, users)


# Guards the check-then-create sequence in get_or_create_user_by_email so two
# concurrent requests for the same brand-new email (e.g. a user clicking
# "Sign in with Google" twice, or on two tabs) can't both see "no existing
# user" and each create a duplicate account. The Flask dev server runs
# threaded (see main.py), so without this lock that race is real, not
# theoretical — it's what actually created duplicate accounts in practice.
_users_write_lock = threading.Lock()


def get_or_create_user_by_email(email: str, build_user) -> dict:
    """Return the existing user for *email*, or atomically create one.

    *build_user* is a zero-argument callable returning the new user dict to
    save if none exists yet — it's only invoked if a create is actually
    needed, and the whole check-and-create happens under one lock so two
    simultaneous callers can't both create an account for the same email.
    """
    with _users_write_lock:
        user = get_user_by_email(email)
        if user is not None:
            return user
        user = build_user()
        save_user(user)
        return user


def update_user(email: str, updates: dict) -> dict | None:
    """Apply *updates* to the user with *email*. Returns the updated user,
    or None if no user with that email exists.
    """
    users = get_all_users()
    for user in users:
        if user.get("email") == email:
            user.update(updates)
            _write_json(USERS_FILE, users)
            return user
    return None


# ---------------------------------------------------------------------------
# App-wide feedback helpers
# ---------------------------------------------------------------------------

def get_all_feedback() -> list:
    """Return every feedback entry, newest first."""
    entries = _read_json(FEEDBACK_FILE)
    return sorted(entries, key=lambda e: e.get("updated_at", ""), reverse=True)


def upsert_feedback(email: str, entry: dict) -> None:
    """Create or replace *email*'s feedback entry."""
    entries = _read_json(FEEDBACK_FILE)
    entries = [e for e in entries if e.get("email") != email]
    entries.append(entry)
    _write_json(FEEDBACK_FILE, entries)


def delete_feedback(email: str) -> bool:
    """Remove *email*'s feedback entry. Returns False if none existed."""
    entries = _read_json(FEEDBACK_FILE)
    remaining = [e for e in entries if e.get("email") != email]
    if len(remaining) == len(entries):
        return False
    _write_json(FEEDBACK_FILE, remaining)
    return True

# ---------------------------------------------------------------------------
# Chat helpers
# ---------------------------------------------------------------------------

def get_all_messages() -> list:
    """Return every chat message, oldest first."""
    entries = _read_json(CHAT_MESSAGES_FILE)
    return sorted(entries, key=lambda e: e.get("created_at", ""))


def add_message(entry: dict) -> None:
    """Append *entry* to the chat messages store."""
    entries = _read_json(CHAT_MESSAGES_FILE)
    entries.append(entry)
    _write_json(CHAT_MESSAGES_FILE, entries)


def delete_message(message_id: str, email: str) -> bool:
    """Replace *email*'s message with a "[deleted]" placeholder.

    Returns False if no message with that id belongs to *email*.
    """
    entries = _read_json(CHAT_MESSAGES_FILE)
    match = next((e for e in entries if e.get("id") == message_id and e.get("email") == email), None)
    if match is None:
        return False
    match["text"] = "[deleted]"
    _write_json(CHAT_MESSAGES_FILE, entries)
    return True
