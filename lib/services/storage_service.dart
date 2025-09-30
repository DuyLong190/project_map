import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_route_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _savedRoutesKey = 'saved_routes';

  /// Save a route to local storage
  Future<bool> saveRoute(SavedRouteModel route) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRoutes = await getSavedRoutes();

      // Check if route with same ID already exists
      final existingIndex = savedRoutes.indexWhere((r) => r.id == route.id);
      if (existingIndex != -1) {
        savedRoutes[existingIndex] = route;
      } else {
        savedRoutes.add(route);
      }

      // Sort by creation date (newest first)
      savedRoutes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Save to storage
      final routesJson = savedRoutes.map((r) => r.toJson()).toList();
      return await prefs.setString(_savedRoutesKey, json.encode(routesJson));
    } catch (e) {
      print('Error saving route: $e');
      return false;
    }
  }

  /// Get all saved routes
  Future<List<SavedRouteModel>> getSavedRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routesString = prefs.getString(_savedRoutesKey);

      if (routesString == null || routesString.isEmpty) {
        return [];
      }

      final List<dynamic> routesJson = json.decode(routesString);
      return routesJson.map((json) => SavedRouteModel.fromJson(json)).toList();
    } catch (e) {
      print('Error loading saved routes: $e');
      return [];
    }
  }

  /// Get favorite routes only
  Future<List<SavedRouteModel>> getFavoriteRoutes() async {
    final allRoutes = await getSavedRoutes();
    return allRoutes.where((route) => route.isFavorite).toList();
  }

  /// Delete a saved route
  Future<bool> deleteRoute(String routeId) async {
    try {
      final savedRoutes = await getSavedRoutes();
      savedRoutes.removeWhere((route) => route.id == routeId);

      final prefs = await SharedPreferences.getInstance();
      final routesJson = savedRoutes.map((r) => r.toJson()).toList();
      return await prefs.setString(_savedRoutesKey, json.encode(routesJson));
    } catch (e) {
      print('Error deleting route: $e');
      return false;
    }
  }

  /// Update route (mark as accessed, toggle favorite, etc.)
  Future<bool> updateRoute(SavedRouteModel updatedRoute) async {
    return await saveRoute(updatedRoute);
  }

  /// Clear all saved routes
  Future<bool> clearAllRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_savedRoutesKey);
    } catch (e) {
      print('Error clearing routes: $e');
      return false;
    }
  }

  /// Get route by ID
  Future<SavedRouteModel?> getRouteById(String routeId) async {
    final savedRoutes = await getSavedRoutes();
    try {
      return savedRoutes.firstWhere((route) => route.id == routeId);
    } catch (e) {
      return null;
    }
  }

  /// Search routes by name or description
  Future<List<SavedRouteModel>> searchRoutes(String query) async {
    final savedRoutes = await getSavedRoutes();
    if (query.isEmpty) return savedRoutes;

    final lowerQuery = query.toLowerCase();
    return savedRoutes.where((route) {
      return route.name.toLowerCase().contains(lowerQuery) ||
          route.description.toLowerCase().contains(lowerQuery) ||
          route.startLocation.address.toLowerCase().contains(lowerQuery) ||
          route.endLocation.address.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final savedRoutes = await getSavedRoutes();
    final favoriteRoutes = savedRoutes.where((r) => r.isFavorite).length;

    return {
      'totalRoutes': savedRoutes.length,
      'favoriteRoutes': favoriteRoutes,
      'totalDistance': savedRoutes.fold(
        0.0,
        (sum, route) => sum + route.route.distance,
      ),
      'oldestRoute': savedRoutes.isEmpty ? null : savedRoutes.last.createdAt,
      'newestRoute': savedRoutes.isEmpty ? null : savedRoutes.first.createdAt,
    };
  }

  /// Export routes as JSON
  Future<String> exportRoutes() async {
    final savedRoutes = await getSavedRoutes();
    return json.encode(savedRoutes.map((r) => r.toJson()).toList());
  }

  /// Import routes from JSON
  Future<bool> importRoutes(String jsonData) async {
    try {
      final List<dynamic> routesJson = json.decode(jsonData);
      final importedRoutes = routesJson
          .map((json) => SavedRouteModel.fromJson(json))
          .toList();

      final savedRoutes = await getSavedRoutes();
      savedRoutes.addAll(importedRoutes);

      final prefs = await SharedPreferences.getInstance();
      final routesJsonString = savedRoutes.map((r) => r.toJson()).toList();
      return await prefs.setString(
        _savedRoutesKey,
        json.encode(routesJsonString),
      );
    } catch (e) {
      print('Error importing routes: $e');
      return false;
    }
  }
}
