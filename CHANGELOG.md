# Changelog

All notable changes to the GlobeTrotter project (Flask backend + Flutter frontend) are documented in this file.

## [Unreleased]

### Added
- Cameroon-branded visual identity: a green/red/gold color palette drawn from the national flag, applied app-wide via the Material theme (cards, app bar, buttons, chips, navigation bar).
- Responsive login/register/forgot-password/reset-password screens: a branded split-screen layout on wide (web/desktop) windows, a compact header on narrow (mobile) windows.
- Post-login/signup welcome screen that greets the user by name before continuing to the home page.
- A home dashboard as the app's landing tab, organized into browsable sections: top destinations, personalized recommendations, restaurants, hotels, and an itineraries preview — replacing the previous single-list landing page.
- A search bar on the home dashboard that jumps to the Destinations tab with results already loaded.
- Nkolmbong sector browsing: the quarter is modeled as six sectors (Premiere Maison, Derriere Chefferie, San Francisco, Dubai City, Terminus, Chefferie Haussa), each with its own hotels and "areas to visit" (points of interest). Reachable directly from the Destinations page and from the home dashboard.
- Itinerary management: edit and delete your own itineraries (previously create/view only).
- Itinerary sharing: share an itinerary with another registered user by email, revoke access, and view itineraries others have shared with you (new "Shared with me" tab).
- Recommendation scoring now blends three signals: stated preferences, tags from the user's own past itineraries, and cross-user popularity of each destination — previously preferences only.
- `/health` endpoint for uptime/liveness probing.
- `CHANGELOG.md` (this file).

### Changed
- Replaced the seed destination catalogue (world cities: Bali, Paris, Tokyo, Cape Town, etc.) with destinations actually located in Nkolmbong, Yaoundé, Cameroon — one or two per sector, matching the sector attractions.
- All prices switched from placeholder dollar notation (`$`, `$$$`, `~$X/day`) to realistic FCFA amounts.
- Corrected the quarter's name from "Nkolmong" to "Nkolmbong" throughout the app, data, and backend.
- `Destination.matchScore` changed from an integer to a numeric type to support the new blended (non-integer) recommendation scores.

### Fixed
- Synced the backend committed on the `Amina` branch (which had fallen behind) with the actual enhanced backend, so the branch's frontend and backend are consistent — the frontend was calling itinerary edit/delete/share and `/health` routes that didn't exist in that branch's backend.

## Initial build

- Flask monolith backend: registration/login with JWT auth, destination search, personalized recommendations, itinerary create/list — scaffolded from the course template (`sas-bergson/globetrotter-capstone`).
- Flutter frontend: login/register screens, destinations/recommendations/itineraries tabs, session persistence.
- Merged the previously separate frontend and backend repositories into a single repo/branch (`Amina`) so the whole project can be built and reviewed together.
