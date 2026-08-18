"""
app/recommendations.py

Personalised destination recommendations.

Routes
------
GET /recommendations
    Returns destinations that best match the authenticated user, blending
    their stated preferences, the tags of destinations they've visited in
    past itineraries, and how popular each destination is across all users.
    Requires a valid JWT in the Authorization header.

Preferences and past itineraries are read from the User Service and
Itinerary Service respectively (this service owns neither), via
app.services_client.
"""
from flask import Blueprint, request, jsonify

from app.auth import get_current_user
from app.models import get_all_destinations
from app import services_client

recommendations_bp = Blueprint("recommendations", __name__)

# Relative weight given to each signal when scoring a destination.
_PREFERENCE_WEIGHT = 1.0
_PAST_TRIP_WEIGHT = 0.5
_POPULARITY_WEIGHT = 0.2


def _past_trip_tags(email: str, destinations: list) -> list:
    """Return the tags of destinations the user has included in their own
    past itineraries, used as a signal that they enjoy similar places.
    """
    by_name = {d.get("name", "").strip().lower(): d for d in destinations}
    visited_tags = []
    for itinerary in services_client.get_user_itineraries(email):
        for name in itinerary.get("destinations", []):
            dest = by_name.get(str(name).strip().lower())
            if dest:
                visited_tags.extend(t.lower() for t in dest.get("tags", []))
    return visited_tags


@recommendations_bp.route("/recommendations", methods=["GET"])
def get_recommendations():
    """Return personalised destination recommendations for the logged-in user.

    Each destination is scored by blending three signals:
      * preference match  – how many of the user's stated preference tags it has
      * past-trip affinity – how many of its tags match destinations from the
        user's own past itineraries
      * popularity         – how many itineraries (across all users) include it

    Destinations are returned in descending score order. An optional
    *limit* query parameter caps the number of results (default 5).

    Requires: Authorization: ******
    """
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    user = services_client.get_user(email)
    if not user:
        return jsonify({"error": "user not found"}), 404

    preferences = [p.lower() for p in user.get("preferences", [])]

    # Parse optional limit parameter
    try:
        limit = int(request.args.get("limit", 5))
    except ValueError:
        return jsonify({"error": "limit must be an integer"}), 400

    destinations = get_all_destinations()
    past_tags = _past_trip_tags(email, destinations)
    popularity = services_client.get_destination_popularity()
    max_popularity = max(popularity.values(), default=0)

    scored = []
    for dest in destinations:
        dest_tags = [t.lower() for t in dest.get("tags", [])]

        preference_score = sum(1 for pref in preferences if pref in dest_tags)
        past_trip_score = sum(1 for tag in past_tags if tag in dest_tags)
        pop_count = popularity.get(dest.get("name", "").strip().lower(), 0)
        popularity_score = (pop_count / max_popularity) if max_popularity else 0

        score = (
            _PREFERENCE_WEIGHT * preference_score
            + _PAST_TRIP_WEIGHT * past_trip_score
            + _POPULARITY_WEIGHT * popularity_score
        )
        scored.append((score, dest))

    # Sort by score descending, then by name for stable ordering
    scored.sort(key=lambda x: (-x[0], x[1].get("name", "")))

    # Build result list, including the match score for transparency
    results = []
    for score, dest in scored[:limit]:
        entry = dict(dest)
        entry["match_score"] = round(score, 2)
        results.append(entry)

    return jsonify(results), 200
