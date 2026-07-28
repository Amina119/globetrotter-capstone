"""
app/auth.py

User registration, login, and JWT handling.

Routes
------
POST /register  – create a new user account
POST /login     – authenticate and return a JWT token
"""
import re
import uuid
import datetime

import jwt
from flask import Blueprint, request, jsonify, current_app
from werkzeug.security import generate_password_hash, check_password_hash

from app.models import get_all_users, get_user_by_username, get_user_by_email, save_user

_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")

auth_bp = Blueprint("auth", __name__)


# ---------------------------------------------------------------------------
# Helper – JWT utilities
# ---------------------------------------------------------------------------

def create_token(username: str, secret: str) -> str:
    """Return a signed JWT for *username* valid for 24 hours."""
    now = datetime.datetime.now(datetime.timezone.utc)
    payload = {
        "sub": username,
        "iat": now,
        "exp": now + datetime.timedelta(hours=24),
    }
    return jwt.encode(payload, secret, algorithm="HS256")


def decode_token(token: str, secret: str) -> dict:
    """Decode and verify *token*. Raises jwt.PyJWTError on failure."""
    return jwt.decode(token, secret, algorithms=["HS256"])


def get_current_user(request_obj) -> str | None:
    """Extract and validate the JWT from the Authorization header.

    Returns the username (subject claim) or None if the token is missing
    or invalid.
    """
    auth_header = request_obj.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return None
    token = auth_header.split(" ", 1)[1]
    try:
        payload = decode_token(token, current_app.config["SECRET_KEY"])
        return payload.get("sub")
    except jwt.PyJWTError:
        return None


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@auth_bp.route("/register", methods=["POST"])
def register():
    """Register a new user with a username, email, and password.

    Expected JSON body:
        { "username": "alice", "email": "alice@example.com", "password": "s3cr3t", "preferences": ["beach", "food"] }

    Returns 201 on success, 400 on validation errors, 409 if the username or
    email is already taken.
    """
    data = request.get_json(silent=True) or {}
    username = data.get("username", "").strip()
    email = data.get("email", "").strip()
    password = data.get("password", "")
    preferences = data.get("preferences", [])  # optional list of interest tags

    if not username or not email or not password:
        return jsonify({"error": "username, email and password are required"}), 400

    if not _EMAIL_RE.match(email):
        return jsonify({"error": "enter a valid email address"}), 400

    if get_user_by_username(username):
        return jsonify({"error": "this username is already taken"}), 409

    if get_user_by_email(email):
        return jsonify({"error": "this email is already registered"}), 409

    # The very first account ever registered becomes the admin, so there's
    # always exactly one owner/admin without needing separate setup.
    is_admin = len(get_all_users()) == 0

    user = {
        "id": str(uuid.uuid4()),
        "username": username,
        "email": email,
        # Store a Werkzeug password hash – never store plain-text passwords.
        "password_hash": generate_password_hash(password),
        "preferences": preferences,
        "is_admin": is_admin,
    }
    save_user(user)
    return jsonify({"message": "user registered successfully", "username": username, "email": email, "is_admin": is_admin}), 201


@auth_bp.route("/login", methods=["POST"])
def login():
    """Authenticate a user by email and return a JWT.

    Expected JSON body:
        { "email": "alice@example.com", "password": "s3cr3t" }

    Returns 200 with a token on success, 400/401 on failure.
    """
    data = request.get_json(silent=True) or {}
    email = data.get("email", "").strip()
    password = data.get("password", "")

    if not email or not password:
        return jsonify({"error": "email and password are required"}), 400

    user = get_user_by_email(email)
    if not user or not check_password_hash(user["password_hash"], password):
        return jsonify({"error": "invalid credentials"}), 401

    username = user["username"]
    token = create_token(username, current_app.config["SECRET_KEY"])
    return jsonify({"token": token, "username": username, "email": user["email"], "is_admin": bool(user.get("is_admin"))}), 200
