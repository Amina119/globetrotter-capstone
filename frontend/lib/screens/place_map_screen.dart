import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/location_service.dart';
import '../services/routing_service.dart';
import '../theme/cameroon_colors.dart';
import '../utils/travel_estimate.dart';

/// Shows a single place's exact position on the map, alongside the user's
/// own live location, the real road-following path to get there, and the
/// estimated distance/time/price on foot, by bike, or by car. Opened from a
/// place's "Show on map" button once the place has a pinned position (set
/// by an admin in Manage Destinations).
class PlaceMapScreen extends StatefulWidget {
  final String placeName;
  final double latitude;
  final double longitude;

  const PlaceMapScreen({
    super.key,
    required this.placeName,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<PlaceMapScreen> createState() => _PlaceMapScreenState();
}

class _PlaceMapScreenState extends State<PlaceMapScreen> {
  late final LatLng _placePosition = LatLng(widget.latitude, widget.longitude);
  final MapController _mapController = MapController();

  LatLng? _myLocation;
  String? _locationError;
  bool _loadingLocation = true;

  // Real road-following routes per mode, fetched once the user's location
  // is known. A mode missing from this map (e.g. the routing service
  // couldn't reach it) just falls back to the straight-line estimate —
  // the path simply won't be drawn for that mode.
  final Map<TravelMode, RouteResult> _routes = {};
  bool _loadingRoutes = false;
  TravelMode? _selectedMode;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      final location = await LocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() => _myLocation = location);
      unawaited(_loadRoutes(location));
    } on LocationUnavailableException catch (e) {
      if (mounted) setState(() => _locationError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  /// Fetches the real walking/bike/car routes in parallel. Each mode is
  /// caught independently so one failing (or the whole public routing
  /// service being briefly down) doesn't block the others.
  Future<void> _loadRoutes(LatLng from) async {
    setState(() {
      _loadingRoutes = true;
      _routes.clear();
    });

    await Future.wait(TravelMode.values.map((mode) async {
      try {
        final result = await RoutingService.getRoute(from, _placePosition, mode);
        if (mounted) setState(() => _routes[mode] = result);
      } on RoutingException {
        // Left out of _routes; the estimate panel falls back to the
        // straight-line approximation for this mode.
      }
    }));

    if (mounted) setState(() => _loadingRoutes = false);
  }

  List<TravelEstimate> get _estimates {
    if (_myLocation == null) return [];
    return TravelMode.values.map((mode) {
      final route = _routes[mode];
      if (route != null) {
        return TravelEstimate.fromRoute(mode: mode, distanceKm: route.distanceKm, etaMinutes: route.etaMinutes);
      }
      return TravelEstimate.from(_myLocation, _placePosition, mode);
    }).whereType<TravelEstimate>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final estimates = _estimates;

    // Default to the fastest mode ("best route") once estimates exist. A
    // plain field write is safe in build() — it only takes effect once.
    if (estimates.isNotEmpty) {
      _selectedMode ??= estimates.reduce((a, b) => a.etaMinutes <= b.etaMinutes ? a : b).mode;
    }
    final selectedRoute = _selectedMode == null ? null : _routes[_selectedMode];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.placeMapTitle(widget.placeName))),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: _placePosition, initialZoom: 15),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.globetrotter.frontend',
                    ),
                    if (selectedRoute != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(points: selectedRoute.points, strokeWidth: 5, color: CameroonColors.green),
                        ],
                      )
                    else if (_myLocation != null)
                      // Real route not available (yet, or this mode's
                      // routing failed) — a dashed straight line still
                      // shows roughly where the place is relative to you.
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [_myLocation!, _placePosition],
                            strokeWidth: 3,
                            color: CameroonColors.green.withValues(alpha: 0.5),
                            pattern: const StrokePattern.dotted(),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _placePosition,
                          width: 44,
                          height: 44,
                          child: const Icon(Icons.location_on, color: CameroonColors.red, size: 44),
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
                if (_locationError != null && _myLocation == null)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: _Banner(text: _locationError!),
                  ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'place-map-my-location',
                    onPressed: _loadLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          _ItineraryPanel(
            estimates: estimates,
            loading: _loadingLocation && _myLocation == null,
            loadingRoutes: _loadingRoutes,
            selectedMode: _selectedMode,
            onModeSelected: (mode) => setState(() => _selectedMode = mode),
          ),
        ],
      ),
    );
  }
}

void unawaited(Future<void> future) {}

/// Lets the user pick a travel mode (tapping a column selects it); the
/// price/ETA shown below always reflects whichever mode is currently
/// selected, and selecting a mode also switches which route is drawn on
/// the map above. Defaults to the fastest mode ("best route").
class _ItineraryPanel extends StatelessWidget {
  final List<TravelEstimate> estimates;
  final bool loading;
  final bool loadingRoutes;
  final TravelMode? selectedMode;
  final ValueChanged<TravelMode> onModeSelected;

  const _ItineraryPanel({
    required this.estimates,
    required this.loading,
    required this.loadingRoutes,
    required this.selectedMode,
    required this.onModeSelected,
  });

  TravelEstimate? _estimateFor(TravelMode mode) {
    for (final e in estimates) {
      if (e.mode == mode) return e;
    }
    return null;
  }

  TravelEstimate? get _bestEstimate {
    if (estimates.isEmpty) return null;
    return estimates.reduce((a, b) => a.etaMinutes <= b.etaMinutes ? a : b);
  }

  String _modeLabel(AppLocalizations l10n, TravelMode mode) {
    switch (mode) {
      case TravelMode.walking:
        return l10n.travelModeWalking;
      case TravelMode.motoSansBachement:
        return l10n.travelModeMotoSansBachement;
      case TravelMode.motoAvecBachement:
        return l10n.travelModeMotoAvecBachement;
      case TravelMode.car:
        return l10n.travelModeCar;
    }
  }

  IconData _modeIcon(TravelMode mode) {
    switch (mode) {
      case TravelMode.walking:
        return Icons.directions_walk_rounded;
      case TravelMode.motoSansBachement:
      case TravelMode.motoAvecBachement:
        return Icons.two_wheeler_rounded;
      case TravelMode.car:
        return Icons.directions_car_filled_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final best = _bestEstimate;
    final selected = selectedMode == null ? null : _estimateFor(selectedMode!);

    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.itineraryFromYou,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (loadingRoutes)
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              const SizedBox(height: 12),
              if (loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 10),
                      Text(l10n.gettingYourLocation),
                    ],
                  ),
                )
              else if (estimates.isEmpty)
                Text(l10n.gettingYourLocation)
              else ...[
                Row(
                  children: [
                    for (final estimate in estimates)
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onModeSelected(estimate.mode),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: estimate.mode == selectedMode
                                  ? CameroonColors.green.withValues(alpha: 0.14)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: estimate.mode == selectedMode ? CameroonColors.green : Colors.black12,
                                width: estimate.mode == selectedMode ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _modeIcon(estimate.mode),
                                  color: estimate.mode == selectedMode ? CameroonColors.greenDark : Colors.black54,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _modeLabel(l10n, estimate.mode),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                    color: estimate.mode == selectedMode ? CameroonColors.greenDark : Colors.black87,
                                  ),
                                ),
                                if (estimate.mode == best?.mode) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.bestRoute,
                                    style: const TextStyle(fontSize: 10, color: CameroonColors.greenDark, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (selected != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CameroonColors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(_modeIcon(selected.mode), color: CameroonColors.greenDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${_modeLabel(l10n, selected.mode)} · ${selected.distanceLabel} · ${selected.etaLabel}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          selected.priceFcfa == null ? l10n.travelFree : '${selected.priceFcfa} FCFA',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: CameroonColors.greenDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;

  const _Banner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      color: Colors.orange.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
