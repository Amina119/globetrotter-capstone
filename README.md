# GlobeTrotter – Travel Assistant

GlobeTrotter is a **Flask backend with a Flutter frontend** that serves as a semester-long capstone project. Phase 1 was a monolith; **Phase 2 (current)** decomposes it into three independent microservices behind an API Gateway. Phase 3 will deploy it to the cloud with resilience patterns using Docker, Kubernetes, and cloud-native tooling.

---

## Architecture (Phase 2: microservices)

```
                        ┌─────────────┐
   Flutter client  ───► │ API Gateway │  (port 5000, the only public port)
                        └──────┬──────┘
                 ┌─────────────┼──────────────────┐
                 ▼             ▼                  ▼
          ┌─────────────┐ ┌────────────────┐ ┌───────────────────────┐
          │ User Service│ │Itinerary Service│ │Recommendation Service │
          │  (port 5001)│ │   (port 5002)   │ │      (port 5003)      │
          └──────┬──────┘ └────────┬────────┘ └───────────┬────────────┘
                 ▼                 ▼                       ▼
           users.json       itineraries.json    destinations.json +
                                                 user_recommendations.json
```

- **User Service** — registration, login, password reset, and profile lookups. Owns `users.json`.
- **Itinerary Service** — itinerary CRUD, sharing, and the destination-popularity aggregate. Owns `itineraries.json`.
- **Recommendation Service** — the destination catalogue, algorithmic recommendations, and user-submitted recommendations. Owns `destinations.json` and `user_recommendations.json`. Reads user preferences/admin status from User Service and past trips/popularity from Itinerary Service over REST (see `app/services_client.py` in each).
- **API Gateway** — the single public entry point (`gateway/app.py`). Routes each request to the right service by path prefix and streams the response back; doesn't touch passwords or JWTs itself. This is also why the Flutter client needs **no changes** — it still points at `http://localhost:5000` and every path it calls is unchanged.

Each service is a self-contained Flask app with its own `requirements.txt`, `Dockerfile`, and `tests/` — genuinely independently deployable, not just organized into folders. Inter-service calls (via `requests`) are synchronous REST only for now; no message queue is wired up yet.

Routes under `/internal/...` (e.g. `GET /internal/users/<email>/exists`) are service-to-service only — the gateway refuses to proxy them, and in `docker-compose.yml` only the gateway publishes a host port, so they're unreachable from outside the Docker network.

---

## Project Structure

```
.
├── services/
│   ├── user-service/            # Flask app, own venv, own tests, own data/
│   ├── itinerary-service/
│   └── recommendation-service/
├── gateway/                     # Reverse-proxy Flask app routing to the 3 services
├── scripts/
│   └── migrate_legacy_data.py   # One-off: split the old monolith's data/ into per-service data/
├── lib/                         # Flutter frontend
│   ├── main.dart
│   ├── screens/                  # App screens (auth, home dashboard, destinations, itineraries, ...)
│   ├── widgets/                   # Reusable UI components
│   ├── services/                   # API client and session management
│   ├── models/                     # Frontend data models
│   └── theme/                       # App color scheme
├── android/ ios/ web/            # Flutter platform targets
├── docker-compose.yml            # Orchestrates gateway + 3 services
├── pubspec.yaml                  # Frontend (Flutter) dependencies
└── README.md
```

Each service directory looks like:

```
services/<name>/
├── app/
│   ├── __init__.py     # Flask app factory
│   ├── models.py        # JSON file I/O for the data this service owns
│   ├── auth.py            # JWT verification (+ issuance, User Service only)
│   ├── services_client.py # Outbound calls to other services (not in User Service)
│   └── main.py              # Entry point
├── data/                # This service's own JSON store
├── tests/
├── requirements.txt
├── requirements-dev.txt
├── pytest.ini
└── Dockerfile
```

---

## REST API

All requests go through the gateway at `http://localhost:5000`.

| Method | Endpoint                    | Auth required | Service        | Description                                    |
|--------|------------------------------|---------------|-----------------|-------------------------------------------------|
| GET    | `/health`                    | No            | Gateway         | Gateway liveness probe                          |
| POST   | `/register`                  | No            | User            | Register a new user                              |
| POST   | `/login`                     | No            | User            | Authenticate and receive a JWT token             |
| POST   | `/forgot-password`            | No            | User            | Request a password reset token                   |
| POST   | `/reset-password`             | No            | User            | Reset a password using a token                    |
| GET    | `/destinations`              | No            | Recommendation  | Search the destination catalogue                 |
| GET    | `/recommendations`           | Yes (JWT)     | Recommendation  | Get personalised recommendations                 |
| POST   | `/my-recommendations`         | Yes (JWT)     | Recommendation  | Submit a destination recommendation               |
| GET    | `/my-recommendations`         | Yes (JWT)     | Recommendation  | List recommendations you've submitted             |
| GET    | `/admin/recommendations`      | Yes (JWT, admin)| Recommendation| List every user's submitted recommendations       |
| POST   | `/itineraries`               | Yes (JWT)     | Itinerary       | Create a new itinerary                           |
| GET    | `/itineraries`               | Yes (JWT)     | Itinerary       | List itineraries owned by the logged-in user     |
| GET    | `/itineraries/shared`        | Yes (JWT)     | Itinerary       | List itineraries shared with the logged-in user  |
| PUT    | `/itineraries/<id>`          | Yes (JWT)     | Itinerary       | Update an itinerary you own                      |
| DELETE | `/itineraries/<id>`          | Yes (JWT)     | Itinerary       | Delete an itinerary you own                      |
| POST   | `/itineraries/<id>/share`    | Yes (JWT)     | Itinerary       | Share an itinerary you own with another user     |
| DELETE | `/itineraries/<id>/share`    | Yes (JWT)     | Itinerary       | Revoke another user's access to your itinerary   |

Protected routes expect the header:  
`Authorization: Bearer <your-token>`

### Example requests

```bash
# Register
curl -X POST http://localhost:5000/register \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice", "email": "alice@example.com", "password": "s3cr3t", "preferences": ["beach", "food"]}'

# Login
curl -X POST http://localhost:5000/login \
  -H "Content-Type: application/json" \
  -d '{"email": "alice@example.com", "password": "s3cr3t"}'
# Save the returned token: TOKEN=<value from .token field>

# Search destinations
curl "http://localhost:5000/destinations?tag=beach&max_cost=100"

# Personalised recommendations
curl http://localhost:5000/recommendations \
  -H "Authorization: Bearer $TOKEN"

# Create an itinerary
curl -X POST http://localhost:5000/itineraries \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title": "Beach Escape", "destinations": ["Bali"], "start_date": "2025-07-01", "end_date": "2025-07-14"}'

# List itineraries
curl http://localhost:5000/itineraries \
  -H "Authorization: Bearer $TOKEN"

# Share an itinerary with a friend
curl -X POST http://localhost:5000/itineraries/<id>/share \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"email": "friend@example.com"}'
```

---

## Running the Backend Locally

### Prerequisites
- Python 3.9+
- pip

Easiest path is Docker Compose (see below) — it starts all four pieces at
once. To run a single service directly (e.g. while developing it):

```bash
cd services/user-service        # or itinerary-service / recommendation-service, or gateway/
python -m venv .venv && .venv/Scripts/activate    # .venv/bin/activate on macOS/Linux
pip install -r requirements-dev.txt
python app/main.py              # gateway/ instead runs: python app.py
```

To run the whole stack without Docker, start User Service (port 5001),
Itinerary Service (5002), and Recommendation Service (5003) each in their
own terminal first, then the gateway (port 5000) last, setting the service
URLs it needs to reach them:

```bash
cd gateway
USER_SERVICE_URL=http://localhost:5001 \
ITINERARY_SERVICE_URL=http://localhost:5002 \
RECOMMENDATION_SERVICE_URL=http://localhost:5003 \
python app.py
```

The API will be available at `http://localhost:5000` either way — the
gateway is the single entry point.

---

## Running the Frontend Locally

### Prerequisites
- Flutter SDK (stable channel)

```bash
# 1. Install dependencies
flutter pub get

# 2. Run against a local backend (defaults to http://localhost:5000)
flutter run -d chrome
```

To point the app at a different backend, pass `--dart-define`:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://your-vps-ip:5000
```

---

## Running with Docker

```bash
# Build and start all 4 containers (gateway + 3 services)
docker compose up --build

# Stop
docker compose down
```

Only the gateway publishes a host port (`5000:5000`); the three services
are reachable only from each other, on the internal Docker network. Each
service's `data/` directory is bind-mounted into its container, so JSON
files persist between runs.

### Running each service's tests

```bash
cd services/user-service         # or itinerary-service / recommendation-service
python -m pytest                 # uses the venv set up above

cd gateway
python -m pytest
```

Each service's tests are fully self-contained — they don't make real HTTP
calls to the other services (those calls are mocked), so any one service
can be tested in isolation.

---

## Data Storage

Each service persists its own data as plain JSON files, inside its own
`data/` directory:

| File                                                    | Owned by               | Purpose                              |
|-----------------------------------------------------------|-------------------------|---------------------------------------|
| `services/user-service/data/users.json`                 | User Service            | Registered users (created at runtime) |
| `services/itinerary-service/data/itineraries.json`      | Itinerary Service       | User itineraries (created at runtime) |
| `services/recommendation-service/data/destinations.json`| Recommendation Service  | Static catalogue of travel destinations (seed data) |
| `services/recommendation-service/data/user_recommendations.json` | Recommendation Service | User-submitted recommendations (created at runtime) |

> **Note:** `services/*/data/*.json` (except `destinations.json`) are excluded from version control via `.gitignore`. If you have a copy of the old monolith's `data/` directory, `python scripts/migrate_legacy_data.py` splits it into the layout above.

---

## Configuration

| Environment Variable         | Default                              | Used by                          | Description           |
|-------------------------------|---------------------------------------|-----------------------------------|-------------------------|
| `SECRET_KEY`                  | `globetrotter-secret-change-in-prod` | User, Itinerary, Recommendation  | Shared JWT signing/verification key – **must be overridden in production**, and must be the same value across all three |
| `FLASK_DEBUG`                 | `0`                                  | All services + gateway            | Set to `1` to enable Flask debug mode (development only) |
| `PORT`                        | `5001`/`5002`/`5003`/`5000`          | All services + gateway            | Port the process listens on (see docker-compose.yml for the default per service) |
| `USER_SERVICE_URL`            | `http://user-service:5001`           | Itinerary, Recommendation, Gateway | Where to reach the User Service |
| `ITINERARY_SERVICE_URL`       | `http://itinerary-service:5002`      | Recommendation, Gateway           | Where to reach the Itinerary Service |
| `RECOMMENDATION_SERVICE_URL`  | `http://recommendation-service:5003` | Gateway                           | Where to reach the Recommendation Service |
