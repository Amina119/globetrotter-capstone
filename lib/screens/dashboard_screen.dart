import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_places.dart';
import '../models/destination.dart';
import '../models/itinerary.dart';
import '../models/local_place.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/cameroon_colors.dart';
import '../widgets/compact_destination_card.dart';
import '../widgets/place_card.dart';
import '../widgets/section_header.dart';
import 'nkolmbong_sectors_screen.dart';
import 'sector_detail_screen.dart';

/// The app's landing tab: a dashboard organized into browsable sections
/// (destinations, recommendations, restaurants, hotels, itineraries)
/// instead of dropping the user straight into a single list.
class DashboardScreen extends StatefulWidget {
  final void Function(int tabIndex) onSeeAll;
  final void Function(String query) onSearch;

  const DashboardScreen({super.key, required this.onSeeAll, required this.onSearch});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  List<Destination> _destinations = [];
  List<Destination> _recommendations = [];
  List<Itinerary> _itineraries = [];
  String? _destinationsError;
  String? _recommendationsError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  ApiService _api() => ApiService(token: context.read<Session>().token);

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = _api();

    try {
      final data = await api.searchDestinations();
      _destinations = data.map((e) => Destination.fromJson(e)).toList();
      _destinationsError = null;
    } catch (_) {
      _destinationsError = 'Could not load destinations.';
    }

    try {
      final data = await api.getRecommendations(limit: 8);
      _recommendations = data.map((e) => Destination.fromJson(e)).toList();
      _recommendationsError = null;
    } catch (_) {
      _recommendationsError = 'Could not load recommendations.';
    }

    try {
      final data = await api.getItineraries();
      _itineraries = data.map((e) => Itinerary.fromJson(e)).toList();
    } catch (_) {
      _itineraries = [];
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final displayName = (session.name != null && session.name!.isNotEmpty) ? session.name : session.email;

    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _GreetingBanner(name: displayName),
          const SizedBox(height: 16),
          _DashboardSearchField(onSearch: widget.onSearch),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Top destinations',
            icon: Icons.explore,
            onSeeAll: () => widget.onSeeAll(1),
          ),
          _DestinationRail(items: _destinations, error: _destinationsError),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Recommended for you',
            icon: Icons.recommend,
            onSeeAll: () => widget.onSeeAll(2),
          ),
          _DestinationRail(items: _recommendations, error: _recommendationsError, emptyText: 'Set preferences at registration to get recommendations.'),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Restaurants near Nkolmbong', icon: Icons.restaurant),
          _PlaceRail(items: sampleRestaurants, icon: Icons.restaurant, accent: CameroonColors.red),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Hotels in Nkolmbong',
            icon: Icons.hotel,
            onSeeAll: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NkolmbongSectorsScreen()),
            ),
          ),
          _PlaceRail(items: sampleHotels, icon: Icons.hotel, accent: CameroonColors.green),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Your itineraries',
            icon: Icons.map,
            onSeeAll: () => widget.onSeeAll(3),
          ),
          _ItinerariesPreview(items: _itineraries, onCreate: () => widget.onSeeAll(3)),
        ],
      ),
    );
  }
}

class _GreetingBanner extends StatelessWidget {
  final String? name;

  const _GreetingBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    final greeting = (name == null || name!.isEmpty) ? 'Mbolo!' : 'Mbolo, $name!';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CameroonColors.greenDark, CameroonColors.green],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 15, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Discover Nkolmbong, Yaoundé and the world beyond',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 26,
            backgroundColor: CameroonColors.gold,
            child: Icon(Icons.travel_explore, color: CameroonColors.greenDark, size: 28),
          ),
        ],
      ),
    );
  }
}

class _DashboardSearchField extends StatefulWidget {
  final void Function(String query) onSearch;

  const _DashboardSearchField({required this.onSearch});

  @override
  State<_DashboardSearchField> createState() => _DashboardSearchFieldState();
}

class _DashboardSearchFieldState extends State<_DashboardSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => widget.onSearch(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search destinations, e.g. "beach" or "Bali"',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _submit),
        ),
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}

class _DestinationRail extends StatelessWidget {
  final List<Destination> items;
  final String? error;
  final String emptyText;

  const _DestinationRail({required this.items, this.error, this.emptyText = 'Nothing to show yet.'});

  @override
  Widget build(BuildContext context) {
    if (error != null) return _RailMessage(text: error!);
    if (items.isEmpty) return _RailMessage(text: emptyText);
    return SizedBox(
      height: 168,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, i) => CompactDestinationCard(destination: items[i]),
      ),
    );
  }
}

class _PlaceRail extends StatelessWidget {
  final List<LocalPlace> items;
  final IconData icon;
  final Color accent;

  const _PlaceRail({required this.items, required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final place = items[i];
          return PlaceCard(
            place: place,
            icon: icon,
            accent: accent,
            onTap: place.sector == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SectorDetailScreen(sector: place.sector!)),
                    ),
          );
        },
      ),
    );
  }
}

class _RailMessage extends StatelessWidget {
  final String text;

  const _RailMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
    );
  }
}

class _ItinerariesPreview extends StatelessWidget {
  final List<Itinerary> items;
  final VoidCallback onCreate;

  const _ItinerariesPreview({required this.items, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: OutlinedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Plan your first trip'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: items.take(3).map((it) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.map_outlined),
              title: Text(it.title),
              subtitle: Text('${it.destinations.join(", ")}\n${it.startDate} → ${it.endDate}'),
              isThreeLine: true,
            ),
          );
        }).toList(),
      ),
    );
  }
}
