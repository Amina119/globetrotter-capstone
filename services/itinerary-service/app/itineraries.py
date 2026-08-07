"""
app/itineraries.py

Create, view, manage and share itineraries for the authenticated user.

Public routes (require a valid JWT in the Authorization header)
-----------------------------------------------------------------
POST   /itineraries                – create a new itinerary
GET    /itineraries                – list itineraries owned by the logged-in user
GET    /itineraries/shared         – list itineraries shared with the logged-in user
PUT    /itineraries/<id>           – update an itinerary you own
DELETE /itineraries/<id>           – delete an itinerary you own
POST   /itineraries/<id>/share     – share an itinerary you own with another user
DELETE /itineraries/<id>/share     – revoke another user's access to an itinerary you own

Internal routes (service-to-service only, not routed through the gateway)
---------------------------------------------------------------------------
GET /internal/itineraries?email=<email>     – itineraries owned by <email>, for Recommendation Service
GET /internal/itineraries/popularity        – destination popularity counts, for Recommendation Service
"""
import uuid
import datetime

from flask import Blueprint, request, jsonify

from app.auth import get_current_user
from app.models import (
    delete_itinerary,
    get_destination_popularity,
    get_itineraries_for_user,
    get_itineraries_shared_with,
    save_itinerary,
    share_itinerary,
    unshare_itinerary,
    update_itinerary,
)
from app import services_client
from app import events

itineraries_bp = Blueprint("itineraries", __name__)


@itineraries_bp.route("/itineraries", methods=["POST"])
def create_itinerary():
    """Create a new itinerary for the authenticated user.

    Expected JSON body:
        {
          "title": "Summer in Europe",
          "destinations": ["Paris", "Rome"],
          "start_date": "2025-06-01",
          "end_date": "2025-06-15",
          "notes": "Optional free-text notes"
        }

    Returns 201 with the created itinerary on success.
    Requires: Authorization: ******
    """
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    data = request.get_json(silent=True) or {}
    title = data.get("title", "").strip()
    destinations = data.get("destinations", [])

    if not title:
        return jsonify({"error": "title is required"}), 400

    if not isinstance(destinations, list):
        return jsonify({"error": "destinations must be a list"}), 400

    itinerary = {
        "id": str(uuid.uuid4()),
        "email": email,
        "title": title,
        "destinations": destinations,
        "start_date": data.get("start_date", ""),
        "end_date": data.get("end_date", ""),
        "notes": data.get("notes", ""),
        "shared_with": [],
        "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }
    save_itinerary(itinerary)
    events.publish_itinerary_created(itinerary)
    return jsonify(itinerary), 201


@itineraries_bp.route("/itineraries", methods=["GET"])
def list_itineraries():
    """List all itineraries owned by the authenticated user.

    Returns 200 with a JSON array of itinerary objects.
    Requires: Authorization: ******
    """
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    itineraries = get_itineraries_for_user(email)
    return jsonify(itineraries), 200


@itineraries_bp.route("/itineraries/shared", methods=["GET"])
def list_shared_itineraries():
    """List itineraries that other users have shared with the authenticated user.

    Returns 200 with a JSON array of itinerary objects.
    Requires: Authorization: ******
    """
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    itineraries = get_itineraries_shared_with(email)
    return jsonify(itineraries), 200


@itineraries_bp.route("/itineraries/<itinerary_id>", methods=["PUT"])
def edit_itinerary(itinerary_id):
    """Update an itinerary you own.

    Expected JSON body: any subset of title / destinations / start_date /
    end_date / notes.

    Returns 200 with the updated itinerary, 404 if it doesn't exist or you
    don't own it.
    Requires: Authorization: ******
    """
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    data = request.get_json(silent=True) or {}
    allowed_fields = {"title", "destinations", "start_date", "end_date", "notes"}
    updates = {k: v for k, v in data.items() if k in allowed_fields}

    if "title" in updates and not str(updates["title"]).strip():
        return jsonify({"error": "title cannot be empty"}), 400
    if "destinations" in updates and not isinstance(updates["destinations"], list):
        return jsonify({"error": "destinations must be a list"}), 400

    updated = update_itinerary(itinerary_id, email, updates)
    if not updated:
        return jsonify({"error": "itinerary not found"}), 404
    return jsonify(updated), 200


@itineraries_bp.route("/itineraries/<itinerary_id>", methods=["DELETE"])
def remove_itinerary(itinerary_id):
    """Delete an itinerary you own.

    Returns 200 on success, 404 if it doesn't exist or you don't own it.
    Requires: Authorization: ******
    """
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    existing = next((it for it in get_itineraries_for_user(email) if it.get("id") == itinerary_id), None)

    if not delete_itinerary(itinerary_id, email):
        return jsonify({"error": "itinerary not found"}), 404

    if existing:
        events.publish_itinerary_deleted(itinerary_id, existing.get("destinations", []))
    return jsonify({"message": "itinerary deleted"}), 200


@itineraries_bp.route("/itineraries/<itinerary_id>/share", methods=["POST"])
def add_share(itinerary_id):
    """Share an itinerary you own with another registered user.

    Expected JSON body: { "email": "friend@example.com" }

    Returns 200 with the updated itinerary. 404 if the itinerary doesn't
    exist / isn't yours, or if the target email has no account. 400 if
    trying to share with yourself.
    Requires: Authorization: ******
    """
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    data = request.get_json(silent=True) or {}
    target_email = data.get("email", "").strip().lower()
    if not target_email:
        return jsonify({"error": "email is required"}), 400
    if target_email == email:
        return jsonify({"error": "you already have access to your own itinerary"}), 400
    if not services_client.user_exists(target_email):
        return jsonify({"error": "no account found with this email"}), 404

    updated = share_itinerary(itinerary_id, email, target_email)
    if not updated:
        return jsonify({"error": "itinerary not found"}), 404
    return jsonify(updated), 200


@itineraries_bp.route("/itineraries/<itinerary_id>/share", methods=["DELETE"])
def remove_share(itinerary_id):
    """Revoke another user's access to an itinerary you own.

    Expected JSON body: { "email": "friend@example.com" }

    Returns 200 with the updated itinerary, 404 if the itinerary doesn't
    exist or isn't yours.
    Requires: Authorization: ******
    """
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    data = request.get_json(silent=True) or {}
    target_email = data.get("email", "").strip().lower()
    if not target_email:
        return jsonify({"error": "email is required"}), 400

    updated = unshare_itinerary(itinerary_id, email, target_email)
    if not updated:
        return jsonify({"error": "itinerary not found"}), 404
    return jsonify(updated), 200


# ---------------------------------------------------------------------------
# Internal routes (service-to-service only)
# ---------------------------------------------------------------------------

@itineraries_bp.route("/internal/itineraries", methods=["GET"])
def list_itineraries_internal():
    """Return itineraries owned by the email in the ?email= query param.

    Used by Recommendation Service to read a user's past trips (no auth –
    only reachable on the internal Docker network, not via the gateway).
    """
    email = request.args.get("email", "").strip().lower()
    if not email:
        return jsonify({"error": "email query parameter is required"}), 400
    return jsonify(get_itineraries_for_user(email)), 200


@itineraries_bp.route("/internal/itineraries/popularity", methods=["GET"])
def popularity_internal():
    """Return destination popularity counts across all itineraries.

    Used by Recommendation Service to boost popular destinations.
    """
    return jsonify(get_destination_popularity()), 200
