"""Direct unit tests for app/models.py, independent of the Flask routes."""
from app import models


# --- generic JSON I/O ---------------------------------------------------------


def test_read_json_missing_file_returns_empty_list(isolated_data):
    assert models._read_json(str(isolated_data / "does-not-exist.json")) == []


def test_write_then_read_json_roundtrip(isolated_data):
    path = str(isolated_data / "roundtrip.json")
    models._write_json(path, [{"a": 1}])
    assert models._read_json(path) == [{"a": 1}]


# --- users ---------------------------------------------------------------------


def test_save_and_get_user_by_email(isolated_data):
    assert models.get_user_by_email("alice@example.com") is None
    models.save_user({"email": "alice@example.com", "name": "Alice"})
    user = models.get_user_by_email("alice@example.com")
    assert user is not None
    assert user["name"] == "Alice"


# --- itineraries: ownership-scoped queries --------------------------------------


def test_get_itineraries_for_user_filters_by_owner(isolated_data):
    models.save_itinerary({"id": "1", "email": "alice@example.com", "destinations": []})
    models.save_itinerary({"id": "2", "email": "bob@example.com", "destinations": []})

    alice_trips = models.get_itineraries_for_user("alice@example.com")
    assert [it["id"] for it in alice_trips] == ["1"]


def test_get_itineraries_shared_with(isolated_data):
    models.save_itinerary({"id": "1", "email": "alice@example.com", "destinations": [], "shared_with": ["bob@example.com"]})
    models.save_itinerary({"id": "2", "email": "alice@example.com", "destinations": [], "shared_with": []})

    shared_with_bob = models.get_itineraries_shared_with("bob@example.com")
    assert [it["id"] for it in shared_with_bob] == ["1"]


# --- itineraries: update / delete / share enforce ownership ---------------------


def test_update_itinerary_requires_ownership(isolated_data):
    models.save_itinerary({"id": "1", "email": "alice@example.com", "title": "Old", "destinations": []})

    assert models.update_itinerary("1", "bob@example.com", {"title": "Hijacked"}) is None
    updated = models.update_itinerary("1", "alice@example.com", {"title": "New"})
    assert updated["title"] == "New"


def test_delete_itinerary_requires_ownership(isolated_data):
    models.save_itinerary({"id": "1", "email": "alice@example.com", "destinations": []})

    assert models.delete_itinerary("1", "bob@example.com") is False
    assert models.delete_itinerary("1", "alice@example.com") is True
    assert models.get_all_itineraries() == []


def test_share_and_unshare_itinerary(isolated_data):
    models.save_itinerary({"id": "1", "email": "alice@example.com", "destinations": [], "shared_with": []})

    shared = models.share_itinerary("1", "alice@example.com", "bob@example.com")
    assert shared["shared_with"] == ["bob@example.com"]

    # Sharing again with the same person doesn't duplicate.
    shared_again = models.share_itinerary("1", "alice@example.com", "bob@example.com")
    assert shared_again["shared_with"] == ["bob@example.com"]

    unshared = models.unshare_itinerary("1", "alice@example.com", "bob@example.com")
    assert unshared["shared_with"] == []


def test_share_itinerary_requires_ownership(isolated_data):
    models.save_itinerary({"id": "1", "email": "alice@example.com", "destinations": [], "shared_with": []})
    assert models.share_itinerary("1", "bob@example.com", "carol@example.com") is None


# --- destination popularity -----------------------------------------------------


def test_destination_popularity_counts_across_itineraries(isolated_data):
    models.save_itinerary({"id": "1", "email": "alice@example.com", "destinations": ["Alpha Market", "Beta Park"]})
    models.save_itinerary({"id": "2", "email": "bob@example.com", "destinations": ["Alpha Market"]})

    popularity = models.get_destination_popularity()
    assert popularity["alpha market"] == 2
    assert popularity["beta park"] == 1


def test_destination_popularity_counts_each_itinerary_once_even_with_duplicates(isolated_data):
    models.save_itinerary({"id": "1", "email": "alice@example.com", "destinations": ["Alpha Market", "Alpha Market"]})

    popularity = models.get_destination_popularity()
    assert popularity["alpha market"] == 1


def test_destination_popularity_empty_when_no_itineraries(isolated_data):
    assert models.get_destination_popularity() == {}
