"""
app/auth.py

User registration, login, password reset, and JWT handling.

Public routes
-------------
POST /register          – create a new user account
POST /login              – authenticate and return a JWT token
POST /forgot-password    – request a password reset token
POST /reset-password     – reset a password using a token from /forgot-password
POST /auth/google        – log in (or auto-register) with a Google ID token
GET  /profile            – the logged-in user's name/preferences (requires a valid JWT)
PUT  /profile            – update the logged-in user's name/preferences

Internal routes (service-to-service only, not routed through the gateway)
---------------------------------------------------------------------------
GET /internal/users/<email>/exists  – used by Itinerary Service to validate a share target
GET /internal/users/<email>          – used by Recommendation Service to read name/preferences/is_admin
"""
import os
import re
import uuid
import datetime
import secrets

import jwt
import requests
from flask import Blueprint, request, jsonify, current_app
from werkzeug.security import generate_password_hash, check_password_hash

from app.models import get_all_users, get_user_by_email, get_or_create_user_by_email, save_user, update_user
from app import email_client

GOOGLE_CLIENT_ID = os.environ.get("GOOGLE_CLIENT_ID", "")
GOOGLE_TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo"

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
    emailed via Brevo (app.email_client). If Brevo isn't configured (no
    BREVO_API_KEY, e.g. local dev), the token is logged instead so it can
    still be retrieved manually.
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
        sent = email_client.send_password_reset_email(email, token)
        if not sent:
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


@auth_bp.route("/auth/google", methods=["POST"])
def google_login():
    """Log in with a Google ID token, auto-registering the account on its
    first use.

    Expected JSON body:
        { "credential": "<ID token from Google Identity Services>" }

    The token is verified with Google's tokeninfo endpoint rather than a
    local JWKS library: it's a single extra network call per login, and
    keeps this service from needing to fetch/cache Google's signing keys.
    Rejects the token if its audience isn't this app's GOOGLE_CLIENT_ID.

    Returns 200 with the same shape as /login on success.
    """
    if not GOOGLE_CLIENT_ID:
        return jsonify({"error": "Google sign-in is not configured"}), 503

    data = request.get_json(silent=True) or {}
    credential = data.get("credential", "").strip()
    if not credential:
        return jsonify({"error": "credential is required"}), 400

    try:
        res = requests.get(GOOGLE_TOKENINFO_URL, params={"id_token": credential}, timeout=5)
    except requests.RequestException:
        current_app.logger.exception("Failed to reach Google to verify sign-in token")
        return jsonify({"error": "could not verify Google credential"}), 502

    if res.status_code != 200:
        return jsonify({"error": "invalid Google credential"}), 401

    claims = res.json()
    if claims.get("aud") != GOOGLE_CLIENT_ID:
        return jsonify({"error": "invalid Google credential"}), 401
    if claims.get("email_verified") not in ("true", True):
        return jsonify({"error": "Google account email is not verified"}), 401

    email = claims.get("email", "").strip().lower()
    name = claims.get("name") or email.split("@")[0]
    if not email:
        return jsonify({"error": "invalid Google credential"}), 401

    def _build_google_user() -> dict:
        return {
            "id": str(uuid.uuid4()),
            "name": name,
            "email": email,
            # No password is ever set for a Google-only account; this hash
            # doesn't correspond to any password so /login can't be used
            # to sign in to it.
            "password_hash": generate_password_hash(secrets.token_urlsafe(32)),
            "preferences": [],
            "is_admin": len(get_all_users()) == 0,
            "auth_provider": "google",
            "reset_token": None,
            "reset_token_expires": None,
        }

    # Checking for an existing account and creating a new one must happen
    # as one atomic step — see get_or_create_user_by_email's docstring for
    # why a plain "if not get_user_by_email(...): save_user(...)" here can
    # (and did) create duplicate accounts for the same email.
    user = get_or_create_user_by_email(email, _build_google_user)

    token = create_token(email, current_app.config["SECRET_KEY"])
    return jsonify({
        "token": token,
        "email": email,
        "name": user.get("name", ""),
        "is_admin": bool(user.get("is_admin")),
    }), 200


# ---------------------------------------------------------------------------
# Profile routes
# ---------------------------------------------------------------------------

@auth_bp.route("/profile", methods=["GET"])
def get_profile():
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    user = get_user_by_email(email)
    if not user:
        return jsonify({"error": "user not found"}), 404

    return jsonify({
        "email": user.get("email"),
        "name": user.get("name", ""),
        "preferences": user.get("preferences", []),
        "is_admin": bool(user.get("is_admin")),
    }), 200


@auth_bp.route("/profile", methods=["PUT"])
def update_profile():
    email = get_current_user(request)
    if not email:
        return jsonify({"error": "authentication required"}), 401

    data = request.get_json(silent=True) or {}
    updates = {}
    if "name" in data:
        name = (data.get("name") or "").strip()
        if not name:
            return jsonify({"error": "name cannot be empty"}), 400
        updates["name"] = name
    if "preferences" in data:
        preferences = data.get("preferences")
        if not isinstance(preferences, list):
            return jsonify({"error": "preferences must be a list"}), 400
        updates["preferences"] = preferences

    user = update_user(email, updates)
    if not user:
        return jsonify({"error": "user not found"}), 404

    return jsonify({
        "email": user.get("email"),
        "name": user.get("name", ""),
        "preferences": user.get("preferences", []),
        "is_admin": bool(user.get("is_admin")),
    }), 200


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
