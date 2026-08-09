/// A restaurant, hotel or point-of-interest listing shown on the home
/// dashboard and destination pages.
///
/// There is no backend model for these yet, so listings are curated sample
/// data representing establishments around Nkolmbong, Yaoundé.
class LocalPlace {
  final String name;
  final String category;
  final double rating;
  final String priceTier;

  /// The Nkolmbong sector this place is in (hotels only, see
  /// [nkolmbongSectors]). Null for places not tied to a sector.
  final String? sector;

  /// Short description shown on the place detail screen. Null falls back to
  /// a generic placeholder message.
  final String? description;

  /// Asset path (e.g. `assets/places/san_francisco/carrefour.mp4`) for a
  /// looping, muted video shown on the place detail screen and list tile —
  /// the preferred media for a place. Takes priority over [imageAsset] when
  /// both are set. Null, or an asset that hasn't been dropped in yet, falls
  /// back to [imageAsset] or the colored icon placeholder.
  final String? videoAsset;

  /// Asset path (e.g. `assets/places/san_francisco/carrefour.jpg`) for a
  /// still photo, used when [videoAsset] isn't set. Null, or an asset that
  /// hasn't been dropped in yet, falls back to a colored icon placeholder.
  final String? imageAsset;

  const LocalPlace({
    required this.name,
    required this.category,
    required this.rating,
    required this.priceTier,
    this.sector,
    this.description,
    this.videoAsset,
    this.imageAsset,
  });
}
