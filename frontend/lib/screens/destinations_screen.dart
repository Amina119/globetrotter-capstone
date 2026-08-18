import 'package:flutter/material.dart';

import '../data/sample_places.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/local_place.dart';
import '../theme/cameroon_colors.dart';
import '../widgets/place_tile.dart';
import 'sector_detail_screen.dart';

class DestinationsScreen extends StatefulWidget {
  final String initialQuery;

  const DestinationsScreen({super.key, this.initialQuery = ''});

  @override
  State<DestinationsScreen> createState() => _DestinationsScreenState();
}

class _DestinationsScreenState extends State<DestinationsScreen> {
  late final _searchController = TextEditingController(text: widget.initialQuery);
  List<LocalPlace> _results = allNkolmbongPlaces;

  void _search() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _results = query.isEmpty
          ? allNkolmbongPlaces
          : allNkolmbongPlaces.where((p) {
              return p.name.toLowerCase().contains(query) ||
                  p.category.toLowerCase().contains(query) ||
                  (p.sector?.toLowerCase().contains(query) ?? false) ||
                  p.tags.any((t) => t.toLowerCase().contains(query));
            }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) _search();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchPlacesHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _search),
            ),
            onSubmitted: (_) => _search(),
          ),
        ),
        const _SectorSection(),
        const Divider(height: 24),
        Expanded(
          child: _results.isEmpty
              ? Center(child: Text(l10n.noPlacesFound))
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, i) => PlaceTile(place: _results[i]),
                ),
        ),
      ],
    );
  }
}

/// Nkolmbong's sectors, shown right on the Destinations page. Tapping one
/// shows the hotels and points of interest in that sector.
class _SectorSection extends StatelessWidget {
  const _SectorSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalizations.of(context)!.exploreBySector,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: nkolmbongSectors.length,
            itemBuilder: (context, i) {
              final sector = nkolmbongSectors[i];
              return _SectorCard(
                sector: sector,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SectorDetailScreen(sector: sector)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectorCard extends StatelessWidget {
  final String sector;
  final VoidCallback onTap;

  const _SectorCard({required this.sector, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: CameroonColors.green,
                  child: Icon(Icons.location_city, color: Colors.white, size: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  sector,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
