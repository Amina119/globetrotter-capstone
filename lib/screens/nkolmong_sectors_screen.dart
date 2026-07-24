import 'package:flutter/material.dart';

import '../data/sample_places.dart';
import '../theme/cameroon_colors.dart';
import 'sector_detail_screen.dart';

/// Lets the user drill into Nkolmong by sector, then see the hotels and
/// points of interest in the sector they pick.
class NkolmongSectorsScreen extends StatelessWidget {
  const NkolmongSectorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nkolmong sectors')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: nkolmongSectors.length,
        separatorBuilder: (context, i) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final sector = nkolmongSectors[i];
          final hotelCount = sampleHotels.where((h) => h.sector == sector).length;
          final attractionCount = sampleAttractions.where((a) => a.sector == sector).length;
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(
                backgroundColor: CameroonColors.green,
                child: Icon(Icons.location_city, color: Colors.white),
              ),
              title: Text(sector, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('$hotelCount hotel${hotelCount == 1 ? '' : 's'} · $attractionCount place${attractionCount == 1 ? '' : 's'} to visit'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SectorDetailScreen(sector: sector)),
              ),
            ),
          );
        },
      ),
    );
  }
}
