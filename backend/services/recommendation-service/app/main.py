"""
app/main.py

Recommendation Service entry point.

Run locally:
    python app/main.py

Or via Docker / docker-compose (see repo root).
"""
import os
import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import create_app

app = create_app()

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5003))
    # Enable debug mode only when explicitly requested (e.g. FLASK_DEBUG=1).
    # Never enable debug in production – it exposes an interactive debugger.
    debug = os.environ.get("FLASK_DEBUG", "0") == "1"
    app.run(host="0.0.0.0", port=port, debug=debug, threaded=True)
