import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';

class RouteService {
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  /// Get route using OSRM API
  Future<RouteModel> getRoute(LocationModel start, LocationModel end) async {
    try {
      String startLng = start.coordinates.longitude.toString();
      String startLat = start.coordinates.latitude.toString();
      String endLng = end.coordinates.longitude.toString();
      String endLat = end.coordinates.latitude.toString();

      String url =
          'http://router.project-osrm.org/route/v1/driving/'
          '$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson';

      print('Requesting route from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          return RouteModel.fromOsrmResponse(data);
        } else {
          throw Exception('No routes found in response');
        }
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Route API error: $e');
      // Fallback to estimated route
      return _createEstimatedRoute(start, end);
    }
  }

  /// Create an estimated straight-line route as fallback
  RouteModel _createEstimatedRoute(LocationModel start, LocationModel end) {
    double distance =
        Geolocator.distanceBetween(
          start.coordinates.latitude,
          start.coordinates.longitude,
          end.coordinates.latitude,
          end.coordinates.longitude,
        ) /
        1000; // Convert to km

    return RouteModel.createEstimatedRoute(
      start.coordinates,
      end.coordinates,
      distance,
    );
  }

  /// Get multiple route options (future enhancement)
  Future<List<RouteModel>> getMultipleRoutes(
    LocationModel start,
    LocationModel end,
  ) async {
    // For now, return single route
    // This can be enhanced to return multiple route options
    RouteModel route = await getRoute(start, end);
    return [route];
  }

  /// Calculate route bounds for camera fitting
  LatLngBounds? calculateRouteBounds(RouteModel route) {
    if (route.coordinates.isEmpty) return null;

    double minLat = route.coordinates.first.latitude;
    double maxLat = route.coordinates.first.latitude;
    double minLng = route.coordinates.first.longitude;
    double maxLng = route.coordinates.first.longitude;

    for (LatLng point in route.coordinates) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Validate if two locations are too close for routing
  bool areLocationsTooClose(
    LocationModel start,
    LocationModel end, {
    double minimumDistanceMeters = 100,
  }) {
    double distance = Geolocator.distanceBetween(
      start.coordinates.latitude,
      start.coordinates.longitude,
      end.coordinates.latitude,
      end.coordinates.longitude,
    );

    return distance < minimumDistanceMeters;
  }
}
