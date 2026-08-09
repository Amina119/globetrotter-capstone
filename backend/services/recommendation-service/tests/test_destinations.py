"""Tests for app/destinations.py: the /destinations search endpoint."""


def test_no_filters_returns_full_catalogue(client):
    res = client.get("/destinations")
    assert res.status_code == 200
    names = {d["name"] for d in res.get_json()}
    assert names == {"Alpha Market", "Beta Park", "Gamma Palace"}


def test_query_matches_name_case_insensitively(client):
    res = client.get("/destinations?q=alpha")
    names = {d["name"] for d in res.get_json()}
    assert names == {"Alpha Market"}


def test_query_matches_description_sector_field(client):
    res = client.get("/destinations?q=historic")
    names = {d["name"] for d in res.get_json()}
    assert names == {"Gamma Palace"}


def test_tag_filter(client):
    res = client.get("/destinations?tag=culture")
    names = {d["name"] for d in res.get_json()}
    assert names == {"Alpha Market", "Gamma Palace"}


def test_quarter_filter(client):
    res = client.get("/destinations?quarter=Dubai City")
    names = {d["name"] for d in res.get_json()}
    assert names == {"Beta Park"}


def test_max_cost_filter_excludes_pricier_and_unpriced_as_appropriate(client):
    res = client.get("/destinations?max_cost=2000")
    names = {d["name"] for d in res.get_json()}
    # Beta Park (0) and Alpha Market (2000) qualify; Gamma Palace (0) too.
    assert names == {"Alpha Market", "Beta Park", "Gamma Palace"}


def test_max_cost_filter_excludes_over_budget(client):
    res = client.get("/destinations?max_cost=0")
    names = {d["name"] for d in res.get_json()}
    assert names == {"Beta Park", "Gamma Palace"}


def test_max_cost_invalid_value(client):
    res = client.get("/destinations?max_cost=not-a-number")
    assert res.status_code == 400


def test_combined_filters_are_ANDed(client):
    res = client.get("/destinations?tag=culture&quarter=Terminus")
    names = {d["name"] for d in res.get_json()}
    assert names == {"Alpha Market"}


def test_no_match_returns_empty_list(client):
    res = client.get("/destinations?q=doesnotexist")
    assert res.status_code == 200
    assert res.get_json() == []
