import 'package:flutter/material.dart';

import '../models/destination.dart';

class DestinationCard extends StatelessWidget {
  final Destination destination;

  const DestinationCard({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${destination.name}, ${destination.town}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (destination.matchScore != null)
                  Chip(
                    label: Text('match ${destination.matchScore}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (destination.quarter.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(destination.quarter, style: Theme.of(context).textTheme.labelMedium),
            ],
            const SizedBox(height: 4),
            Text(destination.sector, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: -8,
              children: [
                for (final tag in destination.tags) Chip(label: Text(tag), visualDensity: VisualDensity.compact),
                if (destination.avgCostPerDay != null)
                  Chip(
                    label: Text('~\$${destination.avgCostPerDay}/day'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
