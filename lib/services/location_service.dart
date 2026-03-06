import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static String? _city;
  static String? _country;
  static String? _fullLocation;
  static bool _initialized = false;

  static Future<void> ensureInitialized({bool forceRefresh = false}) async {
    if (_initialized && !forceRefresh) return;
    _initialized = true;

    final status = await Permission.location.request();
    if (!status.isGranted) {
      _fullLocation = 'Location permission denied';
      _city = null;
      _country = null;
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _city = place.subLocality?.isNotEmpty == true
            ? place.subLocality
            : place.locality ?? 'Unknown City';
        _country = place.country ?? 'Unknown Country';
        _fullLocation = '$_city, $_country';
      } else {
        _fullLocation = 'Location not found';
      }
    } catch (e) {
      _fullLocation = 'Location unavailable';
    }
  }

  /// Public getters
  static String get city => _city ?? 'Unknown City';
  static String get country => _country ?? 'Unknown Country';
  static String get fullLocation => _fullLocation ?? 'Fetching location...';

  /// ✅ Add this public setter for manual fallback
  static void setManualLocation({
    required String city,
    required String country,
  }) {
    _city = city;
    _country = country;
    _fullLocation = '$city, $country';
  }
}
