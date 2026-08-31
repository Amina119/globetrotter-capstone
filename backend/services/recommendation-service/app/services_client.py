"""
app/services_client.py

Outbound calls this service makes to other services:
  - User Service      – read a user's name/preferences/is_admin
  - Itinerary Service  – read a user's past itineraries and cross-user
                          destination popularity

Base URLs default to the docker-compose service hostnames; override with
env vars for local (non-Docker) development.
"""
import os
import logging

import requests

USER_SERVICE_URL = os.environ.get("USER_SERVICE_URL", "http://user-service:5001")
ITINERARY_SERVICE_URL = os.environ.get("ITINERARY_SERVICE_URL", "http://itinerary-service:5002")

_TIMEOUT = 15  # seconds — generous headroom for host CPU contention
_logger = logging.getLogger(__name__)


def get_user(email: str) -> dict | None:
    """Return {email, name, preferences, is_admin} for *email*, or None if
    the account doesn't exist or the User Service can't be reached.
    """
    try:
        res = requests.get(f"{USER_SERVICE_URL}/internal/users/{email}", timeout=_TIMEOUT)
        if res.status_code == 404:
            return None
        res.raise_for_status()
        return res.json()
    except requests.RequestException:
        _logger.exception("Failed to reach User Service for %s", email)
        return None


def get_user_itineraries(email: str) -> list:
    """Return the itineraries owned by *email*. Returns an empty list (not
    an error) if the Itinerary Service can't be reached, so a downstream
    hiccup degrades recommendation quality rather than breaking the request.
    """
    try:
        res = requests.get(f"{ITINERARY_SERVICE_URL}/internal/itineraries", params={"email": email}, timeout=_TIMEOUT)
        res.raise_for_status()
        return res.json()
    except requests.RequestException:
        _logger.exception("Failed to reach Itinerary Service for %s's itineraries", email)
        return []


def get_destination_popularity() -> dict:
    """Return the cross-user destination popularity map.

    Prefers the in-memory cache kept warm by app.event_consumer from
    itinerary.created / itinerary.deleted RabbitMQ events (async path).
    Falls back to a synchronous call to the Itinerary Service's
    /internal/itineraries/popularity endpoint when the cache is empty —
    e.g. right after startup, before any event has arrived, or if the
    broker has never been reachable — so recommendations still work.
    """
    from app.event_consumer import get_cached_popularity

    cached = get_cached_popularity()
    if cached:
        return cached

    try:
        res = requests.get(f"{ITINERARY_SERVICE_URL}/internal/itineraries/popularity", timeout=_TIMEOUT)
        res.raise_for_status()
        return res.json()
    except requests.RequestException:
        _logger.exception("Failed to reach Itinerary Service for destination popularity")
        return {}
