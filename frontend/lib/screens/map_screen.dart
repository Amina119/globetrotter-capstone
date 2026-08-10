import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../models/itinerary.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/session.dart';
import '../theme/cameroon_colors.dart';
import '../utils/bike_estimate.dart';

/// Default map center: Nkolmbong, Yaoundé — where the app's destinations
/// are, so the map opens somewhere useful even before the user's own
/// location is known.
const LatLng _defaultCenter = LatLng(3.8480, 11.5021);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  List<Destination> _destinations = [];
  bool _loading = true;
  String? _error;

  LatLng? _myLocation;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
    _loadLocation();
  }

  ApiService _api() => ApiService(token: context.read<Session>().token);

  Future<void> _loadDestinations() async {
    setState(() => _loading = true);
    try {
      final data = await _api().searchDestinations();
      setState(() {
        _destinations = data.map((e) => Destination.fromJson(e)).where((d) => d.hasPosition).toList();
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'Could not load destinations.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadLocation() async {
    try {
      final location = await LocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _myLocation = location;
        _locationError = null;
      });
      _mapController.move(location, 14);
    } on LocationUnavailableException catch (e) {
      if (mounted) setState(() => _locationError = e.toString());
    }
  }

  void _showDestinationSheet(Destination destination) {
    final estimate = BikeEstimate.from(
      _myLocation,
      LatLng(destination.latitude!, destination.longitude!),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _DestinationSheet(
        destination: destination,
        estimate: estimate,
        locationError: _myLocation == null ? _locationError : null,
        onAddToItinerary: () => _openAddToItinerary(destination),
      ),
    );
  }

  Future<void> _openAddToItinerary(Destination destination) async {
    Navigator.of(context).pop(); // close the bottom sheet first

    try {
      final api = _api();
      final mine = (await api.getItineraries()).map((e) => Itinerary.fromJson(e)).toList();
      if (!mounted) return;

      final choice = await showDialog<Itinerary?>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text('Add ${destination.name} to...'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, null),
              child: const Row(children: [Icon(Icons.add), SizedBox(width: 8), Text('New itinerary')]),
            ),
            if (mine.isNotEmpty) const Divider(),
            ...mine.map(
              (it) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, it),
                child: Text(it.title),
              ),
            ),
          ],
        ),
      );

      if (choice == null && mine.isEmpty) {
        // dialog dismissed without a choice and there was nothing to pick anyway
      }

      if (!mounted) return;

      if (choice != null) {
        await api.updateItinerary(
          choice.id,
          title: choice.title,
          destinations: [...choice.destinations, destination.name],
          startDate: choice.startDate,
          endDate: choice.endDate,
          notes: choice.notes,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${destination.name} to "${choice.title}"')),
        );
      } else {
        await _createItineraryDialog(destination);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _createItineraryDialog(Destination destination) async {
    final titleController = TextEditingController();
    final startController = TextEditingController();
    final endController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New itinerary with ${destination.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: startController,
                decoration: const InputDecoration(labelText: 'Start date (YYYY-MM-DD)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: endController,
                decoration: const InputDecoration(labelText: 'End date (YYYY-MM-DD)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    try {
      await _api().createItinerary(
        title: titleController.text.trim(),
        destinations: [destination.name],
        startDate: startController.text.trim(),
        endDate: endController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created itinerary "${titleController.text.trim()}"')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(initialCenter: _defaultCenter, initialZoom: 13),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.globetrotter.frontend',
            ),
            MarkerLayer(
              markers: [
                for (final destination in _destinations)
                  Marker(
                    point: LatLng(destination.latitude!, destination.longitude!),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showDestinationSheet(destination),
                      child: const Icon(Icons.location_on, color: CameroonColors.red, size: 40),
                    ),
                  ),
                if (_myLocation != null)
                  Marker(
                    point: _myLocation!,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (_error != null)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _Banner(text: _error!, color: Colors.red),
          )
        else if (_locationError != null && _myLocation == null)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _Banner(text: _locationError!, color: Colors.orange),
          ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'my-location',
            onPressed: _loadLocation,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  final Color color;

  const _Banner({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      color: color.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _DestinationSheet extends StatelessWidget {
  final Destination destination;
  final BikeEstimate? estimate;
  final String? locationError;
  final VoidCallback onAddToItinerary;

  const _DestinationSheet({
    required this.destination,
    required this.estimate,
    required this.locationError,
    required this.onAddToItinerary,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(destination.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              [destination.quarter, destination.town].where((s) => s.isNotEmpty).join(', '),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
            if (destination.sector.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(destination.sector, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 16),
            if (estimate != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CameroonColors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.two_wheeler, color: CameroonColors.greenDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${estimate!.distanceLabel} · ${estimate!.etaLabel} · ${estimate!.priceLabel} by bike',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                locationError ?? 'Getting your location…',
                style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAddToItinerary,
                icon: const Icon(Icons.playlist_add),
                label: const Text('Add to itinerary'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
