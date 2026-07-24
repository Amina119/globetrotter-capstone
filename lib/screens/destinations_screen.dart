import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_places.dart';
import '../models/destination.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/cameroon_colors.dart';
import '../widgets/destination_card.dart';
import 'sector_detail_screen.dart';

class DestinationsScreen extends StatefulWidget {
  final String initialQuery;

  const DestinationsScreen({super.key, this.initialQuery = ''});

  @override
  State<DestinationsScreen> createState() => _DestinationsScreenState();
}

class _DestinationsScreenState extends State<DestinationsScreen> {
  late final _searchController = TextEditingController(text: widget.initialQuery);
  List<Destination> _results = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = context.read<Session>().token;
      final api = ApiService(token: token);
      final data = await api.searchDestinations(q: _searchController.text.trim());
      setState(() => _results = data.map((e) => Destination.fromJson(e)).toList());
    } catch (e) {
      setState(() => _error = 'Could not load destinations.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search destinations (name, country, description)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _search),
            ),
            onSubmitted: (_) => _search(),
          ),
        ),
        const _SectorSection(),
        const Divider(height: 24),
        if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? const Center(child: Text('No destinations found.'))
                  : RefreshIndicator(
                      onRefresh: _search,
                      child: ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, i) => DestinationCard(destination: _results[i]),
                      ),
                    ),
        ),
      ],
    );
  }
}

/// Nkolmong's sectors, shown right on the Destinations page. Tapping one
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
            'Explore Nkolmong by sector',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: nkolmongSectors.length,
            itemBuilder: (context, i) {
              final sector = nkolmongSectors[i];
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
