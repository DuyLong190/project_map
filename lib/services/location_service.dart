import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Get current location with permission handling
  Future<LocationModel?> getCurrentLocation() async {
    try {
      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      String address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return LocationModel.fromLatLng(
        LatLng(position.latitude, position.longitude),
        address,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Get address from latitude and longitude
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.street}, ${place.subLocality}, "
            "${place.locality}, ${place.administrativeArea}, "
            "${place.country}";
      }
      return 'Unknown location';
    } catch (e) {
      print('Error getting address: $e');
      return 'Unknown location';
    }
  }

  /// Get coordinates from address
  Future<List<LocationModel>> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      List<LocationModel> results = [];
      for (int i = 0; i < locations.length && i < 5; i++) {
        Location location = locations[i];
        String fullAddress = await getAddressFromCoordinates(
          location.latitude,
          location.longitude,
        );

        results.add(
          LocationModel.fromLatLng(
            LatLng(location.latitude, location.longitude),
            fullAddress,
          ),
        );
      }

      return results;
    } catch (e) {
      print('Error getting coordinates from address: $e');
      return [];
    }
  }

  /// Calculate distance between two points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get location permission status
  Future<LocationPermission> getPermissionStatus() async {
    return await Geolocator.checkPermission();
  }
}
