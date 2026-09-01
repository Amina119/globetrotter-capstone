"""
app/__init__.py

Flask application factory for the Recommendation Service.
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
        return jsonify({"status": "ok", "service": "recommendation-service"}), 200

    # Secret key used to verify JWTs issued by the User Service. Must match
    # the SECRET_KEY the User Service signs tokens with.
    app.config["SECRET_KEY"] = os.environ.get(
        "SECRET_KEY", "globetrotter-secret-change-in-prod"
    )

    from app.destinations import destinations_bp
    from app.recommendations import recommendations_bp
    from app.user_recommendations import user_recommendations_bp
    from app.place_reviews import place_reviews_bp
    from app.place_comments import place_comments_bp


    app.register_blueprint(destinations_bp)
    app.register_blueprint(recommendations_bp)
    app.register_blueprint(user_recommendations_bp)
    app.register_blueprint(place_reviews_bp)
    app.register_blueprint(place_comments_bp)

    # Start the RabbitMQ consumer that keeps the destination-popularity
    # cache warm from itinerary.created / itinerary.deleted events. Skipped
    # under pytest (PYTEST_CURRENT_TEST is set automatically by pytest) so
    # the test suite doesn't need a live broker.
    if "PYTEST_CURRENT_TEST" not in os.environ and os.environ.get("DISABLE_EVENT_CONSUMER") != "1":
        from app.event_consumer import start_consumer
        start_consumer()

    return app
