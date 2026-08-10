import 'dart:math';

import 'package:latlong2/latlong.dart';

/// Estimated distance/time/price to reach a destination by moto-taxi
/// ("bike"), computed locally from straight-line distance — no routing API,
/// no API key, works offline.
///
/// Not real road-routing: [kmRoadFactor] approximates how much longer real
/// roads are than a straight line, [avgSpeedKmh] is a typical Yaoundé
/// moto-taxi city-traffic speed, and the fare uses a flat rate per km with a
/// minimum. All four are simple constants — tune them to match local rates.
class BikeEstimate {
  final double distanceKm;
  final int etaMinutes;
  final int priceFcfa;

  const BikeEstimate({required this.distanceKm, required this.etaMinutes, required this.priceFcfa});

  static const double kmRoadFactor = 1.3;
  static const double avgSpeedKmh = 25;
  static const int ratePerKmFcfa = 150;
  static const int minimumFareFcfa = 300;

  static const Distance _distanceCalculator = Distance();

  /// Returns null if either point is missing.
  static BikeEstimate? from(LatLng? origin, LatLng? destination) {
    if (origin == null || destination == null) return null;

    final straightLineKm = _distanceCalculator.as(LengthUnit.Kilometer, origin, destination);
    final roadKm = straightLineKm * kmRoadFactor;
    final etaMinutes = (roadKm / avgSpeedKmh * 60).round();
    final price = max(minimumFareFcfa, (roadKm * ratePerKmFcfa).round());

    return BikeEstimate(distanceKm: roadKm, etaMinutes: etaMinutes, priceFcfa: price);
  }

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';

  String get etaLabel => etaMinutes < 60 ? '$etaMinutes min' : '${(etaMinutes / 60).toStringAsFixed(1)} h';

  String get priceLabel => '$priceFcfa FCFA';

  String get summary => '$distanceLabel · $etaLabel · $priceLabel by bike';
}
