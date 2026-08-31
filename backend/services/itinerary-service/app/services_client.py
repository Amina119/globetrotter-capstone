"""
app/services_client.py

Outbound calls this service makes to other services. Only User Service is
called from here, to validate that a share target's email has an account.

USER_SERVICE_URL defaults to the docker-compose service hostname; override
with an env var for local (non-Docker) development.
"""
import os
import logging

import requests

USER_SERVICE_URL = os.environ.get("USER_SERVICE_URL", "http://user-service:5001")

_TIMEOUT = 15  # seconds — generous headroom for host CPU contention
_logger = logging.getLogger(__name__)


def user_exists(email: str) -> bool:
    """Return whether an account exists for *email* in the User Service.

    If the User Service is unreachable or errors, this fails closed (treats
    the user as not found) rather than letting the request crash with an
    unhandled exception — the caller still gets a clean 404, just logged as
    a downstream problem instead of silently ignored.
    """
    try:
        res = requests.get(f"{USER_SERVICE_URL}/internal/users/{email}/exists", timeout=_TIMEOUT)
        res.raise_for_status()
        return bool(res.json().get("exists"))
    except requests.RequestException:
        _logger.exception("Failed to reach User Service to check %s", email)
        return False
