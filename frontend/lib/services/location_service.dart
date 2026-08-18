import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationUnavailableException implements Exception {
  final String message;
  LocationUnavailableException(this.message);

  @override
  String toString() => message;
}

/// Thin wrapper around `geolocator`: checks/requests permission and reads
/// the device's current position.
class LocationService {
  /// Returns the user's current position, requesting permission first if
  /// needed. Throws [LocationUnavailableException] with a user-facing
  /// message if location can't be obtained.
  static Future<LatLng> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationUnavailableException('Location services are turned off on this device.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationUnavailableException('Location permission was denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationUnavailableException(
        'Location permission is permanently denied. Enable it in system settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LatLng(position.latitude, position.longitude);
  }

  /// A live stream of the user's position, for showing their marker moving
  /// on the map. Distance-filtered to avoid flooding updates.
  static Stream<LatLng> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).map((p) => LatLng(p.latitude, p.longitude));
  }
}
