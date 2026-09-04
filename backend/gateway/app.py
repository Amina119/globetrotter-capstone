"""
gateway/app.py

API Gateway: the single public entry point for the GlobeTrotter backend.
Routes each request to the service that owns it, based on path prefix, and
streams the response straight back. Doesn't touch passwords or JWTs itself
— each backend service verifies its own tokens.

Route table
-----------
/register, /login, /auth/google, /profile,
  /forgot-password, /reset-password, /feedback,
  /chat, /uploads                                       -> User Service
/itineraries*                                          -> Itinerary Service
/destinations*, /recommendations*,
  /my-recommendations*, /admin/recommendations*,
  /admin/destinations*, /places*                        -> Recommendation Service
/health                                                -> the gateway's own liveness check

Routes starting with /internal/ are service-to-service only and are
deliberately NOT proxied — they're unreachable from outside the Docker
network in the first place (no service publishes a host port except this
gateway), and the gateway refuses to forward to them as a second layer of
protection.
"""
import os
import logging

import requests
from flask import Flask, request, jsonify, Response
from flask_cors import CORS

USER_SERVICE_URL = os.environ.get("USER_SERVICE_URL", "http://user-service:5001")
ITINERARY_SERVICE_URL = os.environ.get("ITINERARY_SERVICE_URL", "http://itinerary-service:5002")
RECOMMENDATION_SERVICE_URL = os.environ.get("RECOMMENDATION_SERVICE_URL", "http://recommendation-service:5003")

_TIMEOUT = 25  # seconds — generous headroom for password hashing under CPU load
_logger = logging.getLogger(__name__)

# Ordered so more specific prefixes (e.g. /itineraries/shared) still match
# correctly under their parent (/itineraries) — plain prefix matching is
# enough here since none of these prefixes overlap with each other.
_ROUTES = [
    ("/register", USER_SERVICE_URL),
    ("/login", USER_SERVICE_URL),
    ("/auth/google", USER_SERVICE_URL),
    ("/forgot-password", USER_SERVICE_URL),
    ("/reset-password", USER_SERVICE_URL),
    ("/feedback", USER_SERVICE_URL),
    ("/chat", USER_SERVICE_URL),
    ("/uploads", USER_SERVICE_URL),
    ("/profile", USER_SERVICE_URL),
    ("/itineraries", ITINERARY_SERVICE_URL),
    ("/destinations", RECOMMENDATION_SERVICE_URL),
    ("/recommendations", RECOMMENDATION_SERVICE_URL),
    ("/my-recommendations", RECOMMENDATION_SERVICE_URL),
    ("/admin/recommendations", RECOMMENDATION_SERVICE_URL),
    ("/admin/destinations", RECOMMENDATION_SERVICE_URL),
    ("/places", RECOMMENDATION_SERVICE_URL),
]

# Hop-by-hop headers that must not be forwarded verbatim between the client,
# the gateway, and the upstream service (per RFC 7230 6.1).
_EXCLUDED_HEADERS = {
    "content-encoding",
    "content-length",
    "transfer-encoding",
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "upgrade",
    "host",
}


def create_app():
    app = Flask(__name__)
    CORS(app)

    @app.route("/health", methods=["GET"])
    def health():
        return jsonify({"status": "ok", "service": "gateway"}), 200

    @app.route("/<path:path>", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
    def proxy(path):
        request_path = f"/{path}"

        if request_path.startswith("/internal/"):
            return jsonify({"error": "not found"}), 404

        target_base = next((base for prefix, base in _ROUTES if request_path == prefix or request_path.startswith(prefix + "/")), None)
        if target_base is None:
            return jsonify({"error": "not found"}), 404

        upstream_url = f"{target_base}{request_path}"
        headers = {k: v for k, v in request.headers.items() if k.lower() not in _EXCLUDED_HEADERS}

        try:
            upstream_response = requests.request(
                method=request.method,
                url=upstream_url,
                headers=headers,
                params=request.args,
                data=request.get_data(),
                timeout=_TIMEOUT,
            )
        except requests.RequestException:
            _logger.exception("Failed to reach upstream service at %s", upstream_url)
            return jsonify({"error": "upstream service unavailable"}), 502

        response_headers = [(k, v) for k, v in upstream_response.headers.items() if k.lower() not in _EXCLUDED_HEADERS]
        return Response(upstream_response.content, status=upstream_response.status_code, headers=response_headers)

    return app


app = create_app()

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    debug = os.environ.get("FLASK_DEBUG", "0") == "1"
    app.run(host="0.0.0.0", port=port, debug=debug, threaded=True)
