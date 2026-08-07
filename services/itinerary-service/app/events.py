"""
app/events.py

Publishes itinerary lifecycle events to RabbitMQ so other services can react
asynchronously, instead of being polled over REST. Recommendation Service
consumes these to keep its destination-popularity cache warm without an
inline call back to this service on every /recommendations request.

Exchange: "globetrotter.events" (topic)
Routing keys: "itinerary.created", "itinerary.deleted"

Publishing is best-effort: if the broker is unreachable, we log and move on
rather than failing the HTTP request that triggered the event. The REST
/internal/itineraries/popularity endpoint still exists as a synchronous
fallback for consumers that want the ground truth on demand.
"""
import os
import json
import logging

import pika

RABBITMQ_URL = os.environ.get("RABBITMQ_URL", "amqp://guest:guest@rabbitmq:5672/%2F")
EXCHANGE_NAME = "globetrotter.events"

_logger = logging.getLogger(__name__)


def _publish(routing_key: str, payload: dict) -> None:
    try:
        params = pika.URLParameters(RABBITMQ_URL)
        params.socket_timeout = 3
        connection = pika.BlockingConnection(params)
        try:
            channel = connection.channel()
            channel.exchange_declare(exchange=EXCHANGE_NAME, exchange_type="topic", durable=True)
            channel.basic_publish(
                exchange=EXCHANGE_NAME,
                routing_key=routing_key,
                body=json.dumps(payload),
                properties=pika.BasicProperties(content_type="application/json", delivery_mode=2),
            )
        finally:
            connection.close()
    except Exception:
        _logger.exception("Failed to publish %s event to RabbitMQ", routing_key)


def publish_itinerary_created(itinerary: dict) -> None:
    """Fire an "itinerary.created" event with the destinations that were
    added, so consumers can update destination-popularity counts.
    """
    _publish("itinerary.created", {
        "id": itinerary.get("id"),
        "email": itinerary.get("email"),
        "destinations": itinerary.get("destinations", []),
    })


def publish_itinerary_deleted(itinerary_id: str, destinations: list) -> None:
    """Fire an "itinerary.deleted" event so consumers can decrement
    destination-popularity counts for the destinations that were removed.
    """
    _publish("itinerary.deleted", {
        "id": itinerary_id,
        "destinations": destinations,
    })
