"""
app/user_recommendations.py

Lets users write their own destination recommendations (as opposed to the
algorithmic ones in app/recommendations.py), and lets the admin account see
every recommendation submitted by every user.

Routes
------
POST /my-recommendations          – submit a recommendation
GET  /my-recommendations          – list recommendations you've submitted
GET  /admin/recommendations       – (admin only) list every user's submissions
GET  /admin/stats                 – (admin only) total/active users + average rating

All routes require a valid JWT in the Authorization header. The submitter's
display name and admin status are read from the User Service, since this
service doesn't own user data.
"""
import uuid
import datetime

from flask import Blueprint, request, jsonify

from app.auth import get_current_user
from app.models import (
    get_user_recommendations_for_user,
    get_all_user_recommendations,
    save_user_recommendation,
    get_all_reviews,
)
from app import services_client

# A user counts as "active" if they've logged in within this many days.
_ACTIVE_WINDOW_DAYS = 7

user_recommendations_bp = Blueprint("user_recommendations", __name__)


@user_recommendations_bp.route("/my-recommendations", methods=["POST"])
def submit_recommendation():
    """Submit a destination recommendation.

    Expected JSON body:
        { "destination": "Marché Terminus", "message": "Great street food, go on a Saturday!" }

    Returns 201 with the created recommendation.
    Requires: Authorization: ******
    """
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    user = services_client.get_user(email)
    data = request.get_json(silent=True) or {}
    destination = data.get("destination", "").strip()
    message = data.get("message", "").strip()

    if not destination or not message:
        return jsonify({"error": "destination and message are required"}), 400

    recommendation = {
        "id": str(uuid.uuid4()),
        "email": email,
        "name": user.get("name", "") if user else "",
        "destination": destination,
        "message": message,
        "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }
    save_user_recommendation(recommendation)
    return jsonify(recommendation), 201


@user_recommendations_bp.route("/my-recommendations", methods=["GET"])
def list_my_recommendations():
    """List the recommendations the authenticated user has submitted.

    Returns 200 with a JSON array of recommendation objects.
    Requires: Authorization: ******
    """
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    return jsonify(get_user_recommendations_for_user(email)), 200


@user_recommendations_bp.route("/admin/recommendations", methods=["GET"])
def list_all_recommendations():
    """List every recommendation submitted by every user. Admin only.

    Returns 200 with a JSON array of recommendation objects, 403 if the
    authenticated user isn't an admin.
    Requires: Authorization: ******
    """
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    user = services_client.get_user(email)
    if not user or not user.get("is_admin"):
        return jsonify({"error": "admin access required"}), 403

    return jsonify(get_all_user_recommendations()), 200


@user_recommendations_bp.route("/admin/stats", methods=["GET"])
def admin_stats():
    """Return platform-wide numbers for the admin dashboard: total and
    recently-active user counts, and the average rating across all place
    reviews. Admin only.

    Returns 200 with {total_users, active_users, average_rating}, 403 if
    the authenticated user isn't an admin.
    Requires: Authorization: ******
    """
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    user = services_client.get_user(email)
    if not user or not user.get("is_admin"):
        return jsonify({"error": "admin access required"}), 403

    users = services_client.get_all_users()
    cutoff = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=_ACTIVE_WINDOW_DAYS)

    def _logged_in_recently(u):
        last_login = u.get("last_login")
        if not last_login:
            return False
        try:
            return datetime.datetime.fromisoformat(last_login) >= cutoff
        except ValueError:
            return False

    active_users = sum(1 for u in users if _logged_in_recently(u))

    ratings = [r["rating"] for r in get_all_reviews() if isinstance(r.get("rating"), (int, float))]
    average_rating = round(sum(ratings) / len(ratings), 2) if ratings else 0

    return jsonify({
        "total_users": len(users),
        "active_users": active_users,
        "average_rating": average_rating,
    }), 200
