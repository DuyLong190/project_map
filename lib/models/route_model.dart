import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteModel {
  final List<LatLng> coordinates;
  final double distance; // in kilometers
  final double duration; // in minutes
  final String? routeInfo;
  final DateTime? timestamp;
  final bool isEstimated; // true if it's a fallback straight line

  const RouteModel({
    required this.coordinates,
    required this.distance,
    required this.duration,
    this.routeInfo,
    this.timestamp,
    this.isEstimated = false,
  });

  factory RouteModel.empty() {
    return RouteModel(
      coordinates: [],
      distance: 0.0,
      duration: 0.0,
      routeInfo: '',
    );
  }

  factory RouteModel.fromOsrmResponse(Map<String, dynamic> data) {
    List<dynamic> coordinates = data['routes'][0]['geometry']['coordinates'];
    List<LatLng> routeCoordinates = coordinates
        .map((coord) => LatLng(coord[1], coord[0]))
        .toList();

    Map<String, dynamic> route = data['routes'][0];
    double distance = route['distance'] / 1000; // Convert to km
    double duration = route['duration'] / 60; // Convert to minutes

    return RouteModel(
      coordinates: routeCoordinates,
      distance: distance,
      duration: duration,
      routeInfo:
          'Khoảng cách: ${distance.toStringAsFixed(1)} km\n'
          'Thời gian: ${duration.toStringAsFixed(0)} phút',
      timestamp: DateTime.now(),
      isEstimated: false,
    );
  }

  factory RouteModel.createEstimatedRoute(
    LatLng start,
    LatLng end,
    double distance,
  ) {
    List<LatLng> coordinates = [start, end];

    return RouteModel(
      coordinates: coordinates,
      distance: distance,
      duration: distance * 2, // Estimate 2 minutes per km
      routeInfo:
          'Đường thẳng (ước tính): ${distance.toStringAsFixed(1)} km\n'
          'Thời gian: ${(distance * 2).toStringAsFixed(0)} phút (ước tính)',
      timestamp: DateTime.now(),
      isEstimated: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coordinates': coordinates
          .map((c) => {'latitude': c.latitude, 'longitude': c.longitude})
          .toList(),
      'distance': distance,
      'duration': duration,
      'routeInfo': routeInfo,
      'timestamp': timestamp?.toIso8601String(),
      'isEstimated': isEstimated,
    };
  }

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    List<LatLng> coords = (json['coordinates'] as List)
        .map((c) => LatLng(c['latitude'], c['longitude']))
        .toList();

    return RouteModel(
      coordinates: coords,
      distance: json['distance']?.toDouble() ?? 0.0,
      duration: json['duration']?.toDouble() ?? 0.0,
      routeInfo: json['routeInfo'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
      isEstimated: json['isEstimated'] ?? false,
    );
  }

  RouteModel copyWith({
    List<LatLng>? coordinates,
    double? distance,
    double? duration,
    String? routeInfo,
    DateTime? timestamp,
    bool? isEstimated,
  }) {
    return RouteModel(
      coordinates: coordinates ?? this.coordinates,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      routeInfo: routeInfo ?? this.routeInfo,
      timestamp: timestamp ?? this.timestamp,
      isEstimated: isEstimated ?? this.isEstimated,
    );
  }

  bool get isEmpty => coordinates.isEmpty;

  @override
  String toString() {
    return 'RouteModel(distance: ${distance.toStringAsFixed(1)}km, '
        'duration: ${duration.toStringAsFixed(0)}min, '
        'points: ${coordinates.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteModel &&
        other.coordinates.length == coordinates.length &&
        other.distance == distance &&
        other.duration == duration &&
        other.isEstimated == isEstimated;
  }

  @override
  int get hashCode {
    return coordinates.hashCode ^
        distance.hashCode ^
        duration.hashCode ^
        isEstimated.hashCode;
  }
}
