"""Tests for app/itineraries.py: create, view, manage, and share itineraries."""


def _create(client, headers, **overrides):
    payload = {
        "title": "Summer trip",
        "destinations": ["Alpha Market"],
        "start_date": "2026-06-01",
        "end_date": "2026-06-10",
        "notes": "Bring sunscreen",
    }
    payload.update(overrides)
    return client.post("/itineraries", json=payload, headers=headers)


# --- create -----------------------------------------------------------------


def test_create_requires_auth(client):
    res = client.post("/itineraries", json={"title": "Trip", "destinations": []})
    assert res.status_code == 401


def test_create_requires_title(client, auth):
    headers = auth()
    res = _create(client, headers, title="")
    assert res.status_code == 400


def test_create_requires_destinations_to_be_a_list(client, auth):
    headers = auth()
    res = _create(client, headers, destinations="not-a-list")
    assert res.status_code == 400


def test_create_success(client, auth):
    headers = auth()
    res = _create(client, headers)
    assert res.status_code == 201
    body = res.get_json()
    assert body["title"] == "Summer trip"
    assert body["shared_with"] == []
    assert "id" in body and "created_at" in body


# --- list / shared ------------------------------------------------------------


def test_list_only_returns_own_itineraries(client, auth):
    alice = auth(email="alice@example.com")
    bob = auth(email="bob@example.com")
    _create(client, alice, title="Alice's trip")
    _create(client, bob, title="Bob's trip")

    res = client.get("/itineraries", headers=alice)
    titles = [it["title"] for it in res.get_json()]
    assert titles == ["Alice's trip"]


def test_shared_endpoint_lists_itineraries_shared_with_me(client, auth):
    alice = auth(email="alice@example.com")
    bob = auth(email="bob@example.com")
    created = _create(client, alice, title="Alice's trip").get_json()

    client.post(f"/itineraries/{created['id']}/share", json={"email": "bob@example.com"}, headers=alice)

    res = client.get("/itineraries/shared", headers=bob)
    titles = [it["title"] for it in res.get_json()]
    assert titles == ["Alice's trip"]

    # It should not show up in Bob's own list.
    own = client.get("/itineraries", headers=bob).get_json()
    assert own == []


# --- update -------------------------------------------------------------------


def test_update_by_owner_succeeds(client, auth):
    headers = auth()
    created = _create(client, headers).get_json()

    res = client.put(f"/itineraries/{created['id']}", json={"notes": "Updated notes"}, headers=headers)
    assert res.status_code == 200
    assert res.get_json()["notes"] == "Updated notes"


def test_update_by_non_owner_fails(client, auth):
    alice = auth(email="alice@example.com")
    bob = auth(email="bob@example.com")
    created = _create(client, alice).get_json()

    res = client.put(f"/itineraries/{created['id']}", json={"notes": "Hijacked"}, headers=bob)
    assert res.status_code == 404


def test_update_nonexistent_itinerary(client, auth):
    headers = auth()
    res = client.put("/itineraries/does-not-exist", json={"notes": "x"}, headers=headers)
    assert res.status_code == 404


def test_update_rejects_empty_title(client, auth):
    headers = auth()
    created = _create(client, headers).get_json()
    res = client.put(f"/itineraries/{created['id']}", json={"title": "   "}, headers=headers)
    assert res.status_code == 400


def test_update_rejects_non_list_destinations(client, auth):
    headers = auth()
    created = _create(client, headers).get_json()
    res = client.put(f"/itineraries/{created['id']}", json={"destinations": "nope"}, headers=headers)
    assert res.status_code == 400


def test_update_ignores_unknown_fields(client, auth):
    headers = auth()
    created = _create(client, headers).get_json()
    res = client.put(f"/itineraries/{created['id']}", json={"email": "hacker@example.com"}, headers=headers)
    assert res.status_code == 200
    assert res.get_json()["email"] != "hacker@example.com"


# --- delete -------------------------------------------------------------------


def test_delete_by_owner_succeeds(client, auth):
    headers = auth()
    created = _create(client, headers).get_json()

    res = client.delete(f"/itineraries/{created['id']}", headers=headers)
    assert res.status_code == 200

    remaining = client.get("/itineraries", headers=headers).get_json()
    assert remaining == []


def test_delete_by_non_owner_fails(client, auth):
    alice = auth(email="alice@example.com")
    bob = auth(email="bob@example.com")
    created = _create(client, alice).get_json()

    res = client.delete(f"/itineraries/{created['id']}", headers=bob)
    assert res.status_code == 404


def test_delete_nonexistent_itinerary(client, auth):
    headers = auth()
    res = client.delete("/itineraries/does-not-exist", headers=headers)
    assert res.status_code == 404


# --- share / unshare ------------------------------------------------------------


def test_share_requires_email(client, auth):
    headers = auth()
    created = _create(client, headers).get_json()
    res = client.post(f"/itineraries/{created['id']}/share", json={}, headers=headers)
    assert res.status_code == 400


def test_share_with_self_is_rejected(client, auth):
    headers = auth(email="alice@example.com")
    created = _create(client, headers).get_json()
    res = client.post(f"/itineraries/{created['id']}/share", json={"email": "alice@example.com"}, headers=headers)
    assert res.status_code == 400


def test_share_with_unknown_account_fails(client, auth):
    headers = auth()
    created = _create(client, headers).get_json()
    res = client.post(f"/itineraries/{created['id']}/share", json={"email": "ghost@example.com"}, headers=headers)
    assert res.status_code == 404


def test_share_success_and_is_idempotent(client, auth):
    alice = auth(email="alice@example.com")
    auth(email="bob@example.com")
    created = _create(client, alice).get_json()

    first = client.post(f"/itineraries/{created['id']}/share", json={"email": "bob@example.com"}, headers=alice)
    second = client.post(f"/itineraries/{created['id']}/share", json={"email": "bob@example.com"}, headers=alice)

    assert first.status_code == 200
    assert second.status_code == 200
    assert first.get_json()["shared_with"] == ["bob@example.com"]
    assert second.get_json()["shared_with"] == ["bob@example.com"]  # not duplicated


def test_share_by_non_owner_fails(client, auth):
    alice = auth(email="alice@example.com")
    bob = auth(email="bob@example.com")
    auth(email="carol@example.com")
    created = _create(client, alice).get_json()

    res = client.post(f"/itineraries/{created['id']}/share", json={"email": "carol@example.com"}, headers=bob)
    assert res.status_code == 404


def test_unshare_removes_access(client, auth):
    alice = auth(email="alice@example.com")
    bob = auth(email="bob@example.com")
    created = _create(client, alice).get_json()
    client.post(f"/itineraries/{created['id']}/share", json={"email": "bob@example.com"}, headers=alice)

    res = client.delete(f"/itineraries/{created['id']}/share", json={"email": "bob@example.com"}, headers=alice)
    assert res.status_code == 200
    assert res.get_json()["shared_with"] == []

    shared_with_bob = client.get("/itineraries/shared", headers=bob).get_json()
    assert shared_with_bob == []
