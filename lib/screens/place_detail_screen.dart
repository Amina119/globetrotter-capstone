import 'package:flutter/material.dart';

import '../models/local_place.dart';
import '../theme/cameroon_colors.dart';
import '../widgets/place_media.dart';

/// Full-screen detail view for a single place: photo, description and the
/// minimum amount needed to spend time there.
class PlaceDetailScreen extends StatelessWidget {
  final LocalPlace place;
  final IconData icon;
  final Color accent;

  const PlaceDetailScreen({super.key, required this.place, required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: accent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, right: 16, bottom: 14),
              title: Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 8, color: Colors.black45)]),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PlaceMedia(videoAsset: place.videoAsset, imageAsset: place.imageAsset, icon: icon, color: accent),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black45],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Chip(icon: Icons.category_outlined, label: place.category, color: accent),
                      _Chip(icon: Icons.star_rounded, label: place.rating.toStringAsFixed(1), color: CameroonColors.gold, dark: true),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'About this place',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.description ?? 'No description yet — check back soon for more details about this place.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [CameroonColors.greenDark, CameroonColors.green],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: CameroonColors.gold,
                          child: Icon(Icons.payments_outlined, color: CameroonColors.greenDark),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Minimum amount to be there', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                place.priceTier,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool dark;

  const _Chip({required this.icon, required this.label, required this.color, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: dark ? Colors.amber.shade800 : color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: dark ? Colors.amber.shade800 : color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
