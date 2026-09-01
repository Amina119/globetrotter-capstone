## this is a comment about the place 
"""
app/place_comments.py

A comment posted on a place. Each one looks like this:

{
  "id": "3f9c1a2b-...",       <- a random unique id we generate for this comment
  "place_id": "bill-pressing", <- which place this comment is on
  "parent_id": null,           <- null if top-level, or another comment's "id" if this is a reply
  "email": "amina@gmail.com",  <- who posted it (taken from their login, never typed by hand)
  "name": "Amina",             <- their display name, shown in the UI
  "text": "Great place!",      <- the comment text
  "created_at": "2026-09-01T10:00:00+00:00"  <- when it was posted
}
"""
import datetime
import email
import uuid

from flask import Blueprint, request, jsonify

from app.auth import get_current_user
from app.models import get_comments_for_place, add_comment, delete_comment
from app import services_client

place_comments_bp = Blueprint("place_comments", __name__)


@place_comments_bp.route("/places/<place_id>/comments", methods=["GET"])
def list_place_comments(place_id):
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    entries = get_comments_for_place(place_id)
    return jsonify({"entries": entries}), 200

@place_comments_bp.route("/places/<place_id>/comments", methods=["POST"])
def create_comment(place_id):
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    data = request.get_json(silent=True) or {}
    text = (data.get("text") or "").strip()
    parent_id = data.get("parent_id")

    if not text:
        return jsonify({"error": "text is required"}), 400

    user = services_client.get_user(email)
    name = (user or {}).get("name") or email.split("@")[0]

    entry = {
        "id": str(uuid.uuid4()),
        "place_id": place_id,
        "parent_id": parent_id,
        "email": email,
        "name": name,
        "text": text,
        "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }
    add_comment(entry)
    return jsonify(entry), 201

@place_comments_bp.route("/places/<place_id>/comments/<comment_id>", methods=["DELETE"])
def remove_comment(place_id, comment_id):
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    if not delete_comment(comment_id, email):
        return jsonify({"error": "no comment found for this account"}), 404
    return jsonify({"message": "comment deleted"}), 200



    



