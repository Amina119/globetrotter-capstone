import 'package:flutter/material.dart';

import '../data/sample_places.dart';
import '../theme/cameroon_colors.dart';
import 'sector_detail_screen.dart';

/// Lets the user drill into Nkolmbong by sector, then see the hotels and
/// points of interest in the sector they pick.
class NkolmbongSectorsScreen extends StatelessWidget {
  const NkolmbongSectorsScreen({super.key});

  static const _palette = [
    [Color(0xFF00532A), Color(0xFF007A3D)],
    [Color(0xFFB00020), CameroonColors.red],
    [Color(0xFF0D47A1), Color(0xFF1976D2)],
    [Color(0xFFE65100), Color(0xFFEF6C00)],
    [Color(0xFF4A148C), Color(0xFF8E24AA)],
    [Color(0xFF004D40), Color(0xFF00897B)],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: CameroonColors.green,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 56, right: 16, bottom: 14),
              title: Text('Nkolmbong sectors', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [CameroonColors.greenDark, CameroonColors.green, CameroonColors.gold],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final sector = nkolmbongSectors[i];
                  final hotelCount = sampleHotels.where((h) => h.sector == sector).length;
                  final attractionCount = sampleAttractions.where((a) => a.sector == sector).length;
                  final colors = _palette[i % _palette.length];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Material(
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      elevation: 3,
                      shadowColor: colors[1].withValues(alpha: 0.4),
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SectorDetailScreen(sector: sector)),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white.withValues(alpha: 0.22),
                                child: const Icon(Icons.location_city, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sector, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        _CountPill(icon: Icons.hotel, label: '$hotelCount hotel${hotelCount == 1 ? '' : 's'}'),
                                        _CountPill(icon: Icons.place_outlined, label: '$attractionCount place${attractionCount == 1 ? '' : 's'}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: nkolmbongSectors.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CountPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
