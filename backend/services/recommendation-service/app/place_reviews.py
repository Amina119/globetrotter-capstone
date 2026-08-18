
"""
app/place_reviews.py

Per-place ratings/comments. Places themselves are curated, static content
shipped inside the frontend app (with a stable id per place, e.g.
`premiere-maison-institut-nourha-couture`) — this service doesn't own place
data, only the reviews users leave against a place id. Each user has at most
one review per place — submitting again replaces their previous rating/
comment for that place.

Routes
------
GET /places/<place_id>/reviews     – every review for a place, newest first,
                                      plus the real average rating and count.
POST /places/<place_id>/reviews    – create or replace the current user's
                                      review of a place.
                                      Body: { "rating": 1-5, "comment": "..." (optional) }
DELETE /places/<place_id>/reviews  – remove the current user's own review.
"""
import datetime

from flask import Blueprint, request, jsonify # type: ignore

from app.auth import get_current_user
from app.models import get_reviews_for_place, upsert_place_review, delete_place_review
from app import services_client

place_reviews_bp = Blueprint("place_reviews", __name__)


def _average(entries: list) -> float | None:
    if not entries:
        return None
    return round(sum(e["rating"] for e in entries) / len(entries), 2)


@place_reviews_bp.route("/places/<place_id>/reviews", methods=["GET"])
def list_place_reviews(place_id):
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    entries = get_reviews_for_place(place_id)
    return jsonify({
        "average": _average(entries),
        "count": len(entries),
        "entries": entries,
    }), 200


@place_reviews_bp.route("/places/<place_id>/reviews", methods=["POST"])
def submit_place_review(place_id):
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    data = request.get_json(silent=True) or {}
    rating = data.get("rating")
    comment = (data.get("comment") or "").strip()

    if not isinstance(rating, int) or not (1 <= rating <= 5):
        return jsonify({"error": "rating must be an integer from 1 to 5"}), 400

    user = services_client.get_user(email)
    name = (user or {}).get("name") or email.split("@")[0]

    entry = {
        "place_id": place_id,
        "email": email,
        "name": name,
        "rating": rating,
        "comment": comment,
        "updated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }
    upsert_place_review(place_id, email, entry)
    return jsonify(entry), 200


@place_reviews_bp.route("/places/<place_id>/reviews", methods=["DELETE"])
def remove_place_review(place_id):
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    if not delete_place_review(place_id, email):
        return jsonify({"error": "no review found for this account on this place"}), 404
    return jsonify({"message": "review removed"}), 200
