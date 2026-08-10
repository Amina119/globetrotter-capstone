"""Tests for the admin-only destination CRUD routes in app/destinations.py."""


def test_create_requires_auth(client):
    res = client.post("/admin/destinations", json={"name": "New Place"})
    assert res.status_code == 401


def test_create_rejects_non_admin(client, auth, seeded_destinations):
    auth(email="alice@example.com")  # first registered -> admin
    bob_headers = auth(email="bob@example.com")  # second -> not admin

    res = client.post("/admin/destinations", json={"name": "New Place"}, headers=bob_headers)
    assert res.status_code == 403


def test_create_destination_with_position(client, auth, seeded_destinations):
    admin_headers = auth(email="alice@example.com")

    res = client.post(
        "/admin/destinations",
        json={
            "name": "New Place",
            "Town": "Yaoundé",
            "quarter": "Nkolmbong",
            "sector": "A brand new spot.",
            "tags": ["nature"],
            "avg_cost_per_day": 1500,
            "latitude": 3.848,
            "longitude": 11.502,
        },
        headers=admin_headers,
    )
    assert res.status_code == 201
    body = res.get_json()
    assert body["name"] == "New Place"
    assert body["latitude"] == 3.848
    assert body["longitude"] == 11.502
    assert "id" in body

    # It should now show up in the public catalogue too.
    res = client.get("/destinations")
    names = [d["name"] for d in res.get_json()]
    assert "New Place" in names


def test_create_destination_without_position(client, auth, seeded_destinations):
    admin_headers = auth(email="alice@example.com")

    res = client.post("/admin/destinations", json={"name": "No Pin Yet"}, headers=admin_headers)
    assert res.status_code == 201
    body = res.get_json()
    assert body["latitude"] is None
    assert body["longitude"] is None


def test_create_requires_name(client, auth, seeded_destinations):
    admin_headers = auth(email="alice@example.com")
    res = client.post("/admin/destinations", json={}, headers=admin_headers)
    assert res.status_code == 400


def test_create_rejects_invalid_coordinates(client, auth, seeded_destinations):
    admin_headers = auth(email="alice@example.com")
    res = client.post(
        "/admin/destinations",
        json={"name": "Bad Coords", "latitude": "not-a-number"},
        headers=admin_headers,
    )
    assert res.status_code == 400


def test_edit_destination_position(client, auth, seeded_destinations):
    admin_headers = auth(email="alice@example.com")

    res = client.put(
        "/admin/destinations/d1",
        json={"latitude": 3.9, "longitude": 11.6},
        headers=admin_headers,
    )
    assert res.status_code == 200
    body = res.get_json()
    assert body["latitude"] == 3.9
    assert body["longitude"] == 11.6
    # Fields not sent are left untouched.
    assert body["name"] == "Alpha Market"


def test_edit_rejects_non_admin(client, auth, seeded_destinations):
    auth(email="alice@example.com")
    bob_headers = auth(email="bob@example.com")
    res = client.put("/admin/destinations/d1", json={"latitude": 1.0}, headers=bob_headers)
    assert res.status_code == 403


def test_edit_missing_destination_404s(client, auth, seeded_destinations):
    admin_headers = auth(email="alice@example.com")
    res = client.put("/admin/destinations/does-not-exist", json={"name": "x"}, headers=admin_headers)
    assert res.status_code == 404


def test_delete_destination(client, auth, seeded_destinations):
    admin_headers = auth(email="alice@example.com")

    res = client.delete("/admin/destinations/d1", headers=admin_headers)
    assert res.status_code == 200

    res = client.get("/destinations")
    ids = [d["id"] for d in res.get_json()]
    assert "d1" not in ids


def test_delete_missing_destination_404s(client, auth, seeded_destinations):
    admin_headers = auth(email="alice@example.com")
    res = client.delete("/admin/destinations/does-not-exist", headers=admin_headers)
    assert res.status_code == 404


def test_delete_rejects_non_admin(client, auth, seeded_destinations):
    auth(email="alice@example.com")
    bob_headers = auth(email="bob@example.com")
    res = client.delete("/admin/destinations/d1", headers=bob_headers)
    assert res.status_code == 403
