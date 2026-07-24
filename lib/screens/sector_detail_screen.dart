import 'package:flutter/material.dart';

import '../data/sample_places.dart';
import '../models/local_place.dart';
import '../theme/cameroon_colors.dart';

/// A single Nkolmong sector: its hotels and its points of interest
/// ("areas to visit").
class SectorDetailScreen extends StatelessWidget {
  final String sector;

  const SectorDetailScreen({super.key, required this.sector});

  @override
  Widget build(BuildContext context) {
    final hotels = sampleHotels.where((h) => h.sector == sector).toList();
    final attractions = sampleAttractions.where((a) => a.sector == sector).toList();

    return Scaffold(
      appBar: AppBar(title: Text(sector)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel(icon: Icons.hotel, text: 'Hotels'),
          const SizedBox(height: 8),
          if (hotels.isEmpty)
            const _EmptyNote(text: 'No hotels listed in this sector yet.')
          else
            ...hotels.map((h) => _PlaceTile(place: h, icon: Icons.hotel, accent: CameroonColors.green)),
          const SizedBox(height: 24),
          _SectionLabel(icon: Icons.place_outlined, text: 'Areas to visit'),
          const SizedBox(height: 8),
          if (attractions.isEmpty)
            const _EmptyNote(text: 'No points of interest listed in this sector yet.')
          else
            ...attractions.map((a) => _PlaceTile(place: a, icon: Icons.place_outlined, accent: CameroonColors.red)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: accent.withValues(alpha: 0.15),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(place.category, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(place.rating.toStringAsFixed(1), style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(width: 12),
                      Text(place.priceTier, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
