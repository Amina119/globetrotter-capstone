import 'package:flutter/material.dart';

import '../data/sample_places.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/cameroon_colors.dart';
import '../theme/sector_palette.dart';
import '../widgets/place_media.dart';
import '../widgets/place_tile.dart';

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
    final l10n = AppLocalizations.of(context)!;

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
                    _StatCard(icon: Icons.hotel, count: hotels.length, label: l10n.hotelsLabel, color: colors[0]),
                    const SizedBox(width: 12),
                    _StatCard(icon: Icons.place_outlined, count: attractions.length, label: l10n.placesToVisitLabel, color: CameroonColors.red),
                  ],
                ),
                const SizedBox(height: 26),
                _SectionLabel(icon: Icons.hotel, text: l10n.hotelsLabel, color: colors[0]),
                const SizedBox(height: 10),
                if (hotels.isEmpty)
                  _EmptyNote(text: l10n.noHotelsYet)
                else
                  ...hotels.map((h) => PlaceTile(place: h, icon: Icons.hotel, accent: colors[0])),
                const SizedBox(height: 26),
                _SectionLabel(icon: Icons.place_outlined, text: l10n.areasToVisitLabel, color: CameroonColors.red),
                const SizedBox(height: 10),
                if (attractions.isEmpty)
                  _EmptyNote(text: l10n.noAttractionsYet)
                else
                  ...attractions.map((a) => PlaceTile(place: a)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
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

