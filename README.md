# GlobeTrotter – Travel Assistant

GlobeTrotter is a **monolithic Flask application with a Flutter frontend** that serves as the starting point for a semester-long capstone project.  
Students build the monolith first, then refactor it into microservices, and finally deploy it to the cloud with resilience patterns using Docker, Kubernetes, and cloud-native tooling.

---

## Project Structure

```
.
├── app/                     # Flask backend
│   ├── __init__.py          # Flask app factory
│   ├── models.py            # Data models and JSON file I/O
│   ├── auth.py               # Registration, login, JWT handling
│   ├── destinations.py       # Destination search endpoint
│   ├── recommendations.py    # Personalised recommendations endpoint
│   ├── itineraries.py        # Create / view / edit / delete / share itineraries
│   └── main.py                # App entry point
├── data/
│   ├── destinations.json     # Static destination catalogue (seed data)
│   ├── users.json            # Created at runtime
│   └── itineraries.json      # Created at runtime
├── tests/                    # Placeholder for future backend tests
├── lib/                      # Flutter frontend
│   ├── main.dart
│   ├── screens/               # App screens (auth, home dashboard, destinations, itineraries, ...)
│   ├── widgets/                # Reusable UI components
│   ├── services/                # API client and session management
│   ├── models/                  # Frontend data models
│   └── theme/                    # App color scheme
├── android/ ios/ web/         # Flutter platform targets
├── Dockerfile
├── docker-compose.yml
├── requirements.txt           # Backend (Python) dependencies
├── pubspec.yaml                # Frontend (Flutter) dependencies
└── README.md
```

---

## REST API

| Method | Endpoint                    | Auth required | Description                                    |
|--------|------------------------------|---------------|-------------------------------------------------|
| GET    | `/health`                    | No            | Liveness/readiness probe                        |
| POST   | `/register`                  | No            | Register a new user                              |
| POST   | `/login`                     | No            | Authenticate and receive a JWT token             |
| GET    | `/destinations`              | No            | Search the destination catalogue                 |
| GET    | `/recommendations`           | Yes (JWT)     | Get personalised recommendations                 |
| POST   | `/itineraries`               | Yes (JWT)     | Create a new itinerary                           |
| GET    | `/itineraries`               | Yes (JWT)     | List itineraries owned by the logged-in user     |
| GET    | `/itineraries/shared`        | Yes (JWT)     | List itineraries shared with the logged-in user  |
| PUT    | `/itineraries/<id>`          | Yes (JWT)     | Update an itinerary you own                      |
| DELETE | `/itineraries/<id>`          | Yes (JWT)     | Delete an itinerary you own                      |
| POST   | `/itineraries/<id>/share`    | Yes (JWT)     | Share an itinerary you own with another user     |
| DELETE | `/itineraries/<id>/share`    | Yes (JWT)     | Revoke another user's access to your itinerary   |

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

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Start the server
python app/main.py
```

The API will be available at `http://localhost:5000`.

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
# Build and start
docker-compose up --build

# Stop
docker-compose down
```

The `data/` directory is mounted into the container, so JSON files persist between runs.

---

## Data Storage

All data is persisted in plain JSON files inside the `data/` directory:

| File                    | Purpose                              |
|-------------------------|--------------------------------------|
| `data/destinations.json`| Static catalogue of travel destinations (seed data) |
| `data/users.json`       | Registered users (created at runtime) |
| `data/itineraries.json` | User itineraries (created at runtime) |

> **Note:** `data/*.json` (except `destinations.json`) are excluded from version control via `.gitignore`.

---

## Configuration

| Environment Variable | Default                              | Description           |
|----------------------|--------------------------------------|-----------------------|
| `SECRET_KEY`         | `globetrotter-secret-change-in-prod` | JWT signing key – **must be overridden in production** |
| `FLASK_DEBUG`        | `0`                                  | Set to `1` to enable Flask debug mode (development only) |
| `PORT`               | `5000`                               | Port the app listens on |
