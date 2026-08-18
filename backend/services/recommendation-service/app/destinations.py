"""
app/destinations.py

Destination search endpoint, plus admin-only catalogue management.

Routes
------
GET  /destinations?q=marche&tag=food&quarter=Terminus
    Returns destinations that match any of the provided query parameters.
    All parameters are optional; omitting them returns the full catalogue.
POST   /admin/destinations        – (admin only) add a destination
PUT    /admin/destinations/<id>   – (admin only) edit a destination
DELETE /admin/destinations/<id>   – (admin only) remove a destination
"""
import uuid

from flask import Blueprint, request, jsonify

from app.auth import get_current_user
from app.models import (
    get_all_destinations,
    save_destination,
    update_destination,
    delete_destination,
)
from app import services_client

destinations_bp = Blueprint("destinations", __name__)


def _require_admin(request_obj):
    """Return (email, None) if the request is from an admin, else (None, error_response)."""
    email = get_current_user(request_obj)
    if not email:
        return None, (jsonify({"error": "authentication required"}), 401)

    user = services_client.get_user(email)
    if not user or not user.get("is_admin"):
        return None, (jsonify({"error": "admin access required"}), 403)

    return email, None


def _parse_coordinate(value):
    """Parse an optional latitude/longitude value. Raises ValueError if invalid."""
    if value is None or value == "":
        return None
    return float(value)


@destinations_bp.route("/destinations", methods=["GET"])
def search_destinations():
    """Search destinations by name keyword, tag, and/or quarter.

    Query parameters (all optional):
        q          – free-text search against name, Town, and sector
        tag        – filter by a single interest tag (e.g. "beach")
        quarter    – filter by sector name (e.g. "Terminus")
        max_cost   – filter by maximum average daily cost (integer)

    Returns a JSON list of matching destination objects.
    """
    q = request.args.get("q", "").strip().lower()
    tag = request.args.get("tag", "").strip().lower()
    quarter = request.args.get("quarter", "").strip().lower()
    max_cost_str = request.args.get("max_cost", "").strip()

    max_cost = None
    if max_cost_str:
        try:
            max_cost = int(max_cost_str)
        except ValueError:
            return jsonify({"error": "max_cost must be an integer"}), 400

    destinations = get_all_destinations()
    results = []

    for dest in destinations:
        # Free-text filter
        if q:
            searchable = " ".join([
                dest.get("name", ""),
                dest.get("Town", ""),
                dest.get("sector", ""),
            ]).lower()
            if q not in searchable:
                continue

        # Tag filter
        if tag and tag not in [t.lower() for t in dest.get("tags", [])]:
            continue

        # Quarter filter
        if quarter and quarter != dest.get("quarter", "").lower():
            continue

        # Cost filter – skip destinations that have no cost information or exceed the limit
        if max_cost is not None:
            cost = dest.get("avg_cost_per_day")
            if cost is None or cost > max_cost:
                continue

        results.append(dest)

    return jsonify(results), 200


@destinations_bp.route("/admin/destinations", methods=["POST"])
def create_destination():
    """Add a destination to the catalogue. Admin only.

    Expected JSON body:
        {
          "name": "Marché Terminus", "Town": "Yaoundé", "quarter": "Terminus",
          "sector": "...", "tags": ["food"], "avg_cost_per_day": 2000,
          "latitude": 3.8667, "longitude": 11.5167
        }
    "latitude"/"longitude" are optional (a destination can be added without a
    pinned position yet, and located on the map later via the edit route).

    Returns 201 with the created destination, 400 on invalid input, 403 if
    the authenticated user isn't an admin.
    Requires: Authorization: ******
    """
    _, error = _require_admin(request)
    if error:
        return error

    data = request.get_json(silent=True) or {}
    name = data.get("name", "").strip()
    if not name:
        return jsonify({"error": "name is required"}), 400

    try:
        latitude = _parse_coordinate(data.get("latitude"))
        longitude = _parse_coordinate(data.get("longitude"))
    except (TypeError, ValueError):
        return jsonify({"error": "latitude/longitude must be numbers"}), 400

    destination = {
        "id": str(uuid.uuid4()),
        "name": name,
        "Town": data.get("Town", "").strip(),
        "quarter": data.get("quarter", "").strip(),
        "sector": data.get("sector", "").strip(),
        "tags": data.get("tags", []) if isinstance(data.get("tags"), list) else [],
        "avg_cost_per_day": data.get("avg_cost_per_day"),
        "latitude": latitude,
        "longitude": longitude,
    }
    save_destination(destination)
    return jsonify(destination), 201


@destinations_bp.route("/admin/destinations/<destination_id>", methods=["PUT"])
def edit_destination(destination_id):
    """Edit a destination in the catalogue, including its map position. Admin only.

    Expected JSON body: same shape as POST /admin/destinations; only the
    fields present are updated.

    Returns 200 with the updated destination, 400 on invalid input, 403 if
    the authenticated user isn't an admin, 404 if the destination doesn't exist.
    Requires: Authorization: ******
    """
    _, error = _require_admin(request)
    if error:
        return error

    data = request.get_json(silent=True) or {}
    updates = {}
    for field in ("name", "Town", "quarter", "sector", "avg_cost_per_day"):
        if field in data:
            updates[field] = data[field]
    if "tags" in data and isinstance(data["tags"], list):
        updates["tags"] = data["tags"]

    try:
        if "latitude" in data:
            updates["latitude"] = _parse_coordinate(data.get("latitude"))
        if "longitude" in data:
            updates["longitude"] = _parse_coordinate(data.get("longitude"))
    except (TypeError, ValueError):
        return jsonify({"error": "latitude/longitude must be numbers"}), 400

    updated = update_destination(destination_id, updates)
    if not updated:
        return jsonify({"error": "destination not found"}), 404
    return jsonify(updated), 200


@destinations_bp.route("/admin/destinations/<destination_id>", methods=["DELETE"])
def remove_destination(destination_id):
    """Remove a destination from the catalogue. Admin only.

    Returns 200 on success, 403 if the authenticated user isn't an admin,
    404 if the destination doesn't exist.
    Requires: Authorization: ******
    """
    _, error = _require_admin(request)
    if error:
        return error

    if not delete_destination(destination_id):
        return jsonify({"error": "destination not found"}), 404
    return jsonify({"message": "destination deleted"}), 200
