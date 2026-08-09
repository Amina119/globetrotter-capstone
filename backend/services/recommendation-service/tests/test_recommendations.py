"""Tests for app/recommendations.py: blended preference/past-trip/popularity scoring."""
import pytest


def test_requires_auth(client):
    res = client.get("/recommendations")
    assert res.status_code == 401


def test_preference_scoring_orders_matching_tags_first(client, auth):
    headers = auth(email="alice@example.com", preferences=["culture"])
    res = client.get("/recommendations", headers=headers)
    assert res.status_code == 200
    body = res.get_json()
    scores = {d["name"]: d["match_score"] for d in body}

    assert scores["Alpha Market"] == pytest.approx(1.0)  # has "culture" tag
    assert scores["Gamma Palace"] == pytest.approx(1.0)  # has "culture" tag
    assert scores["Beta Park"] == pytest.approx(0.0)  # no matching tag

    # Highest-scored destinations come first, alphabetically tie-broken.
    assert [d["name"] for d in body][:2] == ["Alpha Market", "Gamma Palace"]


def test_limit_param_caps_results(client, auth):
    headers = auth(preferences=["culture"])
    res = client.get("/recommendations?limit=1", headers=headers)
    assert len(res.get_json()) == 1


def test_invalid_limit_param(client, auth):
    headers = auth()
    res = client.get("/recommendations?limit=not-a-number", headers=headers)
    assert res.status_code == 400


def test_past_trip_affinity_boosts_similar_destinations(client, auth, add_itinerary):
    headers = auth(email="alice@example.com", preferences=[])
    add_itinerary("alice@example.com", ["Alpha Market"])

    res = client.get("/recommendations", headers=headers)
    scores = {d["name"]: d["match_score"] for d in res.get_json()}

    # Alpha Market: 0 preference + (food+culture=2 tag matches * 0.5) past-trip
    #   + popularity (only itinerary references it, so 1/1 * 0.2) = 1.2
    assert scores["Alpha Market"] == pytest.approx(1.2)
    # Gamma Palace shares the "culture" tag with the visited destination: 1 * 0.5 = 0.5
    assert scores["Gamma Palace"] == pytest.approx(0.5)
    # Beta Park shares no tags with anything visited.
    assert scores["Beta Park"] == pytest.approx(0.0)


def test_popularity_boosts_destination_for_a_user_who_never_visited_it(client, auth, add_itinerary):
    # Two other users each have an itinerary that includes Beta Park.
    auth(email="bob@example.com")
    auth(email="carol@example.com")
    add_itinerary("bob@example.com", ["Beta Park"])
    add_itinerary("carol@example.com", ["Beta Park"])

    # A third user, with no preferences and no past trips of their own, still
    # sees Beta Park boosted purely by its popularity across other users.
    headers_dave = auth(email="dave@example.com")
    res = client.get("/recommendations", headers=headers_dave)
    scores = {d["name"]: d["match_score"] for d in res.get_json()}

    assert scores["Beta Park"] == pytest.approx(0.2)
    assert scores["Alpha Market"] == pytest.approx(0.0)
    assert scores["Gamma Palace"] == pytest.approx(0.0)
