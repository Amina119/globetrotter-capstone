"""
app/chat.py

One shared chat room — any logged-in user can post a message and reply
to anyone else's. Each message has at most one parent (a "reply to");
top-level messages have parent_id = null.

Routes
------
GET /chat             – every message, oldest first.
POST /chat            – post a new message.
                         Body: { "text": "...", "parent_id": "<id>" | null }
DELETE /chat/<msg_id> – remove your own message (replaced with "[deleted]").
"""
import datetime
import uuid

from flask import Blueprint, request, jsonify

from app.auth import get_current_user
from app.models import get_all_messages, add_message, delete_message, get_user_by_email

chat_bp = Blueprint("chat", __name__)

@chat_bp.route("/chat", methods=["GET"])
def list_messages():
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    entries = get_all_messages()
    return jsonify({"entries": entries}), 200

@chat_bp.route("/chat", methods=["POST"])
def post_message():
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    data = request.get_json(silent=True) or {}
    text = (data.get("text") or "").strip()
    parent_id = data.get("parent_id")

    if not text:
        return jsonify({"error": "text is required"}), 400

    user = get_user_by_email(email)
    name = (user or {}).get("name") or email.split("@")[0]

    entry = {
        "id": str(uuid.uuid4()),
        "parent_id": parent_id,
        "email": email,
        "name": name,
        "text": text,
        "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }
    add_message(entry)
    return jsonify(entry), 201

@chat_bp.route("/chat/<message_id>", methods=["DELETE"])
def remove_message(message_id):
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    if not delete_message(message_id, email):
        return jsonify({"error": "no message found for this account"}), 404
    return jsonify({"message": "message deleted"}), 200




