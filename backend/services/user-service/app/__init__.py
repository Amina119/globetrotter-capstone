"""
app/__init__.py

Flask application factory for the User Service.
"""
import logging
import os
from flask import Flask, jsonify
from flask_cors import CORS


def create_app():
    """Create and configure the Flask application."""
    app = Flask(__name__)

    # Flask's default logger sits at WARNING when debug=False, which would
    # silently swallow the logger.info(...) fallback in forgot_password()
    # that prints the reset token when no email provider is configured.
    app.logger.setLevel(logging.INFO)

    # CORS is kept here too (not just at the gateway) so the service can
    # still be exercised directly during local development.
    CORS(app)

    @app.route("/health", methods=["GET"])
    def health():
        """Liveness/readiness probe for uptime monitoring and load balancers."""
        return jsonify({"status": "ok", "service": "user-service"}), 200

    # Secret key used for JWT signing/verification. Shared across all three
    # services (and set from the same env var in docker-compose) so tokens
    # issued here can be verified by Itinerary and Recommendation services.
    app.config["SECRET_KEY"] = os.environ.get(
        "SECRET_KEY", "globetrotter-secret-change-in-prod"
    )

    from app.auth import auth_bp
    from app.feedback import feedback_bp
    from app.chat import chat_bp
    app.register_blueprint(auth_bp)
    app.register_blueprint(feedback_bp)
    app.register_blueprint(chat_bp)


    return app
