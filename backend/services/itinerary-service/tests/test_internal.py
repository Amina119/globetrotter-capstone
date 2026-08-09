"""Tests for the internal (service-to-service) endpoints in app/itineraries.py."""


def _create(client, headers, **overrides):
    payload = {"title": "Summer trip", "destinations": ["Alpha Market", "Beta Park"]}
    payload.update(overrides)
    return client.post("/itineraries", json=payload, headers=headers)


def test_internal_list_requires_email_param(client):
    res = client.get("/internal/itineraries")
    assert res.status_code == 400


def test_internal_list_returns_only_that_users_itineraries(client, auth):
    alice = auth(email="alice@example.com")
    bob = auth(email="bob@example.com")
    _create(client, alice, title="Alice's trip")
    _create(client, bob, title="Bob's trip")

    res = client.get("/internal/itineraries", query_string={"email": "alice@example.com"})
    assert res.status_code == 200
    titles = [it["title"] for it in res.get_json()]
    assert titles == ["Alice's trip"]


def test_internal_popularity_counts_destinations_once_per_itinerary(client, auth):
    alice = auth(email="alice@example.com")
    bob = auth(email="bob@example.com")
    _create(client, alice, destinations=["Alpha Market", "Alpha Market", "Beta Park"])
    _create(client, bob, destinations=["Alpha Market"])

    res = client.get("/internal/itineraries/popularity")
    assert res.status_code == 200
    body = res.get_json()
    assert body["alpha market"] == 2  # deduped within Alice's own itinerary
    assert body["beta park"] == 1
