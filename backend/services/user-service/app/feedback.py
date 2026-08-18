"""
app/feedback.py

App-wide feedback: any logged-in user can rate GlobeTrotter (1-5 stars) and
leave a comment. Each user has exactly one entry — submitting again replaces
their previous rating/comment rather than adding a duplicate, so the average
always reflects each user's *current* opinion, not every draft they typed.

Routes
------
GET /feedback     – every submitted rating/comment, newest first, plus the
                     real average rating and count. Requires a valid JWT.
POST /feedback    – create or replace the current user's rating/comment.
                     Body: { "rating": 1-5, "comment": "..." (optional) }
DELETE /feedback  – remove the current user's own feedback entry.
"""
from flask import Blueprint, request, jsonify

from app.auth import get_current_user
from app.models import get_all_feedback, get_user_by_email, upsert_feedback, delete_feedback

import datetime

feedback_bp = Blueprint("feedback", __name__)


def _average(entries: list) -> float | None:
    if not entries:
        return None
    return round(sum(e["rating"] for e in entries) / len(entries), 2)


@feedback_bp.route("/feedback", methods=["GET"])
def list_feedback():
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    entries = get_all_feedback()
    return jsonify({
        "average": _average(entries),
        "count": len(entries),
        "entries": entries,
    }), 200


@feedback_bp.route("/feedback", methods=["POST"])
def submit_feedback():
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    data = request.get_json(silent=True) or {}
    rating = data.get("rating")
    comment = (data.get("comment") or "").strip()

    if not isinstance(rating, int) or not (1 <= rating <= 5):
        return jsonify({"error": "rating must be an integer from 1 to 5"}), 400

    user = get_user_by_email(email)
    name = (user or {}).get("name", "") or email.split("@")[0]

    entry = {
        "email": email,
        "name": name,
        "rating": rating,
        "comment": comment,
        "updated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }
    upsert_feedback(email, entry)
    return jsonify(entry), 200


@feedback_bp.route("/feedback", methods=["DELETE"])
def remove_feedback():
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    if not delete_feedback(email):
        return jsonify({"error": "no feedback found for this account"}), 404
    return jsonify({"message": "feedback removed"}), 200
