"""Tests for app/user_recommendations.py and the is_admin bootstrap in app/auth.py."""


def test_first_registered_user_is_admin(client):
    first = client.post("/register", json={"username": "alice", "email": "alice@example.com", "password": "secret123"})
    second = client.post("/register", json={"username": "bob", "email": "bob@example.com", "password": "secret123"})

    assert first.get_json()["is_admin"] is True
    assert second.get_json()["is_admin"] is False


def test_login_reports_is_admin(client, auth):
    admin_headers = auth(username="alice")
    other_headers = auth(username="bob")

    admin_login = client.post("/login", json={"email": "alice@example.com", "password": "secret123"}).get_json()
    other_login = client.post("/login", json={"email": "bob@example.com", "password": "secret123"}).get_json()

    assert admin_login["is_admin"] is True
    assert other_login["is_admin"] is False
    # headers fixtures still work regardless
    assert admin_headers != other_headers


def test_submit_recommendation_requires_auth(client):
    res = client.post("/my-recommendations", json={"destination": "Alpha Market", "message": "Great food!"})
    assert res.status_code == 401


def test_submit_recommendation_requires_destination_and_message(client, auth):
    headers = auth()
    res = client.post("/my-recommendations", json={"destination": "", "message": ""}, headers=headers)
    assert res.status_code == 400


def test_submit_recommendation_success(client, auth):
    headers = auth()
    res = client.post(
        "/my-recommendations",
        json={"destination": "Alpha Market", "message": "Great street food, go on a Saturday!"},
        headers=headers,
    )
    assert res.status_code == 201
    body = res.get_json()
    assert body["destination"] == "Alpha Market"
    assert body["message"] == "Great street food, go on a Saturday!"
    assert "id" in body and "created_at" in body


def test_list_my_recommendations_only_shows_own(client, auth):
    alice = auth(username="alice")
    bob = auth(username="bob")
    client.post("/my-recommendations", json={"destination": "Alpha Market", "message": "Nice!"}, headers=alice)
    client.post("/my-recommendations", json={"destination": "Beta Park", "message": "Peaceful."}, headers=bob)

    res = client.get("/my-recommendations", headers=alice)
    destinations = [r["destination"] for r in res.get_json()]
    assert destinations == ["Alpha Market"]


def test_admin_endpoint_requires_auth(client):
    res = client.get("/admin/recommendations")
    assert res.status_code == 401


def test_admin_endpoint_rejects_non_admin(client, auth):
    auth(username="alice")  # first registered -> admin
    bob_headers = auth(username="bob")  # second -> not admin

    res = client.get("/admin/recommendations", headers=bob_headers)
    assert res.status_code == 403


def test_admin_endpoint_returns_all_users_submissions(client, auth):
    admin_headers = auth(username="alice")  # first registered -> admin
    bob_headers = auth(username="bob")

    client.post("/my-recommendations", json={"destination": "Alpha Market", "message": "From alice"}, headers=admin_headers)
    client.post("/my-recommendations", json={"destination": "Beta Park", "message": "From bob"}, headers=bob_headers)

    res = client.get("/admin/recommendations", headers=admin_headers)
    assert res.status_code == 200
    submissions = {(r["username"], r["destination"]) for r in res.get_json()}
    assert submissions == {("alice", "Alpha Market"), ("bob", "Beta Park")}
