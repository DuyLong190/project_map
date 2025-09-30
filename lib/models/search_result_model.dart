import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchResultModel {
  final String name;
  final String address;
  final LatLng coordinates;
  final String? placeId;
  final String? type;
  final double? rating;
  final DateTime timestamp;

  const SearchResultModel({
    required this.name,
    required this.address,
    required this.coordinates,
    this.placeId,
    this.type,
    this.rating,
    required this.timestamp,
  });

  factory SearchResultModel.fromGeocodingResult(
    String query,
    double latitude,
    double longitude,
    String address,
  ) {
    return SearchResultModel(
      name: query,
      address: address,
      coordinates: LatLng(latitude, longitude),
      timestamp: DateTime.now(),
    );
  }

  factory SearchResultModel.fromMap(Map<String, dynamic> data) {
    return SearchResultModel(
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      coordinates: LatLng(data['latitude'], data['longitude']),
      placeId: data['placeId'],
      type: data['type'],
      rating: data['rating']?.toDouble(),
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'placeId': placeId,
      'type': type,
      'rating': rating,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      coordinates: LatLng(json['latitude'], json['longitude']),
      placeId: json['placeId'],
      type: json['type'],
      rating: json['rating']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  SearchResultModel copyWith({
    String? name,
    String? address,
    LatLng? coordinates,
    String? placeId,
    String? type,
    double? rating,
    DateTime? timestamp,
  }) {
    return SearchResultModel(
      name: name ?? this.name,
      address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates,
      placeId: placeId ?? this.placeId,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'SearchResultModel(name: $name, address: $address, coordinates: $coordinates)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchResultModel &&
        other.name == name &&
        other.address == address &&
        other.coordinates == coordinates &&
        other.placeId == placeId;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        address.hashCode ^
        coordinates.hashCode ^
        placeId.hashCode;
  }
}
