import 'dart:math';

import 'package:latlong2/latlong.dart';

enum TravelMode { walking, motoSansBachement, motoAvecBachement, car }

/// Estimated distance/time/price to reach a destination on foot, by private
/// moto-taxi ("sans bâchement"), by shared moto-taxi ("avec bâchement"), or
/// by car/taxi — computed locally from straight-line distance, no routing
/// API or API key needed, works offline.
///
/// Not real road-routing: [_roadFactor] approximates how much longer real
/// roads are than a straight line, and per-mode speeds are typical Yaoundé
/// averages. Fares follow Cameroon (Douala/Yaoundé) local market rates: a
/// base fare covering a minimum distance/duration, plus per-km and
/// per-minute rates beyond that. "Moto avec bâchement" (shared ride) is a
/// flat 45% discount off "moto sans bâchement" (private ride)'s raw fare.
/// All final fares are rounded to the nearest 50 XAF for cash handling.
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
    TravelMode.motoSansBachement: 25,
    TravelMode.motoAvecBachement: 25,
    TravelMode.car: 30,
  };

  /// Raw (unrounded) "moto sans bâchement" fare — also the base used to
  /// derive "moto avec bâchement"'s discounted fare.
  static double _motoSansBachementRaw(double distanceKm, int etaMinutes) {
    const baseFare = 250.0;
    const baseKm = 1.5;
    const baseMinutes = 3;
    const ratePerKm = 70.0;
    const ratePerMinute = 15.0;

    if (distanceKm <= baseKm && etaMinutes <= baseMinutes) return baseFare;
    return baseFare + (max(0, distanceKm - baseKm) * ratePerKm) + (max(0, etaMinutes - baseMinutes) * ratePerMinute);
  }

  static double _carRaw(double distanceKm, int etaMinutes) {
    const baseFare = 450.0;
    const baseKm = 1.8;
    const baseMinutes = 5;
    const ratePerKm = 90.0;
    const ratePerMinute = 25.0;

    if (distanceKm <= baseKm && etaMinutes <= baseMinutes) return baseFare;
    return baseFare + (max(0, distanceKm - baseKm) * ratePerKm) + (max(0, etaMinutes - baseMinutes) * ratePerMinute);
  }

  /// Rounds to the nearest 50 XAF, for easy cash handling.
  static int _roundToNearest50(double fcfa) => (fcfa / 50).round() * 50;

  static int? _priceFor(TravelMode mode, double distanceKm, int etaMinutes) {
    switch (mode) {
      case TravelMode.walking:
        return null;
      case TravelMode.motoSansBachement:
        return _roundToNearest50(_motoSansBachementRaw(distanceKm, etaMinutes));
      case TravelMode.motoAvecBachement:
        return _roundToNearest50(_motoSansBachementRaw(distanceKm, etaMinutes) * 0.55);
      case TravelMode.car:
        return _roundToNearest50(_carRaw(distanceKm, etaMinutes));
    }
  }

  /// Returns null if either point is missing.
  static TravelEstimate? from(LatLng? origin, LatLng? destination, TravelMode mode) {
    if (origin == null || destination == null) return null;

    final straightLineKm = _distanceCalculator.as(LengthUnit.Kilometer, origin, destination);
    final roadKm = straightLineKm * _roadFactor;
    final etaMinutes = (roadKm / _speedKmh[mode]! * 60).round();
    final price = _priceFor(mode, roadKm, etaMinutes);

    return TravelEstimate(mode: mode, distanceKm: roadKm, etaMinutes: etaMinutes, priceFcfa: price);
  }

  /// All modes at once, in a fixed order (walking, moto sans bâchement,
  /// moto avec bâchement, car). Empty if either point is missing.
  static List<TravelEstimate> allModes(LatLng? origin, LatLng? destination) {
    return TravelMode.values.map((m) => from(origin, destination, m)).whereType<TravelEstimate>().toList();
  }

  /// Builds an estimate from a real, already-routed distance/duration (e.g.
  /// from [RoutingService]) instead of the straight-line approximation —
  /// the road factor doesn't apply here since the distance already follows
  /// actual roads/paths. Price still uses the same per-mode fare formula.
  factory TravelEstimate.fromRoute({
    required TravelMode mode,
    required double distanceKm,
    required int etaMinutes,
  }) {
    final price = _priceFor(mode, distanceKm, etaMinutes);
    return TravelEstimate(mode: mode, distanceKm: distanceKm, etaMinutes: etaMinutes, priceFcfa: price);
  }

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';

  String get etaLabel => etaMinutes < 60 ? '$etaMinutes min' : '${(etaMinutes / 60).toStringAsFixed(1)} h';
}
