"""
app/auth.py

User registration, login, password reset, and JWT handling.

Public routes
-------------
POST /register          – create a new user account
POST /login              – authenticate and return a JWT token
POST /forgot-password    – request a password reset token
POST /reset-password     – reset a password using a token from /forgot-password

Internal routes (service-to-service only, not routed through the gateway)
---------------------------------------------------------------------------
GET /internal/users/<email>/exists  – used by Itinerary Service to validate a share target
GET /internal/users/<email>          – used by Recommendation Service to read name/preferences/is_admin
"""
import re
import uuid
import datetime

import jwt
from flask import Blueprint, request, jsonify, current_app
from werkzeug.security import generate_password_hash, check_password_hash

from app.models import get_all_users, get_user_by_email, save_user, update_user

auth_bp = Blueprint("auth", __name__)

_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")

# Password reset tokens expire after this long.
_RESET_TOKEN_TTL = datetime.timedelta(hours=1)


# ---------------------------------------------------------------------------
# Helper – JWT utilities
# ---------------------------------------------------------------------------

def create_token(email: str, secret: str) -> str:
    """Return a signed JWT for *email* valid for 24 hours."""
    now = datetime.datetime.now(datetime.timezone.utc)
    payload = {
        "sub": email,
        "iat": now,
        "exp": now + datetime.timedelta(hours=24),
    }
    return jwt.encode(payload, secret, algorithm="HS256")


def decode_token(token: str, secret: str) -> dict:
    """Decode and verify *token*. Raises jwt.PyJWTError on failure."""
    return jwt.decode(token, secret, algorithms=["HS256"])


def get_current_user(request_obj) -> str | None:
    """Extract and validate the JWT from the Authorization header.

    Returns the user's email (subject claim) or None if the token is
    missing / invalid.
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
# Public routes
# ---------------------------------------------------------------------------

@auth_bp.route("/register", methods=["POST"])
def register():
    """Register a new user.

    Expected JSON body:
        { "name": "Alice", "email": "alice@example.com", "password": "s3cr3t", "preferences": ["beach", "food"] }

    Returns 201 on success, 400 on validation errors, 409 if the email is
    already registered.
    """
    data = request.get_json(silent=True) or {}
    name = data.get("name", "").strip()
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")
    preferences = data.get("preferences", [])  # optional list of interest tags

    if not name or not email or not password:
        return jsonify({"error": "name, email and password are required"}), 400

    if not _EMAIL_RE.match(email):
        return jsonify({"error": "a valid email address is required"}), 400

    if get_user_by_email(email):
        return jsonify({"error": "an account with this email already exists"}), 409

    # The very first account ever registered becomes the admin, so there's
    # always exactly one owner/admin without needing separate setup.
    is_admin = len(get_all_users()) == 0

    user = {
        "id": str(uuid.uuid4()),
        "name": name,
        "email": email,
        # Store a Werkzeug password hash – never store plain-text passwords.
        "password_hash": generate_password_hash(password),
        "preferences": preferences,
        "is_admin": is_admin,
        "reset_token": None,
        "reset_token_expires": None,
    }
    save_user(user)
    return jsonify({"message": "user registered successfully", "email": email, "name": name, "is_admin": is_admin}), 201


@auth_bp.route("/login", methods=["POST"])
def login():
    """Authenticate a user and return a JWT.

    Expected JSON body:
        { "email": "alice@example.com", "password": "s3cr3t" }

    Returns 200 with a token on success, 400/401 on failure.
    """
    data = request.get_json(silent=True) or {}
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")

    if not email or not password:
        return jsonify({"error": "email and password are required"}), 400

    user = get_user_by_email(email)
    if not user or not check_password_hash(user["password_hash"], password):
        return jsonify({"error": "invalid credentials"}), 401

    token = create_token(email, current_app.config["SECRET_KEY"])
    return jsonify({
        "token": token,
        "email": email,
        "name": user.get("name", ""),
        "is_admin": bool(user.get("is_admin")),
    }), 200


@auth_bp.route("/forgot-password", methods=["POST"])
def forgot_password():
    """Request a password reset token for an account.

    Expected JSON body:
        { "email": "alice@example.com" }

    Always returns 200, whether or not an account exists for that email, so
    the response can't be used to enumerate registered accounts. When an
    account does exist, a reset token valid for 1 hour is generated and
    logged (there is no email-sending infrastructure yet, so this stands in
    for "sending" it).
    """
    data = request.get_json(silent=True) or {}
    email = data.get("email", "").strip().lower()

    if not email:
        return jsonify({"error": "email is required"}), 400

    user = get_user_by_email(email)
    if user:
        token = str(uuid.uuid4())
        expires = (datetime.datetime.now(datetime.timezone.utc) + _RESET_TOKEN_TTL).isoformat()
        update_user(email, {"reset_token": token, "reset_token_expires": expires})
        # No email infrastructure exists yet — log the token so it can be
        # retrieved manually during development/testing.
        current_app.logger.info("Password reset token for %s: %s (expires %s)", email, token, expires)

    return jsonify({"message": "if an account exists for this email, a reset link has been sent"}), 200


@auth_bp.route("/reset-password", methods=["POST"])
def reset_password():
    """Reset a password using a token from /forgot-password.

    Expected JSON body:
        { "email": "alice@example.com", "token": "...", "password": "n3wpass" }

    Returns 200 on success, 400 on a missing/expired/invalid token.
    """
    data = request.get_json(silent=True) or {}
    email = data.get("email", "").strip().lower()
    token = data.get("token", "").strip()
    password = data.get("password", "")

    if not email or not token or not password:
        return jsonify({"error": "email, token and password are required"}), 400

    user = get_user_by_email(email)
    if not user or not user.get("reset_token") or user["reset_token"] != token:
        return jsonify({"error": "invalid or expired reset token"}), 400

    expires = user.get("reset_token_expires")
    if not expires or datetime.datetime.fromisoformat(expires) < datetime.datetime.now(datetime.timezone.utc):
        return jsonify({"error": "invalid or expired reset token"}), 400

    update_user(email, {
        "password_hash": generate_password_hash(password),
        "reset_token": None,
        "reset_token_expires": None,
    })
    return jsonify({"message": "password reset successfully"}), 200


# ---------------------------------------------------------------------------
# Internal routes (service-to-service only)
# ---------------------------------------------------------------------------

@auth_bp.route("/internal/users/<email>/exists", methods=["GET"])
def user_exists(email):
    """Return whether an account exists for *email*. Used by Itinerary
    Service to validate a share target before granting access.
    """
    exists = get_user_by_email(email.strip().lower()) is not None
    return jsonify({"exists": exists}), 200


@auth_bp.route("/internal/users/<email>", methods=["GET"])
def get_user_internal(email):
    """Return a user's public profile (name/preferences/is_admin, never the
    password hash). Used by Recommendation Service.
    """
    user = get_user_by_email(email.strip().lower())
    if not user:
        return jsonify({"error": "user not found"}), 404
    return jsonify({
        "email": user.get("email"),
        "name": user.get("name", ""),
        "preferences": user.get("preferences", []),
        "is_admin": bool(user.get("is_admin")),
    }), 200
