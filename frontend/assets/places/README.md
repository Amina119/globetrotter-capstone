Drop place videos here, named to match the `videoAsset` path referenced in
`lib/data/sample_places.dart`, e.g. `assets/places/san_francisco/carrefour.mp4`.
Videos are looped and muted automatically, both on the place's list tile
and on its detail page.

Each sector also has a `assets/places/<sector_slug>/banner.mp4` used as the
hero video at the top of its detail page (slug = sector name lowercased with
spaces/punctuation turned into underscores, see `lib/theme/sector_palette.dart`).

Still photos are also supported as a fallback via the `imageAsset` field
(e.g. `assets/places/san_francisco/carrefour.jpg`) — used only if no video
is set for that place.

Until a video (or photo) exists at its path, the place shows a colorful icon
placeholder instead — nothing breaks if media arrives later.
