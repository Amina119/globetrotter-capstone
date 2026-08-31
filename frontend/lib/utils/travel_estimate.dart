import 'dart:math';

import 'package:latlong2/latlong.dart';

enum TravelMode { walking, bike, car }

/// Estimated distance/time/price to reach a destination on foot, by
/// moto-taxi ("bike"), or by car/taxi — computed locally from straight-line
/// distance, no routing API or API key needed, works offline.
///
/// Not real road-routing: [_roadFactor] approximates how much longer real
/// roads are than a straight line, per-mode speeds are typical Yaoundé
/// averages, and fares use a flat rate per km with a minimum. All are
/// simple constants — tune them to match local rates.
class TravelEstimate {
  final TravelMode mode;
  final double distanceKm;
  final int etaMinutes;

  /// Null for walking — there's no fare.
  final int? priceFcfa;

  const TravelEstimate({
    required this.mode,
    required this.distanceKm,
    required this.etaMinutes,
    this.priceFcfa,
  });

  static const double _roadFactor = 1.3;
  static const Distance _distanceCalculator = Distance();

  static const Map<TravelMode, double> _speedKmh = {
    TravelMode.walking: 5,
    TravelMode.bike: 25,
    TravelMode.car: 30,
  };

  static const Map<TravelMode, int> _ratePerKmFcfa = {
    TravelMode.bike: 150,
    TravelMode.car: 250,
  };

  static const Map<TravelMode, int> _minimumFareFcfa = {
    TravelMode.bike: 300,
    TravelMode.car: 500,
  };

  /// Returns null if either point is missing.
  static TravelEstimate? from(LatLng? origin, LatLng? destination, TravelMode mode) {
    if (origin == null || destination == null) return null;

    final straightLineKm = _distanceCalculator.as(LengthUnit.Kilometer, origin, destination);
    final roadKm = straightLineKm * _roadFactor;
    final etaMinutes = (roadKm / _speedKmh[mode]! * 60).round();

    final rate = _ratePerKmFcfa[mode];
    final price = rate == null ? null : max(_minimumFareFcfa[mode]!, (roadKm * rate).round());

    return TravelEstimate(mode: mode, distanceKm: roadKm, etaMinutes: etaMinutes, priceFcfa: price);
  }

  /// All three modes at once, in a fixed order (walking, bike, car). Empty
  /// if either point is missing.
  static List<TravelEstimate> allModes(LatLng? origin, LatLng? destination) {
    return TravelMode.values.map((m) => from(origin, destination, m)).whereType<TravelEstimate>().toList();
  }

  /// Builds an estimate from a real, already-routed distance/duration (e.g.
  /// from [RoutingService]) instead of the straight-line approximation —
  /// the road factor doesn't apply here since the distance already follows
  /// actual roads/paths. Price still uses the same per-mode rate/minimum.
  factory TravelEstimate.fromRoute({
    required TravelMode mode,
    required double distanceKm,
    required int etaMinutes,
  }) {
    final rate = _ratePerKmFcfa[mode];
    final price = rate == null ? null : max(_minimumFareFcfa[mode]!, (distanceKm * rate).round());
    return TravelEstimate(mode: mode, distanceKm: distanceKm, etaMinutes: etaMinutes, priceFcfa: price);
  }

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';

  String get etaLabel => etaMinutes < 60 ? '$etaMinutes min' : '${(etaMinutes / 60).toStringAsFixed(1)} h';
}
