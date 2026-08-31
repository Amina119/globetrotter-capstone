import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../utils/travel_estimate.dart';

class RoutingException implements Exception {
  final String message;
  RoutingException(this.message);

  @override
  String toString() => message;
}

/// A real, road-following route between two points.
class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int etaMinutes;

  const RouteResult({required this.points, required this.distanceKm, required this.etaMinutes});
}

/// Fetches real walking/cycling/driving routes from the free, public
/// OpenStreetMap routing service at routing.openstreetmap.de (the same
/// OSRM-based service that powers openstreetmap.org's own "Directions"
/// panel) — no API key or account needed.
///
/// This is a shared public service with no uptime guarantee; callers should
/// catch [RoutingException] and fall back to [TravelEstimate.from]'s
/// straight-line approximation if a route can't be fetched.
class RoutingService {
  static String _routedHost(TravelMode mode) {
    switch (mode) {
      case TravelMode.walking:
        return 'routed-foot';
      case TravelMode.bike:
        return 'routed-bike';
      case TravelMode.car:
        return 'routed-car';
    }
  }

  static String _profile(TravelMode mode) {
    switch (mode) {
      case TravelMode.walking:
        return 'foot';
      case TravelMode.bike:
        return 'bike';
      case TravelMode.car:
        return 'car';
    }
  }

  static Future<RouteResult> getRoute(LatLng origin, LatLng destination, TravelMode mode) async {
    final host = _routedHost(mode);
    final profile = _profile(mode);
    final uri = Uri.parse(
      'https://routing.openstreetmap.de/$host/route/v1/$profile/'
      '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson',
    );

    final http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 12));
    } catch (_) {
      throw RoutingException('Could not reach the routing service.');
    }

    if (response.statusCode != 200) {
      throw RoutingException('Could not fetch a route (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>?;
    if (data['code'] != 'Ok' || routes == null || routes.isEmpty) {
      throw RoutingException('No route found.');
    }

    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;
    final points = coordinates
        .map((c) => c as List<dynamic>)
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();

    return RouteResult(
      points: points,
      distanceKm: (route['distance'] as num).toDouble() / 1000,
      etaMinutes: ((route['duration'] as num).toDouble() / 60).round(),
    );
  }
}
