import 'package:geolocator/geolocator.dart';

class LocationFix {
  const LocationFix.coords(this.latitude, this.longitude) : message = null;
  const LocationFix.error(this.message)
      : latitude = null,
        longitude = null;

  final double? latitude;
  final double? longitude;
  final String? message;

  bool get ok => latitude != null && longitude != null;
}

class LocationService {
  const LocationService();

  Future<LocationFix> currentFix() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return const LocationFix.error(
          'Location services are turned off. You can still use Arrive on a flagged place.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationFix.error(
          'Location permission was not granted. You can still use Arrive on a flagged place.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      return LocationFix.coords(position.latitude, position.longitude);
    } catch (_) {
      return const LocationFix.error(
        'This browser or device did not return a location. Use Arrive to walk through a visit.',
      );
    }
  }

  double distanceMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
  }
}
