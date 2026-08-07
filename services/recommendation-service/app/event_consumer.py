"""
app/event_consumer.py

Background consumer for itinerary lifecycle events published by the
Itinerary Service over RabbitMQ (see itinerary-service/app/events.py).

Keeps an in-memory destination-popularity cache warm as an async
alternative to calling GET /internal/itineraries/popularity on every
/recommendations request. app.services_client.get_destination_popularity()
falls back to that synchronous call whenever the cache is empty (e.g.
right after startup, before the first event has arrived, or if the broker
has never been reachable) — so recommendations keep working end-to-end
either way.

The consumer runs in a daemon thread started from create_app() and
reconnects with a short backoff if the broker connection drops.
"""
import os
import json
import time
import logging
import threading

import pika

RABBITMQ_URL = os.environ.get("RABBITMQ_URL", "amqp://guest:guest@rabbitmq:5672/%2F")
EXCHANGE_NAME = "globetrotter.events"
QUEUE_NAME = "recommendation-service.itinerary-events"
_RECONNECT_DELAY_SECONDS = 5

_logger = logging.getLogger(__name__)

_cache_lock = threading.Lock()
_popularity_cache: dict = {}


def get_cached_popularity() -> dict:
    """Return a snapshot of the destination-popularity cache built from
    consumed events. Empty until the first event has been processed.
    """
    with _cache_lock:
        return dict(_popularity_cache)


def _apply_created(payload: dict) -> None:
    destinations = payload.get("destinations", [])
    with _cache_lock:
        seen = set()
        for name in destinations:
            key = str(name).strip().lower()
            if key and key not in seen:
                _popularity_cache[key] = _popularity_cache.get(key, 0) + 1
                seen.add(key)


def _apply_deleted(payload: dict) -> None:
    destinations = payload.get("destinations", [])
    with _cache_lock:
        seen = set()
        for name in destinations:
            key = str(name).strip().lower()
            if key and key not in seen and _popularity_cache.get(key, 0) > 0:
                _popularity_cache[key] -= 1
                seen.add(key)


_HANDLERS = {
    "itinerary.created": _apply_created,
    "itinerary.deleted": _apply_deleted,
}


def _on_message(channel, method, properties, body):
    try:
        payload = json.loads(body)
        handler = _HANDLERS.get(method.routing_key)
        if handler:
            handler(payload)
    except Exception:
        _logger.exception("Failed to process event with routing key %s", method.routing_key)
    finally:
        channel.basic_ack(delivery_tag=method.delivery_tag)


def _run_forever():
    while True:
        try:
            params = pika.URLParameters(RABBITMQ_URL)
            connection = pika.BlockingConnection(params)
            channel = connection.channel()
            channel.exchange_declare(exchange=EXCHANGE_NAME, exchange_type="topic", durable=True)
            channel.queue_declare(queue=QUEUE_NAME, durable=True)
            channel.queue_bind(exchange=EXCHANGE_NAME, queue=QUEUE_NAME, routing_key="itinerary.*")
            channel.basic_qos(prefetch_count=10)
            channel.basic_consume(queue=QUEUE_NAME, on_message_callback=_on_message)
            _logger.info("Connected to RabbitMQ, consuming itinerary events")
            channel.start_consuming()
        except Exception:
            _logger.exception("RabbitMQ consumer error, reconnecting in %ss", _RECONNECT_DELAY_SECONDS)
            time.sleep(_RECONNECT_DELAY_SECONDS)


def start_consumer() -> None:
    """Start the background consumer thread. Safe to call once at app
    startup; the thread runs for the lifetime of the process.
    """
    thread = threading.Thread(target=_run_forever, name="rabbitmq-consumer", daemon=True)
    thread.start()
