import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteData {
  final List<LatLng> points;
  final String distance;
  final String duration;
  final String instructions;
  final String polyline;

  RouteData({
    required this.points,
    required this.distance,
    required this.duration,
    required this.instructions,
    required this.polyline,
  });

  factory RouteData.empty() {
    return RouteData(
      points: [],
      distance: '',
      duration: '',
      instructions: '',
      polyline: '',
    );
  }

  bool get isEmpty => points.isEmpty;

  @override
  String toString() {
    return 'RouteData(distance: $distance, duration: $duration, points: ${points.length})';
  }
}
