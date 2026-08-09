import 'package:flutter/material.dart';

import '../models/local_place.dart';
import 'place_media.dart';

/// Compact card for a restaurant or hotel, used in home dashboard rails.
class PlaceCard extends StatelessWidget {
  final LocalPlace place;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const PlaceCard({super.key, required this.place, required this.icon, required this.accent, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 90,
                width: double.infinity,
                child: PlaceMedia(
                  videoAsset: place.videoAsset,
                  imageAsset: place.imageAsset,
                  icon: icon,
                  color: accent,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.category,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(place.rating.toStringAsFixed(1), style: Theme.of(context).textTheme.labelMedium),
                        const Spacer(),
                        Text(place.priceTier, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
