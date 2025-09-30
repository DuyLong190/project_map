import 'location_model.dart';
import 'route_model.dart';

class SavedRouteModel {
  final String id;
  final String name;
  final String description;
  final LocationModel startLocation;
  final LocationModel endLocation;
  final RouteModel route;
  final DateTime createdAt;
  final DateTime? lastAccessed;
  final bool isFavorite;

  const SavedRouteModel({
    required this.id,
    required this.name,
    required this.description,
    required this.startLocation,
    required this.endLocation,
    required this.route,
    required this.createdAt,
    this.lastAccessed,
    this.isFavorite = false,
  });

  factory SavedRouteModel.create({
    required String name,
    required String description,
    required LocationModel startLocation,
    required LocationModel endLocation,
    required RouteModel route,
  }) {
    return SavedRouteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      startLocation: startLocation,
      endLocation: endLocation,
      route: route,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startLocation': startLocation.toJson(),
      'endLocation': endLocation.toJson(),
      'route': route.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastAccessed': lastAccessed?.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory SavedRouteModel.fromJson(Map<String, dynamic> json) {
    return SavedRouteModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      startLocation: LocationModel.fromJson(json['startLocation']),
      endLocation: LocationModel.fromJson(json['endLocation']),
      route: RouteModel.fromJson(json['route']),
      createdAt: DateTime.parse(json['createdAt']),
      lastAccessed: json['lastAccessed'] != null
          ? DateTime.parse(json['lastAccessed'])
          : null,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  SavedRouteModel copyWith({
    String? id,
    String? name,
    String? description,
    LocationModel? startLocation,
    LocationModel? endLocation,
    RouteModel? route,
    DateTime? createdAt,
    DateTime? lastAccessed,
    bool? isFavorite,
  }) {
    return SavedRouteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      route: route ?? this.route,
      createdAt: createdAt ?? this.createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // Mark as accessed
  SavedRouteModel markAsAccessed() {
    return copyWith(lastAccessed: DateTime.now());
  }

  // Toggle favorite
  SavedRouteModel toggleFavorite() {
    return copyWith(isFavorite: !isFavorite);
  }

  // Get display info
  String get displayInfo {
    return '${route.distance.toStringAsFixed(1)} km • ${route.duration.toStringAsFixed(0)} phút';
  }

  String get shortDescription {
    if (description.isEmpty) {
      return 'Từ ${startLocation.address} đến ${endLocation.address}';
    }
    return description;
  }

  @override
  String toString() {
    return 'SavedRouteModel(id: $id, name: $name, distance: ${route.distance.toStringAsFixed(1)}km)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedRouteModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
