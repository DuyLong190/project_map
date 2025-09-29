import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_data.dart';

class RoutingService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  final String apiKey;

  RoutingService({required this.apiKey});

  Future<RouteData> getRoute({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'driving',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=$travelMode'
          '&key=$apiKey');

      debugPrint('Requesting route: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return _parseRouteData(data['routes'][0]);
        } else {
          debugPrint('Directions API error: ${data['status']}');
          return RouteData.empty();
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode}');
        return RouteData.empty();
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
      return RouteData.empty();
    }
  }

  RouteData _parseRouteData(Map<String, dynamic> route) {
    final legs = route['legs'] as List;
    final leg = legs[0];
    
    // Lấy thông tin khoảng cách và thời gian
    final distance = leg['distance']['text'] as String;
    final duration = leg['duration']['text'] as String;
    
    // Lấy polyline và decode thành các điểm
    final overviewPolyline = route['overview_polyline']['points'] as String;
    final points = _decodePolyline(overviewPolyline);
    
    // Lấy hướng dẫn đường đi
    final steps = leg['steps'] as List;
    final instructions = steps.map((step) => step['html_instructions'] as String).join('\n');
    
    return RouteData(
      points: points,
      distance: distance,
      duration: duration,
      instructions: instructions,
      polyline: overviewPolyline,
    );
  }

  List<LatLng> _decodePolyline(String polyline) {
    try {
      List<LatLng> points = [];
      int index = 0;
      int lat = 0;
      int lng = 0;

      while (index < polyline.length) {
        int b, shift = 0, result = 0;
        do {
          b = polyline.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lat += dlat;

        shift = 0;
        result = 0;
        do {
          b = polyline.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lng += dlng;

        points.add(LatLng(lat / 1e5, lng / 1e5));
      }

      return points;
    } catch (e) {
      debugPrint('Error decoding polyline: $e');
      return [];
    }
  }

  // Tính khoảng cách giữa hai điểm (Haversine formula)
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Bán kính Trái Đất tính bằng mét
    const double pi = 3.14159265359;
    
    final lat1Rad = point1.latitude * (pi / 180);
    final lat2Rad = point2.latitude * (pi / 180);
    final deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    final deltaLngRad = (point2.longitude - point1.longitude) * (pi / 180);

    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }
}
