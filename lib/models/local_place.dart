/// A restaurant or hotel listing shown on the home dashboard.
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

  const LocalPlace({
    required this.name,
    required this.category,
    required this.rating,
    required this.priceTier,
    this.sector,
  });
}
