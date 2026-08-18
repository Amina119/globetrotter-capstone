import 'package:flutter/material.dart';

import '../models/local_place.dart';
import '../screens/place_detail_screen.dart';
import '../theme/cameroon_colors.dart';
import 'place_media.dart';

/// Picks an icon that roughly matches the place's category, for a bit more
/// visual variety than a single generic pin icon everywhere.
IconData iconForCategory(String category) {
  final c = category.toLowerCase();
  if (c.contains('mosque') || c.contains('mosquée') || c.contains('palace') || c.contains('chefferie')) return Icons.mosque_outlined;
  if (c.contains('school') || c.contains('bilingual')) return Icons.school_outlined;
  if (c.contains('driving')) return Icons.drive_eta_outlined;
  if (c.contains('bakery') || c.contains('café') || c.contains('cafe')) return Icons.bakery_dining_outlined;
  if (c.contains('ice cream') || c.contains('dessert') || c.contains('glacier')) return Icons.icecream_outlined;
  if (c.contains('beauty')) return Icons.face_retouching_natural_outlined;
  if (c.contains('salon')) return Icons.content_cut;
  if (c.contains('couture') || c.contains('tailor')) return Icons.checkroom_outlined;
  if (c.contains('clothing') || c.contains('fashion') || c.contains('boutique') || c.contains('abaya')) return Icons.checkroom_outlined;
  if (c.contains('event')) return Icons.celebration_outlined;
  if (c.contains('dry clean') || c.contains('laundry') || c.contains('pressing')) return Icons.local_laundry_service_outlined;
  if (c.contains('hardware')) return Icons.hardware_outlined;
  if (c.contains('market') || c.contains('marché') || c.contains('shopping')) return Icons.storefront_outlined;
  if (c.contains('bar') || c.contains('nightlife') || c.contains('junction')) return Icons.local_bar_outlined;
  if (c.contains('park') || c.contains('green')) return Icons.park_outlined;
  if (c.contains('bus') || c.contains('transit')) return Icons.directions_bus_outlined;
  if (c.contains('square')) return Icons.deck_outlined;
  if (c.contains('hotel')) return Icons.hotel;
  return Icons.place_outlined;
}

/// Cycles through a small, cheerful palette so lists of places don't look
/// monotone.
Color colorForCategory(String category) {
  const palette = [CameroonColors.red, CameroonColors.green, Color(0xFF1976D2), Color(0xFFEF6C00), Color(0xFF8E24AA)];
  return palette[category.hashCode.abs() % palette.length];
}

/// A single real place — with its thumbnail (video, if the place has one, or
/// photo/icon fallback), name, category, rating, and price — shown in a
/// vertical list. Used on the Destinations tab and each sector's detail
/// page, so real places (with their real videos) look the same everywhere.
class PlaceTile extends StatelessWidget {
  final LocalPlace place;
  final IconData? icon;
  final Color? accent;

  const PlaceTile({super.key, required this.place, this.icon, this.accent});

  @override
  Widget build(BuildContext context) {
    final resolvedIcon = icon ?? iconForCategory(place.category);
    final resolvedAccent = accent ?? colorForCategory(place.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shadowColor: resolvedAccent.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place, icon: resolvedIcon, accent: resolvedAccent)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: PlaceMedia(
                  videoAsset: place.videoAsset,
                  imageAsset: place.imageAsset,
                  icon: resolvedIcon,
                  color: resolvedAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(place.category, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(place.rating.toStringAsFixed(1), style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: resolvedAccent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            place.priceTier,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: resolvedAccent),
                          ),
                        ),
                        if (place.sector != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.location_on, size: 13, color: Colors.black38),
                          const SizedBox(width: 1),
                          Text(place.sector!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black45)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
