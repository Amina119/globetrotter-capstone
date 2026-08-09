"""
app/email_client.py

Sends password-reset emails via Brevo's transactional email API
(https://api.brevo.com/v3/smtp/email).

Configured via env vars:
  BREVO_API_KEY     – required to actually send; if unset, sending is
                       skipped and the caller should fall back to logging
                       the token (dev/test mode, no secret available).
  BREVO_SENDER_EMAIL – "from" address, must be a verified Brevo sender.
  BREVO_SENDER_NAME  – "from" display name (default "GlobeTrotter").
  PASSWORD_RESET_URL – frontend URL the reset link points to, with the
                        token and email appended as query params
                        (default "http://localhost:5000/reset-password").

Sending is best-effort: network or API failures are logged and swallowed
rather than raised, so a broker/provider hiccup never breaks the
/forgot-password request itself (which always returns 200 regardless).
"""
import os
import logging

import requests

BREVO_API_URL = "https://api.brevo.com/v3/smtp/email"
BREVO_API_KEY = os.environ.get("BREVO_API_KEY", "")
SENDER_EMAIL = os.environ.get("BREVO_SENDER_EMAIL", "")
SENDER_NAME = os.environ.get("BREVO_SENDER_NAME", "GlobeTrotter")
RESET_URL_BASE = os.environ.get("PASSWORD_RESET_URL", "http://localhost:5000/reset-password")

_TIMEOUT = 5  # seconds
_logger = logging.getLogger(__name__)


def send_password_reset_email(email: str, token: str) -> bool:
    """Send a password-reset email to *email* containing a link built from
    *token*. Returns True if Brevo accepted the request, False if sending
    was skipped (no API key configured) or failed.
    """
    if not BREVO_API_KEY or not SENDER_EMAIL:
        _logger.info("Brevo not configured; skipping email send for %s", email)
        return False

    reset_link = f"{RESET_URL_BASE}?email={email}&token={token}"

    payload = {
        "sender": {"name": SENDER_NAME, "email": SENDER_EMAIL},
        "to": [{"email": email}],
        "subject": "Reset your GlobeTrotter password",
        "htmlContent": (
            f"<p>We received a request to reset your GlobeTrotter password.</p>"
            f"<p><a href=\"{reset_link}\">Click here to reset your password</a></p>"
            f"<p>This link expires in 1 hour. If you didn't request this, you can ignore this email.</p>"
        ),
    }
    headers = {
        "api-key": BREVO_API_KEY,
        "Content-Type": "application/json",
        "Accept": "application/json",
    }

    try:
        res = requests.post(BREVO_API_URL, json=payload, headers=headers, timeout=_TIMEOUT)
        res.raise_for_status()
        return True
    except requests.RequestException:
        _logger.exception("Failed to send password reset email to %s via Brevo", email)
        return False
