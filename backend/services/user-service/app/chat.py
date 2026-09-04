"""
app/chat.py

One shared chat room — any logged-in user can post a message and reply
to anyone else's. Each message has at most one parent (a "reply to");
top-level messages have parent_id = null.

Messages can carry text and/or a single attachment (image, voice note,
or video) uploaded beforehand via POST /chat/upload.

Routes
------
GET /chat                 – every message, oldest first.
POST /chat                – post a new message.
                             Body: { "text": "...", "parent_id": "<id>" | null,
                                     "media_url": "<url>" | null,
                                     "media_type": "image" | "audio" | "video" | null }
POST /chat/upload         – upload an image/voice-note/video attachment.
                             multipart/form-data, field name "file".
                             Returns { "url": "...", "media_type": "..." }.
DELETE /chat/<msg_id>     – remove your own message (replaced with "[deleted]").
GET /uploads/<filename>   – serve a previously uploaded attachment.
"""
import datetime
import os
import uuid

from flask import Blueprint, request, jsonify, send_from_directory
from werkzeug.utils import secure_filename

from app.auth import get_current_user
from app.models import (
    get_all_messages,
    add_message,
    delete_message,
    get_user_by_email,
    CHAT_UPLOADS_DIR,
)

chat_bp = Blueprint("chat", __name__)

# Maps an accepted file extension to the attachment kind the frontend uses
# to decide how to render it (image / audio / video).
_ALLOWED_EXTENSIONS = {
    "jpg": "image", "jpeg": "image", "png": "image", "gif": "image", "webp": "image",
    "m4a": "audio", "mp3": "audio", "wav": "audio", "aac": "audio", "ogg": "audio",
    "mp4": "video", "mov": "video", "webm": "video",
}

MAX_UPLOAD_BYTES = 25 * 1024 * 1024  # 25 MB


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
    media_url = data.get("media_url")
    media_type = data.get("media_type")

    if not text and not media_url:
        return jsonify({"error": "text or media is required"}), 400

    if media_type not in (None, "image", "audio", "video"):
        return jsonify({"error": "invalid media_type"}), 400

    user = get_user_by_email(email)
    name = (user or {}).get("name") or email.split("@")[0]

    entry = {
        "id": str(uuid.uuid4()),
        "parent_id": parent_id,
        "email": email,
        "name": name,
        "text": text,
        "media_url": media_url,
        "media_type": media_type if media_url else None,
        "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }
    add_message(entry)
    return jsonify(entry), 201

@chat_bp.route("/chat/upload", methods=["POST"])
def upload_attachment():
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    file = request.files.get("file")
    if file is None or file.filename == "":
        return jsonify({"error": "file is required"}), 400

    ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else ""
    media_type = _ALLOWED_EXTENSIONS.get(ext)
    if media_type is None:
        return jsonify({"error": "unsupported file type"}), 400

    file.seek(0, os.SEEK_END)
    size = file.tell()
    file.seek(0)
    if size > MAX_UPLOAD_BYTES:
        return jsonify({"error": "file is too large"}), 400

    os.makedirs(CHAT_UPLOADS_DIR, exist_ok=True)
    filename = secure_filename(f"{uuid.uuid4()}.{ext}")
    file.save(os.path.join(CHAT_UPLOADS_DIR, filename))

    return jsonify({"url": f"/uploads/{filename}", "media_type": media_type}), 201

@chat_bp.route("/uploads/<path:filename>", methods=["GET"])
def get_upload(filename):
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401
    return send_from_directory(CHAT_UPLOADS_DIR, filename)

@chat_bp.route("/chat/<message_id>", methods=["DELETE"])
def remove_message(message_id):
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    if not delete_message(message_id, email):
        return jsonify({"error": "no message found for this account"}), 404
    return jsonify({"message": "message deleted"}), 200
