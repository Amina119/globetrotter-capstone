"""
app/__init__.py

Flask application factory for the Itinerary Service.
"""
import os
from flask import Flask, jsonify
from flask_cors import CORS


def create_app():
    """Create and configure the Flask application."""
    app = Flask(__name__)

    # CORS is kept here too (not just at the gateway) so the service can
    # still be exercised directly during local development.
    CORS(app)

    @app.route("/health", methods=["GET"])
    def health():
        """Liveness/readiness probe for uptime monitoring and load balancers."""
        return jsonify({"status": "ok", "service": "itinerary-service"}), 200

    # Secret key used to verify JWTs issued by the User Service. Must match
    # the SECRET_KEY the User Service signs tokens with.
    app.config["SECRET_KEY"] = os.environ.get(
        "SECRET_KEY", "globetrotter-secret-change-in-prod"
    )

    from app.itineraries import itineraries_bp
    app.register_blueprint(itineraries_bp)

    return app
