import 'package:flutter/material.dart';

import '../data/sample_places.dart';
import '../models/local_place.dart';
import '../theme/cameroon_colors.dart';
import '../theme/sector_palette.dart';
import '../widgets/place_media.dart';
import 'place_detail_screen.dart';

/// A single Nkolmbong sector: its hotels and its points of interest
/// ("areas to visit").
class SectorDetailScreen extends StatelessWidget {
  final String sector;

  const SectorDetailScreen({super.key, required this.sector});

  @override
  Widget build(BuildContext context) {
    final hotels = sampleHotels.where((h) => h.sector == sector).toList();
    final attractions = sampleAttractions.where((a) => a.sector == sector).toList();
    final colors = sectorColors(sector);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 210,
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: colors[0],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, right: 16, bottom: 14),
              title: Text(
                sector,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 8, color: Colors.black45)]),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PlaceMedia(
                    videoAsset: 'assets/places/${sectorSlug(sector)}/banner.mp4',
                    imageAsset: 'assets/places/${sectorSlug(sector)}/banner.jpg',
                    icon: Icons.location_city,
                    color: colors[1],
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [colors[0].withValues(alpha: 0.35), Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    _StatCard(icon: Icons.hotel, count: hotels.length, label: 'Hotels', color: colors[0]),
                    const SizedBox(width: 12),
                    _StatCard(icon: Icons.place_outlined, count: attractions.length, label: 'Places to visit', color: CameroonColors.red),
                  ],
                ),
                const SizedBox(height: 26),
                _SectionLabel(icon: Icons.hotel, text: 'Hotels', color: colors[0]),
                const SizedBox(height: 10),
                if (hotels.isEmpty)
                  const _EmptyNote(text: 'No hotels listed in this sector yet.')
                else
                  ...hotels.map((h) => _PlaceTile(place: h, icon: Icons.hotel, accent: colors[0])),
                const SizedBox(height: 26),
                _SectionLabel(icon: Icons.place_outlined, text: 'Areas to visit', color: CameroonColors.red),
                const SizedBox(height: 10),
                if (attractions.isEmpty)
                  const _EmptyNote(text: 'No points of interest listed in this sector yet.')
                else
                  ...attractions.map((a) => _PlaceTile(place: a, icon: _iconFor(a.category), accent: _colorFor(a.category))),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Picks an icon that roughly matches the place's category, for a bit more
/// visual variety than a single generic pin icon everywhere.
IconData _iconFor(String category) {
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
  return Icons.place_outlined;
}

/// Cycles through a small, cheerful palette so the "Areas to visit" list
/// doesn't look monotone.
Color _colorFor(String category) {
  const palette = [CameroonColors.red, CameroonColors.green, Color(0xFF1976D2), Color(0xFFEF6C00), Color(0xFF8E24AA)];
  return palette[category.hashCode.abs() % palette.length];
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _StatCard({required this.icon, required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 18, backgroundColor: color, child: Icon(icon, size: 18, color: Colors.white)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
                  Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _SectionLabel({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String text;

  const _EmptyNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54));
  }
}

class _PlaceTile extends StatelessWidget {
  final LocalPlace place;
  final IconData icon;
  final Color accent;

  const _PlaceTile({required this.place, required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: accent.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place, icon: icon, accent: accent)),
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
                  icon: icon,
                  color: accent,
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
                          decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            place.priceTier,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: accent),
                          ),
                        ),
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
