import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationModel {
  final LatLng coordinates;
  final String address;
  final String? name;
  final DateTime? timestamp;

  const LocationModel({
    required this.coordinates,
    required this.address,
    this.name,
    this.timestamp,
  });

  factory LocationModel.fromLatLng(LatLng latLng, String address) {
    return LocationModel(
      coordinates: latLng,
      address: address,
      timestamp: DateTime.now(),
    );
  }

  factory LocationModel.fromSearchResult(Map<String, dynamic> data) {
    return LocationModel(
      coordinates: LatLng(data['latitude'], data['longitude']),
      address: data['address'] ?? '',
      name: data['name'],
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'address': address,
      'name': name,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      coordinates: LatLng(json['latitude'], json['longitude']),
      address: json['address'] ?? '',
      name: json['name'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }

  LocationModel copyWith({
    LatLng? coordinates,
    String? address,
    String? name,
    DateTime? timestamp,
  }) {
    return LocationModel(
      coordinates: coordinates ?? this.coordinates,
      address: address ?? this.address,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'LocationModel(coordinates: $coordinates, address: $address, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.coordinates == coordinates &&
        other.address == address &&
        other.name == name;
  }

  @override
  int get hashCode {
    return coordinates.hashCode ^ address.hashCode ^ name.hashCode;
  }
}
