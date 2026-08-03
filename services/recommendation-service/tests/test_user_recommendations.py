"""Tests for app/user_recommendations.py."""


def test_submit_recommendation_requires_auth(client):
    res = client.post("/my-recommendations", json={"destination": "Alpha Market", "message": "Great food!"})
    assert res.status_code == 401


def test_submit_recommendation_requires_destination_and_message(client, auth):
    headers = auth()
    res = client.post("/my-recommendations", json={"destination": "", "message": ""}, headers=headers)
    assert res.status_code == 400


def test_submit_recommendation_success(client, auth):
    headers = auth(email="alice@example.com", name="Alice")
    res = client.post(
        "/my-recommendations",
        json={"destination": "Alpha Market", "message": "Great street food, go on a Saturday!"},
        headers=headers,
    )
    assert res.status_code == 201
    body = res.get_json()
    assert body["destination"] == "Alpha Market"
    assert body["message"] == "Great street food, go on a Saturday!"
    assert body["email"] == "alice@example.com"
    assert body["name"] == "Alice"
    assert "id" in body and "created_at" in body


def test_list_my_recommendations_only_shows_own(client, auth):
    alice = auth(email="alice@example.com", name="Alice")
    bob = auth(email="bob@example.com", name="Bob")
    client.post("/my-recommendations", json={"destination": "Alpha Market", "message": "Nice!"}, headers=alice)
    client.post("/my-recommendations", json={"destination": "Beta Park", "message": "Peaceful."}, headers=bob)

    res = client.get("/my-recommendations", headers=alice)
    destinations = [r["destination"] for r in res.get_json()]
    assert destinations == ["Alpha Market"]


def test_admin_endpoint_requires_auth(client):
    res = client.get("/admin/recommendations")
    assert res.status_code == 401


def test_admin_endpoint_rejects_non_admin(client, auth):
    auth(email="alice@example.com", name="Alice")  # first registered -> admin
    bob_headers = auth(email="bob@example.com", name="Bob")  # second -> not admin

    res = client.get("/admin/recommendations", headers=bob_headers)
    assert res.status_code == 403


def test_admin_endpoint_returns_all_users_submissions(client, auth):
    admin_headers = auth(email="alice@example.com", name="Alice")  # first registered -> admin
    bob_headers = auth(email="bob@example.com", name="Bob")

    client.post("/my-recommendations", json={"destination": "Alpha Market", "message": "From alice"}, headers=admin_headers)
    client.post("/my-recommendations", json={"destination": "Beta Park", "message": "From bob"}, headers=bob_headers)

    res = client.get("/admin/recommendations", headers=admin_headers)
    assert res.status_code == 200
    submissions = {(r["email"], r["destination"]) for r in res.get_json()}
    assert submissions == {("alice@example.com", "Alpha Market"), ("bob@example.com", "Beta Park")}
